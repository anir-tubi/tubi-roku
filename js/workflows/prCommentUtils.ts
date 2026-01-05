const fs = require('fs');
import { testUtils } from '../automated-tests/test-utils';

interface GitHubComment {
  id: number;
  user: {
    login: string;
    type?: string;
  };
  body: string;
  created_at?: string;
  updated_at?: string;
}

interface GitHubEvent {
  number?: number;
  pull_request?: {
    number?: number;
  };
}

export interface PRCommentOptions {
  commentBody: string;
  commentIdentifier: string; // Unique string to identify this comment type (e.g., "Smoke Test Results")
  githubRepository: string;
  githubApiUrl?: string;
  githubToken: string;
}

/**
 * Creates GitHub API headers for REST API v3
 */
function getGitHubApiHeaders(githubToken: string, includeContentType = false): Record<string, string> {
  const headers: Record<string, string> = {
    'Accept': 'application/vnd.github+json',
    'Authorization': `Bearer ${githubToken}`,
    'X-GitHub-Api-Version': '2022-11-28'
  };
  if (includeContentType) {
    headers['Content-Type'] = 'application/json';
  }
  return headers;
}

/**
 * Builds GitHub API URL for issue comments
 */
function getIssueCommentsUrl(githubApiUrl: string, repository: string, prNumber: number): string {
  return `${githubApiUrl}/repos/${repository}/issues/${prNumber}/comments`;
}

/**
 * Builds GitHub API URL for a specific issue comment
 */
function getIssueCommentUrl(githubApiUrl: string, repository: string, commentId: number): string {
  return `${githubApiUrl}/repos/${repository}/issues/comments/${commentId}`;
}

/**
 * Gets PR number from GitHub event path
 * This workflow is triggered on pull_request events, so the PR number is always available in the event
 */
export function getPRNumber(env: NodeJS.ProcessEnv): number | null {
  if (!env.GITHUB_EVENT_PATH || !fs.existsSync(env.GITHUB_EVENT_PATH)) {
    return null;
  }

  try {
    const eventData: GitHubEvent = JSON.parse(fs.readFileSync(env.GITHUB_EVENT_PATH, 'utf8'));
    return eventData.number || eventData.pull_request?.number || null;
  } catch (e) {
    return null;
  }
}

/**
 * Gets all existing comment IDs from github-actions bot matching the identifier
 */
async function getExistingCommentIds(
  repository: string,
  prNumber: number,
  githubToken: string,
  githubApiUrl: string,
  commentIdentifier: string
): Promise<number[]> {
  try {
    const apiUrl = getIssueCommentsUrl(githubApiUrl, repository, prNumber);
    const response = await testUtils.sendNetworkRequest({
      method: 'get',
      url: apiUrl,
      headers: getGitHubApiHeaders(githubToken)
    });

    if (response && Array.isArray(response)) {
      const allBotComments = response.filter(
        (comment: GitHubComment) => comment.user.login === 'github-actions[bot]'
      );

      const botComments = allBotComments.filter(
        (comment: GitHubComment) => comment.body.includes(commentIdentifier)
      );

      const commentIds = botComments.map((comment: GitHubComment) => comment.id);
      return commentIds;
    }
  } catch (e) {
    // Silently fail and return empty array
  }

  return [];
}

/**
 * Updates an existing PR comment
 */
async function updateComment(
  repository: string,
  commentId: number,
  commentBody: string,
  githubToken: string,
  githubApiUrl: string
): Promise<void> {
  const apiUrl = getIssueCommentUrl(githubApiUrl, repository, commentId);
  await testUtils.sendNetworkRequest({
    method: 'patch',
    url: apiUrl,
    headers: getGitHubApiHeaders(githubToken, true),
    body: {
      body: commentBody
    }
  });
}

/**
 * Posts a new PR comment
 */
