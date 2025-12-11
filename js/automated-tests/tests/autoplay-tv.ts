import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

import { shared } from '../test-helpers';
import { waitForDebugger } from 'inspector';

describe('Autoplay Series', function () {

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768087
  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535750
  it('C768087 - Autoplay Next Video On - Autoplay next title @autoplay', async () => {
    await triggerSeriesAutoplayUI();

    await testUtils.waitForElementToHaveFocus('autoplayUINextEpisodeButton', 'Timed out waiting for Next Episode button to have focus', 15000);

    // Testing to make sure it is auto plays to the next title.
    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayUISeriesGrid'
    );
    // TODO Optimize in future by providing a way for automation to override the value.
    // 16 seconds is a long wait. We need to update to pull from settings then from constants.
    await utils.sleep(16000);
    const videoNode2 = await testUtils.getNodeForElement('videoPlayerActual');
    const newVideoId = videoNode2.content.id;
    expect(newVideoId).to.be.equal(gridContents[0].id);

    // Testing to make sure the new video is playing.
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768088
  it('C768088 - Autoplay Next Video On - Press back during Autoplay countdown @autoplay', async () => {
    await triggerSeriesAutoplayUI();

    await ecp.sendKeypress(ecp.Key.Back);
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('videoPlayerScreen');
  });

  //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/148693
  it('C148693 - Autoplay - Series- When user searches for a Series and initiates playback, Autoplay should work @autoplay', async () => {
    // Search for a Series title
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await testUtils.waitForElementToFullyShowOnScreen('searchKeyPad');
    const TITLE = "everybody hates chris";
    await ecp.sendText(TITLE);

    await shared.navigateToContentInSearchResults({ title: TITLE });
    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text.toLowerCase()).to.contain(TITLE);
    });

    //Play title, trigger autoplay
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await seekToTriggerCuePoint();

    // Autoplay triggered?
    await checkIfSeriesAutoPlayUIisShowing();
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535854
  it('C535854 - Autoplay - Series - Next episode plays after multiple consecutive auto plays @autoplay', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);
    await shared.openSeries();
    // Are we on the Series page?
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
    await ecp.sendKeypress(ecp.Key.Play);

    await seekToEndToTriggerCuePointAndCheckIfNextEpisodePlays();

    await seekToEndToTriggerCuePointAndCheckIfNextEpisodePlays();

    await seekToEndToTriggerCuePointAndCheckIfNextEpisodePlays();

    await seekToEndToTriggerCuePointAndCheckIfNextEpisodePlays();
  });


  async function seekToEndToTriggerCuePointAndCheckIfNextEpisodePlays() {
    await seekToTriggerCuePoint();
    // Autoplay triggered?
    await checkIfSeriesAutoPlayUIisShowing();
    await testUtils.waitForElementToHaveFocus('autoplayUINextEpisodeButton', 'Timed out waiting for Next Episode button to have focus', 15000);
    // Testing to make sure it is auto plays to the next title.
    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayUISeriesGrid'
    );
    await ecp.sendKeypress(ecp.Key.Ok);
    const videoNode2 = await testUtils.getNodeForElement('videoPlayerActual');
    const newVideoId = videoNode2.content.id;
    expect(newVideoId).to.be.equal(gridContents[0].id);

    // Testing to make sure the new video is playing.
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
  }

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768089
  it('C768089 - Autoplay Next Video Off - Do not Autoplay next episode @autoplay', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    await shared.enableAutoplayInSettings(false);
    await validateAutoplayNextVideoUINotShowing();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768094
  it('C768094 - Autoplay Next Video Off - Press Back button @autoplay', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    await shared.enableAutoplayInSettings(false);
    await validateAutoplayNextVideoUINotShowing();

    await ecp.sendKeypress(ecp.Key.Back);
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('videoPlayerScreen');

    await testUtils.waitForCurrentScreenToEqual('detailScreen');
  });

});


async function triggerSeriesAutoplayUI() {
  await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
  await shared.enableAutoplayInSettings(true);
  await shared.openSeries();
  // Are we on the Movies page?
  await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
  await ecp.sendKeypress(ecp.Key.Down);
  await utils.sleep(1000);
  await ecp.sendKeypress(ecp.Key.Play);
  await seekToTriggerCuePoint();

  // Autoplay triggered?
  await checkIfSeriesAutoPlayUIisShowing();
}


async function seekToTriggerCuePoint() {
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
  await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');
}

async function checkIfSeriesAutoPlayUIisShowing() {
  await testUtils.waitForElementToFullyShowOnScreen('countDownAutoPlay');
  const countDownAutoPlay = await testUtils.getNodeForElement('countDownAutoPlay');
  // Testing to make sure countdown is showing.
  expect(countDownAutoPlay.text).to.contain('Up Next in');

  // Testing to make sure countdown is counting down.
  await testUtils.waitForElementToFullyShowOnScreen('countDownSecondsAutoPlay');
  await utils.sleep(1000);
  var countDownNode = await testUtils.getNodeForElement('countDownSecondsAutoPlay');
  var seconds = parseInt(countDownNode.text);
  if ((typeof seconds === 'number' && !Number.isNaN(seconds)) === false) {
    await utils.sleep(1000);
    countDownNode = await testUtils.getNodeForElement('countDownSecondsAutoPlay');
    seconds = parseInt(countDownNode.text);
  }
  await utils.sleep(2000);
  const countDownNode2 = await testUtils.getNodeForElement('countDownSecondsAutoPlay');
  expect(seconds).to.be.greaterThan(parseInt(countDownNode2.text));
}

async function validateAutoplayNextVideoUINotShowing() {
  await testUtils.goToPage('series');
  await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

  await ecp.sendKeypress(ecp.Key.Play);
  await seekToTriggerCuePoint();
  await testUtils.waitForElementToHaveFocus('autoplayUINextEpisodeButton', 'Timed out waiting for next episode button to have focus', 15000);

  await testUtils.waitForElementToNotShowOnScreen('autoplayCountdownTimerSection', 'Countdown timer section is still showing', 10000);
}
