import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';
import { count, timeEnd } from 'console';



describe('Closed Captions Checks', function () {
  beforeEach(async () => {
    await testUtils.startApplicationAtPage('home');
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/438464
  it('C438464 - Closed Caption toggle = ON is in sync between VOD and Linear, @closed_captions', async () => {

    // Navigate to the Live News Row from Home screen
    // Scroll down to find "On Now" row (due to pagination)
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels' });
    await utils.sleep(1000);
    // Start a live feed
    await ecp.sendKeypress(ecp.Key.Ok);
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 25000);
    await ecp.sendKeypress(ecp.Key.Left, { count: 4, wait: 500 });
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    await testUtils.goToPage('search');
    await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for search screen', 10000);
    await ecp.sendText('t');

    await shared.navigateRightToSearchGrid();

    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToNotShowOnScreen('contentControllerSpinner', 'contentControllerSpinner is still shown', 10000);
    await testUtils.waitForCurrentScreenToEqual('detailScreen');
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'title not shown', 20000);

    // Wait for detail screen menu to load with items and have focus
    await testUtils.retryWithTimeOut(async () => {
      const menuItems = await testUtils.getAllGridItemsContent('detailScreenMenu');
      expect(menuItems.length).to.be.greaterThan(0, 'detailScreenMenu should have items');

      await testUtils.waitForElementToShowOnScreen('detailScreenMenu', 'detailScreenMenu not shown', 10000);

      const hasFocus = await testUtils.elementHasFocus('detailScreenMenu');
      expect(hasFocus).to.equal(true, 'detailScreenMenu should have focus');
    }, 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 120000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);

    // Check CC state is On for VOD title
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);

    const videoNode = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoNode.globalCaptionMode).to.equal('On');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/438466
  it('C438466 - Closed Caption toggle = OFF is in sync between VOD and Linear, @closed_captions', async () => {

    // Navigate to the Live News Row from Home screen
    // Scroll down to find "On Now" row (due to pagination)
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels' });
    await utils.sleep(1000);
    // Start a live feed
    await ecp.sendKeypress(ecp.Key.Ok);
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 25000);
    await ecp.sendKeypress(ecp.Key.Left, { count: 4, wait: 500 });
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(100);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    await testUtils.goToPage('search');
    await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for search screen', 10000);
    await ecp.sendText('the');

    await shared.navigateRightToSearchGrid();

    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForElementToNotShowOnScreen('contentControllerSpinner', 'contentControllerSpinner is still shown', 10000);
    await testUtils.waitForCurrentScreenToEqual('detailScreen');
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'title not shown', 10000);

    // Wait for detail screen menu to load with items and have focus
    await testUtils.retryWithTimeOut(async () => {
      const menuItems = await testUtils.getAllGridItemsContent('detailScreenMenu');
      expect(menuItems.length).to.be.greaterThan(0, 'detailScreenMenu should have items');

      await testUtils.waitForElementToShowOnScreen('detailScreenMenu', 'detailScreenMenu not shown', 10000);

      const hasFocus = await testUtils.elementHasFocus('detailScreenMenu');
      expect(hasFocus).to.equal(true, 'detailScreenMenu should have focus');
    }, 10000);


    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 120000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 20000);

    // Check CC state is Off for VOD title
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);

    const videoNode = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoNode.globalCaptionMode).to.equal('Off');
  });

});

