import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';

describe('Closed Caption Checks', function () {
  before(async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

  });  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/438464
  it.only(' C438464 - Closed Caption toggle = ON is in sync between VOD and Linear, @closed_captions', async () => {
    
    // Navigate to the Live News Row
    const node = await testUtils.getNodeForElement('topNavRecommendedWhiteLabel');
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Recommended Channels');


    // Start a live feed
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Toggle closed caption = on.
    await ecp.sendKeypress(ecp.Key.Left, {count: 2});
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Play a VOD title with CC.
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Press up to display the playback controls.
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Right, {count: 4});
    await ecp.sendKeypress(ecp.Key.Ok);
    const closedCaptionSection = await testUtils.getNodeForElement('closedCaptionSection');
    expect(closedCaptionSection.visible).to.be.true;
    await ecp.sendKeypress(ecp.Key.Down);
    const closedCaptionOn = await testUtils.getNodeForElement('closedCaptionOn');
    expect(closedCaptionOn.visible).to.be.true;


  });

});

