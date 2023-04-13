'use strict';

import { ecp, odc, utils, device } from 'roku-test-automation';
import { testUtils } from './test-utils';

before(async () => {
  console.log('deploying app');
  await device.deploy({
    rootDir: 'build/local',
    files: [
      '**/*'
    ]
  });

  await testUtils.waitForApplicationStartup();
});

after(async function () {
  await odc.shutdown();
});
