const fs = require('fs');
const { jsonReportOutputPath } = require('../automated-tests');
import {
  postPRComment,
  PRCommentOptions,
  formatDeviceInfo,
  DeviceInfo,
  formatDuration,
  getWorkflowRunUrl,
  getHTMLReportUrl,
  formatStatus
} from './prCommentUtils';

interface TestReport {
  stats: {
    tests: number;
    passes: number;
    failures: number;
    pending: number;
    duration: number;
  };
  failures?: Array<{
    fullTitle?: string;
    title?: string;
    err?: {
      message?: string;
    };
  }>;
  deviceInfo?: {
    modelName?: string;
    softwareVersion?: string;
    uiResolution?: string;
  };
  runInfo?: {
    branch?: string;
    applicationVersion?: string;
    runName?: string;
  };
}

/**
 * Gets status emoji based on test results
 */
function getStatusEmoji(report: TestReport): string {
  if (report.stats.failures > 0) {
    return '❌';
  }
  // Only show warning emoji if there are pending tests AND failures
  // Pending tests without failures should show success
  return '✅';
}

/**
 * Formats brief summary table of failed tests
 */
function formatFailedTestsSummary(failures: TestReport['failures']): string {
  if (!failures || failures.length === 0) {
    return '';
  }

  let summary = '**Failed Tests Summary:**\n\n';
  summary += '| Test Name |\n';
  summary += '|-----------|\n';

  failures.forEach((failure) => {
    const title = failure.fullTitle || failure.title || 'Unknown test';

    // Extract test name (part after " - " or the whole title if no separator)
    const parts = title.split(' - ');
    let testName = parts.length > 1 ? parts.slice(1).join(' - ').trim() : title.trim();

    // Truncate test name if too long
    if (testName.length > 80) {
      testName = testName.substring(0, 77) + '...';
    }

    summary += `| ${testName} |\n`;
  });

  summary += '\n';
  return summary;
}

/**
 * Formats failed tests section with details
 */
function formatFailedTests(failures: TestReport['failures']): string {
  if (!failures || failures.length === 0) {
    return '';
  }

  let section = '### ❌ Failed Tests\n\n';
  failures.forEach((failure, index) => {
    const testTitle = failure.fullTitle || failure.title || 'Unknown test';
    section += `${index + 1}. **${testTitle}**\n`;
    if (failure.err?.message) {
      const errorMessage = failure.err.message.split('\n')[0];
      const truncated = errorMessage.substring(0, 200);
      section += `   \`${truncated}${errorMessage.length > 200 ? '...' : ''}\`\n`;
    }
    section += '\n';
  });

  return section;
}


/**
 * Builds the comment body from test report
 */
async function buildCommentBody(report: TestReport, workflowRunUrl: string, env: NodeJS.ProcessEnv): Promise<string> {
  const statusEmoji = getStatusEmoji(report);
  const { tests = 0, pending = 0, duration = 0 } = report.stats;

  // Use actual failures array length instead of stats.failures
  // This ensures hook failures and affected tests are counted correctly
  const actualFailures = report.failures ? report.failures.length : 0;

  // Calculate actual passes: total tests - failures - pending
  // This ensures the math is correct when hooks fail
  const actualPasses = tests - actualFailures - pending;

  const durationSeconds = Math.round(duration / 1000);
  const formattedDuration = formatDuration(durationSeconds);

  const testSummary = [
    `${actualPasses}/${tests} passed`,
    actualFailures > 0 ? `${actualFailures} failed` : '',
    pending > 0 ? `${pending} pending` : ''
  ].filter(Boolean).join(', ');

  let body = `## ${statusEmoji} Smoke Test Results\n\n`;

  // Status with icons using generic utility
  body += formatStatus(actualFailures > 0, pending > 0);

  body += `**Tests:** ${testSummary}\n`;

  // Add brief summary of failed tests if any
  if (actualFailures > 0 && report.failures) {
    body += formatFailedTestsSummary(report.failures);
  }

  body += `**Duration:** ⏱️ ${formattedDuration}\n`;
  const htmlReportUrl = await getHTMLReportUrl(env, 'HTML Report');
  body += `**Run:** 🔗 [View Details](${workflowRunUrl}) | 📊 [HTML Report](${htmlReportUrl})\n\n`;

  body += formatFailedTests(report.failures);

  // Format device info using generic utility
  const deviceInfo: DeviceInfo = {
    modelName: report.deviceInfo?.modelName,
    softwareVersion: report.deviceInfo?.softwareVersion,
    uiResolution: report.deviceInfo?.uiResolution,
    applicationVersion: report.runInfo?.applicationVersion
  };
  body += formatDeviceInfo(deviceInfo);

  return body;
}


/**
 * Main function to post test results as PR comment
 */
async function postPRTestResults(): Promise<void> {
  const env = process.env;

  // Load and validate report
  if (!fs.existsSync(jsonReportOutputPath)) {
    console.error(`Test report not found at: ${jsonReportOutputPath}`);
    process.exit(1);
  }

  const report: TestReport = JSON.parse(fs.readFileSync(jsonReportOutputPath, 'utf8'));

  // Build comment body
  const workflowRunUrl = getWorkflowRunUrl(env);
  if (!workflowRunUrl) {
    console.error('Could not build workflow run URL, missing required environment variables');
    process.exit(1);
  }
  const commentBody = await buildCommentBody(report, workflowRunUrl, env);

  // Use generic PR comment utility
  const options: PRCommentOptions = {
    commentBody,
    commentIdentifier: 'Smoke Test Results',
    githubToken: env.GITHUB_TOKEN!,
    githubRepository: env.GITHUB_REPOSITORY!,
    githubApiUrl: env.GITHUB_API_URL
  };

  const prNumber = await postPRComment(options);

  if (!prNumber) {
    process.exit(0);
  }
}

// Run the script
postPRTestResults().catch((error) => {
  console.error('Error posting PR comment:', error);
  process.exit(1);
});
