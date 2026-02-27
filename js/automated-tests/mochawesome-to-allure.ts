/**
 * Mocha JSON to Allure Results Converter
 *
 * Reads a Mocha JSON reporter output and generates allure-results/ files
 * that `allure generate` can consume.
 *
 * Expects Mocha JSON reporter format: flat { passes, failures, pending } arrays.
 *
 * Usage:
 *   npx ts-node js/automated-tests/mochawesome-to-allure.ts
 *
 * Environment Variables:
 *   ALLURE_RESULTS_DIR  - Output directory (default: 'allure-results')
 *   REPORT_JSON_PATH    - Path to the JSON report file (default: 'out/ui-tests-output/report.json')
 */
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

const ALLURE_RESULTS_DIR = process.env.ALLURE_RESULTS_DIR || 'allure-results';
const REPORT_JSON_PATH = process.env.REPORT_JSON_PATH || 'out/ui-tests-output/report.json';

// --- Types ---

interface MochaTest {
  title: string;
  fullTitle: string;
  file?: string;
  duration?: number;
  currentRetry?: number;
  speed?: string;
  state?: string;
  pass?: boolean;
  fail?: boolean;
  pending?: boolean;
  skipped?: boolean;
  err?: { message?: string; stack?: string; estack?: string };
}

interface AllureLabel {
  name: string;
  value: string;
}

interface AllureResult {
  uuid: string;
  historyId: string;
  testCaseId: string;
  fullName: string;
  name: string;
  status: string;
  stage: string;
  start: number;
  stop: number;
  labels: AllureLabel[];
  links: any[];
  parameters: any[];
  steps: any[];
  statusDetails?: { message: string; trace: string };
}

// --- Helpers ---

let timestampCursor: number;

function md5(str: string): string {
  return crypto.createHash('md5').update(str).digest('hex');
}

function extractTags(title: string): string[] {
  return title.match(/@[\w]+/g) || [];
}

function mapStatus(test: MochaTest, category: 'pass' | 'fail' | 'pending'): string {
  if (category === 'pending') return 'skipped';
  if (category === 'pass') return 'passed';
  if (category === 'fail') {
    const msg = (test.err?.message || '').toLowerCase();
    if (msg.includes('assert') || msg.includes('expected') || msg.includes('should')) {
      return 'failed';
    }
    return 'broken';
  }
  return 'unknown';
}

function convertTest(test: MochaTest, category: 'pass' | 'fail' | 'pending'): AllureResult {
  const start = timestampCursor;
  const stop = start + (test.duration || 0);
  timestampCursor = stop + 1;

  const labels: AllureLabel[] = [
    { name: 'framework', value: 'mocha' },
    { name: 'language', value: 'typescript' },
  ];

  // Use fullTitle to derive suite labels
  const suiteStr = test.fullTitle.slice(0, test.fullTitle.length - test.title.length).trim();
  const suiteParts = suiteStr.split(' > ').length > 1
    ? suiteStr.split(' > ')
    : suiteStr.split(/\s{2,}/).filter(Boolean);

  // If splitting didn't work well, use the whole suite string
  const suitePath = suiteParts.length > 0 && suiteParts[0] ? suiteParts : (suiteStr ? [suiteStr] : []);

  if (suitePath.length > 0) labels.push({ name: 'parentSuite', value: suitePath[0] });
  if (suitePath.length > 1) labels.push({ name: 'suite', value: suitePath[1] });
  if (suitePath.length > 2) labels.push({ name: 'subSuite', value: suitePath.slice(2).join(' > ') });

  if (test.file) {
    const shortFile = test.file.replace(/.*\/js\/automated-tests\//, 'js/automated-tests/');
    labels.push({ name: 'package', value: shortFile });
  }

  for (const tag of extractTags(test.title)) {
    labels.push({ name: 'tag', value: tag });
  }

  const result: AllureResult = {
    uuid: crypto.randomUUID(),
    historyId: md5(test.fullTitle),
    testCaseId: md5(test.fullTitle),
    fullName: test.fullTitle,
    name: test.title,
    status: mapStatus(test, category),
    stage: 'finished',
    start,
    stop,
    labels,
    links: [],
    parameters: [],
    steps: [],
  };

  if (test.err && (test.err.message || test.err.estack || test.err.stack)) {
    result.statusDetails = {
      message: test.err.message || '',
      trace: test.err.estack || test.err.stack || '',
    };
  }

  return result;
}

// --- Main ---

function main(): void {
  const reportPath = REPORT_JSON_PATH;
  if (!fs.existsSync(reportPath)) {
    console.error(`No JSON report found at ${reportPath}`);
    process.exit(1);
  }

  console.log(`Reading report: ${reportPath}`);
  const report = JSON.parse(fs.readFileSync(reportPath, 'utf-8'));

  const stats = report.stats || {};
  console.log(`Stats: ${stats.tests || 0} tests, ${stats.passes || 0} passed, ${stats.failures || 0} failed, ${stats.pending || 0} pending`);

  timestampCursor = new Date(stats.start || Date.now()).getTime();

  fs.mkdirSync(ALLURE_RESULTS_DIR, { recursive: true });

  const allResults: AllureResult[] = [];

  // Mocha JSON reporter format: flat arrays of tests
  const passes: MochaTest[] = report.passes || [];
  const failures: MochaTest[] = report.failures || [];
  const pending: MochaTest[] = report.pending || [];

  console.log(`Processing: ${passes.length} passes, ${failures.length} failures, ${pending.length} pending`);

  for (const test of passes) {
    allResults.push(convertTest(test, 'pass'));
  }
  for (const test of failures) {
    allResults.push(convertTest(test, 'fail'));
  }
  for (const test of pending) {
    allResults.push(convertTest(test, 'pending'));
  }

  for (const result of allResults) {
    fs.writeFileSync(
      path.join(ALLURE_RESULTS_DIR, `${result.uuid}-result.json`),
      JSON.stringify(result, null, 2)
    );
  }

  console.log(`Generated ${allResults.length} test results in ${ALLURE_RESULTS_DIR}/`);
}

main();
