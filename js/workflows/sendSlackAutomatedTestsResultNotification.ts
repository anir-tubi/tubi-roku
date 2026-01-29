const fs = require('fs');
const { jsonReportOutputPath } = require('../automated-tests');
import { testUtils } from '../automated-tests/test-utils';

const report = JSON.parse(fs.readFileSync(jsonReportOutputPath, 'utf8'));
const env = process.env;
const workflowRunUrl = `${env.GITHUB_SERVER_URL}/${env.GITHUB_REPOSITORY}/actions/runs/${env.GITHUB_RUN_ID}`;

// Get branch name - prefer CLI arg (from matrix job), else fallback to GitHub refs
const branchArg = process.argv[2];
const rawBranch = branchArg || env.GITHUB_HEAD_REF || env.GITHUB_REF_NAME || 'unknown';

// Use actual failures array length instead of stats.failures
// This ensures hook failures and affected tests are counted correctly
const actualFailures = report.failures ? report.failures.length : 0;

// Get status emoji and color
let statusEmoji = '✅';
let statusColor = '#36a64f'; // green
if (actualFailures > 0) {
  statusEmoji = '❌';
  statusColor = '#dc3545'; // red
}
// Remove pending warning - only show warning if there are actual failures

// Build test summary
const { tests = 0, pending = 0, duration = 0 } = report.stats;

// Calculate actual passes: total tests - failures - pending
// This ensures the math is correct when hooks fail
const actualPasses = tests - actualFailures - pending;

const testSummary = [
  `${actualPasses}/${tests} passed`,
  actualFailures > 0 ? `${actualFailures} failed` : '',
  pending > 0 ? `${pending} pending` : ''
].filter(Boolean).join(' • ');

// Format duration
const durationSeconds = Math.round(duration / 1000);
const durationMinutes = Math.floor(durationSeconds / 60);
const remainingSeconds = durationSeconds % 60;
const formattedDuration = durationMinutes > 0
  ? `${durationMinutes}m ${remainingSeconds}s`
  : `${remainingSeconds}s`;

// Format failed tests summary
let failedTestsSection = '';
if (actualFailures > 0 && report.failures && report.failures.length > 0) {
  const failedTests = report.failures.slice(0, 5).map((failure, index) => {
    const title = failure.fullTitle || failure.title || 'Unknown test';

    // Extract test case ID (e.g., C438466) and test name
    const testCaseMatch = title.match(/^(C\d+)\s*-\s*(.+)$/);
    let testCaseId = '';
    let testName = title;

    if (testCaseMatch) {
      testCaseId = testCaseMatch[1];
      testName = testCaseMatch[2].trim();
    } else {
      // If no test case ID, extract after " - " if present
      const parts = title.split(' - ');
      testName = parts.length > 1 ? parts.slice(1).join(' - ').trim() : title.trim();
    }

    return testCaseId
      ? `*${testCaseId}*: ${testName}`
      : `• ${testName}`;
  });

  const moreTests = report.failures.length > 5 ? `\n_...and ${report.failures.length - 5} more test(s) failed_` : '';
  failedTestsSection = '*Failed Tests:*\n' + failedTests.join('\n') + moreTests;
}

// Format device info
let deviceInfoSection = '';
if (report.deviceInfo || report.runInfo) {
  const deviceLines = [];
  if (report.deviceInfo?.modelName) deviceLines.push(`Model: ${report.deviceInfo.modelName}`);
  if (report.deviceInfo?.softwareVersion) deviceLines.push(`OS: ${report.deviceInfo.softwareVersion}`);
  if (report.deviceInfo?.uiResolution) deviceLines.push(`Resolution: ${report.deviceInfo.uiResolution}`);
  if (report.runInfo?.applicationVersion) deviceLines.push(`App: v${report.runInfo.applicationVersion}`);
  if (deviceLines.length > 0) {
    deviceInfoSection = '*Device:* ' + deviceLines.join(' | ');
  }
}

// Build Slack blocks for rich formatting
const blocks = [
  {
    type: 'header',
    text: {
      type: 'plain_text',
      text: `${statusEmoji} UI Automation Results`,
      emoji: true
    }
  },
  {
    type: 'section',
    fields: [
      {
        type: 'mrkdwn',
        text: `*Branch:*\n\`${rawBranch}\``
      },
      {
        type: 'mrkdwn',
        text: `*Tests:*\n${testSummary}`
      },
      {
        type: 'mrkdwn',
        text: `*Duration:*\n⏱️ ${formattedDuration}`
      },
      {
        type: 'mrkdwn',
        text: `*Status:*\n${statusEmoji} ${actualFailures > 0 ? 'Failed' : pending > 0 ? 'Pending' : 'Passed'}`
      }
    ]
  }
];

// Add failed tests section if any
if (failedTestsSection) {
  blocks.push({
    type: 'divider'
  });
  blocks.push({
    type: 'section',
    text: {
      type: 'mrkdwn',
      text: failedTestsSection
    }
  });
}

// Add device info
if (deviceInfoSection) {
  blocks.push({
    type: 'divider'
  });
  blocks.push({
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: deviceInfoSection
      }
    ]
  });
}

// Add action button
blocks.push({
  type: 'divider'
});
blocks.push({
  type: 'actions',
  elements: [
    {
      type: 'button',
      text: {
        type: 'plain_text',
        text: '📊 View Full Report',
        emoji: true
      },
      url: workflowRunUrl,
      style: actualFailures > 0 ? 'danger' : 'primary'
    }
  ]
});

void testUtils.sendNetworkRequest({
  method: 'post',
  url: 'https://hooks.slack.com/services/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',
  body: {
    blocks: blocks,
    // Fallback text for notifications
    text: `${statusEmoji} UI Automation Results - ${testSummary}`
  }
});
