import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { log } from 'console';
import { Utils } from 'handlebars';
import { ALL } from 'dns';

describe('Playback', function () {
  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537377  - https://tubi.testrail.io/index.php?/cases/view/537380

  it('C537377 537380 - Pause Playback @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(3000);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('pause');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/vie/537905
  it('C537905 - Forward Playback 30 seconds @playback_1,@guest_user', async () => {

    // Start at home page to select another title, different from previous test
    await testUtils.startApplicationAtPage('home');

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Press OK twice to activate player controls
    await utils.sleep(5000);
    await ecp.sendKeypress(ecp.Key.Play);

    //Get current player position
    const currentposition = await testUtils.getPlayerPosition();
    const startposition = currentposition;
    console.log('start', startposition);

    // Hover on the ff 30 second button, get start position
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);
    await seekWithinRange(startposition);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537378
  it('C537378 - Rewind Payback 30 seconds @playback_1,@guest_user', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(3000);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Press OK  to activate player controls
    await utils.sleep(5000);
    await ecp.sendKeypress(ecp.Key.Play);

    //Move forward in timeline and Get current player position
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Right);

    // See highlighted forward 30 button? press OK
    const forward30Button = await testUtils.getNodeForElement('forward30Button');
    expect(forward30Button.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Ok);

    //Get player position
    const currentposition = await testUtils.getPlayerPosition();
    const startposition = currentposition;
    //console.log('start', startposition);

    // Hover on the rewind 30 second button, get start position
    await ecp.sendKeypress(ecp.Key.Left);
    const rewind30Button = await testUtils.getNodeForElement('rewind30Button');
    expect(rewind30Button.visible).to.equal(true);
    await seekWithinRange(startposition);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535814
  it('C535814- Fast Forward 1x @playback_1,@registered_user,@smoke', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Right, { count: 2 });

    // FF button highlighted
    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);

    // Press FF button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify FF button state is FF 1
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-ffw');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535815
  it('C535815 - Fast Forward 2x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Right, { count: 2 });

    // FF button highlighted
    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);

    // Press FF button twice
    await ecp.sendKeypress(ecp.Key.Ok, { count: 2 });

    // Verify FF button state is FF 2
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-ffw');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537379
  it('C535816 - Fast Forward 3x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Right, { count: 2 });

    // FF button highlighted
    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);

    // Press FF button three times
    await ecp.sendKeypress(ecp.Key.Ok, { count: 3 });

    // Verify FF button state is FF 3
    expect(fastForwardButton.uri).to.equal('pkg:/images/transport/sgplayer/icon-ffw.webp');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535816
  it('C535816 - Fast Forward 4x @playback_1,@registered_user', async () => {

    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');
    await ecp.sendKeypress(ecp.Key.Right, { count: 2 });

    // FF button highlighted
    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);

    // Press FF button foiur times
    await ecp.sendKeypress(ecp.Key.Ok, { count: 4 });

    // Verify FF button state is FF 4 (back to 1x)
    expect(fastForwardButton.uri).to.equal('pkg:/images/transport/sgplayer/icon-ffw.webp');


  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/537688
  it('C537688 - Details Page Displays History Progress Bar @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    //await testUtils.expectPlayerStateToEventuallyEqual('pause');
    await ecp.sendKeypress(ecp.Key.Right, { count: 2 });

    // FF button highlighted
    const fastForwardButton = await testUtils.getNodeForElement('fastForwardButton');
    expect(fastForwardButton.visible).to.equal(true);

    // Press FF button three time
    await ecp.sendKeypress(ecp.Key.Ok, { count: 3 });

    // Verify FF button state is FF 3
    expect(fastForwardButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-ffw');

    // Back out of the video player to land on Details page after FF
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    await ecp.sendKeypress(ecp.Key.Back);


    // Are we on the details page?
    const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
    expect(detailScreenTitle.visible).to.equal(true);

    // Check that movie has history
    const resumePlayingButton = await testUtils.getNodeForElement('resumePlayingButton');
    expect(resumePlayingButton.visible).to.equal(true);


    // await testUtils.exitApplication();// exit application, temporary

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/535850

  it('C535850 - Resume from series details page play @playback_1,@registered_user,@regression', async () => {
    await testUtils.startApplicationAtPage('tv', { shouldCreateNewUser: true });

    // Are we on the series page?
    const tvScreenRowList = await testUtils.getNodeForElement('tvScreenRowList');
    expect(tvScreenRowList.visible).to.equal(true);

    // verify resume when user goes back to series screen and selects/plays title again
    await verifyResumeWithinRangeWhenBackToScreen();

    // Remove from History
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/536522
  it('536522 -  Resume from series details page episode play @playback_1,@registered_user,@regression', async () => {
    await testUtils.goToPage('tv');


    // Are we on the series page?
    await utils.sleep(2000); // Improvement
    const tvScreenRowList = await testUtils.getNodeForElement('tvScreenRowList');
    expect(tvScreenRowList.visible).to.be.true;

    // Enter Details page to get to Episodes list
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.selectAndVerifyDetailPageMenuItem('episodesList');
    const episodesScreen = await testUtils.getNodeForElement('episodesScreen');
    expect(episodesScreen.visible).to.equal(true);


    // verify resume when user goes back to series screen and selects/plays title again
    await verifyResumeWithinRangeWhenBackToScreen();

    // Remove from History
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25125
  it('C25125 - Rewind 1x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(2000);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await utils.sleep(4000);
    //  await testUtils.expectPlayerStateToEventuallyEqual('pause');
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Rewind button highlighted
    const rewindButton = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton.visible).to.equal(true);

    // Press Rewind button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Rewind button state is RW 1
    const rewindButton1x = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton1x.uri).to.contain('pkg:/images/transport/sgplayer/icon-rew-1');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25126
  it('C25126 - Rewind 2x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move leff to Rewind button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Rewind button highlighted
    const rewindButton = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton.visible).to.equal(true);

    // Press Rewind button twice
    await ecp.sendKeypress(ecp.Key.Ok, { count: 2 });

    // Verify Rewind button state is RW 2
    const rewindButton2x = await testUtils.getNodeForElement('rewindButton2x');
    expect(rewindButton2x.uri).to.contain('pkg:/images/transport/sgplayer/icon-rew-2');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25127
  it('C25127 - Rewind 3x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move right to FF button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Rewind button highlighted
    const rewindButton = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton.visible).to.equal(true);

    // Press Rewind button 3x
    await ecp.sendKeypress(ecp.Key.Ok, { count: 3 });

    // Verify Rewind button state is RW 3
    const rewindButton3x = await testUtils.getNodeForElement('rewindButton3x');
    expect(rewindButton3x.uri).to.contain('pkg:/images/transport/sgplayer/icon-rew-3');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/25128
  it('C25128 - Rewind 4x @playback_1,@registered_user', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    // Are we on the home page?
    const homeScreenRowList = await testUtils.getNodeForElement('homeScreenRowList');
    expect(homeScreenRowList.visible).to.equal(true);

    //Play title, pause to open player, move left to rewind button and press, verify state
    await ecp.sendKeypress(ecp.Key.Play);
    const videoPlayerActual = await testUtils.getNodeForElement('videoPlayerActual');
    expect(videoPlayerActual.visible).to.equal(true);
    await testUtils.expectPlayerStateToEventuallyEqual('play');
    await ecp.sendKeypress(ecp.Key.Play);
    const playPauseButton = await testUtils.getNodeForElement('playPauseButton');
    expect(playPauseButton.visible).to.equal(true);
    await utils.sleep(4000); // alternative to sleep here? I thought the next line would do it.
    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });

    // Rewind button highlighted
    const rewindButton = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton.visible).to.equal(true);

    // Press Rewind button 4x
    await ecp.sendKeypress(ecp.Key.Ok, { count: 4 });

    // Verify Rewind button state is RW 1 again
    const rewindButton1x = await testUtils.getNodeForElement('rewindButton');
    expect(rewindButton1x.uri).to.contain('pkg:/images/transport/sgplayer/icon-rew-1');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/44200
  it('C44200 - Search - When User chooses a title from Search Page then playback should be initiated @playback_1,@registered_user,@smoke', async () => {
    await testUtils.startApplicationAtPage('search', { shouldCreateNewUser: true });
    await ecp.sendText('zapped');

    // Call function to navigate right to search results grid
    await shared.navigateRightToGrid();

    // Initiate playback
    await ecp.sendKeypress(ecp.Key.Play);

    // Verify playback
    await testUtils.waitForElementToHaveFocus('videoPlayerScreen');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
  });
});


//Functions for playback page
async function seekWithinRange(startposition) {

  // Find out if current postion and resume postion are within range

  await ecp.sendKeypress(ecp.Key.Ok, { count: 1 });
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
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
  const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
  await shared.createHistory(); // Create history function
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
  const currentposition = await testUtils.getPlayerPosition();

  console.log('current', currentposition);
  expect(videoPlayerScreen.visible).to.equal(true);

  await ecp.sendKeypress(ecp.Key.Back);
  // Are we on the details page?
  const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
  expect(detailScreenTitle.visible).to.equal(true);
  // Back to previous screen
  await ecp.sendKeypress(ecp.Key.Back);
  // Back to title
  await ecp.sendKeypress(ecp.Key.Ok);
  await utils.sleep(2000);



  // Select Resume and check for playback
  await testUtils.selectAndVerifyDetailPageMenuItem('resume');
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);

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

async function verifyResumeWithinRangeWhenBackToScreenEpisodes() {
  await ecp.sendKeypress(ecp.Key.Play);// PLay to create history
  const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
  await shared.createHistory(); // Create history function
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);
  const currentposition = await testUtils.getPlayerPosition();

  console.log('current', currentposition);
  expect(videoPlayerScreen.visible).to.equal(true);
  await ecp.sendKeypress(ecp.Key.Back);

  // Are we on Episodes page?
  await testUtils.selectAndVerifyDetailPageMenuItem('episodesList'); // selectAndVerifyDetailPageMenuItem needs to be updated
  await ecp.sendKeypress(ecp.Key.Back);

  // Are we on the details page?
  const detailScreenTitle = await testUtils.getNodeForElement('detailScreenTitle');
  expect(detailScreenTitle.visible).to.equal(true);

  // Back to previous screen
  await ecp.sendKeypress(ecp.Key.Back);

  // Back to title
  await ecp.sendKeypress(ecp.Key.Ok);

  // Select Resume and check for playback
  await testUtils.selectAndVerifyDetailPageMenuItem('resume');
  await testUtils.expectPlayerStateToEventuallyEqual('play', 15000);

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
