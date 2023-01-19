'use strict';
const { ecp, odc } = require('roku-test-automation');
const {waitForNodeCountStability, writeOutTestData } = require('../performance-utils');
const {expect} = require('chai');

describe('grid-navigation', function () {
  before(async function(){
    // want to wait for initial load to finish to give a stable platform to test off of
    await waitForNodeCountStability();

    // Make sure we're focused on the grid before we proceed
    const {node} = await odc.getFocusedNode();
    expect(node.id).to.equal('RowList');
  });


  afterEach(async function() {
    await odc.deleteNodeReferences();
  });


  it('horizontal_navigation', async function() {
    // Here we're adding a test to see how long it takes to navigate horizontally from one RowList item to the one to the right of it.
    const currFocusColumnObservePromise = odc.observeField({
      base: 'focusedNode',
      keyPath: 'currFocusColumn',
      match: 1
    })
    await odc.startResponsivenessTesting();
    const startTime = Date.now();
    await ecp.sendKeyPress(ecp.Key.RIGHT);
    const chanperfPromise = ecp.getChanperf();
    await currFocusColumnObservePromise;
    const outputData = {};
    outputData.navigateDuration = Date.now() - startTime;
    outputData.cpuPercent = (await chanperfPromise).plugin.cpuPercent;
    const {testingTotals} = await odc.getResponsivenessTestingData();
    outputData.responsivenessTesting = testingTotals;
    writeOutTestData(this, outputData);
  });


  it('vertical_navigation', async function() {
    // Here we're adding a test to see how long it takes to navigate vertically from one RowList item to the one to the right of it.
    const currFocusRowObservePromise = odc.observeField({
      base: 'focusedNode',
      keyPath: 'currFocusRow',
      match: 1
    });
    await odc.startResponsivenessTesting();
    const startTime = Date.now();
    await ecp.sendKeyPress(ecp.Key.DOWN);
    const chanperfPromise = ecp.getChanperf();
    await currFocusRowObservePromise;
    const outputData = {};
    outputData.navigateDuration = Date.now() - startTime;
    outputData.cpuPercent = (await chanperfPromise).plugin.cpuPercent;
    const {testingTotals} = await odc.getResponsivenessTestingData();
    outputData.responsivenessTesting = testingTotals;
    writeOutTestData(this, outputData);
  });
});
