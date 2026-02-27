/**
 * Update S3 Report Index (data.json)
 *
 * Maintains a rolling index of the last N Allure report uploads in S3.
 * Each entry records the S3 directory, build number, and aggregated test metadata
 * (pass/fail/skip/broken counts, start/stop timestamps) extracted from behaviors.json.
 *
 * Used by the S3-hosted report index page to list recent test runs with summary stats.
 * Mirrors the web-ott-automation updateDataJson.js script.
 *
 * Environment Variables:
 *   S3_REPORT_DIR  - S3 path for this report (e.g. 'reports/roku/12345')
 *   BUILD_NUMBER   - CI build/run identifier for display name
 *
 * Usage:
 *   1. Download existing data.json from S3 (or create empty [])
 *   2. Run this script: S3_REPORT_DIR=reports/roku/123 BUILD_NUMBER=123 node updateReportDataJson.js
 *   3. Upload the updated data.json back to S3
 */
const fs = require('fs');
const path = require('path');

const DATA_JSON_PATH = path.join(process.cwd(), 'data.json');
const BEHAVIORS_JSON_PATH = path.join(process.cwd(), 'allure-report/data/behaviors.json');
const MAX_RECORDS = 20;

/**
 * Removes duplicate entries from a list based on a property value.
 * Keeps the first occurrence (newest, since new records are prepended).
 * @param {Array} list - Array of objects to deduplicate
 * @param {string} property - Property name to check for uniqueness
 * @returns {Array} Deduplicated array
 */
function dedupe(list, property) {
  const seen = new Set();
  return list.filter((item) => {
    if (seen.has(item[property])) return false;
    seen.add(item[property]);
    return true;
  });
}

/**
 * Recursively collects leaf test-case nodes from the Allure behaviors tree.
 * Leaf nodes have a `status` property; branch nodes only have `children`.
 * @param {Object} node - A node in the behaviors tree
 * @param {Array} leaves - Accumulator for discovered leaf nodes
 */
function collectLeaves(node, leaves) {
  if (node.status) {
    leaves.push(node);
    return;
  }
  if (Array.isArray(node.children)) {
    for (const child of node.children) {
      collectLeaves(child, leaves);
    }
  }
}

/**
 * Extracts aggregated test metadata from the Allure behaviors.json file.
 * Recursively traverses the nested children tree to find actual test-case
 * nodes (leaves), then counts pass/fail/skip/broken and determines the
 * overall time range.
 * @returns {Object} Metadata with counts and start/stop timestamps, or empty object if unavailable
 */
function extractMetadata() {
  if (!fs.existsSync(BEHAVIORS_JSON_PATH)) return {};

  let behaviors;
  try {
    behaviors = JSON.parse(fs.readFileSync(BEHAVIORS_JSON_PATH, 'utf8'));
  } catch (err) {
    console.warn(`Could not parse ${BEHAVIORS_JSON_PATH}: ${err.message}`);
    return {};
  }

  if (!behaviors.children) return {};

  const leaves = [];
  for (const child of behaviors.children) {
    collectLeaves(child, leaves);
  }

  const VALID_STATUSES = new Set(['passed', 'failed', 'skipped', 'broken', 'unknown']);
  const counts = { passed: 0, failed: 0, skipped: 0, broken: 0, unknown: 0 };
  let start = Number.POSITIVE_INFINITY;
  let stop = Number.NEGATIVE_INFINITY;

  for (const leaf of leaves) {
    if (VALID_STATUSES.has(leaf.status)) {
      counts[leaf.status]++;
    }
    if (leaf.time) {
      if (leaf.time.start < start) start = leaf.time.start;
      if (leaf.time.stop > stop) stop = leaf.time.stop;
    }
  }

  return {
    ...counts,
    start: Number.isFinite(start) ? start : 0,
    stop: Number.isFinite(stop) ? stop : 0,
  };
}

/**
 * Updates data.json with a new report entry.
 * Prepends the new record, deduplicates by directory, and trims to MAX_RECORDS.
 * @param {string} s3Dir - The S3 directory path for this report (e.g. 'reports/roku/12345')
 */
function updateDataJson(s3Dir) {
  let indexList = [];
  if (fs.existsSync(DATA_JSON_PATH)) {
    try {
      indexList = JSON.parse(fs.readFileSync(DATA_JSON_PATH, 'utf8'));
    } catch (err) {
      console.warn(`Could not parse ${DATA_JSON_PATH}, starting fresh: ${err.message}`);
      indexList = [];
    }
  }

  const buildNumber = process.env.BUILD_NUMBER || '';

  const record = {
    directory: s3Dir,
    displayName: buildNumber ? `Workflow #${buildNumber}` : '',
    buildNumber,
    metadata: extractMetadata(),
    updatedAt: new Date().toISOString(),
  };

  const newIndexList = dedupe([record, ...indexList], 'directory');
  fs.writeFileSync(DATA_JSON_PATH, JSON.stringify(newIndexList.slice(0, MAX_RECORDS), null, 2));

  const meta = record.metadata;
  if (meta.passed !== undefined) {
    console.log(`Updated data.json: ${meta.passed} passed, ${meta.failed} failed, ${meta.skipped} skipped, ${meta.broken} broken`);
  }
  console.log(`Index now contains ${Math.min(newIndexList.length, MAX_RECORDS)} records`);
}

const s3ReportDir = process.env.S3_REPORT_DIR;
if (!s3ReportDir) {
  console.error('S3_REPORT_DIR environment variable is required');
  process.exit(1);
}
updateDataJson(s3ReportDir);
