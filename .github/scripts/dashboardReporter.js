/**
 * Automation UI Dashboard Reporter
 *
 * Centralizes all dashboard API interactions:
 *   - start:        Notify dashboard that a test run has started
 *   - complete:     Notify dashboard that a test run has completed
 *   - send-suite:   Forward a single suite result from workflow dispatch
 *   - send-suites:  Send per-suite test results (populates "Completed Suites")
 *   - push-report:  Push the full Allure report for ingestion
 *
 * Usage:
 *   node .github/scripts/dashboardReporter.js <action>
 *
 * Environment Variables (common):
 *   DASHBOARD_BASE_URL - Base API URL (required for start, complete, send-suites)
 *   PLATFORM           - Platform identifier (default: 'roku')
 *
 * Environment Variables (start):
 *   TAG                - Test tag (default: 'Run All Tests')
 *   GITHUB_ACTION_ID   - GitHub run ID of the calling workflow
 *   ESTIMATED_TESTS    - Estimated number of tests (default: 605)
 *   ESTIMATED_SUITES   - Estimated number of suites (default: 49)
 *
 * Environment Variables (complete):
 *   TEST_OUTCOME       - 'success' or 'failure'
 *   TOTAL_TESTS        - Total tests executed
 *   PASSED_TESTS       - Passed count
 *   FAILED_TESTS       - Failed count
 *   SKIPPED_TESTS      - Skipped count
 *   DURATION_MS        - Duration in milliseconds
 *   TOTAL_SUITES       - Total suites
 *
 * Environment Variables (send-suites, push-report):
 *   REPORT_DIR         - Path to the generated Allure report (default: 'allure-report')
 *
 * Environment Variables (push-report):
 *   API_URL            - Full ingest-direct endpoint URL
 *   REPORT_ID          - Unique report identifier, typically github.run_id
 */
var fs = require('fs');
var path = require('path');
var https = require('https');
var http = require('http');

var PLATFORM = process.env.PLATFORM || 'roku';
var REPORT_DIR = process.env.REPORT_DIR || 'allure-report';

// --- Shared helpers ---

/**
 * Sends a JSON payload via HTTP POST and returns the parsed response.
 * Automatically selects http or https transport based on the URL protocol.
 * @param {string} url - The full URL to POST to
 * @param {Object} data - The payload object (will be JSON-stringified)
 * @returns {Promise<{statusCode: number, data: Object}>} Parsed response
 */
