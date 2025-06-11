import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { count, timeEnd } from 'console';



describe('Closed Captions Checks', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/438464
  it('C438464 - Closed Caption toggle = ON is in sync between VOD and Linear, @closed_captions', async () => {

    // Navigate to the Live News Row from Home screen
    // Jump to Recommended Channels row
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

    // Start a live feed
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(7000); // Needed this
   
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 25000);

    // Turn on Linear CC
    await utils.sleep(1500);
    await ecp.sendKeypress(ecp.Key.Left, {count:2});
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
 
    // Back to Home, Search page and play a VOD title
    await utils.sleep(3000);
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 10000);
    
    // Is the left Nav open?
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.verifyFocusedSideNavMenuItemEquals('home');

    // If so, select Search
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Up);
    const leftNavSearchItem = await testUtils.getNodeForElement('leftNavSearchItem');
    expect(leftNavSearchItem.text).to.equal('Search');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we on the Search page?
    await utils.sleep(3000); // Will not work without sleep here
    await testUtils.getNodeForElement('searchKeyPad');

    // If so, send search terms
    await ecp.sendText('lego masters');

    // Call function to navigate right to search results grid
    await navigateRightToGrid();

    // Select item and Play button
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'title not shown', 10000);
    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen','playing', 20000);

    // Check CC state is On for VOD title
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Right, {count:4});
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);
    const content = await testUtils.getAllGridItemsContent('closedCaptionCheckBoxList');
    const closedCaptionOn = content.find(item => item.title === 'English');
    expect(closedCaptionOn.checked).to.be.true;

  }); 

 // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/438466
 it('C438466 - Closed Caption toggle = OFF is in sync between VOD and Linear, @closed_captions', async () => {

    // Navigate to the Live News Row from Home screen
    await testUtils.goToPage('home');

    // Jump to Recommended Channels row
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

    // Start a live feed
    await ecp.sendKeypress(ecp.Key.Ok, {count: 2});
    
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

    // Turn OFF Linear CC
    await ecp.sendKeypress(ecp.Key.Left, {count:2});
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Ok);
 
 
    // Back to Home, Search page and play a VOD title
    await utils.sleep(4000);
    await testUtils.goToPage('home');
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    
    // Is the left Nav open?
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.verifyFocusedSideNavMenuItemEquals('home');

    // If so, select Search
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.getNodeForElement('leftNavSearchItem');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Are we on the Search page?
    await utils.sleep(2000);
    await testUtils.getNodeForElement('searchKeyPad');

    // If so, send search terms
    await ecp.sendText('lego');
    await utils.sleep(3000);


    // Call function to navigate right to search results grid
    await navigateRightToGrid();

    // Select item and Play button
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.selectAndVerifyDetailPageMenuItem('play');

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Check CC state is Off for VOD title
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Right, {count:4});
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);
    const content = await testUtils.getAllGridItemsContent('closedCaptionCheckBoxList');
    const closedCaptionOff = content.find(item => item.title === 'Off');
    expect(closedCaptionOff.checked).to.be.true;
  }); 

});

// Navigate right until the grid is in focus
async function navigateRightToGrid() {
    await testUtils.untilTrue(async () => {
      await ecp.sendKeypress(ecp.Key.Right);
      const { value: id } = await odc.getValue({
        base: 'focusedNode',
        keyPath: 'id'
      });
      return id === 'ResultGrid';
    }, 'ResultGrid never obtained focus');
  }