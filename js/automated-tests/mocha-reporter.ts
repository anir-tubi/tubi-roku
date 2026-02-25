// Mocha doesn't support multiple reporters by itself. We want to do onscreen output for progress tracking,
// json output that will be used for importing into Testrail, html report output through mochawesome,
// and optionally allure results for nightly CI reports.
// When DASHBOARD_API_URL is set, suite results are also sent to the Automation UI dashboard in real time.
import * as mocha from 'mocha';
import * as Mochawesome from 'mochawesome';
import * as fs from 'fs';

let AllureMochaReporter: any = null;
try {
  AllureMochaReporter = require('allure-mocha');
} catch (_) {
  // allure-mocha not installed — skip
}

let DashboardManagerModule: any = null;
try {
  DashboardManagerModule = require('./dashboard-manager');
} catch (_) {
  // dashboard-manager not available — skip
}

interface SuiteContext {
  startTime: number;
  passed: Array<{ title: string; duration: number }>;
  failed: Array<{ title: string; duration: number; error: string }>;
}

class MochaReporter {
  private mochawesomeReporter: Mochawesome;
  private jsonReporter: mocha.reporters.JSON;
  private allureReporter: any;
  private dashboardManager: any;
  private suiteStack: SuiteContext[];
  private totalPassed: number;
  private totalFailed: number;
  private runStartTime: number;

  constructor(runner: mocha.Runner, options: mocha.MochaOptions) {
    this.mochawesomeReporter = new Mochawesome(runner, options);
    this.jsonReporter = new mocha.reporters.JSON(runner, options);

    const enableAllure = process.env.ENABLE_ALLURE === 'true' || !!process.env.DASHBOARD_API_URL;
    if (enableAllure && AllureMochaReporter) {
      this.allureReporter = new AllureMochaReporter(runner, options);
    }

    this.suiteStack = [];
    this.totalPassed = 0;
    this.totalFailed = 0;
    this.runStartTime = Date.now();

    const dashboardApiUrl = process.env.DASHBOARD_API_URL;
    if (dashboardApiUrl && DashboardManagerModule) {
      let bucketId = process.env.BUCKET_ID;
      if (!bucketId) {
        try {
          if (fs.existsSync('.test-bucket-id')) {
            bucketId = fs.readFileSync('.test-bucket-id', 'utf-8').trim();
          }
        } catch (_) {}
      }

      if (bucketId) {
        this.dashboardManager = new DashboardManagerModule.DashboardManager({
          apiUrl: dashboardApiUrl,
          platform: process.env.PLATFORM || 'roku',
          bucketId,
        });

        console.log(`Dashboard reporting enabled: ${dashboardApiUrl}`);
        console.log(`  Running in CI mode with Bucket ID: ${bucketId}`);
        this.setupDashboardListeners(runner);
      } else {
        console.log('Dashboard reporting skipped: no BUCKET_ID or .test-bucket-id found');
      }
    }
  }

  private setupDashboardListeners(runner: mocha.Runner): void {
    runner.on('suite', (suite: mocha.Suite) => {
      if (suite.root) return;
      this.suiteStack.push({
        startTime: Date.now(),
        passed: [],
        failed: [],
      });
    });

    runner.on('pass', (test: mocha.Test) => {
      const ctx = this.suiteStack[this.suiteStack.length - 1];
      if (ctx) {
        ctx.passed.push({
          title: test.fullTitle(),
          duration: test.duration || 0,
        });
      }
      this.totalPassed++;
    });

    runner.on('fail', (test: mocha.Test, err: Error) => {
      const ctx = this.suiteStack[this.suiteStack.length - 1];
      if (ctx) {
        ctx.failed.push({
          title: test.fullTitle(),
          duration: test.duration || 0,
          error: err.message || String(err),
        });
      }
      this.totalFailed++;
    });

    runner.on('suite end', (suite: mocha.Suite) => {
      if (suite.root) return;
      const ctx = this.suiteStack.pop();
      if (!ctx || (ctx.passed.length === 0 && ctx.failed.length === 0)) return;

      const suitePath = suite.file ? suite.file.replace(process.cwd() + '/', '') : suite.title;

      if (this.dashboardManager) {
        this.dashboardManager.sendSuiteResult({
          suitePath,
          suiteName: suite.title,
          duration: Date.now() - ctx.startTime,
          passed: ctx.passed.length,
          failed: ctx.failed.length,
          passedTests: ctx.passed,
          failedTests: ctx.failed,
        }).catch(() => {});
      }
    });

    runner.on('end', () => {
      const duration = Date.now() - this.runStartTime;
      const summary = {
        totalTests: this.totalPassed + this.totalFailed,
        passed: this.totalPassed,
        failed: this.totalFailed,
        duration,
      };

      try {
        fs.writeFileSync('.test-run-summary.json', JSON.stringify(summary));
      } catch (_) {}

      if (this.dashboardManager) {
        this.dashboardManager.completeTestRun(this.totalPassed, this.totalFailed, duration).catch(() => {});
      }
    });
  }

  done(failures: number, fn?: (failures: number) => void): void {
    const finishMochawesome = () => {
      if (this.mochawesomeReporter.done) {
        this.mochawesomeReporter.done(failures, fn);
      } else if (fn) {
        fn(failures);
      }
    };

    if (this.allureReporter && this.allureReporter.done) {
      let called = false;
      const onAllureDone = () => {
        if (called) return;
        called = true;
        finishMochawesome();
      };

      const timeout = setTimeout(onAllureDone, 5000);

      try {
        this.allureReporter.done(failures, () => {
          clearTimeout(timeout);
          onAllureDone();
        });
      } catch (_) {
        clearTimeout(timeout);
        onAllureDone();
      }
    } else {
      finishMochawesome();
    }
  }
}

module.exports = MochaReporter;
