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
import * as fs from 'fs';
import * as https from 'https';
import * as path from 'path';
import { DEVICE_INFO_DIR, fileKey } from './device-info-constants';

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
  private githubRunId: string;
  private pendingTests: Map<string, PendingSuite> = new Map();
  private inflightDispatches: Promise<void>[] = [];
  private dispatchSuccessCount: number = 0;
  private dispatchFailureCount: number = 0;

  constructor(runner: mocha.Runner, options: mocha.MochaOptions) {
    this.mochawesomeReporter = new Mochawesome(runner, options);
    this.jsonReporter = new mocha.reporters.JSON(runner, options);

    this.githubToken = process.env.GITHUB_TOKEN || '';
    this.githubRepository = process.env.GITHUB_REPOSITORY || '';
    this.dashboardBranch = process.env.DASHBOARD_BRANCH || 'master';
    this.platform = process.env.PLATFORM || 'roku';
    this.githubRunId = process.env.runId || '';
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

      runner.on(mocha.Runner.constants.EVENT_TEST_PENDING, (test: mocha.Test) => {
        this.accumulateTest(test, 'skipped');
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

  /**
   * Reads device info written by the worker that executed the given file.
   * Returns {id, model} or undefined if unavailable.
   */
  private getDeviceInfoForFile(file: string): { id: string; model: string } | undefined {
    try {
      const entryPath = path.join(DEVICE_INFO_DIR, `fwm-${fileKey(file)}.json`);
      if (!fs.existsSync(entryPath)) return undefined;
      const entry = JSON.parse(fs.readFileSync(entryPath, 'utf-8'));
      const infoPath = path.join(DEVICE_INFO_DIR, `worker-${entry.workerId}.json`);
      if (!fs.existsSync(infoPath)) return undefined;
      const info = JSON.parse(fs.readFileSync(infoPath, 'utf-8'));
      if (!info.id && !info.model) return undefined;
      return info;
    } catch {
      return undefined;
    }
  }

  /** Builds and dispatches a suite result payload. */
  private reportSuite(file: string, data: PendingSuite): void {
    const passed = data.tests.filter(t => t.state === 'passed');
    const failed = data.tests.filter(t => t.state === 'failed');
    const skipped = data.tests.filter(t => t.state === 'skipped');

    if (passed.length === 0 && failed.length === 0 && skipped.length === 0) return;

    const suitePath = path.relative(process.cwd(), file);

    const suiteData: Record<string, unknown> = {
      platform: this.platform,
      suite: {
        path: suitePath,
        name: data.suiteName,
      },
      results: {
        total: data.tests.length,
        passed: passed.length,
        failed: failed.length,
        broken: 0,
        skipped: skipped.length,
      },
      tests: data.tests.map(t => ({
        title: t.title,
        fullName: t.fullTitle,
        duration: t.duration,
        status: t.state,
        ...(t.state === 'failed' ? { failureMessages: [t.error || 'Unknown error'] } : {}),
      })),
    };

    const deviceInfo = this.getDeviceInfoForFile(file);
    if (deviceInfo) {
      suiteData.device = deviceInfo;
    }

    const status = failed.length > 0 ? 'FAIL' : 'PASS';
    console.log(`  [Dashboard] ${status} ${data.suiteName} (P:${passed.length} F:${failed.length} S:${skipped.length})`);

    this.inflightDispatches.push(this.dispatchSuiteResult(suiteData, data.suiteName));
  }

  /**
   * Dispatches dashboard-api.yml with send-suite action via the GitHub API.
   * Returns a promise that resolves once the HTTP response is received.
   * Successes increment a counter (logged once in done()); failures are logged
   * inline with the suite name for diagnosability.
   */
  private dispatchSuiteResult(suiteData: unknown, suiteName: string): Promise<void> {
    return new Promise((resolve) => {
      const recordFailure = (reason: string) => {
        this.dispatchFailureCount++;
        console.log(`  [Dashboard] Dispatch failed for "${suiteName}": ${reason}`);
      };

      try {
        const [owner, repo] = this.githubRepository.split('/');
        const body = JSON.stringify({
          ref: this.dashboardBranch,
          inputs: {
            action: 'send-suite',
            platform: this.platform,
            github_action_id: this.githubRunId,
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
          timeout: 15000,
        }, (res) => {
          let responseBody = '';
          res.on('data', (chunk: Buffer) => { responseBody += chunk; });
          res.on('end', () => {
            if (res.statusCode === 204) {
              this.dispatchSuccessCount++;
            } else {
              recordFailure(`HTTP ${res.statusCode}: ${responseBody}`);
            }
            resolve();
          });
          res.resume();
        });

        req.on('timeout', () => {
          req.destroy(new Error('Request timed out'));
        });

        req.on('error', (err: Error) => {
          recordFailure(err.message);
          resolve();
        });

        req.write(body);
        req.end();
      } catch (err: unknown) {
        recordFailure(err instanceof Error ? err.message : String(err));
        resolve();
      }
    });
  }

  done(failures: number, fn?: (failures: number) => void): void {
    const finish = () => {
      const total = this.inflightDispatches.length;
      if (total > 0) {
        const succeeded = this.dispatchSuccessCount;
        const failed = this.dispatchFailureCount;
        const indeterminate = total - succeeded - failed;
        let summary = `  [Dashboard] Dispatched ${succeeded}/${total} suites`;
        if (failed > 0) summary += `, ${failed} failed`;
        if (indeterminate > 0) summary += `, ${indeterminate} unresolved (drain timeout)`;
        console.log(summary);
      }
      if (this.mochawesomeReporter.done) {
        this.mochawesomeReporter.done(failures, fn);
      } else if (fn) {
        fn(failures);
      }
    };

    if (this.inflightDispatches.length > 0) {
      console.log(`  [Dashboard] Waiting for ${this.inflightDispatches.length} pending dispatch(es)...`);
      const timeout = new Promise<void>((resolve) => setTimeout(() => {
        console.log('  [Dashboard] Drain timeout reached, proceeding with exit');
        resolve();
      }, 30000));
      Promise.race([Promise.all(this.inflightDispatches), timeout]).then(finish, finish);
    } else {
      finish();
    }
  }
}

module.exports = MochaReporter;
