import * as fs from 'fs';
import * as path from 'path';
import axios from 'axios';

const BUCKET_ID_FILE = '.test-bucket-id';
const BUCKET_DATA_FILE = '.test-bucket-data.json';
const SUMMARY_FILE = '.test-run-summary.json';

const TEMP_FILES = [BUCKET_ID_FILE, BUCKET_DATA_FILE, SUMMARY_FILE];

const DEFAULT_PLATFORM = 'roku';
const DEFAULT_TESTS_DIR = 'js/automated-tests/tests';
const DEFAULT_REQUEST_TIMEOUT = 5000;
const DEFAULT_CLOSE_TIMEOUT = 10000;
const DEFAULT_RETRY_COUNT = 3;

// --- Interfaces ---

interface DashboardConfig {
  apiUrl: string;
  platform: string;
  bucketId?: string;
}

interface SuitePayload {
  suitePath: string;
  suiteName: string;
  duration: number;
  passed: number;
  failed: number;
  passedTests: Array<{ title: string; duration: number }>;
  failedTests: Array<{ title: string; duration: number; error: string }>;
}

interface TestCounts {
  totalTests: number;
  totalSuites: number;
}

interface TestRunSummary {
  totalTests: number;
  passed: number;
  failed: number;
  duration: number;
}

interface BucketData {
  bucketId: string;
  platform: string;
  tag?: string;
  startTime: string;
}

interface StartBucketOptions {
  dashboardApiUrl: string;
  platform: string;
  tag?: string;
  runners?: string;
  githubActionId?: string;
}

interface CloseBucketOptions {
  dashboardApiUrl: string;
  success?: boolean;
}

// --- Main Class ---

/**
 * Manages communication with the Automation UI dashboard API.
 *
 * Supports two modes:
 * - **CI mode**: Bucket lifecycle (start/close) is managed by Gulp tasks via static methods.
 *   The mocha reporter only sends suite-level results during test execution.
 * - **Standalone mode**: The instance manages the full lifecycle (start → suites → complete).
 */
export class DashboardManager {
  private apiUrl: string;
  private platform: string;
  private bucketId: string | null;
  private isCiMode: boolean;

  constructor(config: DashboardConfig) {
    this.apiUrl = config.apiUrl;
    this.platform = config.platform;
    this.bucketId = config.bucketId || null;
    this.isCiMode = !!this.bucketId;
  }

  /**
   * Scans test files to count the number of `it()` blocks matching a tag.
   * If no tag is provided, counts all `it()` blocks.
   * Used to populate the `estimated` field when starting a test run.
   */
  static countTestsWithTag(tag?: string, testsDir = DEFAULT_TESTS_DIR): TestCounts {
    if (!fs.existsSync(testsDir)) return { totalTests: 0, totalSuites: 0 };

    let totalTests = 0;
    let totalSuites = 0;
    const isValidTag = tag && tag.startsWith('@');
    const escapedTag = isValidTag ? tag.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') : '';
    const testPattern = isValidTag
      ? new RegExp(`it\\s*\\([^'"]*['"][^'"]*${escapedTag}[^'"]*['"]`, 'g')
      : /it\s*\(/g;
    const suitePattern = /describe\s*\(/g;

    function scanDir(dir: string): void {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          scanDir(fullPath);
        } else if (entry.name.endsWith('.ts')) {
          const content = fs.readFileSync(fullPath, 'utf-8');
          const testMatches = content.match(testPattern);
          if (testMatches && testMatches.length > 0) {
            totalTests += testMatches.length;
            const suiteMatches = content.match(suitePattern);
            totalSuites += suiteMatches ? suiteMatches.length : 1;
          }
        }
      }
    }

    scanDir(testsDir);
    return { totalTests, totalSuites };
  }