async function postComment(
  repository: string,
  prNumber: number,
  commentBody: string,
  githubToken: string,
  githubApiUrl: string
): Promise<void> {
  const apiUrl = getIssueCommentsUrl(githubApiUrl, repository, prNumber);
  await testUtils.sendNetworkRequest({
    method: 'post',
    url: apiUrl,
    headers: getGitHubApiHeaders(githubToken, true),
    body: {
      body: commentBody
    }
  });
}

/**
 * Posts or updates a PR comment
 * This is a generic utility that can be used for any type of PR comment
 * 
 * @param options - Configuration options for the PR comment
 * @param prNumber - The PR number (if not provided, will be extracted from GitHub event)
 * @returns The PR number that was used, or null if PR number couldn't be determined
 */
export async function postPRComment(
  options: PRCommentOptions,
  prNumber?: number | null
): Promise<number | null> {
  const env = process.env;

  // Get PR number if not provided
  if (!prNumber) {
    prNumber = getPRNumber(env);
    if (!prNumber) {
      return null;
    }
  }

  const githubApiUrl = options.githubApiUrl || env.GITHUB_API_URL || 'https://api.github.com';

  // Get all existing comment IDs matching the identifier
  const existingCommentIds = await getExistingCommentIds(
    options.githubRepository,
    prNumber,
    options.githubToken,
    githubApiUrl,
    options.commentIdentifier
  );

  // If an existing comment is found, update it; otherwise create a new one
  if (existingCommentIds.length > 0) {
    const firstCommentId = existingCommentIds[0];
    try {
      await updateComment(
        options.githubRepository,
        firstCommentId,
        options.commentBody,
        options.githubToken,
        githubApiUrl
      );
      return prNumber; // Return early since we updated instead of creating new
    } catch (updateError: any) {
      // Continue to postComment below - update failed
    }
  }

  // Create a new comment if no existing comment found or update failed
  await postComment(
    options.githubRepository,
    prNumber,
    options.commentBody,
    options.githubToken,
    githubApiUrl
  );

  return prNumber;
}

export interface DeviceInfo {
  modelName?: string;
  softwareVersion?: string;
  uiResolution?: string;
  applicationVersion?: string;
}

/**
 * Formats duration in seconds to a human-readable format (minutes and seconds)
 * @param seconds - Duration in seconds
 * @returns Formatted string like "45s", "2m", or "4m 20s"
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return `${seconds}s`;
  }
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  if (remainingSeconds === 0) {
    return `${minutes}m`;
  }
  return `${minutes}m ${remainingSeconds}s`;
}

/**
 * Builds GitHub Actions workflow run URL
 * @param env - Process environment variables
 * @returns Workflow run URL or null if required env vars are missing
 */
export function getWorkflowRunUrl(env: NodeJS.ProcessEnv): string | null {
  if (!env.GITHUB_SERVER_URL || !env.GITHUB_REPOSITORY || !env.GITHUB_RUN_ID) {
    return null;
  }
  return `${env.GITHUB_SERVER_URL}/${env.GITHUB_REPOSITORY}/actions/runs/${env.GITHUB_RUN_ID}`;
}

interface GitHubArtifact {
  id: number;
  name: string;
  url: string;
}

/**
 * Gets artifact ID by name from GitHub Actions run
 * @param repository - Repository in format "owner/repo"
 * @param runId - GitHub Actions run ID
 * @param artifactName - Name of the artifact to find
 * @param githubToken - GitHub token for API access
 * @param githubApiUrl - GitHub API URL
 * @returns Artifact ID or null if not found
 */
async function getArtifactIdByName(
  repository: string,
  runId: string,
  artifactName: string,
  githubToken: string,
  githubApiUrl: string
): Promise<number | null> {
  try {
    const apiUrl = `${githubApiUrl}/repos/${repository}/actions/runs/${runId}/artifacts`;
    const response = await testUtils.sendNetworkRequest({
      method: 'get',
      url: apiUrl,
      headers: getGitHubApiHeaders(githubToken)
    });

    if (response && response.artifacts && Array.isArray(response.artifacts)) {
      const artifact = response.artifacts.find(
        (art: GitHubArtifact) => art.name === artifactName
      );
      return artifact?.id || null;
    }
  } catch (e: any) {
    // Silently fail and return null
  }

  return null;
}

