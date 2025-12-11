import * as fs from 'fs';
import * as path from 'path';
import { ecp, odc, device, utils } from 'roku-test-automation';
import { auth, testUtils } from './test-utils';

exports.mochaHooks = {
  // Useful for debugging what is running on which Roku device
  // beforeEach() {
  //   console.log(this.currentTest.title, process.env.MOCHA_WORKER_ID)
  // },
  async beforeAll() {
    let deviceSelector = 0;
    if (process.env.MOCHA_WORKER_ID !== undefined) {
      deviceSelector = +process.env.MOCHA_WORKER_ID;
    }

    utils.setupEnvironmentFromConfigFile(undefined, deviceSelector);
    const host = device.getCurrentDeviceConfig().host;

    // Used to let us know if we have already deployed the application to this device or if this the first time running
    let isFirstRunForDevice = true;

    if (process.env.RERUN_AUTOMATED_TESTS === 'true') {
      // Check if the application is currently running
      if (!await ecp.isActiveApp()) {
        console.log('Launching existing channel');
        // If not go ahead and launch it
        await ecp.sendLaunchChannel();
      }
    } else {
      if (device.deployed) {
        isFirstRunForDevice = false;
        // If we have already deployed do nothing
      } else if (fs.existsSync(device.getOutputZipFilePath({}))) {
        // Check if our package already exists, if it does then we are running through gulp runAutomatedTests and have already made our package
        console.log(`Publishing package to ${host}`);
        await device.publish();
        device.deployed = true;
      } else {
        // Else we're running mocha directly and need to deploy instead
        let buildFolder = 'build/local';
        if (process.env.buildFolder) {
          buildFolder = process.env.buildFolder;
        }

        console.log(`Deploying app to ${host}`);
        await device.deploy({
          rootDir: buildFolder,
          files: [
            '**/*'
          ]
        });
      }
    }

    // Wait for the application to startup to verify the application has been successfully loaded on the device before we proceed. In some cases we were somehow triggering an ECP launch before the application had finished loading.
    await testUtils.untilTrue(async () => {
      return await testUtils.isApplicationRunning();
    });

    if (isFirstRunForDevice) {
      const deviceId = await auth.getDeviceId();
      console.log(`Retrieved Device ID: ${deviceId}`);
    }
  },
  async afterEach() {
    const test: Mocha.Test = this.currentTest;
    if (test.state === 'failed') {
      const baseScreenshotPath = path.join(testUtils.testsOutputFolder, 'screenshots');
      try {
        const screenshot = await device.getTestScreenshot(this, baseScreenshotPath, '_' + Date.now().toString());
        test.err['screenshotPath'] = screenshot.path;
      } catch (e) { }
      test.err['telnetLog'] = await device.getTelnetLog();
    }
  },
  async afterAll() {
    await odc.shutdown();
  }
};
