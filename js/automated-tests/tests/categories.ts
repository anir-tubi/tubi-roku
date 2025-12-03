import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import type { RegisteredUser } from '../test-utils';
import { testUtils } from '../test-utils';
import { ok } from 'assert';
import { shared, testHelpers } from '../test-helpers';
import { moveToGrid } from '../analytics/utils/helpers';


describe('Categories', function () {
  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48644 ,  https://tubi.testrail.io/index.php?/cases/view/637122 , https://tubi.testrail.io/index.php?/cases/view/638442
  it('C48644 and C637123 - Continue Watching Row - when user plays a title and navigates back to Home screen then Continue Watching row should be displayed, @categories', async () => {

    // Create user with history only
    const user = await testUtils.createRegisteredUser();
    await createHistory(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus(
      'homeScreenRowList',
      'Timed out waiting for Rowlist to have focus'
    );

    // Navigate to find Continue Watching category
    await testHelpers.navigateToCategories();
    await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingButton');
    const continueWatchingButtonText = testUtils.getNodeForElement('continueWatchingButton');
    expect((await continueWatchingButtonText).text).to.equal('Continue Watching');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48646
  it('C48646 - Continue Watching - Category removed after choosing Remove From history in the details page, @categories', async () => {
    // Create user with history only
    const user = await testUtils.createRegisteredUser();
    await createHistory(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus(
      'homeScreenRowList',
      'Timed out waiting for Rowlist to have focus'
    );

    // Go to All Categories page
    await testHelpers.navigateToCategories();

    // Navigate to Continue Watching category
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton', 'button not found');
    await ecp.sendKeypress(ecp.Key.Down);

    // Press OK to reach Details of title
    await testUtils.waitForElementToFullyShowOnScreen('categoryPageTitle');
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingCategoryPoster');
    await ecp.sendKeypress(ecp.Key.Right, { wait: 2000 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Remove from History
    await testUtils.waitForElementToShowOnScreen('resumeButton');
    //await ecp.sendKeypress(ecp.Key.Down, {count:5});
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

    // Go to All Categories page
    await ecp.sendKeypress(ecp.Key.Back, { count: 4, wait: 2000 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Continue Watching category does not exist
    await testUtils.waitForElementToNotShowOnScreen('continueWatchingButton');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/48647
  it('C48647 - Continue Watching - When user removes title from history and navigates back to Home screen then Continue Watching row should be removed, @categories', async () => {
    // Launch as registered user

    // Create user with history only
    const user = await testUtils.createRegisteredUser();
    await createHistory(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus(
      'homeScreenRowList',
      'Timed out waiting for Rowlist to have focus'
    );

    // Jump to CW row
    await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Continue Watching');

    await testUtils.waitForElementToFullyShowOnScreen(
      'continueWatchingRowHome'
    );

    // Press Ok to reach Details page for title in CW Row
    await ecp.sendKeypress(ecp.Key.Ok);

    // Remove from History
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');

    // Back to Home
    await ecp.sendKeypress(ecp.Key.Back);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Homescreen page should not display Continue Watching Row
    await testUtils.waitForElementToNotShowOnScreen('continueWatchingRowHome');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/524602
  it('C524602 - User sees 6 titles per row on full screen categories page (kids mode), @categories', async () => {
    await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToShowOnScreen('channelsVideoGrid');
    await ecp.sendKeypress(ecp.Key.Right);

    // Are we on the Video Grid? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // If so, navigate horizontally to last poster + 1
    await verifyFourColumns();
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/539354
  it('C539354 - User sees 6 titles per row on full screen channels page, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Navigate to the video grid in a channel
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.getNodeForElement('categoryNameInCategoryDetailsPage');
    await ecp.sendKeypress(ecp.Key.Right);

    // Are we on the Video Grid? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // If so, navigate horizontally to last poster + 1
    await verifyFourColumns();

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/637124 and https://tubi.testrail.io/index.php?/cases/view/690609
  it('C637124 - Guest User - Recommended is shown at the top of list, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

  });

  // https://tubi.testrail.io/index.php?/cases/view/637123
  it('C637123 - Registered User - Continue Watching is NOT displayed near top of list, if user does not have titles to resume, @categories', async () => {
    // Create user with history only
    const user = await testUtils.createRegisteredUser();
    await createHistory(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to All Categories page
    await testHelpers.navigateToCategories();
    await testUtils.waitForElementToNotShowOnScreen('continueWatchingButton');
  });

  // https://tubi.testrail.io/index.php?/cases/view/638438
  it('C638438 - Registered User - My List is displayed near top of list, if user has titles in "My List", @categories', async () => {

    // Create user with watchlist
    const user = await testUtils.createRegisteredUser();
    await createWatchList(user);

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to All Categories page
    await testHelpers.navigateToCategories();
    await testUtils.waitForElementToShowOnScreen('categoryMyListMenuItem');
    const categoryMyListMenuItemText = await testUtils.getNodeForElement('categoryMyListMenuItem');
    expect(categoryMyListMenuItemText.text).to.equal('My List');

  });


  // https://tubi.testrail.io/index.php?/cases/view/638439
  it('C638439 - Registered User - My List is NOT displayed near top of list, if user has no titles in "My List", @categories', async () => {

    // Create user with watchlist
    const user = await testUtils.createRegisteredUser();

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to All Categories page
    await testHelpers.navigateToCategories();
    await testUtils.waitForElementToFullyShowOnScreen('categoryMyListMenuItem');
    const buttonText = await testUtils.getNodeForElement('categoryMyListMenuItem');
    expect(buttonText.title).to.not.equal('My List');

  });


  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/638443
  it('C638443 - "Networks" is shown near the top of the list, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify that the Networks button is near the top
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToFullyShowOnScreen('channelNetworksButtonFocused');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638445
  // https://tubi.testrail.io/index.php?/cases/view/765063
  // https://tubi.testrail.io/index.php?/cases/view/765064
  it('C638445 - Selecting a network poster will display the category page view of all the titles in the network, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
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
    const position = await shared.findContentPositionInGridThatContainsVideoPreview('channelsDetailsGrid', true, 6);
    await moveToGrid({ grid: { row: 0, col: 0 }, destRow: position[0], destCol: position[1] });

    // Additional check to make sure the video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');

    await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'stopped');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/765056
  it('C765056 - Static image is shown when title does not have a video preview, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    await testUtils.waitForElementToShowOnScreen('categoryPosterFirst');
    await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

    const position = await shared.findContentPositionInGridThatContainsVideoPreview('channelsVideoGrid', false, 4);
    await moveToGrid({ grid: { row: 0, col: 0 }, destRow: position[0], destCol: position[1] });

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'stopped');

    await testUtils.waitForElementToShowOnScreen('backgroundPoster');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638444
  it('C638444 - Selecting "Networks" will display the networks as separate posters, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Down to Networks button and select
    await ecp.sendKeypress(ecp.Key.Down, { wait: 1500 });
    await testUtils.waitForElementToFullyShowOnScreen('categoryPageTitle');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Network posters
    await testUtils.waitForElementToShowOnScreen('networksContentGrid');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C638446 and https://tubi.testrail.io/index.php?/cases/view/638447
  it('C638446 - Selecting any category will move focus to first title in the container, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Is the metadate Info panel present?
    // Checking for metadata info panel only because background poster will not be visible when autoplay is enabled and preview video plays.
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/765057
  it('C765057 - When a title is in focus, video preview does not play when Autoplay Previews is Off, @categories', async () => {
    // Create user with watch list and history
    const user = await testUtils.createRegisteredUser();
    // Launch to home page
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');

    // Open settings
    await ecp.sendKeypress(ecp.Key.Left);
    await shared.openSettings();

    // Are we on Settings page?
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

    // Turn off video previews
    await ecp.sendKeypress(ecp.Key.Down);
    // Waiting until the autoplay preview section is fully shown on screen.
    await testUtils.waitForElementToFullyShowOnScreen('autoplayPreviewOn');
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Navigate to back to home screen
    await ecp.sendKeypress(ecp.Key.Back, { count: 2, wait: 200 });

    // Expect Home Side Nav item to be highlighted and on Home page
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Is the Background Poster present?
    await testUtils.waitForElementToShowOnScreen('backgroundPoster');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/765055
  // https://tubi.testrail.io/index.php?/cases/view/765065
  // https://tubi.testrail.io/index.php?/cases/view/765058
  it('C765055 - When a title is in focus, video preview plays when Autoplay Previews is On, @categories', async () => {
    // Launch to home page
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
    const position = await shared.findContentPositionInGridThatContainsVideoPreview('channelsVideoGrid', true, 6);
    await moveToGrid({ grid: { row: 0, col: 0 }, destRow: position[0], destCol: position[1] });
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');

    await ecp.sendKeypress(ecp.Key.Ok, { wait: 200 });
    // Verify Details page opens
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');

    // Navigate back to category list screen.
    await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });
    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Moving focus to category filters.
    await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'paused');
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/765059
  it('C765059 - Once video preview ends, title auto starts, @categories', async () => {
    // Launch to home page
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
    const position = await shared.findContentPositionInGridThatContainsVideoPreview('channelsVideoGrid', true, 6);
    await moveToGrid({ grid: { row: 0, col: 0 }, destRow: position[0], destCol: position[1] });

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing');
    await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -1000, "end");
    // Verify Details page opens
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 20000);
  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C690718 and https://tubi.testrail.io/index.php?/cases/view/638449
  it('C690718 - When title is NOT in focus, the metadata/static image is removed from the top of the screen, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Is the metadata Info panel present?
    // Not checking for background poster because it will depend on whether autoplay is enabled or not.
    // Since when autoplay is enabled, preview video will play and background poster will not be visible.
    // Just checking for metadata info panel should be enough.
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

    // Press back and check background poster and metadata info is no longer present
    await ecp.sendKeypress(ecp.Key.Back, { wait: 2000 });
    // Is the metadata Info panel present?
    await testUtils.waitForElementToNotShowOnScreen('categoriesDetailsPageInfo');

    // Is the category menu item selected?
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/637124 and https://tubi.testrail.io/index.php?/cases/view/690609
  it('C638448 - Selecting a title opens the details page, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 1000 });

    // Wait until the first content tile is shown.
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Is the metadata Info panel present?
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');

    // Select a Title
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });

    // Verify Details page opens
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

  });

  // Test Rail link: https://tubi.testrail.io/index.php?/cases/view/C690716
  it('C690716 - Verify UI/UX while in Kids mode, @categories', async () => {
    await testUtils.startApplicationAtPage('kids', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Networks category button at the top
    await testUtils.waitForElementToFullyShowOnScreen('categoryHeader');
    const headerName = await testUtils.getNodeForElement('categoryHeader');
    expect(headerName.text).to.equal('Networks');

  });

  // https://tubi.testrail.io/index.php?/cases/view/690606
  it('690606 - Pressing "back" from details page takes user back to category tile screen, @categories', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 200 });

    // Is the metadata Info panel present?
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');
    // Select a Title
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 200 });
    // Verify Details page opens
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Timed out waiting for detailScreenTitle to be shown', 10000);
    // Press back to go back to category title screen
    await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });

    // Is the metadata Info panel present?
    await testUtils.waitForElementToFullyShowOnScreen('categoriesDetailsPageInfo');
  });

});


async function verifyFourColumns() {

  // Verify 6 rows only, navigate horizontally to last poster + 1
  await utils.sleep(1000);
  await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
  await utils.sleep(1000);

  // Are we still on the 4th title after navigating right more than 3 times?
  const channelsVideoGrid = await testUtils.getNodeForElement('channelsVideoGrid');
  expect(channelsVideoGrid.currFocusColumn).to.equal(3);

}

async function createWatchList(user) {

  // Create a user with mix of little kids and non-little kid rated titles with history

  const ContentTVG = await user.getContent().ofContentType('series').withRating('TV-G').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentTVG);
  const ContentG = await user.getContent().ofContentType('movie').withRating('G').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentG);
  const ContentPG = await user.getContent().ofContentType('movie').withRating('PG').retrieve({ limit: 6 });
  await user.addContentToWatchList(ContentPG);

}

async function createHistory(user) {

  // Create a user with mix of little kids and non-little kid rated titles with history
  const ContentG = await user.getContent().withRating('G').ofContentType('movie').retrieve({ limit: 1 });
  await user.addContentToViewHistory(ContentG, 600);
  const movieContentPG = await user.getContent().withRating('PG').ofContentType('movie').retrieve({ limit: 2 });
  await user.addContentToViewHistory(movieContentPG, 500);
}
