/**
 * Automation UI Dashboard Reporter
 *
 * Centralizes all dashboard API interactions:
 *   - start:        Notify dashboard that a test run has started
 *   - complete:     Notify dashboard that a test run has completed
 *   - send-suite:   Forward a single suite result from workflow dispatch
 *   - push-report:  Push the full Allure report for ingestion
 *
 * Per-suite results are dispatched live by the test runner (see
 * js/automated-tests/mocha-reporter.ts) via the send-suite action, so there
 * is no batch suite-reporting action here.
 *
 * Usage:
 *   node .github/scripts/dashboardReporter.js <action>
 *
 * Environment Variables (common):
 *   DASHBOARD_BASE_URL - Base API URL (required for all actions except push-report)
 *   PLATFORM           - Platform identifier (default: 'roku')
 *   TEST_RUN_ID        - Deterministic test run ID ({platform}.{githubRunId})
 *
 * Environment Variables (start):
 *   TAG                - Test tag (default: 'Run All Tests')
 *   GITHUB_ACTION_ID   - GitHub run ID of the calling workflow (required)
 *   ESTIMATED_TESTS    - Estimated number of tests (required)
 *   ESTIMATED_SUITES   - Estimated number of suites (required)
 *   DEVICE_COUNT       - Number of devices participating in the run (default: 1)
 *
 * Environment Variables (complete):
 *   TEST_OUTCOME       - 'success' or 'failure'
 *   TOTAL_TESTS        - Total tests executed
 *   PASSED_TESTS       - Passed count
 *   FAILED_TESTS       - Failed count
 *   SKIPPED_TESTS      - Skipped count
 *   DURATION_MS        - Duration in milliseconds
 *
 * Environment Variables (send-suite):
 *   SUITE_DATA         - JSON-encoded suite payload from mocha-reporter
 *
 * Environment Variables (push-report):
 *   API_URL            - Full ingest-direct endpoint URL
 *   REPORT_DIR         - Path to the generated Allure report (default: 'allure-report')
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
 * Sends a JSON payload via HTTP and returns the parsed response.
 * Automatically selects http or https transport based on the URL protocol.
 * @param {string} url - The full URL
 * @param {string} method - HTTP method (POST, PATCH, etc.)
 * @param {Object} data - The payload object (will be JSON-stringified)
 * @param {number} [timeoutMs] - Optional request timeout in milliseconds
 * @returns {Promise<{statusCode: number, data: Object}>} Parsed response
 */
