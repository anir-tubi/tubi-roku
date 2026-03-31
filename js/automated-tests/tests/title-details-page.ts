import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';
import { elements } from '../../../automated-tests-config/elements';

// Skipping these tests for now as it is still a experimental feature.
// Will be used for manual testing during development and qa phase.
describe('Title Details Page', function () {
  // Helper function to start application with content details experiment overrides
  async function startApplicationWithExperimentOverrides(page: string, args: any = {}) {
    return await testUtils.startApplicationAtPage(page as any, {
      ...args,
      experimentOverrides: {
        roku_content_details: {
          roku_content_details_v5: {
            default: { "enabled": true }
          }
        }
      }
    });
  }

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845203
  it('C845203 - Full Screen Video hero in the detail page as background @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies');

    await utils.sleep(3000);

    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreen', 'Detail screen not visible', 10000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    const playerState = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(playerState).to.equal('playing', 'Full screen video hero should be playing in the detail page background');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845244
  it('C845244 - Default Focus on horizontal button is Resume when movie has history @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testHelpers.createHistory();

    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await utils.sleep(2500);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('resume');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845215
  it('C845215 - Left arrow opens navigation bar @sidenav', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Left);

    await testUtils.waitForSideNavMenuToBeExpanded();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845251
  it('C845251 - Episodes is the first tab for series @guest,@series_details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenSectionTabs', 'Menu not shown', 10000);

    const sectionTabs = await testUtils.getNodeForElement('vodDetailScreenSectionTabs');
    expect(sectionTabs.buttons[0].id).to.equal('episodes', 'Episodes button not found');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845245
  it('C845245 - Default Focus on horizontal button is Play when title has no history @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('play');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845248
  it('C845248 - Add to My List changes to Remove from my List when selected in details page @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'addToQueue');
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(1000);
    // Verify that "Add to My List" button changed to "Remove From My List" by navigating to it
    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'removeFromQueue');
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('removeFromQueue');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845243
  it('C845243 - Details page displays static image when user plays the content from details page and returns back to details page @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Find content that has a video preview
    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('movieScreenRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview');
    }
    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('movieScreenRowList', row, col);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await utils.sleep(2000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'stopped', 15000);

    // Verify either backgroundPoster or backgroundPoster2 has opacity 1 (static image is shown)
    await testUtils.untilTrue(async () => {
      const backgroundPoster = await testUtils.getNodeForElement('backgroundPoster');
      const backgroundPoster2 = await testUtils.getNodeForElement('backgroundPoster2');
      return backgroundPoster.opacity === 1 || backgroundPoster2.opacity === 1;
    }, 'Either backgroundPoster or backgroundPoster2 should have opacity 1', 20000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845240
  it('C845240 - Video preview pauses when user scrolls through episodes, Details @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus');

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('tvScreenRowList', true, 5);
    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('tvScreenRowList', row, col);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown', 10000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown after scrolling', 10000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', ['paused'], 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845241
  it('C845241 - Video preview resumes when user goes back to main detail page from episodes or Details @guest,@series_details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus');
    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('tvScreenRowList', true, 5);
    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('tvScreenRowList', row, col);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown', 10000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown after scrolling', 10000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'paused', 10000);
    await testHelpers.jumpToButtonById('vodDetailScreenSectionTabs', 'details');

    await ecp.sendKeypress(ecp.Key.Up);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845242
  it('C845242 - Static image is displayed if video preview is not available in the detail page @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('movieScreenRowList', false, 5);
    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('movieScreenRowList', row, col);

    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreen', 'Detail screen not visible', 10000);

    // Verify preview player is not playing, buffering, or paused
    await testUtils.untilTrue(async () => {
      const playerState = await testUtils.getElementField('previewVideoPlayer', 'state');
      return playerState !== 'playing' && playerState !== 'buffering' && playerState !== 'paused';
    }, 'Preview player should not be playing, buffering, or paused', 10000);

    // Verify either backgroundPoster or backgroundPoster2 has opacity 1 (static image is shown)
    await testUtils.untilTrue(async () => {
      const backgroundPoster = await testUtils.getNodeForElement('backgroundPoster');
      const backgroundPoster2 = await testUtils.getNodeForElement('backgroundPoster2');
      return backgroundPoster.opacity === 1 || backgroundPoster2.opacity === 1;
    }, 'Either backgroundPoster or backgroundPoster2 should have opacity 1', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845238
  it('C845238 - Fullscreen video in details page autoplays if title is not played @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Find content that has a video preview
    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('movieScreenRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview');
    }
    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('movieScreenRowList', row, col);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Seek to near end of preview to trigger autoplay
    await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -1000, 'end');

    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 60000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.equal('playing', 'Fullscreen video should autoplay after preview ends');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845239
  it('C845239 - Video Preview resumes from homepage to detail page @videopreview', async () => {
    await startApplicationWithExperimentOverrides('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview');
    }
    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('videoTitlesRowList', row, col);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);
    await utils.sleep(2000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845216
  it('C845216 - Episodes are displayed below Seasons and user can navigate across seasons and episodes @guest,@series_details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenSeasonList', 'Season list not shown', 10000);
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenEpisodesList', 'Episodes list not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenEpisodesList', 'Episodes list not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);

    const itemIndex = await testUtils.getCurrentlyFocusedGridItemIndex('vodDetailScreenEpisodesList');
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);

    const itemIndex2 = await testUtils.getCurrentlyFocusedGridItemIndex('vodDetailScreenEpisodesList');
    expect(itemIndex2).to.be.not.equal(itemIndex);

    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(500);

    const itemIndex3 = await testUtils.getCurrentlyFocusedGridItemIndex('vodDetailScreenEpisodesList');
    expect(itemIndex3).to.be.not.equal(itemIndex2);
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845206
  it('C845206 - Order for horizontal menu bar in details page of title that is from a network @guest,@details_page', async () => {
    await startApplicationWithExperimentOverrides('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testHelpers.navigateToCategories();
    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Down to Networks button
    await ecp.sendKeypress(ecp.Key.Down, { wait: 200 });
    await testUtils.waitForElementToShowOnScreen('categoryPosterFirst');
    await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');
    // Are we on the Video Grid and are the category titles available?
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 200 });

    // Verify Channel Video Grid
    await testUtils.waitForElementToShowOnScreen('channelsDetailsGrid');
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menu.buttons.map(button => button.id);

    // Verify button order for network-associated title
    // Expected order: Play → Sign up → Trailer → Add to list → Like → Dislike → Go to Network
    expect(buttonIds[0]).to.equal('play', 'First button should be Play');

    // Check for Sign up or Resume (depending on whether user has history)
    const hasSignUp = buttonIds.includes('signIn');
    const hasResume = buttonIds.includes('resume');
    expect(hasSignUp || hasResume, 'Should have Sign up or Resume button').to.equal(true);

    const content = await testUtils.getElementField('vodDetailScreen', 'content');

    if (content.hasTrailer) {
      // Check for Trailer (may or may not be present depending on content)
      const trailerIndex = buttonIds.findIndex(id => id === 'watchTrailer');
      expect(trailerIndex).to.be.greaterThan(0, 'Should have Trailer button');
    }

    // Verify Add to list / Remove from list
    const hasAddToList = buttonIds.includes('addToQueue');
    const hasRemoveFromList = buttonIds.includes('removeFromQueue');
    expect(hasAddToList || hasRemoveFromList, 'Should have Add to list or Remove from list button').to.equal(true);

    // Verify Like button
    expect(buttonIds).to.include('like', 'Should have Like button');

    // Verify Dislike button
    expect(buttonIds).to.include('dislike', 'Should have Dislike button');

    // Verify Go to Network button (specific to network-associated titles)
    expect(buttonIds).to.include('gotoChannel', 'Should have Go to Network button for network-associated content');

    // Verify button order sequence
    const playIndex = buttonIds.indexOf('play');
    const likeIndex = buttonIds.indexOf('like');
    const dislikeIndex = buttonIds.indexOf('dislike');
    const networkIndex = buttonIds.indexOf('gotoChannel');

    expect(playIndex).to.equal(0, 'Play should be first');
    expect(likeIndex).to.be.greaterThan(playIndex, 'Like should come after Play');
    expect(dislikeIndex).to.be.greaterThan(likeIndex, 'Dislike should come after Like');
    expect(networkIndex).to.be.greaterThan(dislikeIndex, 'Go to Channel should come after Dislike');
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845207
  it('C845207 - Registered user: Order for horizontal menu bar in details page of series @guest,@sdp_1', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: false });
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);
    const content = await testUtils.getElementField('vodDetailScreen', 'content');

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menu.buttons.map(button => button.id);

    expect(buttonIds.length).to.be.greaterThan(0);


    expect(buttonIds[0]).to.equal('play');
    expect(buttonIds).to.include('signIn');
    if (content.hasTrailer) {
      expect(buttonIds).to.include('watchTrailer');
    }
    expect(buttonIds).to.include('addToQueue');
    expect(buttonIds).to.include('like');
    expect(buttonIds).to.include('dislike');
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845246
  it('C845246 - Default Focus on horizontal button is Play S6 E2 when series has history @guest,@sdp_1', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);
    await utils.sleep(1000);
    let menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const playButton = menu.buttons[0];
    expect(playButton.title).to.match(/Play S\d+ E\d+/);

    await ecp.sendKeypress(ecp.Key.Play);
    await testHelpers.createHistory();

    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);
    await utils.sleep(1000);
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('resume');
    menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const resumeButton = menu.buttons[0];
    expect(resumeButton.title).to.match(/Resume S\d+ E\d+/);
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845254
  it('C845254 - First episode will be displayed as default for Series that was never watched @guest,@sdp_1', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenEpisodesList', 'Episodes list not shown', 10000);

    // Get the first episode from the episodes list
    const firstEpisode = await testUtils.getGridItemContent('vodDetailScreenEpisodesList', 0);
    expect(firstEpisode.title).to.match(/S\d+:E\d+/, 'Episode title should contain season and episode');

    // Extract the season and episode numbers (e.g., "S01:E01" from "S01:E01 - Pilot")
    const seasonEpisodeMatch = firstEpisode.title.match(/S(\d+):E(\d+)/);
    expect(seasonEpisodeMatch).to.exist;

    // Remove leading zeroes (e.g., "S01:E01" becomes "S1 E1" for the button)
    const seasonNumber = parseInt(seasonEpisodeMatch[1], 10); // Convert "01" to 1
    const episodeNumber = parseInt(seasonEpisodeMatch[2], 10); // Convert "01" to 1
    const seasonEpisodeWithoutZeroes = `S${seasonNumber} E${episodeNumber}`; // e.g., "S1 E1"

    // Get the Play button from the menu
    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const playButton = menu.buttons.find(button => button.id === 'play');
    expect(playButton).to.exist;

    // Verify the Play button has the format "Play S1 E1" (without leading zeroes and with space)
    const expectedPlayButtonText = `Play ${seasonEpisodeWithoutZeroes}`;
    expect(playButton.title).to.equal(expectedPlayButtonText, `Play button should say "${expectedPlayButtonText}" for the first episode`);

  });


  // Test Rail Link: Manual test - All interactive buttons work correctly
  it('C876709 - Test all detail page buttons: Like, Dislike, and Delete History @guest,@details_page,@buttons', async () => {
    // Start application and navigate to movies page
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Open movie detail page
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    // Wait for menu to stabilize (avoid race condition with app state updates)
    await utils.sleep(1000);

    // Get initial menu state
    const initialMenu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const initialButtonIds = initialMenu.buttons.map(button => button.id);


    // ========================================
    // TEST 5: Create History and Test Delete History Button
    // ========================================

    // Start playback to create history
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 10000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Create history by seeking forward (2 minutes of watch time)
    await testHelpers.createHistory();

    // Go back to detail page
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);
    await utils.sleep(2500);

    // Verify Resume button is now available (indicates history was created)
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown after return', 10000);

    // Get menu to check if resume button exists
    const menuWithHistory = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menuWithHistory.buttons.map(button => button.id);
    expect(buttonIds).to.include('resume', 'Resume button should be present after creating history');

    // ========================================
    // TEST 6: Delete History
    // ========================================
    expect(buttonIds).to.include('removeFromHistory', 'Remove from History button should be present after creating history');

    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'removeFromHistory');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    // Wait for history to be removed and menu to update
    await utils.sleep(2000);

    // Verify that Resume button is no longer present (replaced with Play)
    const menuAfterDelete = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIdsAfterDelete = menuAfterDelete.buttons.map(button => button.id);

    // Should have Play button, not Resume
    expect(buttonIdsAfterDelete).to.include('play', 'Play button should be present after deleting history');
    expect(buttonIdsAfterDelete).to.not.include('resume', 'Resume button should not be present after deleting history');

    // Verify focused button is Play (default when no history)
    // TODO: Re-visit this requirement as the default focus is not clear in the spec
    // const { node } = await odc.getFocusedNode();
    // expect(node.id).to.equal('play', 'Play button should be focused after deleting history');

    // ========================================
    // TEST 1: Like Button Functionality
    // ========================================

    // Navigate to Like button
    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'like');
    await utils.sleep(500);

    // Click Like button - it should change to "Liked" state
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify the Like button changed its state to Liked
    const menuAfterLike = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const likeButton = menuAfterLike.buttons.find(button => button.id === 'like');
    expect(likeButton).to.exist;
    expect(likeButton.title).to.include('Liked', 'Like button should show "Liked" text after clicking');

    // ========================================
    // TEST 2: Change Like to Neutral
    // ========================================

    // Click the Like button again to toggle back to neutral
    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'like');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify button is back to Like (neutral state)
    const menuAfterUnlike = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const likeButtonNeutral = menuAfterUnlike.buttons.find(button => button.id === 'like');
    expect(likeButtonNeutral).to.exist;
    expect(likeButtonNeutral.title).to.equal('Like', 'Like button should show "Like" text after toggling off');

    // ========================================
    // TEST 3: Dislike Button Functionality
    // ========================================

    // Navigate to Dislike button
    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'dislike');
    await utils.sleep(500);

    // Click Dislike button - it should change to "Disliked" state
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify the Dislike button changed its state to Disliked
    const menuAfterDislike = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const dislikeButton = menuAfterDislike.buttons.find(button => button.id === 'dislike');
    expect(dislikeButton).to.exist;
    expect(dislikeButton.title).to.include('Disliked', 'Dislike button should show "Disliked" text after clicking');

    // ========================================
    // TEST 4: Change Dislike to Neutral
    // ========================================

    // Click the Dislike button again to toggle back to neutral
    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'dislike');
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify button is back to Dislike (neutral state)
    const menuAfterUndislike = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const dislikeButtonNeutral = menuAfterUndislike.buttons.find(button => button.id === 'dislike');
    expect(dislikeButtonNeutral).to.exist;
    expect(dislikeButtonNeutral.title).to.equal('Dislike', 'Dislike button should show "Dislike" text after toggling off');


  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845247
  it('C845247 - CTA buttons labels appear only when hovered over @guest @details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    // Check unfocused label is empty/hidden before focusing on "Add to My List" button
    const labelUnfocusedBefore = await testUtils.getNodeForElement('addToMyListButtonLabelUnfocused');
    expect(labelUnfocusedBefore.text).to.equal('', 'Unfocused label should be empty before focus');

    // Check focused label is hidden before focusing
    const labelFocusedBefore = await testUtils.getNodeForElement('addToMyListButtonLabelFocused');
    expect(labelFocusedBefore.opacity).to.equal(0, 'Focused label should have opacity 0 before focus');

    // Move focus to "Add to My List" button
    await testHelpers.jumpToButtonById('vodDetailScreenActionButtons', 'addToQueue');
    await utils.sleep(500);

    // Verify button is focused
    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('addToQueue', 'Add to My List button should be focused');

    // Check focused label is visible with text after focusing
    const labelFocusedAfter = await testUtils.getNodeForElement('addToMyListButtonLabelFocused');
    expect(labelFocusedAfter.opacity).to.be.greaterThan(0, 'Focused label should have opacity greater than 0 after focus');
    expect(labelFocusedAfter.text).to.equal('Add to My List', 'Label text should be "Add to My List"');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845212
  it('C845212 - Title and metadata below each tile is displayed @guest @browse', async () => {
    // Open a series detail page
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: false });
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    // Navigate down to YMAL (More Like This) section
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown', 10000);

    // Jump to "More Like This" tab
    await testHelpers.jumpToButtonById('vodDetailScreenSectionTabs', 'moreLikeThis');
    await utils.sleep(500);

    // Press down to focus on the YMAL grid first item
    await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
    await utils.sleep(1000);

    // Validate first item has title and description metadata displayed
    const firstTitleNode = await testUtils.getNodeForElement('vodDetailScreenYmalTileTitle');
    const firstTitleText = firstTitleNode.text;
    expect(firstTitleText).to.exist;
    expect(firstTitleText).to.not.equal('', 'First item should have a title');

    const firstDescriptionNode = await testUtils.getNodeForElement('vodDetailScreenYmalTileDescription');
    const firstDescriptionText = firstDescriptionNode.text;
    expect(firstDescriptionText).to.exist;
    expect(firstDescriptionText).to.not.equal('', 'First item should have a description');

    // Move right to second item and validate metadata changes
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);

    const secondTitleNode = await testUtils.getNodeForElement('vodDetailScreenYmalTileTitle');
    const secondTitleText = secondTitleNode.text;
    expect(secondTitleText).to.exist;
    expect(secondTitleText).to.not.equal('', 'Second item should have a title');
    expect(secondTitleText).to.not.equal(firstTitleText, 'Second item title should be different from first item');

    const secondDescriptionNode = await testUtils.getNodeForElement('vodDetailScreenYmalTileDescription');
    const secondDescriptionText = secondDescriptionNode.text;
    expect(secondDescriptionText).to.exist;
    expect(secondDescriptionText).to.not.equal('', 'Second item should have a description');
    expect(secondDescriptionText).to.not.equal(firstDescriptionText, 'Second item description should be different from first item');

    // Move right to third item and validate metadata changes
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);

    const thirdTitleNode = await testUtils.getNodeForElement('vodDetailScreenYmalTileTitle');
    const thirdTitleText = thirdTitleNode.text;
    expect(thirdTitleText).to.exist;
    expect(thirdTitleText).to.not.equal('', 'Third item should have a title');
    expect(thirdTitleText).to.not.equal(secondTitleText, 'Third item title should be different from second item');

    const thirdDescriptionNode = await testUtils.getNodeForElement('vodDetailScreenYmalTileDescription');
    const thirdDescriptionText = thirdDescriptionNode.text;
    expect(thirdDescriptionText).to.exist;
    expect(thirdDescriptionText).to.not.equal('', 'Third item should have a description');
    expect(thirdDescriptionText).to.not.equal(secondDescriptionText, 'Third item description should be different from second item');
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845204
  it('C845204 - Title art is displayed in the details page for Series, if available @guest @series_details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await utils.sleep(3000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 20000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const titleLabel = await testUtils.getNodeForElement('vodDetailScreenTitle');
    expect(titleLabel.visible).to.equal(true, 'Title label should be visible in the details page for series');
    expect(titleLabel.text).to.exist;
    expect(titleLabel.text).to.not.equal('', 'Title text should not be empty');
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845205
  it('C845205 - Title art is displayed in the details page for Movies, if available @guest @details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await utils.sleep(3000);
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenTitle', 'Title label not visible', 10000);

    const titleLabel = await testUtils.getNodeForElement('vodDetailScreenTitle');
    expect(titleLabel.visible).to.equal(true, 'Title label should be visible in the details page for movies');
    expect(titleLabel.text).to.exist;
    expect(titleLabel.text).to.not.equal('', 'Title text should not be empty');
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845208
  it('C845208 - Registered user: Order for horizontal menu bar in details page of movies @guest @details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 30000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 20000);

    await utils.sleep(2000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 15000);

    await testUtils.retryWithTimeOut(async () => {
      const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
      expect(menu.buttons.length).to.be.greaterThan(0);
    }, 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menu.buttons.map(button => button.id);

    expect(buttonIds.length).to.be.greaterThan(0);

    expect(buttonIds[0]).to.equal('play');

    const content = await testUtils.getElementField('vodDetailScreen', 'content');
    if (content.hasTrailer) {
      expect(buttonIds).to.include('watchTrailer');
    }

    expect(buttonIds).to.include('addToQueue');
    expect(buttonIds).to.include('like');
    expect(buttonIds).to.include('dislike');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845209
  it('C845209 - Registered user: Order for horizontal menu bar in details page of movies with history @guest @details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testHelpers.createHistory();

    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 20000);

    await utils.sleep(2500);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 15000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menu.buttons.map(button => button.id);

    expect(buttonIds.length).to.be.greaterThan(0);

    expect(buttonIds[0]).to.equal('resume');

    const content = await testUtils.getElementField('vodDetailScreen', 'content');
    if (content.hasTrailer) {
      expect(buttonIds).to.include('watchTrailer');
    }

    expect(buttonIds).to.include('addToQueue');
    expect(buttonIds).to.include('like');
    expect(buttonIds).to.include('dislike');
    expect(buttonIds).to.include('removeFromHistory');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845210
  it('C845210 - Registered user: Order for horizontal menu bar in details page of series with history', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for series screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testHelpers.createHistory();

    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 20000);

    await utils.sleep(2500);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menu.buttons.map(button => button.id);

    expect(buttonIds.length).to.be.greaterThan(0);

    expect(buttonIds[0]).to.equal('resume');
    expect(buttonIds).to.include('addToQueue');
    expect(buttonIds).to.include('like');
    expect(buttonIds).to.include('dislike');
    expect(buttonIds).to.include('removeFromHistory');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845250
  it('C845250 - Typed out art displays and becomes smaller and shifts to top of the page when user navigates to Episodes/Details @guest @series_details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    // Find a series without title art to test typed text
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');
    let itemIndexWithoutTitleImage = -1;

    for (const [index, item] of rowItemsContent.entries()) {
      if (!item.images || !item.images.title_art || (Array.isArray(item.images.title_art) && item.images.title_art.length === 0)) {
        itemIndexWithoutTitleImage = index;
        break;
      }
    }

    expect(itemIndexWithoutTitleImage).to.be.greaterThan(-1, 'Should find at least one series without titleImageUrl');

    // Navigate to the item without titleImageUrl
    const currentIndex = await testUtils.getCurrentlyFocusedGridItemIndex('tvScreenRowList');
    const rowIndex = currentIndex[0];
    await testUtils.jumpToRowItem('tvScreenRowList', [rowIndex, itemIndexWithoutTitleImage]);
    await utils.sleep(500);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    // Measure the initial title size (large, above the fold) from videoMetadataPanel
    const initialTitlePath = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#vodDetailScreen.#contentGroup.#contentContainer.#videoMetadataPanel.#metadataGroup.#infoPanel.#metadataGroup.#title';
    const initialTitleResult = await odc.getValue({
      keyPath: initialTitlePath + '.boundingRect()'
    });
    const initialHeight = initialTitleResult.value.height;

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Measure the title after scrolling (should be smaller) using contentTitleLabel
    await testUtils.waitForElementToShowOnScreen('contentTitleLabel', 'Content title label not visible after navigation', 10000);
    const updatedTitleResult = await odc.getValue({
      keyPath: elements.contentTitleLabel.keyPath + '.boundingRect()'
    });
    const updatedHeight = updatedTitleResult.value.height;

    // Verify typed text title becomes smaller after navigating to Episodes/Details
    expect(updatedHeight).to.be.lessThan(initialHeight, 'Typed title should be smaller after navigating to Episodes/Details');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845214
  it('C845214 - Guest user: Order for horizontal menu bar in details page of movies @guest @details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: false });
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonIds = menu.buttons.map(button => button.id);

    expect(buttonIds.length).to.be.greaterThan(0);

    expect(buttonIds[0]).to.equal('play');
    expect(buttonIds).to.include('signIn');

    const content = await testUtils.getElementField('vodDetailScreen', 'content');
    if (content.hasTrailer) {
      expect(buttonIds).to.include('watchTrailer');
    }

    expect(buttonIds).to.include('addToQueue');
    expect(buttonIds).to.include('like');
    expect(buttonIds).to.include('dislike');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845252
  it('C845252 - Autoplay should comply with settings @autoplay', async () => {
    await startApplicationWithExperimentOverrides('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testHelpers.enableAutoplayInSettings(false);
    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');

    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Rowlist to have focus', 15000);
    await testHelpers.verifyAutoplayUINotShowing('autoplayCountdownTimerSection', true);

    await testHelpers.enableAutoplayInSettings(true);
    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Right, { count: 2 });

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    await utils.sleep(1000);
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');

    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Rowlist to have focus', 15000);

    await testHelpers.verifyAutoplayUIShowing('countDownAutoPlay', 'countDownSecondsAutoPlay', true);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845249
  it('C845249 - Title art becomes smaller and shifts to top of the page when user navigates to Episodes/Details @guest @series_details_page', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 15000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenTitle', 'Title label not visible', 10000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenSectionTabs', 'Section tabs not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    await testUtils.waitForElementToShowOnScreen('contentTitleLabel', 'Content title label not visible after navigation', 10000);

    // Get initial boundingRect by calling boundingRect() function
    const initialBoundingRectResult = await odc.getValue({
      keyPath: elements.vodDetailScreenTitle.keyPath + '.boundingRect()'
    });
    const widthBefore = initialBoundingRectResult.value.width;
    const heightBefore = initialBoundingRectResult.value.height;

    // Get updated boundingRect from contentTitleLabel (shown when scrolled down)
    const updatedBoundingRectResult = await odc.getValue({
      keyPath: elements.contentTitleLabel.keyPath + '.boundingRect()'
    });
    const widthAfter = updatedBoundingRectResult.value.width;
    const heightAfter = updatedBoundingRectResult.value.height;

    expect(widthAfter).to.be.lessThan(widthBefore, 'Title art width should be smaller after navigating to Episodes/Details');
    expect(heightAfter).to.be.lessThan(heightBefore, 'Title art height should be smaller after navigating to Episodes/Details');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845213
  it('C845213 - Guest user: Order for horizontal menu bar in details page of series @guest', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: false });
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 20000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 20000);

    await utils.sleep(2000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 15000);

    await testUtils.retryWithTimeOut(async () => {
      const menuButtons = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
      expect(menuButtons.buttons.length).to.be.greaterThan(0);
    }, 10000);

    const menuButtons = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const buttonOrder = menuButtons.buttons.map(button => button.id);

    expect(buttonOrder.length).to.be.greaterThan(0);
    expect(buttonOrder[0]).to.equal('play');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845211
  it('C845211 - secondary CTAs are simplified to icons unless hovered over in detail page @guest @details_page', async () => {
    await startApplicationWithExperimentOverrides('movies', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);

    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const likeButton = menu.buttons.find(button => button.id === 'like');
    const dislikeButton = menu.buttons.find(button => button.id === 'dislike');

    expect(likeButton).to.exist;
    expect(dislikeButton).to.exist;

    // Check that label groups have no width when not focused (simplified to icons only)
    const likeLabelBeforeFocusResult = await odc.getValue({
      keyPath: elements.likeButtonLabelGroup.keyPath + '.boundingRect()'
    });
    const likeLabelWidthBeforeFocus = likeLabelBeforeFocusResult.value.width;
    expect(likeLabelWidthBeforeFocus).to.be.lessThan(5, 'Like button label should be simplified (no text) when not focused');

    const dislikeLabelBeforeFocusResult = await odc.getValue({
      keyPath: elements.dislikeButtonLabelGroup.keyPath + '.boundingRect()'
    });
    const dislikeLabelWidthBeforeFocus = dislikeLabelBeforeFocusResult.value.width;
    expect(dislikeLabelWidthBeforeFocus).to.be.lessThan(5, 'Dislike button label should be simplified (no text) when not focused');

    await odc.setValue(testUtils.getElementKeyPath('vodDetailScreenActionButtons', {
      field: 'jumpToIndex',
      value: menu.buttons.findIndex(button => button.id === 'like')
    }), { timeout: 10000 });

    await utils.sleep(500);

    const { node: focusedNode } = await odc.getFocusedNode();
    expect(focusedNode.id).to.equal('like', 'Like button should be focused');

    // Check that label group has width when focused (shows text label)
    const likeLabelAfterFocusResult = await odc.getValue({
      keyPath: elements.likeButtonLabelGroup.keyPath + '.boundingRect()'
    });
    const likeLabelWidthAfterFocus = likeLabelAfterFocusResult.value.width;
    expect(likeLabelWidthAfterFocus).to.be.greaterThan(10, 'Like button label should be visible (has text) when focused');

    await odc.setValue(testUtils.getElementKeyPath('vodDetailScreenActionButtons', {
      field: 'jumpToIndex',
      value: menu.buttons.findIndex(button => button.id === 'dislike')
    }), { timeout: 10000 });

    await utils.sleep(500);

    const { node: focusedNodeDislike } = await odc.getFocusedNode();
    expect(focusedNodeDislike.id).to.equal('dislike', 'Dislike button should be focused');

    // Check that dislike label group has width when focused (shows text label)
    const dislikeLabelAfterFocusResult = await odc.getValue({
      keyPath: elements.dislikeButtonLabelGroup.keyPath + '.boundingRect()'
    });
    const dislikeLabelWidthAfterFocus = dislikeLabelAfterFocusResult.value.width;
    expect(dislikeLabelWidthAfterFocus).to.be.greaterThan(10, 'Dislike button label should be visible (has text) when focused');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845253
  it('C845253 - Deeplinking to a title should display the new details page design @guest @details_page @deeplink', async () => {
    const user = await testUtils.createRegisteredUser();
    await testUtils.startApplicationWithDeeplink({
      mediaType: 'movie',
      contentID: '342067'
    }, {
      user, experimentOverrides: {
        roku_content_details: {
          roku_content_details_v5: {
            default: { "enabled": true }
          }
        }
      }
    });

    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 10000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 10000);
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Horizontal menu not shown', 10000);

    await testUtils.waitForElementToShowOnScreen('vodDetailScreenDescription', 'Description not visible', 10000);

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    expect(menu.buttons.length).to.be.greaterThan(0, 'Horizontal action button menu should have buttons');
    expect(menu.buttons[0].id).to.equal('play', 'First button should be Play in the new design');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/845255
  it('C845255 - Current episode will be displayed as default under Episodes for Series if already started watching @guest,@sdp_1', async () => {
    await startApplicationWithExperimentOverrides('tv', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen rowlist to have focus', 20000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);

    await testUtils.waitForElementToFullyShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testHelpers.createHistory();

    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('vodDetailScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenActionButtons', 'Menu not shown', 10000);
    await testUtils.waitForElementToShowOnScreen('vodDetailScreenEpisodesList', 'Episodes list not shown', 10000);
    await utils.sleep(1000);

    const { node } = await odc.getFocusedNode();
    expect(node.id).to.equal('resume');

    const menu = await testUtils.getNodeForElement('vodDetailScreenActionButtons');
    const resumeButton = menu.buttons.find(button => button.id === 'resume');
    expect(resumeButton).to.exist;

    const resumeMatch = resumeButton.title.match(/Resume S(\d+) E(\d+)/);
    expect(resumeMatch).to.exist;

    const seasonNumber = parseInt(resumeMatch[1], 10);
    const episodeNumber = parseInt(resumeMatch[2], 10);
    const currentEpisodePattern = `S${seasonNumber.toString().padStart(2, '0')}:E${episodeNumber.toString().padStart(2, '0')}`;

    const firstEpisode = await testUtils.getGridItemContent('vodDetailScreenEpisodesList', 0);
    expect(firstEpisode.title).to.contain(currentEpisodePattern, `First episode in list should be ${currentEpisodePattern} (the current episode with history)`);
  });

});
