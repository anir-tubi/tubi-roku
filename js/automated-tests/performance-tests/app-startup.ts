import { ecp, odc, utils } from 'roku-test-automation';
import { performanceTestUtils } from '../performance-test-utils';
import { testUtils } from '../test-utils';

describe('app-startup', function () {
  before(async function(){
    // Waiting for the application to fully load and try and make/cache its initial network calls to hopefully remove some of the variability in subsequent run
    await performanceTestUtils.waitForNodeCountStability();
  });


  afterEach(async function() {
    await odc.deleteNodeReferences();
    await odc.stopResponsivenessTesting();
  });


  it('app_launch', async function() {
    // Next want to exit the application since deploying auto launches the application and we want to give a more stable boot than the initial deploy does
    await testUtils.exitApplication();

    const startTime = Date.now();

    // Now we want to launch the application
    await ecp.sendLaunchChannel();
    await odc.startResponsivenessTesting();

    await testUtils.waitForAppLaunchBeaconToFire();

    // Start capturing our output data
    const outputData = {} as any;
    outputData.launchDuration = Date.now() - startTime;

    const {testingTotals} = await odc.getResponsivenessTestingData();
    outputData.responsivenessTesting = testingTotals;

    // Waiting for all initial nodes to load to get a better idea of true node count and memory usage
    const {totalNodes, nodeCountByType} = await performanceTestUtils.waitForNodeCountStability();

    const chanperf = await ecp.getChanperf();
    outputData.memory = chanperf.plugin.memory;

    outputData.totalNodes = totalNodes;
    outputData.nodeCountByType = nodeCountByType;

    performanceTestUtils.writeOutTestData(this, outputData);
  });


  it('app_resume', async function() {
    const observeActiveEventPromise = odc.onFieldChangeOnce({
      base: 'global',
      keyPath: 'trackingLoggingTask.trackEvent',
      match: {
        base: 'global',
        keyPath: 'trackingLoggingTask.trackEvent.type',
        value: 'active'
      }
    });

    await ecp.sendKeyPress(ecp.Key.Home);

    // Wait until the application has shutdown
    await testUtils.waitForApplicationShutdown();

    const startTime = Date.now();

    // Now we want to resume the application
    await ecp.sendLaunchChannel();

    // We consider ourselves loaded once the active event is fired
    await observeActiveEventPromise;

    // Start capturing our output data
    const resumeDuration = Date.now() - startTime;

    const {totalNodes, nodeCountByType} = await performanceTestUtils.waitForNodeCountStability();

    const chanperf = await ecp.getChanperf();
    const outputData = {
      resumeDuration: resumeDuration,
      memory: chanperf.plugin.memory,
      totalNodes: totalNodes,
      nodeCountByType: nodeCountByType
    };

    performanceTestUtils.writeOutTestData(this, outputData);
  });


  it('app_restart', async function() {
    // See how many nodes we started with
    const {totalNodes: previousTotalNodes} = await odc.storeNodeReferences({includeNodeCountInfo: true});
    await odc.deleteNodeReferences();

    await ecp.sendKeyPress(ecp.Key.Home);

    // Wait until the application has shutdown
    await testUtils.waitForApplicationShutdown();

    const startTime = Date.now();

    // Now we want to restart the application
    await ecp.sendLaunchChannel({
      params: {
        page: '' // Using page param to force a restart
      }
    });

    await testUtils.waitForAppLaunchBeaconToFire();

    // Start capturing our output data
    const restartDuration = Date.now() - startTime;

    // Have to wait for modal to appear before we try to remove it
    await utils.sleep(4000);

    // Remove the open modal for better node increase measurement
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Waiting for all initial nodes to load to get a better idea of true node count and memory usage
    const {totalNodes, nodeCountByType} = await performanceTestUtils.waitForNodeCountStability();

    const chanperf = await ecp.getChanperf();
    const outputData = {
      restartDuration: restartDuration,
      memory: chanperf.plugin.memory,
      totalNodes: totalNodes,
      nodeCountByType: nodeCountByType,
      totalNodesChange: totalNodes - previousTotalNodes
    };

    performanceTestUtils.writeOutTestData(this, outputData);
  });
});