function requestJSON(url, method, data, timeoutMs) {
  return new Promise(function (resolve, reject) {
    var body = JSON.stringify(data);
    var parsed = new URL(url);
    var transport = parsed.protocol === 'https:' ? https : http;

    var options = {
      hostname: parsed.hostname,
      port: parsed.port,
      path: parsed.pathname + parsed.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    var req = transport.request(options, function (res) {
      var responseBody = '';
      res.on('data', function (chunk) { responseBody += chunk; });
      res.on('end', function () {
        var parsed;
        try { parsed = JSON.parse(responseBody); } catch (e) { parsed = responseBody; }
        resolve({ statusCode: res.statusCode, data: parsed });
      });
    });

    if (timeoutMs > 0) {
      req.setTimeout(timeoutMs, function () {
        req.destroy(new Error('Request timed out after ' + timeoutMs + 'ms'));
      });
    }

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function postJSON(url, data, timeoutMs) {
  return requestJSON(url, 'POST', data, timeoutMs);
}

function patchJSON(url, data, timeoutMs) {
  return requestJSON(url, 'PATCH', data, timeoutMs);
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

// --- start: POST /api/v2/test-runs ---

/**
 * Creates a new test run on the dashboard.
 * Returns a deterministic testRunId ({platform}.{githubRunId}).
 * @returns {Promise<void>}
 */
function actionStart() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');
  var tag = process.env.TAG || 'Run All Tests';

  var payload = {
    platform: PLATFORM,
    githubRunId: requireEnv('GITHUB_ACTION_ID'),
    totalSuites: parseInt(requireEnv('ESTIMATED_SUITES'), 10),
    tags: tag ? [tag] : [],
    deviceCount: parseInt(process.env.DEVICE_COUNT || '1', 10),
    type: 'regression'
  };

  if (process.env.ESTIMATED_TESTS) {
    payload.estimatedTests = parseInt(process.env.ESTIMATED_TESTS, 10);
  }

  console.log('Starting test run: platform=' + PLATFORM);

  return postJSON(baseUrl + '/v2/test-runs', payload).then(function (response) {
    handleResponse(response, 'Test run started successfully', 'Failed to start test run');

    var resData = response.data || {};
    var testRunId = (resData.data || {}).testRunId;
    if (testRunId) {
      console.log('Test run ID: ' + testRunId);
    }
  });
}

// --- complete: PATCH /api/v2/test-runs/:testRunId ---

/**
 * Marks a test run as completed on the dashboard.
 * @returns {Promise<void>}
 */
function actionComplete() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');
  var testRunId = requireEnv('TEST_RUN_ID');
  var success = (process.env.TEST_OUTCOME || 'success') === 'success';
  var durationMs = parseInt(process.env.DURATION_MS || '0', 10);

  var payload = {
    status: success ? 'completed' : 'failed',
    summary: {
      totalTests: parseInt(process.env.TOTAL_TESTS || '0', 10),
      passed: parseInt(process.env.PASSED_TESTS || '0', 10),
      failed: parseInt(process.env.FAILED_TESTS || '0', 10),
      skipped: parseInt(process.env.SKIPPED_TESTS || '0', 10),
      durationMs: durationMs
    }
  };

  console.log('Completing test run: id=' + testRunId + ', status=' + payload.status +
    ', tests=' + payload.summary.totalTests +
    ' (P:' + payload.summary.passed +
    ' F:' + payload.summary.failed +
    ' S:' + payload.summary.skipped + ')');

  return patchJSON(baseUrl + '/v2/test-runs/' + testRunId, payload).then(function (response) {
    handleResponse(response, 'Test run completed successfully', 'Failed to complete test run');
  });
}

// --- send-suite: two-step suite lifecycle from workflow dispatch ---

/**
 * Forwards a single suite result payload to the dashboard using the
 * two-step suite lifecycle: POST to create, PATCH to complete.
 * @returns {Promise<void>}
 */
function actionSendSuite() {
  var baseUrl = requireEnv('DASHBOARD_BASE_URL');
  var testRunId = requireEnv('TEST_RUN_ID');
  var suiteDataStr = requireEnv('SUITE_DATA');

  var payload;
  try {
    payload = JSON.parse(suiteDataStr);
  } catch (e) {
    console.error('Failed to parse SUITE_DATA: ' + e.message);
    process.exit(1);
  }

  var suite = payload.suite || {};
  var suiteName = suite.name || 'unknown';
  if (!suite.name || !suite.path) {
    console.error('SUITE_DATA must include suite.name and suite.path');
    process.exit(1);
  }

  var deviceDesc = payload.device ? ' (device: ' + (payload.device.model || payload.device.id || 'unknown') + ')' : '';
  console.log('Sending suite result: ' + suiteName + deviceDesc);

  var startPayload = {
    suite: { path: suite.path, name: suite.name },
    typeOfTest: 'functional'
  };
  if (payload.device) {
    startPayload.device = payload.device;
  }

  var suiteUrl = baseUrl + '/v2/test-runs/' + testRunId + '/suites';

  return postJSON(suiteUrl, startPayload).then(function (response) {
    handleResponse(response, 'Suite created: ' + suiteName, 'Failed to create suite: ' + suiteName);

    var suiteId = ((response.data || {}).data || {}).suiteId;
    if (!suiteId) {
      console.error('No suiteId returned from suite creation');
      process.exit(1);
    }

    var tests = payload.tests || [];
    var results = payload.results || {};

    var completePayload = {
      results: {
        total: results.total || (results.passed || 0) + (results.failed || 0) + (results.broken || 0) + (results.skipped || 0),
        passed: results.passed || 0,
        failed: results.failed || 0,
        broken: results.broken || 0,
        skipped: results.skipped || 0
      },
      tests: tests,
      status: 'completed'
    };

    return patchJSON(suiteUrl + '/' + suiteId, completePayload);
  }).then(function (response) {
    handleResponse(response, 'Suite completed: ' + suiteName, 'Failed to complete suite: ' + suiteName);
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
    } catch (e) { /* skip unreadable files */ }
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

  return postJSON(apiUrl, payload).then(function (response) {
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
  'push-report': actionPushReport
};

var action = process.argv[2];
var actionFn = ACTIONS[action];

if (!actionFn) {
  console.error('Usage: node dashboardReporter.js <start|complete|send-suite|push-report>');
  process.exit(1);
}

actionFn().catch(function (err) {
  console.error('Error in ' + action + ': ' + err.message);
  process.exit(1);
});
