import { expect } from 'chai';
import { ecp, odc } from 'roku-test-automation';
import { performanceTestUtils } from '../performance-test-utils';

describe('grid-navigation', function () {
  before(async function(){
    // want to wait for initial load to finish to give a stable platform to test off of
    await performanceTestUtils.waitForNodeCountStability();

    // Make sure we're focused on the grid before we proceed
    const {node} = await odc.getFocusedNode();
    expect(node.id).to.equal('RowList');
  });


  afterEach(async function() {
    await odc.deleteNodeReferences();
  });


  it('horizontal_navigation', async function() {
    // Here we're adding a test to see how long it takes to navigate horizontally from one RowList item to the one to the right of it.
    const currFocusColumnObservePromise = odc.onFieldChangeOnce({
      base: 'focusedNode',
      keyPath: 'currFocusColumn',
      match: 1
    });
    await odc.startResponsivenessTesting();
    const startTime = Date.now();
    await ecp.sendKeypress(ecp.Key.Right);
    const chanperfPromise = ecp.getChanperf();
    await currFocusColumnObservePromise;
    const outputData = {} as any;
    outputData.navigateDuration = Date.now() - startTime;
    outputData.cpuPercent = (await chanperfPromise).plugin.cpuPercent;
    const {testingTotals} = await odc.getResponsivenessTestingData();
    outputData.responsivenessTesting = testingTotals;
    performanceTestUtils.writeOutTestData(this, outputData);
  });


  it('vertical_navigation', async function() {
    // Here we're adding a test to see how long it takes to navigate vertically from one RowList item to the one to the right of it.
    const currFocusRowObservePromise = odc.onFieldChangeOnce({
      base: 'focusedNode',
      keyPath: 'currFocusRow',
      match: 1
    });
    await odc.startResponsivenessTesting();
    const startTime = Date.now();
    await ecp.sendKeypress(ecp.Key.Down);
    const chanperfPromise = ecp.getChanperf();
    await currFocusRowObservePromise;
    const outputData = {} as any;
    outputData.navigateDuration = Date.now() - startTime;
    outputData.cpuPercent = (await chanperfPromise).plugin.cpuPercent;
    const {testingTotals} = await odc.getResponsivenessTestingData();
    outputData.responsivenessTesting = testingTotals;
    performanceTestUtils.writeOutTestData(this, outputData);
  });
});
