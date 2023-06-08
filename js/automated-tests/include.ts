'use strict';

import { ecp, odc, utils, device } from 'roku-test-automation';
import { testUtils } from './test-utils';

before(async () => {
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
});

after(async function () {
  await odc.shutdown();
});
