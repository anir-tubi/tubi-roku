/**
 * Push Allure Report to Automation UI Dashboard
 *
 * Reads the generated Allure report (suites.json + individual test case files)
 * and pushes it to the Automation UI's direct ingestion API. Only failed/broken
 * test case details are included to keep the payload size manageable.
 *
 * Mirrors the web-ott-automation pushToAutomationUI.cjs script.
 *
 * Environment Variables:
 *   API_URL            - Full ingest-direct endpoint URL (required)
 *   PLATFORM           - Platform identifier (default: 'roku')
 *   REPORT_ID          - Unique report identifier, typically github.run_id
 *   REPORT_DIR         - Path to the generated Allure report (default: 'allure-report')
 *   GITHUB_RUN_ID      - Fallback for REPORT_ID when running in GitHub Actions
 */
import * as fs from 'fs';
import * as path from 'path';
import axios from 'axios';

// --- Configuration ---

const config = {
  reportDir: process.env.REPORT_DIR || 'allure-report',
  apiUrl: process.env.API_URL,
  platform: process.env.PLATFORM || 'roku',
  reportId: process.env.REPORT_ID || process.env.GITHUB_RUN_ID || String(Date.now()),
  timeout: 60000,
  maxPayloadBytes: 10 * 1024 * 1024,
};

// --- Interfaces ---

interface AllureSuiteChild {
  uid?: string;
  name?: string;
  status?: string;
  time?: { start?: number; stop?: number; duration?: number };
  children?: AllureSuiteChild[];
}

interface AllureSuitesData {
  children?: AllureSuiteChild[];
}

interface IngestPayload {
  platform: string;
  reportId: number;
  reportData: {
    suites: AllureSuitesData;
    testCases: Record<string, unknown>;
  };
  metadata: {
    triggeredBy: string;
    testRunName: string;
  };
}

// --- Report Reading ---

/**
 * Reads and parses the suites.json file from the Allure report directory.
 * This file contains the full test suite hierarchy with pass/fail status for each test.
 */
function readSuitesData(reportDir: string): AllureSuitesData {
  const suitesPath = path.join(reportDir, 'data', 'suites.json');

  if (!fs.existsSync(suitesPath)) {
    throw new Error(`Suites file not found: ${suitesPath}`);
  }

  try {
    return JSON.parse(fs.readFileSync(suitesPath, 'utf-8'));
  } catch (err: any) {
    throw new Error(`Failed to parse ${suitesPath}: ${err.message}`);
  }
}

/**
 * Recursively walks the suites tree to find UIDs of failed or broken tests.
 * A node is considered a test case (not a suite) if it has a `time` property.
 */
function extractFailedTestUids(suitesData: AllureSuitesData): string[] {
  const failedUids: string[] = [];

  function walk(children?: AllureSuiteChild[]): void {
    if (!children) return;
    for (const child of children) {
      const isFailed = child.status === 'failed' || child.status === 'broken';
      if (child.time && isFailed && child.uid) {
        failedUids.push(child.uid);
      }
      if (child.children) walk(child.children);
    }
  }

  walk(suitesData.children);
  return failedUids;
}

/**
 * Reads individual test case detail files ({uid}.json) for the given UIDs.
 * These files contain error messages and stack traces for failed tests,
 * which the dashboard uses to display failure details.
 */
function readTestCaseDetails(reportDir: string, uids: string[]): Record<string, unknown> {
  const testCasesDir = path.join(reportDir, 'data', 'test-cases');
  const testCases: Record<string, unknown> = {};

  if (!fs.existsSync(testCasesDir)) return testCases;

  let loaded = 0;
  for (const uid of uids) {
    const filePath = path.join(testCasesDir, `${uid}.json`);
    try {
      if (fs.existsSync(filePath)) {
        testCases[uid] = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
        loaded++;
      }
    } catch {
      console.warn(`Could not read test case ${uid}`);
    }
  }

  console.log(`Loaded ${loaded}/${uids.length} test case details`);
  return testCases;
}

// --- API Communication ---

/**
 * Builds the payload for the ingest-direct API endpoint.
 */
function buildPayload(suitesData: AllureSuitesData, testCases: Record<string, unknown>): IngestPayload {
  return {
    platform: config.platform,
    reportId: parseInt(String(config.reportId), 10) || Date.now(),
    reportData: {
      suites: suitesData,
      testCases,
    },
    metadata: {
      triggeredBy: 'github-actions',
      testRunName: `Roku Test Run ${config.reportId}`,
    },
  };
}

// --- Main ---

/**
 * Orchestrates the full push flow:
 * 1. Validates configuration
 * 2. Reads suites.json from the Allure report
 * 3. Extracts UIDs of failed/broken tests
 * 4. Reads detailed test case files for failures
 * 5. POSTs the assembled payload to /api/reports/ingest-direct
 */
async function pushReport(): Promise<void> {
  if (!config.apiUrl) {
    throw new Error('API_URL is required');
  }

  if (!fs.existsSync(config.reportDir)) {
    throw new Error(`Report directory does not exist: ${config.reportDir}`);
  }

  console.log(`Pushing report to Automation UI`);
  console.log(`Platform:   ${config.platform}`);
  console.log(`Report ID:  ${config.reportId}`);
  console.log(`Report Dir: ${config.reportDir}`);
  console.log(`API URL:    ${config.apiUrl}`);

  const suitesData = readSuitesData(config.reportDir);
  console.log(`Loaded suites with ${suitesData.children?.length || 0} top-level entries`);

  const failedUids = extractFailedTestUids(suitesData);
  console.log(`Found ${failedUids.length} failed/broken tests`);

  const testCases = readTestCaseDetails(config.reportDir, failedUids);

  const payload = buildPayload(suitesData, testCases);
  const payloadSize = Buffer.byteLength(JSON.stringify(payload));
  console.log(`Payload size: ${(payloadSize / 1024).toFixed(2)} KB`);

  const response = await axios.post(config.apiUrl, payload, {
    headers: { 'Content-Type': 'application/json' },
    timeout: config.timeout,
    maxBodyLength: config.maxPayloadBytes,
  });

  if (response.data?.success) {
    console.log(`Test Run ID:  ${response.data.data?.testRunId}`);
    console.log(`Test Cases:   ${response.data.data?.testCaseResultsCount}`);
    console.log('Report pushed successfully');
  } else {
    throw new Error(`API returned unsuccessful: ${JSON.stringify(response.data)}`);
  }
}

pushReport().catch((error) => {
  console.error(`Failed to push report: ${error.message}`);
  if (error.response) {
    console.error(`Status: ${error.response.status}`);
    console.error(`Response: ${JSON.stringify(error.response.data)}`);
  }
  process.exit(1);
});
