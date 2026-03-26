import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';
import { log } from 'console';
import { Utils } from 'handlebars';
import { ALL } from 'dns';

describe('Playback', function () {
  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537377  - https://tubi.testrail.io/index.php?/cases/view/537380

  it('C537377 537380 - Pause Playback @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/vie/537905
  it('C537905 - Forward Playback 30 seconds @playback_1', async () => {

    // Start at home page to select another title, different from previous test
    await testUtils.startApplicationAtPage('home');

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');

    const startposition = await testUtils.getPlayerPosition();

    // Fast-forward scrub (transport no longer has a +30s hop control)
    await ecp.sendKeypress(ecp.Key.Forward);
    await utils.sleep(2500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await seekWithinRange(startposition);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537378
  it('C537378 - Rewind Payback 30 seconds @playback_1', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Pause and scrub forward, then scrub back (hop buttons removed from transport)
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await testUtils.waitForElementToFullyShowOnScreen('playPauseButton');

    await ecp.sendKeypress(ecp.Key.Forward);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    const midPosition = await testUtils.getPlayerPosition();

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await seekWithinRange(midPosition);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535814
  it('C535814- Fast Forward 1x @playback_1,@registered_user,@smoke', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause to open player, use remote Forward for fast-forward scrub (no on-screen FF button)
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Forward);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');

    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-fwd');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('1');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535815
  it('C535815 - Fast Forward 2x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause, increase fast-forward speed with remote Forward
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Forward);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');
    await ecp.sendKeypress(ecp.Key.Forward);

    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-fwd');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('2');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537379
  it('C535816 - Fast Forward 3x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause, three Forward presses for 3x scrub speed
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Forward);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');
    await ecp.sendKeypress(ecp.Key.Forward);
    await ecp.sendKeypress(ecp.Key.Forward);

    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-fwd');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('3');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535816
  it('C535816 - Fast Forward 4x @playback_1,@registered_user', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause; fourth Forward wraps scrub speed back to 1x (maxScrub = 2 → speeds 1,2,3,1)
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Forward);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');
    await ecp.sendKeypress(ecp.Key.Forward);
    await ecp.sendKeypress(ecp.Key.Forward);
    await ecp.sendKeypress(ecp.Key.Forward);

    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-fwd');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('1');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537688
  it('C537688 - Details Page Displays History Progress Bar @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Forward, { count: 3 });
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');

    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-fwd');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('3');

    // Back out of the video player to land on Details page after FF
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await utils.sleep(1000);
    const videoPlayerScreenTopOverlay = await testUtils.getNodeForElement('videoPlayerScreenTopOverlay');
    if (videoPlayerScreenTopOverlay.opacity == 1) {
      await ecp.sendKeypress(ecp.Key.Back);
    }
    await ecp.sendKeypress(ecp.Key.Back);

    // Are we on the details page?
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    // Check that movie has history
    await testUtils.waitForElementToShowOnScreen('resumePlayingButton');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535850
  it('C535850 - Resume from series details page play @playback_1,@registered_user,@regression', async () => {
    await shared.openSeriesScreenAndWaitUntilListIsFocused();

    // verify resume when user goes back to series screen and selects/plays title again
    await verifyResumeWithinRangeWhenBackToScreen();

    // Remove from History
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/536522
  it('C536522 -  Resume from series details page episode play @playback_1,@registered_user,@regression', async () => {
    await shared.openSeriesScreenAndWaitUntilListIsFocused();

    // Enter Details page to get to Episodes list
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('episodesListButton');
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');

    // verify resume when user goes back to series screen and selects/plays title again
    await verifyResumeWithinRangeWhenBackToScreenEpisodes();

    // Remove from History
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25125
  it('C25125 - Rewind 1x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause, remote Rewind for rewind scrub
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');

    const rewindButton1x = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton1x.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-rew');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('1');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25126
  it('C25126 - Rewind 2x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause, two Rewind presses for 2x rewind scrub
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Rewind);

    await testUtils.waitForElementToFullyShowOnScreen('rewindButton2x');
    const rewindButton2x = await testUtils.getNodeForElement('rewindButton2x');
    expect(rewindButton2x.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-rew');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('2');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25127
  it('C25127 - Rewind 3x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause, three Rewind presses for 3x rewind scrub
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await ecp.sendKeypress(ecp.Key.Rewind);

    const rewindButton3x = await testUtils.getNodeForElement('rewindButton3x');
    expect(rewindButton3x.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-rew');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('3');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25128
  it('C25128 - Rewind 4x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await shared.ensurePlayableContentFocused();

    //Play title, pause; fourth Rewind wraps scrub speed back to 1x
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await testUtils.waitForElementToFullyShowOnScreen('videoPlayerSeekGroup');
    await ecp.sendKeypress(ecp.Key.Rewind);
    await ecp.sendKeypress(ecp.Key.Rewind);
    await ecp.sendKeypress(ecp.Key.Rewind);

    const rewindButton1x = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton1x.uri).to.contain('pkg:/images/transport/sgplayer/icon-vector-rew');
    expect(await testUtils.getElementField('videoPlayerSeekSpeedLabel', 'text')).to.equal('1');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/44200
  it('C44200 - Search - When User chooses a title from Search Page then playback should be initiated @playback_1,@registered_user,@smoke', async () => {
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await ecp.sendText('zapped');

    // Call function to navigate right to search results grid
    await shared.navigateRightToSearchGrid();

    // Initiate playback
    await ecp.sendKeypress(ecp.Key.Play);

    // Verify playback (focus lives on a child e.g. ProgressBar, not the screen root)
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
  });
});


//Functions for playback page
async function seekWithinRange(startposition) {

  // Find out if current postion and resume postion are within range

  await ecp.sendKeypress(ecp.Key.Ok, { count: 1 });
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
  const nextposition = await testUtils.getPlayerPosition();
  //console.log('next', nextposition);
  const difference = (nextposition - startposition);
  //console.log('diff', difference);
  const min = -20000;
  const max = 35000;
  expect(difference).greaterThanOrEqual(min);
  expect(difference).lessThanOrEqual(max);
}

async function verifyResumeWithinRangeWhenBackToScreen() {
  await ecp.sendKeypress(ecp.Key.Play);// PLay to create history
  await shared.createHistoryWithForward(); // Create history function
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
  const currentPosition = await testUtils.getPlayerPosition();
  await utils.sleep(2000);
  const videoPlayerScreenTopOverlay = await testUtils.getNodeForElement('videoPlayerScreenTopOverlay');
  if (videoPlayerScreenTopOverlay.opacity == 1) {
    await ecp.sendKeypress(ecp.Key.Back);
  }
  await ecp.sendKeypress(ecp.Key.Back);
  // Are we on the details page?
  await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

  // Back to previous screen
  await ecp.sendKeypress(ecp.Key.Back);

  // Back to title
  await ecp.sendKeypress(ecp.Key.Ok);
  await utils.sleep(2000);

  // Select Resume and check for playback
  await testUtils.selectAndVerifyDetailPageMenuItem('resume', 5000);
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

  // Find resume position
  const resumePosition = await testUtils.getPlayerPosition();
  const difference = (resumePosition - currentPosition);

  // Find out if current postion and resume postion are within range
  const min = -9000;
  const max = 9000;
  expect(difference).greaterThanOrEqual(min);
  expect(difference).lessThanOrEqual(max);

}

async function verifyResumeWithinRangeWhenBackToScreenEpisodes() {
  await ecp.sendKeypress(ecp.Key.Play);// PLay to create history
  await shared.createHistory(); // Create history function
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
  const currentposition = await testUtils.getPlayerPosition();
  console.log('current', currentposition);
  await ecp.sendKeypress(ecp.Key.Back);

  // Are we on Episodes page?
  await testUtils.waitForElementToFullyShowOnScreen('episodesList'); // selectAndVerifyDetailPageMenuItem needs to be updated
  await ecp.sendKeypress(ecp.Key.Back);

  // Are we on the details page?
  const detailScreenTitle = await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

  // Back to previous screen
  await ecp.sendKeypress(ecp.Key.Back);

  // Back to title

  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

  // Select Resume and check for playback
  await testUtils.selectAndVerifyDetailPageMenuItem('resume');
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

  // Find resume position
  const resumeposition = await testUtils.getPlayerPosition();
  console.log('resume', resumeposition);
  const difference = (resumeposition - currentposition);
  console.log('diff', difference);

  // Find out if current postion and resume postion are within range
  const min = -9000;
  const max = 9000;
  expect(difference).greaterThanOrEqual(min);
  expect(difference).lessThanOrEqual(max);

}