/**
 * Builds GitHub Actions artifacts URL
 * @param workflowRunUrl - Base workflow run URL
 * @returns Artifacts URL with anchor
 */
export function getArtifactsUrl(workflowRunUrl: string): string {
  return `${workflowRunUrl}#artifacts`;
}

/**
 * Builds direct GitHub Actions artifact URL
 * @param workflowRunUrl - Base workflow run URL
 * @param artifactId - Artifact ID
 * @returns Direct artifact URL
 */
export function getDirectArtifactUrl(workflowRunUrl: string, artifactId: number): string {
  // Extract run ID from workflow URL
  const runIdMatch = workflowRunUrl.match(/\/runs\/(\d+)/);
  if (!runIdMatch) {
    return getArtifactsUrl(workflowRunUrl); // Fallback to anchor if can't parse
  }

  // Build direct artifact URL: https://github.com/owner/repo/actions/runs/{runId}/artifacts/{artifactId}
  const baseUrl = workflowRunUrl.replace(/\/actions\/runs\/\d+.*$/, '');
  return `${baseUrl}/actions/runs/${runIdMatch[1]}/artifacts/${artifactId}`;
}

/**
 * Gets direct HTML report artifact URL
 * @param env - Process environment variables
 * @param artifactName - Name of the artifact (default: "HTML Report")
 * @returns Direct artifact URL or fallback to artifacts section
 */
export async function getHTMLReportUrl(
  env: NodeJS.ProcessEnv,
  artifactName: string = 'HTML Report'
): Promise<string> {
  const workflowRunUrl = getWorkflowRunUrl(env);
  if (!workflowRunUrl) {
    return '#';
  }

  const repository = env.GITHUB_REPOSITORY;
  const runId = env.GITHUB_RUN_ID;
  const githubToken = env.GITHUB_TOKEN;
  const githubApiUrl = env.GITHUB_API_URL || 'https://api.github.com';

  if (!repository || !runId || !githubToken) {
    return getArtifactsUrl(workflowRunUrl);
  }

  const artifactId = await getArtifactIdByName(
    repository,
    runId,
    artifactName,
    githubToken,
    githubApiUrl
  );

  if (artifactId) {
    return getDirectArtifactUrl(workflowRunUrl, artifactId);
  }

  // Fallback to artifacts section if artifact not found
  return getArtifactsUrl(workflowRunUrl);
}

/**
 * Formats status with emoji and bold text
 * @param hasFailures - Whether there are failures
 * @param hasPending - Whether there are pending tests
 * @returns Formatted status string
 */
export function formatStatus(hasFailures: boolean, hasPending: boolean): string {
  if (hasFailures) {
    return `**Status:** ❌ **Failed**\n`;
  }
  // Only show pending warning if there are actual failures
  // Pending tests without failures should be treated as passed
  return `**Status:** ✅ **Passed**\n`;
}

/**
 * Formats device info section for PR comments
 * Generic utility that can format any device information
 */
export function formatDeviceInfo(deviceInfo?: DeviceInfo): string {
  if (!deviceInfo) {
    return '';
  }

  const hasAnyInfo = deviceInfo.modelName ||
    deviceInfo.softwareVersion ||
    deviceInfo.uiResolution ||
    deviceInfo.applicationVersion;

  if (!hasAnyInfo) {
    return '';
  }

  let section = `### 📱 Device Info\n\n`;

  if (deviceInfo.modelName) {
    section += `- **Model:** ${deviceInfo.modelName}\n`;
  }
  if (deviceInfo.softwareVersion) {
    section += `- **Software Version:** ${deviceInfo.softwareVersion}\n`;
  }
  if (deviceInfo.uiResolution) {
    section += `- **UI Resolution:** ${deviceInfo.uiResolution}\n`;
  }
  if (deviceInfo.applicationVersion) {
    section += `- **Application Version:** ${deviceInfo.applicationVersion}\n`;
  }

  section += '\n';
  return section;
}