function postJSON(url, data) {
  return new Promise(function(resolve, reject) {
    var body = JSON.stringify(data);
    var parsed = new URL(url);
    var transport = parsed.protocol === 'https:' ? https : http;

    var options = {
      hostname: parsed.hostname,
      port: parsed.port,
      path: parsed.pathname + parsed.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    var req = transport.request(options, function(res) {
      var responseBody = '';
      res.on('data', function(chunk) { responseBody += chunk; });
      res.on('end', function() {
        var parsed;
        try { parsed = JSON.parse(responseBody); } catch(e) { parsed = responseBody; }
        resolve({ statusCode: res.statusCode, data: parsed });
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

/**
 * Reads a required environment variable. Exits with error if not set.
 * @param {string} name - Environment variable name
 * @returns {string} The environment variable value
 */
function requireEnv(name) {
  var val = process.env[name];
  if (!val) {
    console.error(name + ' environment variable is required');
    process.exit(1);
  }
  return val;
}

/**
 * Logs the API response and exits on failure.
 * @param {{statusCode: number, data: Object}} response - The API response
 * @param {string} successMsg - Message to log on 2xx status
 * @param {string} failMsg - Message to log on non-2xx status (triggers process.exit)
 */
function handleResponse(response, successMsg, failMsg) {
  console.log('HTTP ' + response.statusCode + ': ' + JSON.stringify(response.data));
  if (response.statusCode >= 200 && response.statusCode < 300) {
    console.log(successMsg);
  } else {
    console.error(failMsg + ' (HTTP ' + response.statusCode + ')');
    process.exit(1);
  }
}

/**
 * Reads and parses the Allure suites.json file from the report directory.
 * @param {string} reportDir - Path to the Allure report directory
 * @returns {Object|null} Parsed suites data, or null if file not found
 */
function readSuitesData(reportDir) {
  var suitesPath = path.join(reportDir, 'data', 'suites.json');
  if (!fs.existsSync(suitesPath)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(suitesPath, 'utf-8'));
}

/**
 * Recursively counts test results in an Allure suite tree node.
 * Leaf nodes (no children) are counted as individual tests.
 * @param {Object} node - An Allure suite tree node
 * @returns {{total: number, passed: number, failed: number, skipped: number, duration: number}}
 */
function countTests(node) {
  if (!node.children || node.children.length === 0) {
    var status = node.status || 'unknown';
    return {
      total: 1,
      passed: status === 'passed' ? 1 : 0,
      failed: (status === 'failed' || status === 'broken') ? 1 : 0,
      skipped: status === 'skipped' ? 1 : 0,
      duration: (node.time && node.time.duration) || 0
    };
  }

  var result = { total: 0, passed: 0, failed: 0, skipped: 0, duration: 0 };
  for (var i = 0; i < node.children.length; i++) {
    var child = countTests(node.children[i]);
    result.total += child.total;
    result.passed += child.passed;
    result.failed += child.failed;
    result.skipped += child.skipped;
    result.duration += child.duration;
  }
  return result;
}

// --- start: POST /api/test-run/start ---

/**
 * Notifies the dashboard that a test run has started.
 * Sends estimated test/suite counts and the triggering GitHub Action ID.
 * @returns {Promise<void>}
 */
function actionStart() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');

  var payload = {
    event: 'test_run_started',
    timestamp: new Date().toISOString(),
    platform: PLATFORM,
    runners: '1',
    tag: process.env.TAG || 'Run All Tests',
    githubActionId: process.env.GITHUB_ACTION_ID || '',
    estimated: {
      tests: parseInt(process.env.ESTIMATED_TESTS || '605', 10),
      suites: parseInt(process.env.ESTIMATED_SUITES || '49', 10)
    }
  };

  console.log('Starting test run: platform=' + PLATFORM);

  return postJSON(baseUrl + '/test-run/start', payload).then(function(response) {
    handleResponse(response, 'Test run started successfully', 'Failed to start test run');

    var resData = response.data || {};
    var bucketId = (resData.data || {}).test_run_id_in_progress;
    if (bucketId) {
      console.log('Test bucket: ' + bucketId);
    }
  });
}

// --- complete: POST /api/test-run/complete ---

/**
 * Notifies the dashboard that a test run has completed.
 * Sends the test outcome (success/failure) and a summary of test counts.
 * @returns {Promise<void>}
 */
function actionComplete() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');
  var success = (process.env.TEST_OUTCOME || 'success') === 'success';
  var durationMs = parseInt(process.env.DURATION_MS || '0', 10);
  var endTime = new Date();
  var startTime = new Date(endTime.getTime() - durationMs);

  var payload = {
    event: 'test_run_completed',
    timestamp: endTime.toISOString(),
    platform: PLATFORM,
    success: success,
    summary: {
      totalTestSuites: parseInt(process.env.TOTAL_SUITES || '0', 10),
      totalTests: parseInt(process.env.TOTAL_TESTS || '0', 10),
      passed: parseInt(process.env.PASSED_TESTS || '0', 10),
      failed: parseInt(process.env.FAILED_TESTS || '0', 10),
      skipped: parseInt(process.env.SKIPPED_TESTS || '0', 10),
      duration: durationMs
    },
    startTime: startTime.toISOString(),
    endTime: endTime.toISOString()
  };

  console.log('Completing test run: platform=' + PLATFORM + ', success=' + success +
    ', tests=' + payload.summary.totalTests +
    ' (P:' + payload.summary.passed +
    ' F:' + payload.summary.failed +
    ' S:' + payload.summary.skipped + ')');

  return postJSON(baseUrl + '/test-run/complete', payload).then(function(response) {
    handleResponse(response, 'Test run completed successfully', 'Failed to complete test run');
  });
}

// --- send-suites: POST /api/test-suite/result for each suite ---

/**
 * Sends a single suite's test results to the dashboard.
 * @param {string} baseUrl - Dashboard API base URL
 * @param {Object} suite - Allure suite tree node
 * @param {number} index - Zero-based index of the suite (for logging)
 * @returns {Promise<{statusCode: number, data: Object}>} API response
 */
function sendSuiteResult(baseUrl, suite, index) {
  var counts = countTests(suite);
  var suiteName = suite.name || ('Suite ' + index);

  var payload = {
    event: 'test_suite_completed',
    timestamp: new Date().toISOString(),
    platform: PLATFORM,
    suite: {
      path: suiteName,
      name: suiteName,
      duration: counts.duration
    },
    results: {
      total: counts.total,
      passed: counts.passed,
      failed: counts.failed,
      skipped: counts.skipped
    }
  };

  return postJSON(baseUrl + '/test-suite/result', payload).then(function(response) {
    var ok = response.statusCode >= 200 && response.statusCode < 300;
    console.log('  [' + (index + 1) + '] "' + suiteName + '" -> HTTP ' + response.statusCode +
      (ok ? ' (tests: ' + counts.total + ', P:' + counts.passed + ' F:' + counts.failed + ' S:' + counts.skipped + ')' : ' (ERROR)'));
    return response;
  });
}

/**
 * Sends suite results one at a time to avoid overwhelming the API.
 * @param {string} baseUrl - Dashboard API base URL
 * @param {Array<Object>} suites - Array of Allure suite tree nodes
 * @param {number} index - Current index in the array
 * @returns {Promise<void>}
 */
function sendSequentially(baseUrl, suites, index) {
  if (index >= suites.length) {
    return Promise.resolve();
  }
  return sendSuiteResult(baseUrl, suites[index], index).then(function() {
    return sendSequentially(baseUrl, suites, index + 1);
  });
}

/**
 * Reads Allure suites.json and sends per-suite results to the dashboard.
 * This populates the "Completed Suites" counter on the Automation UI.
 * Must run before test-run/complete so completedSuites metadata is preserved.
 * @returns {Promise<void>}
 */
function actionSendSuites() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');

  var suitesData = readSuitesData(REPORT_DIR);
  if (!suitesData) {
    console.log('suites.json not found in ' + REPORT_DIR + ', skipping');
    process.exit(0);
  }

  var topLevelSuites = suitesData.children || [];
  if (topLevelSuites.length === 0) {
    console.log('No suites to send');
    process.exit(0);
  }

  console.log('Sending ' + topLevelSuites.length + ' suite results to dashboard');

  return sendSequentially(baseUrl, topLevelSuites, 0).then(function() {
    console.log('Sent ' + topLevelSuites.length + ' suite results');
  });
}

// --- send-suite: POST a single suite result from workflow dispatch ---

/**
 * Forwards a single suite result payload to the dashboard.
 * Reads the suite data from the SUITE_DATA environment variable (JSON string)
 * and POSTs it to /test-suite/result.
 * @returns {Promise<void>}
 */
function actionSendSuite() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');
  var suiteDataStr = requireEnv('SUITE_DATA');

  var payload;
  try {
    payload = JSON.parse(suiteDataStr);
  } catch (e) {
    console.error('Failed to parse SUITE_DATA: ' + e.message);
    process.exit(1);
  }

  payload.platform = payload.platform || PLATFORM;

  var suiteName = (payload.suite && payload.suite.name) || 'unknown';
  console.log('Sending suite result: ' + suiteName);

  return postJSON(baseUrl + '/test-suite/result', payload).then(function(response) {
    handleResponse(response, 'Suite result sent: ' + suiteName, 'Failed to send suite result: ' + suiteName);
  });
}

// --- push-report: POST full report to /reports/ingest-direct ---

/**
 * Walks the Allure suite tree and collects UIDs of failed/broken test cases.
 * @param {Object} suitesData - Parsed suites.json root object
 * @returns {Array<string>} Array of UIDs for failed or broken tests
 */
function extractFailedTestUids(suitesData) {
  var failedUids = [];
  function walk(children) {
    if (!children) return;
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      var isFailed = child.status === 'failed' || child.status === 'broken';
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
 * Reads individual test case detail JSON files from the Allure report.
 * Only loads details for the specified UIDs (typically failed/broken tests).
 * @param {string} reportDir - Path to the Allure report directory
 * @param {Array<string>} uids - UIDs of test cases to load
 * @returns {Object<string, Object>} Map of UID to parsed test case data
 */
function readTestCaseDetails(reportDir, uids) {
  var testCasesDir = path.join(reportDir, 'data', 'test-cases');
  var testCases = {};
  if (!fs.existsSync(testCasesDir)) return testCases;

  var loaded = 0;
  for (var i = 0; i < uids.length; i++) {
    var filePath = path.join(testCasesDir, uids[i] + '.json');
    try {
      if (fs.existsSync(filePath)) {
        testCases[uids[i]] = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
        loaded++;
      }
    } catch(e) { /* skip unreadable files */ }
  }
  console.log('Loaded ' + loaded + '/' + uids.length + ' test case details');
  return testCases;
}

/**
 * Pushes the full Allure report to the dashboard's ingest-direct endpoint.
 * Reads suites.json for the report structure and individual test case files
 * for failed/broken test details. Exits gracefully if the report is empty.
 * @returns {Promise<void>}
 */
function actionPushReport() {
  var apiUrl = requireEnv('API_URL');
  var reportId = process.env.REPORT_ID || process.env.GITHUB_RUN_ID || String(Date.now());

  if (!fs.existsSync(REPORT_DIR)) {
    console.error('Report directory does not exist: ' + REPORT_DIR);
    process.exit(1);
  }

  var suitesData = readSuitesData(REPORT_DIR);
  if (!suitesData) {
    console.log('suites.json not found, skipping push');
    process.exit(0);
  }

  var suiteCount = (suitesData.children || []).length;
  if (suiteCount === 0) {
    console.log('No suites found in report, skipping push');
    process.exit(0);
  }

  var failedUids = extractFailedTestUids(suitesData);
  var testCases = readTestCaseDetails(REPORT_DIR, failedUids);

  var payload = {
    platform: PLATFORM,
    reportId: parseInt(String(reportId), 10) || Date.now(),
    reportData: {
      suites: suitesData,
      testCases: testCases
    },
    metadata: {
      triggeredBy: 'github-actions',
      testRunName: 'Roku Test Run ' + reportId,
      timestamp: new Date().toISOString()
    }
  };

  var payloadSize = Buffer.byteLength(JSON.stringify(payload));
  console.log('Pushing report: platform=' + PLATFORM + ', reportId=' + reportId +
    ', suites=' + suiteCount + ', failedTests=' + failedUids.length +
    ', size=' + (payloadSize / 1024).toFixed(1) + 'KB');

  return postJSON(apiUrl, payload).then(function(response) {
    var resData = response.data || {};
    var resDetail = resData.data || {};

    handleResponse(response, 'Report pushed successfully', 'Failed to push report');

    if (resData.success) {
      console.log('Test Run ID: ' + (resDetail.testRunId || 'N/A') +
        ', Test Cases: ' + (resDetail.testCaseResultsCount || 'N/A'));
    }
  });
}

// --- Entry point ---

var ACTIONS = {
  'start': actionStart,
  'complete': actionComplete,
  'send-suite': actionSendSuite,
  'send-suites': actionSendSuites,
  'push-report': actionPushReport
};

var action = process.argv[2];
var actionFn = ACTIONS[action];

if (!actionFn) {
  console.error('Usage: node dashboardReporter.js <start|complete|send-suite|send-suites|push-report>');
  process.exit(1);
}

actionFn().catch(function(err) {
  console.error('Error in ' + action + ': ' + err.message);
  process.exit(1);
});