  /**
   * Signals the start of a test run to the dashboard.
   * Skipped in CI mode — Gulp handles this via `startBucket()`.
   * @returns The bucket/run ID assigned by the dashboard, or null on failure.
   */
  async startTestRun(tag?: string, runners?: string, githubActionId?: string): Promise<string | null> {
    if (this.isCiMode) {
      console.log('Skipping start event (CI mode - handled by Gulp)');
      return this.bucketId;
    }

    try {
      const counts = DashboardManager.countTestsWithTag(tag);
      console.log(`Found ~${counts.totalTests} tests in ~${counts.totalSuites} suites`);

      const payload: Record<string, unknown> = {
        event: 'test_run_started',
        timestamp: new Date().toISOString(),
        platform: this.platform,
        runners: runners || '1',
        tag: tag || null,
        estimated: {
          tests: counts.totalTests,
          suites: counts.totalSuites,
        },
      };

      if (githubActionId) {
        payload.githubActionId = githubActionId;
      }

      const response = await this.sendToDashboard('/test-run/start', payload);
      const bucketId = this.extractBucketId(response);

      if (bucketId) {
        this.bucketId = bucketId;
        console.log(`Test run started: ${bucketId}`);
      }

      return bucketId;
    } catch (error: any) {
      console.error('Failed to send test run start:', error.message);
      return null;
    }
  }

  /**
   * Reports a completed test suite (describe block) to the dashboard.
   * Called by the mocha reporter after each non-root suite finishes.
   */
  async sendSuiteResult(suitePayload: SuitePayload): Promise<void> {
    try {
      const payload = {
        event: 'test_suite_completed',
        timestamp: new Date().toISOString(),
        testRunId: this.bucketId,
        platform: this.platform,
        suite: {
          path: suitePayload.suitePath,
          name: suitePayload.suiteName,
          duration: suitePayload.duration,
        },
        results: {
          passed: suitePayload.passed,
          failed: suitePayload.failed,
        },
        tests: {
          passed: suitePayload.passedTests,
          failed: suitePayload.failedTests,
        },
      };

      await this.sendToDashboard('/test-suite/result', payload);

      const status = suitePayload.failed > 0 ? 'FAIL' : 'PASS';
      console.log(`[Dashboard] ${status} Suite: ${suitePayload.suiteName} - Passed: ${suitePayload.passed}, Failed: ${suitePayload.failed}`);
    } catch (error: any) {
      console.error('Failed to send suite results to dashboard:', error.message);
    }
  }

  /**
   * Signals the end of a test run to the dashboard with final summary.
   * Skipped in CI mode — Gulp handles this via `closeBucket()`.
   */
  async completeTestRun(passed: number, failed: number, duration: number): Promise<void> {
    if (this.isCiMode) {
      console.log('Skipping complete event (CI mode - handled by Gulp)');
      return;
    }

    try {
      const payload = {
        event: 'test_run_completed',
        timestamp: new Date().toISOString(),
        platform: this.platform,
        test_run_id_in_progress: this.bucketId,
        summary: { totalTests: passed + failed, passed, failed, duration },
        success: failed === 0,
      };

      await this.sendToDashboard('/test-run/complete', payload);
      console.log(`Test run completed - Passed: ${passed}, Failed: ${failed}`);
    } catch (error: any) {
      console.error('Failed to send test run completion:', error.message);
    }
  }

