'use strict';

import { ecp, odc, utils, device } from 'roku-test-automation';
import { testUtils } from './test-utils';

before(async () => {
  if (process.env.isAlreadyDeployed === 'true') {
    // Check if the application is currently running
    if (!await ecp.isActiveApp()) {
      console.log('Launching existing channel');
      // If not go ahead and launch it
      await ecp.sendLaunchChannel();
    }
  } else {
    console.log('deploying app');

    let buildFolder = 'build/local';
    if (process.env.buildFolder) {
      buildFolder = process.env.buildFolder;
    }

    await device.deploy({
      rootDir: buildFolder,
      files: [
        '**/*'
      ]
    });
  }
});

after(async function () {
  await odc.shutdown();
});
