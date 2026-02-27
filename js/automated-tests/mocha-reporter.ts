// Mocha doesn't support multiple reporters by itself. We want to do onscreen output
// for progress tracking, json output that will be used for importing into Testrail,
// and html report output through mochawesome so we use this to do that.
//
// Allure results are generated separately by post-processing Mochawesome JSON output
// via mochawesome-to-allure.ts, avoiding allure-mocha's incompatibility with --parallel.
//
// When DASHBOARD_REPORTING is enabled and GITHUB_TOKEN is available, per-suite
// progress updates are dispatched to dashboard-api.yml after each suite completes.
import * as mocha from 'mocha';
import * as Mochawesome from 'mochawesome';
import * as https from 'https';
import * as path from 'path';

interface TestResult {
  title: string;
  fullTitle: string;
  duration: number;
  state: string;
  error?: string;
}

interface PendingSuite {
  suiteName: string;
  tests: TestResult[];
}

class MochaReporter {
  private mochawesomeReporter: Mochawesome;
  private jsonReporter: mocha.reporters.JSON;
  private dashboardEnabled: boolean;
  private githubToken: string;
  private githubRepository: string;
  private dashboardBranch: string;
  private platform: string;
  private pendingTests: Map<string, PendingSuite> = new Map();

  constructor(runner: mocha.Runner, options: mocha.MochaOptions) {
    this.mochawesomeReporter = new Mochawesome(runner, options);
    this.jsonReporter = new mocha.reporters.JSON(runner, options);

    this.githubToken = process.env.GITHUB_TOKEN || '';
    this.githubRepository = process.env.GITHUB_REPOSITORY || '';
    this.dashboardBranch = process.env.DASHBOARD_BRANCH || 'master';
    this.platform = process.env.PLATFORM || 'roku';
    this.dashboardEnabled =
      process.env.DASHBOARD_REPORTING === 'true' &&
      !!this.githubToken &&
      !!this.githubRepository;

    if (this.dashboardEnabled) {
      console.log('  [Dashboard] Per-suite reporting enabled');

      runner.on(mocha.Runner.constants.EVENT_TEST_PASS, (test: mocha.Test) => {
        this.accumulateTest(test, 'passed');
      });

      runner.on(mocha.Runner.constants.EVENT_TEST_FAIL, (test: mocha.Test) => {
        this.accumulateTest(test, 'failed');
      });

      runner.on(mocha.Runner.constants.EVENT_SUITE_END, (suite: mocha.Suite) => {
        this.onSuiteEnd(suite);
      });
    }
  }

  /**
   * Accumulates a test result keyed by file path. Extracts the top-level suite
   * name from fullTitle since suite.parent/file are unavailable in parallel mode.
   */
  private accumulateTest(test: mocha.Test, state: string): void {
    const file = (test as any).file as string;
    if (!file) return;

    const fullTitle = test.fullTitle?.() || test.title;
    const suiteName = fullTitle.substring(0, fullTitle.length - test.title.length).trim();

    if (!this.pendingTests.has(file)) {
      this.pendingTests.set(file, { suiteName, tests: [] });
    }

    this.pendingTests.get(file)!.tests.push({
      title: test.title,
      fullTitle,
      duration: test.duration || 0,
      state,
      error: state === 'failed' ? (test.err?.message || 'Unknown error') : undefined,
    });
  }

  /**
   * On EVENT_SUITE_END, finds accumulated tests matching the suite title,
   * builds a payload, and dispatches it to the dashboard.
   */
  private onSuiteEnd(suite: mocha.Suite): void {
    if (suite.root) return;

    for (const [file, data] of this.pendingTests) {
      if (data.suiteName === suite.title) {
        this.reportSuite(file, data);
        this.pendingTests.delete(file);
        break;
      }
    }
  }

  /** Builds and dispatches a suite result payload. */
  private reportSuite(file: string, data: PendingSuite): void {
    const passed = data.tests.filter(t => t.state === 'passed');
    const failed = data.tests.filter(t => t.state === 'failed');

    if (passed.length === 0 && failed.length === 0) return;

    const suitePath = path.relative(process.cwd(), file);

    const suiteData = {
      event: 'test_suite_completed',
      timestamp: new Date().toISOString(),
      workerId: process.env.MOCHA_WORKER_ID || '0',
      platform: this.platform,
      suite: {
        path: suitePath,
        name: data.suiteName,
        duration: data.tests.reduce((sum, t) => sum + t.duration, 0),
      },
      results: {
        passed: passed.length,
        failed: failed.length,
      },
      tests: {
        passed: passed.map(t => ({
          title: t.title,
          fullName: t.fullTitle,
          duration: t.duration,
        })),
        failed: failed.map(t => ({
          title: t.title,
          fullName: t.fullTitle,
          duration: t.duration,
          failureMessages: [t.error || 'Unknown error'],
        })),
      },
    };

    const status = failed.length > 0 ? 'FAIL' : 'PASS';
    console.log(`  [Dashboard] ${status} ${data.suiteName} (P:${passed.length} F:${failed.length})`);

    this.dispatchSuiteResult(suiteData);
  }

  /**
   * Dispatches dashboard-api.yml with send-suite action via the GitHub API.
   * Fire-and-forget: errors are logged but never disrupt tests.
   */
  private dispatchSuiteResult(suiteData: unknown): void {
    try {
      const [owner, repo] = this.githubRepository.split('/');
      const body = JSON.stringify({
        ref: this.dashboardBranch,
        inputs: {
          action: 'send-suite',
          platform: this.platform,
          suite_data: JSON.stringify(suiteData),
        },
      });

      const req = https.request({
        hostname: 'api.github.com',
        path: `/repos/${owner}/${repo}/actions/workflows/dashboard-api.yml/dispatches`,
        method: 'POST',
        headers: {
          'Authorization': `token ${this.githubToken}`,
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'roku-mocha-reporter',
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
      }, (res) => {
        if (res.statusCode === 204) {
          console.log('  [Dashboard] Dispatch accepted');
        } else {
          let responseBody = '';
          res.on('data', (chunk: Buffer) => { responseBody += chunk; });
          res.on('end', () => {
            console.log(`  [Dashboard] Dispatch HTTP ${res.statusCode}: ${responseBody}`);
          });
        }
      });

      req.on('error', (err: Error) => {
        console.log(`  [Dashboard] Dispatch error: ${err.message}`);
      });

      req.write(body);
      req.end();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.log(`  [Dashboard] Dispatch failed: ${message}`);
    }
  }

  done(failures: number, fn?: (failures: number) => void): void {
    if (this.mochawesomeReporter.done) {
      this.mochawesomeReporter.done(failures, fn);
    } else if (fn) {
      fn(failures);
    }
  }
}

module.exports = MochaReporter;