  /**
   * Sends a payload to the dashboard API with retry logic.
   * Retries with exponential backoff (1s, 2s, 3s) on failure.
   */
  private async sendToDashboard(endpoint: string, payload: Record<string, unknown>, retries = DEFAULT_RETRY_COUNT): Promise<any> {
    const url = `${this.apiUrl}${endpoint}`;

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        return await axios.post(url, payload, {
          timeout: DEFAULT_REQUEST_TIMEOUT,
          headers: { 'Content-Type': 'application/json' },
        });
      } catch (error) {
        if (attempt === retries) throw error;
        await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
      }
    }
  }

  /**
   * Extracts the bucket/run ID from the dashboard API response.
   * Handles multiple response formats for compatibility.
   */
  private extractBucketId(response: any): string | null {
    if (response?.data?.success && response?.data?.data) {
      return response.data.data.test_run_id_in_progress;
    }
    return response?.data?.bucketId || response?.data?.runId || response?.data?.id || null;
  }

  // --- Static helpers for Gulp task lifecycle ---

  /**
   * Starts a new test bucket via the dashboard API (called from Gulp).
   * Persists the bucket ID to disk so the mocha reporter and `closeBucket` can use it.
   * In GitHub Actions, also writes BUCKET_ID to $GITHUB_ENV for subsequent steps.
   */
  static async startBucket(options: StartBucketOptions): Promise<string | null> {
    const manager = new DashboardManager({
      apiUrl: options.dashboardApiUrl,
      platform: options.platform,
    });

    const bucketId = await manager.startTestRun(options.tag, options.runners, options.githubActionId);

    if (bucketId) {
      fs.writeFileSync(BUCKET_ID_FILE, bucketId);
      fs.writeFileSync(BUCKET_DATA_FILE, JSON.stringify({
        bucketId,
        platform: options.platform,
        tag: options.tag,
        startTime: new Date().toISOString(),
      } as BucketData, null, 2));

      if (process.env.GITHUB_ENV) {
        fs.appendFileSync(process.env.GITHUB_ENV, `BUCKET_ID=${bucketId}\n`);
        fs.appendFileSync(process.env.GITHUB_ENV, `AUTOMATION_UI_IN_PROGRESS=true\n`);
      }
    }

    return bucketId;
  }

  /**
   * Closes the test bucket via the dashboard API (called from Gulp after tests finish).
   * Reads the test summary written by the mocha reporter to include final counts in the payload.
   * Cleans up all temp files (bucket ID, bucket data, test summary) regardless of outcome.
   */
  static async closeBucket(options: CloseBucketOptions): Promise<void> {
    try {
      if (!fs.existsSync(BUCKET_ID_FILE)) {
        console.error('Bucket ID file not found. Cannot close bucket.');
        return;
      }

      const bucketId = fs.readFileSync(BUCKET_ID_FILE, 'utf-8').trim();
      const bucketData = DashboardManager.readJsonFile<BucketData>(BUCKET_DATA_FILE);
      const summary = DashboardManager.readJsonFile<TestRunSummary>(SUMMARY_FILE);

      if (summary) {
        console.log(`Test summary: ${summary.passed} passed, ${summary.failed} failed, ${summary.totalTests} total, ${summary.duration}ms`);
      }

      const payload: Record<string, unknown> = {
        event: 'test_run_completed',
        timestamp: new Date().toISOString(),
        platform: bucketData?.platform || process.env.PLATFORM || DEFAULT_PLATFORM,
        test_run_id_in_progress: bucketId,
        success: options.success !== undefined ? options.success : (summary ? summary.failed === 0 : true),
      };

      if (summary) {
        payload.summary = summary;
      }

      await axios.post(`${options.dashboardApiUrl}/test-run/complete`, payload, {
        timeout: DEFAULT_CLOSE_TIMEOUT,
        headers: { 'Content-Type': 'application/json' },
      });
      console.log('Test bucket closed successfully');
    } catch (error: any) {
      console.error('Failed to close test bucket:', error.message);
      throw error;
    } finally {
      DashboardManager.cleanupTempFiles();
    }
  }

  /**
   * Reads and parses a JSON file, returning null if it doesn't exist or can't be parsed.
   */
  private static readJsonFile<T>(filePath: string): T | null {
    if (!fs.existsSync(filePath)) return null;
    try {
      return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    } catch {
      console.warn(`Could not read ${filePath}`);
      return null;
    }
  }

  /**
   * Removes all temp files created during the test run lifecycle.
   */
  private static cleanupTempFiles(): void {
    for (const file of TEMP_FILES) {
      try { fs.unlinkSync(file); } catch {}
    }
  }
}
