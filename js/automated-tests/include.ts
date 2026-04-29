import * as fs from 'fs';
import * as path from 'path';
import { ecp, odc, device, utils } from 'roku-test-automation';
import { auth, testUtils } from './test-utils';
import { CIRCUIT_BREAKER_DIR, CIRCUIT_BREAKER_THRESHOLD } from './circuit-breaker-constants';
import { DEVICE_INFO_DIR, fileKey } from './device-info-constants';


function getCircuitBreakerPath(workerId: string): string {
  return path.join(CIRCUIT_BREAKER_DIR, `worker-${workerId}.txt`);
}

function getConsecutiveFailures(workerId: string): number {
  try {
    const filePath = getCircuitBreakerPath(workerId);
    if (fs.existsSync(filePath)) {
      return parseInt(fs.readFileSync(filePath, 'utf-8').trim(), 10) || 0;
    }
  } catch (err) {
    console.warn(`Circuit breaker I/O error (read): ${err.message}`);
  }
  return 0;
}

function recordFailure(workerId: string): void {
  try {
    if (!fs.existsSync(CIRCUIT_BREAKER_DIR)) {
      fs.mkdirSync(CIRCUIT_BREAKER_DIR, { recursive: true });
    }
    const current = getConsecutiveFailures(workerId);
    fs.writeFileSync(getCircuitBreakerPath(workerId), String(current + 1));
  } catch (err) {
    console.warn(`Circuit breaker I/O error (write): ${err.message}`);
  }
}

async function writeDeviceInfo(workerId: string): Promise<void> {
  try {
    const { body } = await device.sendEcpGet('query/device-info');
    let serialNumber = '';
    let modelName = '';
    let modelNumber = '';
    const children = (body && (body as any).children) || [];
    for (const child of children) {
      if (child.name === 'serial-number') serialNumber = child.value;
      if (child.name === 'model-name') modelName = child.value;
      if (child.name === 'model-number') modelNumber = child.value;
    }
    const model = modelNumber ? modelName + ' - ' + modelNumber : modelName;
    if (!serialNumber && !model) {
      const childNames = children.map((c: any) => c && c.name).filter(Boolean).join(',');
      console.warn(`[DeviceInfo] worker ${workerId}: ECP returned no usable fields (children=[${childNames}]); skipping write`);
      return;
    }
    if (!fs.existsSync(DEVICE_INFO_DIR)) {
      fs.mkdirSync(DEVICE_INFO_DIR, { recursive: true });
    }
    const infoPath = path.join(DEVICE_INFO_DIR, `worker-${workerId}.json`);
    fs.writeFileSync(infoPath, JSON.stringify({ id: serialNumber, model: model }));
  } catch (err: any) {
    console.warn(`[DeviceInfo] worker ${workerId}: query failed: ${err.message}`);
  }
}

function resetFailures(workerId: string): void {
  try {
    const filePath = getCircuitBreakerPath(workerId);
    if (fs.existsSync(filePath)) {
      fs.writeFileSync(filePath, '0');
    }
  } catch (err) {
    console.warn(`Circuit breaker I/O error (reset): ${err.message}`);
  }
}

const fileWorkerMapWritten = new Set<string>();

exports.mochaHooks = {
  async beforeAll() {
    let deviceSelector = 0;
    if (process.env.MOCHA_WORKER_ID !== undefined) {
      deviceSelector = +process.env.MOCHA_WORKER_ID;
    }
    const workerId = process.env.MOCHA_WORKER_ID ?? '0';

    // Circuit breaker: if this worker has failed too many times in a row, skip immediately
    const consecutiveFailures = getConsecutiveFailures(workerId);
    if (consecutiveFailures >= CIRCUIT_BREAKER_THRESHOLD) {
      const msg = `Circuit breaker tripped: worker ${workerId} has ${consecutiveFailures} consecutive beforeAll failures. Skipping suite to avoid wasting time on an unresponsive device.`;
      console.error(`⚠ ${msg}`);
      throw new Error(msg);
    }

    try {
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

      // Wait for the application to startup to verify the application has been successfully loaded on the device before we proceed.
      try {
        await testUtils.untilTrue(async () => {
          return await testUtils.isApplicationRunning();
        });
      } catch (initialError) {
        // Recovery attempt: re-publish and re-launch the channel once before giving up
        console.warn(`⚠ Application not running on ${host} after initial wait. Attempting recovery (re-publish + re-launch)...`);
        try {
          if (fs.existsSync(device.getOutputZipFilePath({}))) {
            await device.publish();
          }
          await ecp.sendLaunchChannel();
          await testUtils.untilTrue(async () => {
            return await testUtils.isApplicationRunning();
          });
          console.log(`✓ Recovery succeeded on ${host}`);
        } catch (recoveryError) {
          console.warn(`⚠ Initial error on ${host}: ${initialError.message}`);
          throw new Error(`Application failed to start on ${host} even after recovery attempt: ${String(recoveryError)}`);
        }
      }

      if (isFirstRunForDevice) {
        const deviceId = await auth.getDeviceId();
        console.log(`Retrieved Device ID: ${deviceId}`);
      }

      // Suite setup succeeded — reset the circuit breaker for this worker
      resetFailures(workerId);
      await writeDeviceInfo(workerId);
    } catch (error) {
      // Record this failure for the circuit breaker
      recordFailure(workerId);
      throw error;
    }
  },
  beforeEach() {
    const test: Mocha.Test = this.currentTest;
    const file = (test as any).file as string;
    const workerId = process.env.MOCHA_WORKER_ID ?? '0';
    if (file && !fileWorkerMapWritten.has(file)) {
      fileWorkerMapWritten.add(file);
      try {
        if (!fs.existsSync(DEVICE_INFO_DIR)) {
          fs.mkdirSync(DEVICE_INFO_DIR, { recursive: true });
        }
        const safeKey = fileKey(file);
        const entryPath = path.join(DEVICE_INFO_DIR, `fwm-${safeKey}.json`);
        fs.writeFileSync(entryPath, JSON.stringify({ file, workerId }));
      } catch (err: any) {
        console.warn(`[DeviceInfo] worker ${workerId}: failed to write file-worker map: ${err.message}`);
      }
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
      try {
        test.err['telnetLog'] = await device.getTelnetLog();
      } catch (e) { }
    }
  },
  async afterAll() {
    try {
      const host = device.getCurrentDeviceConfig().host;
      const workerId = process.env.MOCHA_WORKER_ID ?? '0';
      console.log(`\n  Suite completed on device ${host} (worker ${workerId})\n`);
    } catch (_) { }
    try {
      await odc.shutdown();
    } catch (_) { }
  }
};
