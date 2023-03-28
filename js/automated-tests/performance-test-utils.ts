import { ecp, odc, utils, device } from 'roku-test-automation';
import * as fs from 'fs';
import * as shell from 'shelljs';

class PerformanceTestUtils {
  public writeOutTestData(test, contents) {
    const [testFolder, testName] = utils.getTestTitlePath(test);
    const outFolder = `out/performance-tests-output/${testFolder}`;

    if (!fs.existsSync(outFolder)) {
      fs.mkdirSync(outFolder, { recursive: true });
    }

    const {stdout: branchName} = shell.exec('git branch --show-current');
    const date = new Date().toISOString().split('.')[0];
    const fileName = `${outFolder}/${testName}_${branchName.trim()}_${date}.json`;
    fs.writeFileSync(fileName, JSON.stringify(contents, null, 2));
  }


  // Waits a minimum of 2 seconds for the node count to stay the same. With us checking every 250ms.
  // If node count changes we start over until node matches for a 2 second period.
  public async waitForNodeCountStability() {
    let lastNodeCount = 0;
    let numberOfTimesNodeCountMatched = 0;
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const result = await odc.getAllCount();
      if (lastNodeCount === result.totalNodes) {
        numberOfTimesNodeCountMatched++;
        if (numberOfTimesNodeCountMatched === 8) {
          return result;
        }
      } else {
        numberOfTimesNodeCountMatched = 0;
      }
      await utils.sleep(250);
      lastNodeCount = result.totalNodes;
    }
  }
}

const performanceTestUtils = new PerformanceTestUtils();

export {
  performanceTestUtils
};
