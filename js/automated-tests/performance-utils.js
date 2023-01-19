'use strict';
const { odc, ecp, utils } = require('roku-test-automation');
const fs = require('fs');
const shell = require('shelljs');
shell.config.silent = true;


function writeOutTestData(test, contents) {
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
async function waitForNodeCountStability() {
  let lastNodeCount = 0;
  let numberOfTimesNodeCountMatched = 0
  while (true) {
    const result = await odc.storeNodeReferences({
      includeNodeCountInfo: true
    });
    await odc.deleteNodeReferences();
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


function waitForAppLaunchBeaconToFire() {
  return odc.observeField({
    base: 'global',
    keyPath: 'trackingLoggingTask.logMsg',
    match: {
      base: 'global',
      keyPath: 'trackingLoggingTask.logMsg.subtype',
      value: 'time-to-load'
    }
  });
}


async function exitApplication() {
  try {
    await odc.setValue({
      base: 'scene',
      keyPath: 'ContentController.exitApp',
      value: true
    });
  } catch (e) {
    // We don't care if it does not return since this can be expected behavior since we're stopping the application
  }
}


async function waitForApplicationShutdown(appId = 'dev') {
  let result;
  do {
    result = await ecp.getActiveApp();
  } while(result.app.id === appId);
}


module.exports = {
  writeOutTestData,
  waitForNodeCountStability,
  waitForAppLaunchBeaconToFire,
  exitApplication,
  waitForApplicationShutdown
};
