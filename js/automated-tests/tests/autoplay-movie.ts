import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

import { shared } from '../shared';
import { waitForDebugger } from 'inspector';
import { send } from 'process';

describe('Autoplay Movies', function () {

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768091
  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/105693
  it('C768091 - Autoplay Next Video On - Autoplay next title @autoplay', async () => {
    await triggerMovieAutoplayUI();

    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('GridMovie');

    // Testing to make sure the first item is focused.
    expect(node.itemFocused).to.be.equal(0);
    // Testing to make sure it is auto plays to the next title.
    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayGridMovie'
    );
    // TODO Optimize in future by providing a way for automation to override the value.
    // 30 seconds is a long wait. We need to update to pull from settings then from constants.
    await utils.sleep(30000);

    // Testing to make sure the new video is playing.
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const playerContent = await testUtils.getPlayerContent('videoPlayerScreen');
    const newVideoId = playerContent.parentType == 'series' ? playerContent.parentId : playerContent.id;
    expect(newVideoId).to.be.equal(gridContents[0].id);
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76115
  it('C76115 - Autoplay - Movie - When content focused then year displayed @autoplay', async () => {
    await triggerMovieAutoplayUI();

    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('GridMovie');

    // Testing to make sure it is auto plays to the next title.
    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayGridMovie'
    );

    const firstLine = await testUtils.getNodeForElement('autoPlayYearAndDuration');
    expect(firstLine.text).to.contain(gridContents[0].releaseDate);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768092
  it('C768092 - Autoplay Next Video On - Press back during Autoplay countdown @autoplay', async () => {
    await triggerMovieAutoplayUI();

    await ecp.sendKeypress(ecp.Key.Back);
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('videoPlayerScreen');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/70395
  it('C70395 - Autoplay - Movie - Timer resets as users navigates within the titles in autoplay UI @autoplay', async () => {
    await triggerMovieAutoplayUI();
    // Waiting for 5 seconds to let the countdown timer count down.
    await utils.sleep(5000);
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToNotShowOnScreen('countDownSecondsAutoPlay');
    // Testing to make sure countdown is counting down.
    await testUtils.waitForElementToFullyShowOnScreen('countDownSecondsAutoPlay');
    await utils.sleep(1000);
    const countDownNode = await testUtils.getNodeForElement('countDownSecondsAutoPlay');
    const seconds = parseInt(countDownNode.text);
    expect(seconds).to.be.greaterThanOrEqual(28);
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25123
  it('C25123 - Autoplay - Movie - When user chooses last title on the list then movie plays @autoplay', async () => {
    await triggerMovieAutoplayUI();

    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Rowlist to have focus', 15000);

    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayGridMovie'
    );
    const totalItems = gridContents.length;
    await ecp.sendKeypress(ecp.Key.Right, { count: totalItems, wait: 200 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'stopped');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const playerContent = await testUtils.getPlayerContent('videoPlayerScreen');
    const newVideoId = playerContent.parentType == 'series' ? playerContent.parentId : playerContent.id;
    expect(newVideoId).to.be.equal(gridContents[totalItems - 1].id);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/76105
  it('C76105 - Autoplay - Movie - When user chooses first title on the list then movie plays @autoplay', async () => {
    await triggerMovieAutoplayUI();

    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Rowlist to have focus', 15000);

    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayGridMovie'
    );
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'stopped');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const playerContent = await testUtils.getPlayerContent('videoPlayerScreen');
    const newVideoId = playerContent.parentType == 'series' ? playerContent.parentId : playerContent.id;
    expect(newVideoId).to.be.equal(gridContents[0].id);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/705819
  it('C705819 - BWW does not appear while autoplay modal is shown @autoplay', async () => {
    await triggerMovieAutoplayUI();

    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Movie Grid to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });

    // Focus should still be in the movie grid.
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('GridMovie');

    const infoPanel = await testUtils.getNodeForElement('browseWhileWatchingInfoPanel');
    expect(infoPanel.opacity).to.equal(0);
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/710850
  it('C710850 - Ensure movie plays to the end after dismissing autoplay modal @autoplay', async () => {
    await triggerMovieAutoplayUI();

    await ecp.sendKeypress(ecp.Key.Back);
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('videoPlayerScreen');

    // Testing to make sure it is auto plays to the next title.
    const gridContents = await testUtils.getAllGridItemsContent(
      'autoplayGridMovie'
    );
    // TODO Optimize in future by providing a way for automation to override the value.
    // 30 seconds is a long wait. We need to update to pull from settings then from constants.
    await utils.sleep(30000);

    // Testing to make sure the new video is playing.
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const playerContent = await testUtils.getPlayerContent('videoPlayerScreen');
    const newVideoId = playerContent.parentType == 'series' ? playerContent.parentId : playerContent.id;
    expect(newVideoId).to.be.equal(gridContents[0].id);
  });


  //Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/148692
  it('C148692 - Autoplay - Movie - When user searches for a movie and initiates playback, Autoplay should work @autoplay,@smoke', async () => {
    // Search for a Movie title
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await testUtils.waitForElementToFullyShowOnScreen('searchKeyPad');
    const MOVIE_TITLE = "Zapped";
    await ecp.sendText(MOVIE_TITLE);

    await shared.navigateToContentInSearchResults({ title: MOVIE_TITLE });
    await testUtils.retryWithTimeOut(async () => {
      const searchResultsText = await testUtils.getNodeForElement('searchResultsText');
      expect(searchResultsText.text).to.contain(MOVIE_TITLE);
    });

    //Play title, trigger autoplay
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await seekToTriggerCuePoint();

    // Autoplay triggered?
    await checkIfMovieAutoPlayUIisShowing();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768093
  it('C768093 - Autoplay Next Video Off - Do not Autoplay next episode @autoplay', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    await shared.turnOffAutoplay();
    await validateAutoplayNextVideoUINotShowing();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768094
  it('C768094 - Autoplay Next Video Off - Press Back button @autoplay', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    await shared.turnOffAutoplay();
    await validateAutoplayNextVideoUINotShowing();

    await ecp.sendKeypress(ecp.Key.Back);
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('videoPlayerScreen');

    await testUtils.waitForCurrentScreenToEqual('detailScreen');
  });

});

async function triggerMovieAutoplayUI() {
  await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
  await shared.turnOnAutoplay();
  await shared.openMovies();
  // Are we on the Movies page?
  await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
  await ecp.sendKeypress(ecp.Key.Play);
  await seekToTriggerCuePoint();

  // Autoplay triggered?
  await checkIfMovieAutoPlayUIisShowing();
}

async function seekToTriggerCuePoint() {
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
  await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');
}

async function checkIfMovieAutoPlayUIisShowing() {
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
  await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'width', 640, 10000);
  await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'height', 360, 10000);
}

async function validateAutoplayNextVideoUINotShowing() {
  await testUtils.goToPage('movies');
  await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

  await ecp.sendKeypress(ecp.Key.Play);
  await seekToTriggerCuePoint();
  await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Rowlist to have focus', 15000);

  await testUtils.waitForElementToNotShowOnScreen('autoplayCountdownTimerSection', 'Countdown timer section is still showing', 10000);

  await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'width', 640, 10000);
  await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'height', 360, 10000);
}
