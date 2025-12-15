// Mocha doesn't support multiple reporters by itself. We want to do onscreen output for progress tracking, json output that will be used for importing into Testrail and html report output through mochawesome so we use this to do that.
import * as mocha from 'mocha';
import * as Mochawesome from 'mochawesome';

class MochaReporter {
  private mochawesomeReporter: Mochawesome;
  private jsonReporter: mocha.reporters.JSON;

  constructor(runner: mocha.Runner, options: mocha.MochaOptions) {
    this.mochawesomeReporter = new Mochawesome(runner, options);
    this.jsonReporter = new mocha.reporters.JSON(runner, options);
  }

  done(failures: number, fn?: (failures: number) => void): void {
    // Call mochawesome done first to generate HTML
    if (this.mochawesomeReporter.done) {
      this.mochawesomeReporter.done(failures, fn);
    } else if (fn) {
      fn(failures);
    }
  }
}

module.exports = MochaReporter;
