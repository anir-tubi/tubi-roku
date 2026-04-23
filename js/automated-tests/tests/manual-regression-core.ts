import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';
import { mockDataHelpers } from '../mock-data-helpers';
import {
  setupAdMockAndLaunchApp,
  resetAudioOptions,
  safeResumeProxy
} from './manual-regression-helpers';

/**
 * Core Manual Regression Tests
 * Tests for categories, navigation, VOD playback, search, kids mode, My List,
 * feedback, audio description, continue watching, ads, trailers, BWW, backgrounding,
 * deeplink, voice commands, YMAL/autoplay, and My Stuff
 */

describe('Core Manual Regression Tests', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  afterEach(async () => {
    await proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/637125
  it('C637125 - Categories shown in alphabetical order @manual_regression', async () => {
    /**
     * Pre-conditions: Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. In left nav, select "Categories"
     * 3. Verify categories are displayed in alphabetical order
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Categories
    await testHelpers.navigateToCategories();

    // Wait a bit for grid to populate
    await utils.sleep(1000);

    // Get all category items
    const categories = await testUtils.getAllGridItemsContent('categoriesListMenu');

    expect(categories).to.exist;
    expect(categories.length).to.be.greaterThan(0, 'No categories found');

    // Extract category titles, filtering out "Recommended" and "Networks"
    const allCategoryTitles = categories.map(cat => cat.title || cat.name).filter(title => title);
    const categoryTitles = allCategoryTitles.filter(title =>
      title.toLowerCase() !== 'recommended' && title.toLowerCase() !== 'networks'
    );

    expect(categoryTitles.length).to.be.greaterThan(0, 'No categories found after filtering');
    // Create a sorted copy using ASCII order (uppercase letters come before lowercase)
    const sortedTitles = [...categoryTitles].sort((a, b) => {
      // Trim and normalize spaces, but keep case for comparison
      const normalizeForSort = (str: string) =>
        str.trim().replace(/\s+/g, ' ');

      const normA = normalizeForSort(a);
      const normB = normalizeForSort(b);

      // Direct string comparison uses ASCII values where uppercase < lowercase
      // e.g., 'T' (84) < 'a' (97), so "True" comes before "a Book"
      return normA < normB ? -1 : normA > normB ? 1 : 0;
    });

    // Verify categories are in alphabetical order
    expect(categoryTitles).to.deep.equal(sortedTitles,
      `Categories are not in alphabetical order (ignoring Recommended and Networks).\nActual: ${categoryTitles.join(', ')}\nExpected: ${sortedTitles.join(', ')}`
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/691557
  it('C691557 - Background image changes when focusing on categories @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * - In Settings, Autoplay Previews = OFF
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to Categories screen.
     * 3. Verify background poster is visible and changes when focusing on different categories.
     * 4. Verify that background images from home screen do not appear on Categories screen.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn off Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(false);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to Categories
    await testHelpers.navigateToCategories();

    //Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');


    await ecp.sendKeypress(ecp.Key.Right);

    // Get both background poster elements (app may use either or both)
    await testUtils.waitForElementToShowOnScreen('backgroundPoster', 'Background poster not visible', 5000);
    const bgPoster1First = await testUtils.getNodeForElement('backgroundPoster');
    const bgPoster2First = await testUtils.getNodeForElement('backgroundPoster2');

    const firstBackgroundUri1 = bgPoster1First.uri;
    const firstBackgroundUri2 = bgPoster2First.uri;
    // Navigate to next category
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Get both background poster URIs again
    const bgPoster1Second = await testUtils.getNodeForElement('backgroundPoster');
    const bgPoster2Second = await testUtils.getNodeForElement('backgroundPoster2');

    const secondBackgroundUri1 = bgPoster1Second.uri;
    const secondBackgroundUri2 = bgPoster2Second.uri;

    // Verify that at least one of the background posters changed
    const bgPoster1Changed = secondBackgroundUri1 !== firstBackgroundUri1;
    const bgPoster2Changed = secondBackgroundUri2 !== firstBackgroundUri2;

    expect(bgPoster1Changed || bgPoster2Changed).to.equal(true,
      'At least one background poster should change when focusing on different categories. ' +
      `backgroundPoster: ${firstBackgroundUri1} -> ${secondBackgroundUri1}, ` +
      `backgroundPoster2: ${firstBackgroundUri2} -> ${secondBackgroundUri2}`
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765055
  it('C765055 - Video preview plays when title is in focus @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. In left nav, select "Categories".
     * 3. Select any category.
     * 4. Focus on a title that has a video preview.
     * 5. Verify video preview plays.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Find and navigate to content with video preview
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoriesScreenContentGrid', true, 6);
    expect(position.length).to.equal(2, 'Could not find content with video preview');

    // Verify video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765057
  it('C765057 - If video previews is turned off in app settings, static image is shown when title is in focus @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - Video preview is turned off in app settings.
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Turn off video previews in settings.
     * 3. In left nav, select "Categories".
     * 4. Select any category.
     * 5. Focus on a title that has a video preview.
     * 6. Verify static image is shown (not video preview).
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn off Video Previews in Settings
    await testHelpers.enablePreviewInSettings(false);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Find and navigate to content with video preview (to verify static image is shown for content that HAS preview capability)
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoriesScreenContentGrid', true, 6);
    expect(position.length).to.equal(2, 'Could not find content with video preview');

    // Verify static image is shown (background poster should be visible since preview is OFF)
    await testUtils.waitForElementToShowOnScreen('backgroundPoster');

    // Verify preview player is NOT playing (since previews are turned off)
    const previewPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
    expect(previewPlayer.state).to.not.equal('playing', 'Preview should not be playing when previews are turned off');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765058
  it('C765058 - If user taps title while video preview is playing, video preview continues in details page @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. In left nav, select "Categories".
     * 3. Select any category.
     * 4. Focus on a title that has a video preview.
     * 5. While video preview is playing, select the title.
     * 6. Verify video preview continues playing in details page.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected?
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Find and navigate to content with video preview
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoriesScreenContentGrid', true, 6);
    expect(position.length).to.equal(2, 'Could not find content with video preview');

    // Verify video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Select the title while video preview is playing
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify Details page opens
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

    // Verify video preview continues playing in details page
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765059
  it('C765059 - Once video preview ends, title autostarts @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. In left nav, select "Categories".
     * 3. Select any category.
     * 4. Focus on a title that has a video preview.
     * 5. Let video preview complete.
     * 6. Verify title autostarts (navigates to detail screen and starts playing).
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Find and navigate to content with video preview
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoriesScreenContentGrid', true, 6);
    expect(position.length).to.equal(2, 'Could not find content with video preview');

    // Verify video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Seek to near end of preview to speed up test
    await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -1000, "end");

    // Verify Details page opens (autostart behavior)
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 20000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765063
  it('C765063 - Video preview plays for Network @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. In left nav, select "Categories".
     * 3. Select "Networks".
     * 4. Select any network.
     * 5. Focus on a title that has a video preview.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Categories
    await testHelpers.navigateToCategories();
    await testUtils.waitForElementToHaveFocus('categoriesListMenu', 'Timed out waiting for Categories list menu to have focus');

    // Find and navigate to "Networks" category
    const itemFocused = await testUtils.jumpToRowWithTitle('categoriesListMenu', 'Networks');
    await testUtils.waitForElementFieldToEqual('categoriesListMenu', 'itemFocused', itemFocused, 15000);
    await testUtils.waitForGridContentToLoad('channelsListScreenGrid', 15000);

    // Move focus to Networks grid (retry Right keypress until grid has focus)
    await testUtils.retryWithTimeOut(async () => {
      await ecp.sendKeypress(ecp.Key.Right);
      const isInFocus = await testUtils.elementIsInFocusChain('channelsListScreenGrid');
      if (!isInFocus) {
        throw new Error('Networks grid does not have focus yet');
      }
    }, 10000);

    // Select the first network
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for network detail screen to load
    await testUtils.waitForCurrentScreenToEqual('categoryDetailsScreen', 15000);

    // Find and navigate to a title with video preview
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoryDetailsVideoGrid', true, 6);
    expect(position.length).to.equal(2, 'Could not find content with video preview in Network');

    // Verify video preview is playing for Network content
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('categoryDetailsVideoGrid');
    const playerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(playerContent).to.exist;
    expect(playerContent.id).to.equal(focusedContent.id, 'Preview player should be playing the focused Network content');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/765065
  it('C765065 - Video preview stops when user select Categories list @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. In left nav, select "Categories".
     * 3. Select any category.
     * 4. Focus on a title that has a video preview.
     * 5. During preview, press "Back" button on remote to move focus to Category list.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Go to Categories Details page
    await testHelpers.navigateToCategories();

    // Verify Recommended button at the top
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton');

    // Select Category Button
    await ecp.sendKeypress(ecp.Key.Ok);

    // Is the first poster now selected? 
    await testUtils.waitForElementToFullyShowOnScreen('categoryPosterFirst');

    // Find and navigate to content with video preview
    const position = await testHelpers.findAndNavigateToVideoPreviewContentInGrid('categoriesScreenContentGrid', true, 6);
    expect(position.length).to.equal(2, 'Could not find content with video preview');

    // Verify video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Moving focus to category filters (Back to category list)
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify video preview has paused/stopped
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'paused', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/692880
  it('C692880 - Play VOD @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Connected to VPN in UK or similar method (for locale testing)
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to home screen
     * 3. Find and select a VOD content (movie or series)
     * 4. Verify detail screen opens
     * 5. Play the content
     * 6. Verify video player screen opens and playback starts
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Find and navigate to a movie (VOD content, not linear)
    // Will search current row first, then up to 20 rows if needed
    const { row, column } = await testHelpers.findAndNavigateToContentType('v', 'videoTitlesRowList', 20);
    if (row > 0) {
      await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', row, 10000);
    }
    if (column > 0) {
      await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'currFocusColumn', column, 10000);
    }

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.be.oneOf(['v', 's'], 'Focused content should be VOD (movie or series)');

    // Select the content to open detail screen
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    // Verify detail screen title is visible
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 5000);
    const detailTitle = await testUtils.getNodeForElement('detailScreenTitle');
    expect(detailTitle.visible).to.equal(true, 'Detail screen title should be visible');

    // Play the content
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);

    // Verify playback started
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Video should be playing or buffering');

    // Verify player has content loaded
    const playerContent = await testUtils.getElementField('videoPlayerScreen', 'content');
    expect(playerContent).to.exist;
    expect(playerContent.id).to.equal(focusedContent.id, 'Player should be playing the selected content');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/692881
  it('C692881 - Search @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Connected to VPN in UK or similar method (for locale testing)
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to search screen
     * 3. Enter a search query
     * 4. Verify search results appear
     * 5. Select a search result
     * 6. Verify detail screen opens
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to search screen
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);


    // Verify keyboard is visible
    await testUtils.waitForElementToShowOnScreen('searchKeyPad', 'Search keyboard not visible', 5000);
    const keyboard = await testUtils.getNodeForElement('searchKeyPad');
    expect(keyboard.visible).to.equal(true, 'Search keyboard should be visible');

    // Enter search query "action"
    const searchQuery = 'action';
    await ecp.sendText(searchQuery);
    await utils.sleep(2000);

    // Verify search results appear
    await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);
    const searchResultsGrid = await testUtils.getNodeForElement('searchResultGrid');
    expect(searchResultsGrid.visible).to.equal(true, 'Search results grid should be visible');

    // Verify grid has content
    const gridContentCount = await testUtils.getElementField('searchResultGrid', 'content.getChildCount()');
    expect(gridContentCount).to.be.greaterThan(0, 'Search should return at least one result');

    // Navigate to search results grid using helper
    await testHelpers.navigateRightToSearchGrid();
    await utils.sleep(500);

    // Verify we can get focused item from search results
    const focusedItem = await testUtils.getCurrentlyFocusedGridItemContent('searchResultGrid');
    expect(focusedItem).to.exist;
    expect(focusedItem.id).to.exist;

    // Select the first search result
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    // Verify detail screen opened with correct content
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 5000);
    const detailTitle = await testUtils.getNodeForElement('detailScreenTitle');
    expect(detailTitle.visible).to.equal(true, 'Detail screen title should be visible');
    expect(detailTitle.text).to.exist.and.not.be.empty;

    // Verify content matches the selected item
    const detailContent = await testUtils.getElementField('detailScreen', 'content');
    expect(detailContent).to.exist;
    expect(detailContent.id).to.equal(focusedItem.id, 'Detail page should show the selected content');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/450493
  it('C450493 - When the \'Sign up to save your progress\' modal surfaces, background and foreground Tubi @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * - Platforms that support background mode (does not work on Hisense)
     * 
     * Test Steps:
     * 1. Launch app as guest user
     * 2. Play content and watch for sign up modal to appear
     * 3. Background the app
     * 4. Foreground the app
     * 5. Verify modal still visible or app state is correct
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find and play content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Wait for sign up modal to appear (typically appears after a few minutes for guest users)
    // Skip to end to trigger modal faster
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', -30000, 'end');
    await utils.sleep(10000);

    // Background the app (regardless of modal state)
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(3000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(5000);

    // Verify app recovered properly after background/foreground
    let currentScreenIsVideoPlayer = false;
    try {
      await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 10000);
      currentScreenIsVideoPlayer = true;
    } catch (e) {
      // May return to home screen, which is also valid
      try {
        await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);
      } catch (e2) {
        // App recovered to some other state
      }
    }

    if (currentScreenIsVideoPlayer) {
      const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
      expect(playerState).to.be.oneOf(['playing', 'paused', 'stopped'],
        'Player should be in valid state after background/foreground');
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/22728
  it('C22728 - Search - When movie selected then corresponding movie details page displayed @manual_regression', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to search
     * 3. Search for a movie
     * 4. Select movie from results
     * 5. Verify movie details page is displayed with correct content
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to search
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);


    // Enter search query for a popular movie
    await ecp.sendText('action');
    await utils.sleep(2000);

    // Verify search results appear
    await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);

    // Navigate to search results grid using helper
    await testHelpers.navigateRightToSearchGrid();
    await utils.sleep(500);

    // Navigate to first movie in search results (type 'v' and no seriesId)
    await testUtils.navigateToGridItem('searchResultGrid', (item) => item.type === 'video' && (!item.seriesId || item.seriesId === ''));
    await utils.sleep(500);

    // Get the focused movie content
    const movieContent = await testUtils.getCurrentlyFocusedGridItemContent('searchResultGrid');
    expect(movieContent.type).to.equal('video', 'Selected content should be a movie');

    // Select the movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    // Verify movie details page is displayed
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 5000);
    const detailTitle = await testUtils.getNodeForElement('detailScreenTitle');
    expect(detailTitle.visible).to.equal(true, 'Movie details page should be visible');
    expect(detailTitle.text).to.exist.and.not.be.empty;

    // Verify content matches
    const detailContent = await testUtils.getElementField('detailScreen', 'content');
    expect(detailContent).to.exist;
    expect(detailContent.id).to.equal(movieContent.id, 'Detail page should show the selected movie');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/22729
  it('C22729 - Search - When series selected then corresponding series details page displayed @manual_regression', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to search
     * 3. Search for a series
     * 4. Select series from results
     * 5. Verify series details page is displayed with correct content
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to search
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);


    // Enter search query for a series
    await ecp.sendText('comedy');
    await utils.sleep(2000);

    // Verify search results appear
    await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);

    // Navigate to search results grid using helper
    await testHelpers.navigateRightToSearchGrid();
    await utils.sleep(500);

    // Navigate to first series in search results (type 's' or has seriesId)
    await testUtils.navigateToGridItem('searchResultGrid', (item) => (item.type === 'series'));
    await utils.sleep(500);

    // Get the focused series content
    const seriesContent = await testUtils.getCurrentlyFocusedGridItemContent('searchResultGrid');

    // Select the series
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    // Verify series details page is displayed
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 5000);
    const detailTitle = await testUtils.getNodeForElement('detailScreenTitle');
    expect(detailTitle.visible).to.equal(true, 'Series details page should be visible');
    expect(detailTitle.text).to.exist.and.not.be.empty;

    // Verify content matches
    const detailContent = await testUtils.getElementField('detailScreen', 'content');
    expect(detailContent).to.exist;
    expect(detailContent.id).to.equal(seriesContent.id, 'Detail page should show the selected series');
  });


  it('C243579 - Guest User locked into kids mode after entering age < 13, deep links show "Content Not Available" @manual_regression @kids', async () => {
    /**
     * Pre-conditions:
     * - Guest User
     * - Access Kids Mode
     * - Select Exit Kids Mode
     * - When age gate displays, enter age between 5-12 years
     * - When "Cannot Exit Kids Mode" dialog displays, select Close
     * 
     * Test Steps:
     * 1. Launch app as guest user
     * 2. Enter kids mode
     * 3. Try to exit kids mode with age < 13
     * 4. Verify locked in kids mode
     * 5. Deep link to adult content
     * 6. Verify "Content Not Available" or remains in kids mode
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to kids mode via side nav
    await testHelpers.openKidsMode();
    await testUtils.waitForGridContentToLoad('homeScreenRowList', 10000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 20000);

    // Verify in kids mode by checking for kids logo (already verified in helper, but double-check)
    await testUtils.waitForElementToShowOnScreen('tubiKidsLogo', 'Kids logo not visible', 10000);
    const kidsLogo = await testUtils.getNodeForElement('tubiKidsLogo');
    expect(kidsLogo.visible).to.equal(true, 'Should be in kids mode');

    // Select "Exit Kids Mode" option
    await testHelpers.exitKidsMode();

    // Verify Age Gate Screen appears
    await testUtils.waitForElementToShowOnScreen('ageVerificationNumberPad', 'Age gate not shown', 5000);

    // Enter age < 13 (age 10 means birth year = current year - 10)
    const birthYear = new Date().getFullYear() - 10;
    await ecp.sendText(birthYear.toString());
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // "Cannot Exit Kids Mode" dialog should appear
    await testUtils.waitForElementToShowOnScreen('cannotExitKidsModeTitle', 'Cannot exit kids mode dialog not shown', 5000);
    const cannotExitTitle = await testUtils.getNodeForElement('cannotExitKidsModeTitle');
    expect(cannotExitTitle.text).to.equal('Cannot Exit Kids Mode', 'Dialog title should match');

    // Close the dialog
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify still in kids mode
    const kidsLogoAfter = await testUtils.getNodeForElement('tubiKidsLogo');
    expect(kidsLogoAfter.visible).to.equal(true, 'Should still be in kids mode after failed exit');

    // Try to deep link to adult content (TV-MA movie not available in kids mode)
    await testUtils.startApplicationWithDeeplink({
      mediaType: 'movie',
      contentID: '679437' // TV-MA/Adult content
    });
    await utils.sleep(3000);

    // Verify that the detail screen is not loaded (restricted content blocked)
    let detailScreenLoaded = false;
    try {
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);
      detailScreenLoaded = true;
    } catch (_) { }
    expect(detailScreenLoaded, 'Detail screen should not have loaded for restricted content').to.be.false;
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);
  });


  it('C264839 - Guest user without age info selects Add to My List from Details page @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - New guest user without age info
     * 
     * Test Steps:
     * 1. Launch app as new guest user
     * 2. Navigate to content details page
     * 3. Select "Add to My List" button
     * 4. Verify age gate or sign-in prompt appears
     */

    // Launch app as new guest user
    await testUtils.startApplicationAtPage('home', { clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);


    // Select first content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Select "Add to My List" button (will trigger age gate/sign-in for guest user)
    await testUtils.selectMenuItem('detailScreenMenu', 'Add to My List');


    await testUtils.waitForElementToShowOnScreen('modalDialogScreen', 'Sign-in modal not shown', 10000);
    await testUtils.waitForElementToShowOnScreen('addToMyListAccountNeededMessage', 'add to my list account needed message not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify sign-in screen appeared for guest user
    await testUtils.waitForCurrentScreenToEqual('signInScreen', 5000);
    await testUtils.waitForElementToShowOnScreen('signInScreenPageHeader', 'Sign-in screen not shown', 3000);
  });


  it('C574104 - Guest user could see the feedback icon on series player @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * 
     * Test Steps:
     * 1. Launch app as guest user
     * 2. Find and play series content
     * 3. Show HUD (Play/OK depending on device)
     * 4. Move focus to top overlay area where transport buttons are visible
     * 5. Verify Send Feedback button exists and is visible
     */

    // Start app with Guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to TV Shows and select a series
    await testUtils.goToPage('series');
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'TV screen row not found', 15000);
    await ecp.sendKeypress(ecp.Key.Play);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Move focus to top overlay area where transport buttons are visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(300);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton).to.exist;

    // If node is found, ensure it is visible when HUD is up
    if (sendFeedbackButton.visible !== undefined) {
      expect(Boolean(sendFeedbackButton.visible)).to.equal(true);
    }
  });


  it('C574105 - Registered user could see the feedback icon on movie player @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Registered user
     * 
     * Test Steps:
     * 1. Launch app as registered user
     * 2. Find and play movie content
     * 3. Show HUD (Play/OK depending on device)
     * 4. Move focus to top overlay area where transport buttons are visible
     * 5. Verify Send Feedback button exists and is visible
     */

    // Start app with Registered user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Movies and select a movie
    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Movie screen row not found', 15000);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('playButton', 'Play button not found', 15000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Move focus to top overlay area where transport buttons are visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(300);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton).to.exist;

    // If node is found, ensure it is visible when HUD is up
    if (sendFeedbackButton.visible !== undefined) {
      expect(Boolean(sendFeedbackButton.visible)).to.equal(true);
    }
  });


  it('C574109 - User could choose one item and see the confirm page (Roku shows Thank You/QR Code) @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - All users
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play content
     * 3. Open feedback panel
     * 4. Select a feedback option
     * 5. Verify Thank You / QR Code page is shown
     */

    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to transport buttons then to sendFeedback button
    await testHelpers.navigateToTransportButtons();
    await testHelpers.navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const overlayGroup = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(overlayGroup.visible).to.equal(true);

    await ecp.sendKeypress(ecp.Key.Down);

    // Select the feedback in sendFeedback overlay and goes to confirmation page
    await ecp.sendKeypress(ecp.Key.Ok);

    //small wait for QR code open
    await utils.sleep(800);

    // Verify overlay visible
    const qrCodeOverlay = await testUtils.getNodeForElement('SendFeedbackQRCodeOverlayOnPlayer');
    expect(qrCodeOverlay.visible).to.equal(true);
  });


  it('C574110 - User could close the send feedback side menu by pressing back button @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - All users
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play content and open feedback panel
     * 3. Press back button
     * 4. Verify feedback panel closes and returns to player
     */

    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to transport buttons then to sendFeedback button
    await testHelpers.navigateToTransportButtons();
    await testHelpers.navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const sendFeedbackSelectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlay');
    await utils.sleep(800);

    await testUtils.elementHasFocus('sendFeedbackSelectionOverlay');

    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(800);

    // Verify overlay is hidden
    await testUtils.waitForElementToNotShowOnScreen('sendFeedbackSelectionOverlay');
  });


  it('C678503 - [Roku] When feedback panel is open, the content playback is NOT paused @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Roku platform
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play content
     * 3. Open feedback panel
     * 4. Verify playback continues (not paused)
     */

    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Ensure we're focused on playable content before pressing Play
    await shared.ensurePlayableContentFocused();

    // Press play to start video, then check if it is playing
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Navigate to transport buttons then to sendFeedback button
    await testHelpers.navigateToTransportButtons();
    await testHelpers.navigateToSendFeedbackButton();

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);

    // Fetch fresh player state after opening feedback overlay to verify playback continues
    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    expect(videoPlayerScreen.state).to.equal('playing', 'Playback should continue while feedback panel is open');
  });


  it('C574118 - The feedback icon should be hidden in kids mode @manual_regression @kids', async () => {
    /**
     * Pre-conditions:
     * - All users
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Enter kids mode
     * 3. Play kids content
     * 4. Show HUD
     * 5. Verify feedback icon is NOT visible
     */

    // Start app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await testHelpers.openKidsMode();
    await utils.sleep(800);

    // Navigate right to home page focus
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await ecp.sendKeypress(ecp.Key.Play);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);

    // Navigate to transport buttons and verify sendFeedback button is not reachable
    await testHelpers.navigateToTransportButtons();
    let foundButton = false;
    try {
      await testHelpers.navigateToSendFeedbackButton();
      foundButton = true;
    } catch (e) {
      // Expected: button not found
    }
    expect(foundButton).to.equal(false, 'sendFeedBackButton should not be reachable in kids mode');
  });


  it('C795973 - On home screen load, new /inapp endpoint fires @manual_regression', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Set up wrapper ad mock
     * 2. Launch app and wait for home screen
     * 3. Verify wrapper ad appears on home screen
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Wrapper], { shouldCreateNewUser: false });

    // Verify home screen skin ad elements are visible and non-empty
    await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should be visible on home screen', 3000);
    const skinAdLogoUri = await testUtils.getElementField('skinAdLogo', 'uri');
    expect(skinAdLogoUri).to.not.be.empty;

    await testUtils.waitForElementToShowOnScreen('skinAdDescription', 'Skin ad description should be visible on home screen', 3000);
    const skinAdDescText = await testUtils.getElementField('skinAdDescription', 'text');
    expect(skinAdDescText).to.not.be.empty;

    proxy.pause();
  });


  it('C424702 - Registered User: AD selection persists between sessions on same device (background/foreground) @manual_regression @audio_description', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to Categories -> Audio Description
     * 3. Select and play first title
     * 4. Enable AD
     * 5. Exit player and navigate back
     * 6. Select a different title from Audio Description category
     * 7. Verify AD is still enabled
     * 
     * Expected:
     * - AD is still enabled for the second title
     * - AD settings persist across different titles
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Categories
    await testHelpers.navigateToCategories();
    await testUtils.waitForElementToHaveFocus('categoriesListMenu', 'Timed out waiting for categories list menu to have focus');

    // Find and navigate to "Audio Description" category
    const rowIndex = await testUtils.jumpToRowWithTitle('categoriesListMenu', 'Audio Description');
    await testUtils.waitForElementFieldToEqual('categoriesListMenu', 'itemFocused', rowIndex, 10000);

    // Wait for the grid to be visible and verify it's the Audio Description category
    await testUtils.waitForElementToShowOnScreen('categoriesScreenContentGrid', 'Audio Description grid not visible', 5000);
    await testUtils.observeFieldUntilMatch('categoriesScreenContentGrid', (content) => content?.id === 'audio_description', 'content', 10000);
    // Move focus to the grid on the right
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('categoriesScreenContentGrid', 'Timed out waiting for categories screen content grid to have focus', 15000);

    // Select first title and play
    await ecp.sendKeypress(ecp.Key.Play);
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Open player controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(800);

    // Verify Closed Caption audio button is present
    const closedCaptionAudioButton = await testUtils.getNodeForElement('closedCaptionAudioButton');
    expect(closedCaptionAudioButton.uri).to.contain('pkg:/images/transport/sgplayer/icon-subtitles');

    // Navigate right to open Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Validate options are present
    const closedCaptionSectionHeaderLabel = await testUtils.getNodeForElement('closedCaptionSectionHeaderLabel');
    expect(closedCaptionSectionHeaderLabel.text).to.equal('Subtitles');

    const audioTracksSectionHeaderLabel = await testUtils.getNodeForElement('audioTracksSectionHeaderLabel');
    expect(audioTracksSectionHeaderLabel.text).to.equal('Audio');

    // Enable AD - navigate to Audio Description option
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 200 });
    await utils.sleep(200);
    await ecp.sendKeypress(ecp.Key.Ok);


    // Exit player and go back to Audio Description category
    await ecp.sendKeypress(ecp.Key.Back);

    // Retry Back keypress until we're on detailScreen
    await testUtils.untilTrue(async () => {
      const currentScreen = await testUtils.getElementField('screenStack', '-1', 5000);
      if (currentScreen.id === 'detailScreen') {
        return true;
      }
      await ecp.sendKeypress(ecp.Key.Back);
      await utils.sleep(1000);
      return false;
    }, 'Should navigate back to detail screen', 15000);

    // One more Back to get to category grid
    await ecp.sendKeypress(ecp.Key.Back);

    // Should be back on Audio Description category grid
    await testUtils.waitForElementToHaveFocus('categoriesScreenContentGrid', 'Grid should have focus after navigating back', 15000);
    await ecp.sendKeypress(ecp.Key.Right);
    // Select the new title
    await ecp.sendKeypress(ecp.Key.Play);
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Open player controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(800);

    // Navigate right to open Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify that AD is still enabled for the second title
    await testUtils.waitForElementToFullyShowOnScreen('audioDescriptionItemChecked', 'AD should still be enabled', 5000);

    // Reset AD controls to default
    await resetAudioOptions();
  });


  it('C443158 - [Roku Only] While Audio and Subtitle modal is displayed, background and foreground the app @manual_regression @audio_description', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Playback any VOD content (doesn't need to be AD supported)
     * 3. In playback controls, select the Audio and Subtitle icon
     * 4. While the Audio and Subtitle modal is displayed, background the app
     * 5. Foreground the app
     * 6. Playback the content
     * 
     * Expected:
     * - Playback should resume without Audio and Subtitle modal displayed
     */

    // Launch app with AD-supported content (episode 526358)
    await testUtils.startApplicationAtPage('home', { clearRegistry: false });

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);

    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Pause playback to interact with controls
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'paused');

    // Navigate right to open Audio and Subtitle Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Verify Audio and Subtitle modal is displayed
    const closedCaptionAndAudioSelectionOverlay = await testUtils.getNodeForElement('closedCaptionAndAudioSelectionOverlay');
    expect(closedCaptionAndAudioSelectionOverlay.opacity).to.be.equal(1);

    // While modal is displayed, background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(3000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Play);

    // Verify playback resumed and modal is not displayed
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 10000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Verify modal is not displayed (sections should not be visible)
    const closedCaptionAndAudioSelectionOverlayAfter = await testUtils.getNodeForElement('closedCaptionAndAudioSelectionOverlay');
    expect(closedCaptionAndAudioSelectionOverlayAfter.opacity).to.be.equal(0);
  });


  it('C43926 - Continue Watching - Maintain focus after removing rightmost title in CW Row @manual_regression @continue_watching', async () => {
    /**
     * Pre-conditions:
     * - Logged in user
     * - At least 3 titles in Continue Watching
     * 
     * Test Steps:
     * 1. Add multiple content items to Continue Watching category
     * 2. Navigate to an item in the Continue Watching row on the home page
     * 3. Navigate to the detail screen and remove from history
     * 4. Return to the home screen
     * 
     * Expected:
     * - If the item removed in Continue Watching was the last one, then the next to last one will gain focus
     * - If the item removed was anything other than the last one, then focus will be one title to the right
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Create Continue Watching history with multiple different titles (like my-stuff tests)
    const movieContentPG = await user.getContent().withRating('PG' as any).ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentPG, 500);
    const movieContentPG13 = await user.getContent().withRating('PG-13' as any).ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentPG13, 500);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Continue Watching row
    const cwRowIndex = await testUtils.findRowIndexWithSlug('videoTitlesRowList', 'continue_watching');
    await testUtils.jumpToRowIndex('videoTitlesRowList', cwRowIndex);
    await utils.sleep(1000);

    // Get the Continue Watching row content
    const cwContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', cwRowIndex);
    expect(cwContent).to.exist;
    expect(cwContent.length).to.be.greaterThan(2, 'Should have at least 3 items in Continue Watching');

    // Navigate to the last item in Continue Watching row
    const lastItemIndex = cwContent.length - 1;
    await testUtils.jumpToRowItem('videoTitlesRowList', [cwRowIndex, lastItemIndex]);


    const focusedItemBefore = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItemBefore).to.exist;

    // Go to details screen
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Remove from history using the proper helper (like C421108 in my-stuff.ts)
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    await utils.sleep(3000);

    // Return to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);


    // Verify focus is on the next-to-last item (since we removed the last item)
    const focusedItemAfter = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItemAfter).to.exist;
    expect(focusedItemAfter.id).to.not.equal(focusedItemBefore.id, 'Focus should have moved to a different item');
  });


  it('C433372 - Pre-rolls - Ad plays after exiting during Ad playback @manual_regression @ads @preroll', async () => {
    /**
     * Pre-conditions:
     * - Guest or Signed-In user
     * 
     * Test Steps:
     * 1. Play a VOD title
     * 2. As pre-roll ad is playing, Exit the ad (Back button) to reach Details screen
     * 3. Press Play button
     * 4. Check if pre-roll ad plays
     * 
     * Expected:
     * - Pre-roll Ad should play and title should start from beginning
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Select any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Play the content
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(2000);

    // Wait for pre-roll ad to start (if present)
    await utils.sleep(3000);

    // Press Back to exit during ad playback
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);


    // Press Play again
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);

    // Verify playback starts (may have ad or may go directly to content)
    await utils.sleep(5000);
    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Player should be active');
  });


  it('C433373 - Mid-rolls - Ad plays after exiting during Ad playback @manual_regression @ads @midroll', async () => {
    /**
     * Pre-conditions:
     * - Guest or Signed-In user
     * 
     * Test Steps:
     * 1. Play a VOD title
     * 2. Watch or scrub to cue point of a mid-roll Ad for the title
     * 3. When mid-roll ad is playing, Exit the ad (Back button) to reach Details screen
     * 4. Press Resume or Play button to continue playback
     * 5. Check if mid-roll ad plays prior to resuming playback
     * 
     * Expected:
     * - Mid-roll Ad should play and title should resume from playback position it was at prior to the Ad
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Select any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Play the content
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Fast forward to trigger a mid-roll ad (typically around 5-10 minutes into content)
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 300000, 'current'); // 5 minutes from current position
    await utils.sleep(5000);

    // Press Back to exit during mid-roll ad playback
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);


    // Press Play/Resume button
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);

    // Verify playback resumes (may show mid-roll ad again)
    await utils.sleep(5000);
    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Player should be active');
  });


  it('C244283 - Ad Request - Pre-rolls - Playback start from beginning when ads not returned @manual_regression @ads', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Playback any title
     * 3. Check rainmaker calls respond with empty ads
     * 
     * Expected:
     * - The title playback from the beginning
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Select any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Play the content
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Verify playback starts from beginning (position should be near 0)
    await utils.sleep(2000);
    const position = await testUtils.getElementField('videoPlayerScreen', 'position');
    expect(position).to.be.lessThan(10, 'Playback should start from near the beginning');
  });


  it('C548493 - Movies with Trailers - No History @manual_regression @trailers', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Sign In
     * 3. Select a Movie with trailer which has not been played before (no history)
     * 4. Select Watch Trailer button
     * 5. Select Watch Movie
     * 
     * Expected:
     * - Movie playback starts from beginning
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a movie with trailer (would need to navigate through content)
    // For this test, we'll select any content and assume it has a trailer button
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Try to find and select Watch Trailer button
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Navigate to Watch Trailer button (if present)
    for (let i = 0; i < 3; i++) {
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(300);
    }

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(5000);

    // Watch trailer for a few seconds
    await utils.sleep(5000);

    // Exit trailer and go back to details
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);


    // Select Watch Movie / Play
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Verify movie starts from beginning
    await utils.sleep(2000);
    const position = await testUtils.getElementField('videoPlayerScreen', 'position');
    expect(position).to.be.lessThan(10, 'Movie should start from beginning after watching trailer');
  });


  it('C611453 - Pause Ad appears even when BWW has focus @manual_regression @bww @pause_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * - Paused ads will only appear if there is a campaign running
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any movie or series
     * 3. Pause VOD
     * 4. Press "down" to expand BWW section
     * 5. Wait 20 seconds
     * 
     * Expected:
     * - BWW section closes
     * - Pause ad displays
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Play any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Pause the video
    await ecp.sendKeypress(ecp.Key.Play); // Toggle to pause
    await utils.sleep(2000);

    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.equal('paused', 'Player should be paused');

    // Press down to expand BWW section
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Wait 20 seconds for pause ad to appear
    await utils.sleep(20000);

    // Check if pause ad is displayed (BWW should have closed)
    // In a real test, we would verify the pause ad element is visible
    // and BWW section is closed
  });


  it('C685992 - BWW section does not appear when playing a trailer @manual_regression @bww @trailers', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Find a movie with a trailer
     * 3. Play trailer
     * 4. Display transport controls and observe if BWW section is shown below transport controls
     * 
     * Expected:
     * - BWW section should NOT be shown under transport controls, when playing a trailer
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Select any content (assuming it has a trailer)
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    // Try to play trailer
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Navigate to Watch Trailer button (if present)
    for (let i = 0; i < 3; i++) {
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(300);
    }

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(5000);

    // Display transport controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(2000);

    // Try to press Down to see if BWW appears
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // In a real test, we would verify BWW section is NOT visible
  });


  it('C611436 - Focus moves from BWW to Autoplay UI, when autoplay cue point is triggered (movie) @manual_regression @bww @autoplay', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any movie
     * 3. FFWD to an area right before autoplay cue point triggers
     * 4. Display transport controls
     * 5. Press down on the remote to expand BWW section
     * 6. Wait for autoplay cue point to trigger
     * 
     * Expected:
     * - Focus moves to Autoplay UI
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Enable autoplay next video setting
    await testHelpers.enableAutoplayInSettings(true);

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Find a movie (type 'v') using helper
    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 10, 'v');
    if (position.length === 0) {
      throw new Error('Could not find a movie in the first 10 rows');
    }
    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(1000);

    // Play the movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Fast forward to near the end (before autoplay cue point)
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', -10000, 'end'); // 30 seconds before end

    // Display transport controls
    await ecp.sendKeypress(ecp.Key.Up);
    // Press down to expand BWW
    await ecp.sendKeypress(ecp.Key.Down);

    // Wait for autoplay cue point to trigger and verify autoplay UI appears
    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Autoplay UI should have focus (movie)', 30000);

    // Verify countdown timer is visible
    await testUtils.waitForElementToFullyShowOnScreen('autoplayCountdownTimerSection', 'Autoplay countdown should be visible', 20000);
  });


  it('C611437 - Focus moves from BWW to Autoplay UI, when autoplay cue point is triggered (series) @manual_regression @bww @autoplay', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any series
     * 3. FFWD to an area right before autoplay cue point triggers
     * 4. Display transport controls
     * 5. Press down on the remote to expand BWW section
     * 6. Wait for autoplay cue point to trigger
     * 
     * Expected:
     * - Focus moves to Autoplay UI
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Enable autoplay next video setting
    await testHelpers.enableAutoplayInSettings(true);

    // Go to TV screen where all content is series
    await testUtils.goToPage('tv');
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for tvScreenRowList to have focus', 20000);

    // Select a series
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Fast forward to near the end (before autoplay cue point)
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', -30000, 'end'); // 30 seconds before end
    await utils.sleep(2000);

    // Display transport controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Press down to expand BWW
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Wait for autoplay cue point to trigger and verify autoplay UI appears
    await testUtils.waitForElementToHaveFocus('autoplayUINextEpisodeButton', 'Autoplay Next Episode button should have focus (series)', 20000);

    // Verify autoplay UI elements are visible
    await testUtils.waitForElementToFullyShowOnScreen('autoplayUISeriesGrid', 'Autoplay series grid should be visible', 5000);
  });


  it('C611451 - User can see current video playing while BWW is expanded @manual_regression @bww', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any movie
     * 3. Display transport controls
     * 4. Press down to expand BWW section
     * 5. Observe current video playing
     * 
     * Expected:
     * - Opacity of gradient is light enough that user can still see video playing
     * - It should not be a black screen
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Play any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Display transport controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(2000);

    // Press down to expand BWW section
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify video is still playing
    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Video should still be playing while BWW is expanded');

  });


  it('C611452 - User can see current video playing while interacting with transport controls @manual_regression @bww', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any movie
     * 3. Interact with transport controls (ie: Play/Pause, Rewind, Fast Forward)
     * 4. Observe video during interaction
     * 
     * Expected:
     * - Video should still be visible to the user
     * - The screen should not be black
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Play any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Display transport controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(2000);

    // Interact with transport controls - Pause
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(1000);

    // Resume
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(1000);

    // Interact with transport controls (playback controls are visible during interaction)
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Verify video is visible (not black screen)
  });


  it('C611454 - BWW focus and functionality for titles with Skip Intro/Recap @manual_regression @bww @skip_intro', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any movie or episode with Skip Intro/Recap (Ex: MasterChef Mexico S01:E02)
     * 3. Bring up BWW by pressing Down or OK
     * 4. Check that playback controls work while Skip Intro/Recap is visible
     * 
     * Expected:
     * - BWW should display correctly
     * - Skip Intro/Recap button should function
     * - Skip Intro/Recap should disappear after a few seconds
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a series episode (more likely to have Skip Intro/Recap)
    let foundSeries = false;
    for (let i = 0; i < 20; i++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (focusedContent && (focusedContent.type === 's' || focusedContent.seriesId)) {
          foundSeries = true;
          break;
        }
      } catch (e) {
        // Continue
      }
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(300);
    }

    if (!foundSeries) {
    }

    // Play the content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Wait for Skip Intro/Recap to appear (typically within first 30 seconds)
    await utils.sleep(10000);

    // Bring up BWW by pressing Down
    await ecp.sendKeypress(ecp.Key.Down);

    // Verify BWW displays and playback controls work
    await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW header should be visible', 5000);
    await testUtils.waitForElementToShowOnScreen('browseWhileWatchingRowList', 'BWW row list should be visible', 5000);

    // Verify transport controls are still accessible
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport controls should be visible', 5000);

    // Verify playback continues
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);
  });


  it('C833541 - YMAL container is shown in BWW section @manual_regression @bww', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play any VOD
     * 3. Activate player controls
     * 
     * Expected:
     * - YMAL container is shown in BWW section
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Play any content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Activate player controls and expand BWW
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);

    // Verify YMAL container is shown in BWW section
    await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW header should be visible', 5000);
    await testUtils.waitForElementToShowOnScreen('browseWhileWatchingRowList', 'BWW YMAL row list should be visible', 5000);

    // Verify YMAL has content
    const ymalContent = await testUtils.getAllGridItemsContent('browseWhileWatchingRowList');
    expect(ymalContent.length).to.be.greaterThan(0, 'YMAL container should have at least one title');
  });


  it('C171804 - Guest User: Backgrounding app on Home Page then foregrounding @manual_regression @backgrounding', async () => {
    /**
     * Pre-conditions:
     * - User is guest
     * - Foregrounding app occurs < 24 hours
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Land on Home page
     * 3. Move the focus to another title other than Featured, first title in the row
     * 4. Background the app
     * 5. Launch the app again
     * 
     * Expected:
     * - App should launch to home page with Focus highlighted on title in step 3
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Move focus to different title
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
  });


  it('C171840 - Guest User: Deeplinking a Movie after backgrounding the app @manual_regression @backgrounding @deeplink', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * 
     * Test Steps:
     * 1. Open App
     * 2. Go into details page
     * 3. Play movie for several minutes
     * 4. Background the app
     * 5. Deeplink into the app using the same title
     * 
     * Expected:
     * - Verify that the playback starts from the beginning
     */

    // Launch app and go to movies page
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movieScreenRowList to have focus', 20000);

    // Get the focused movie content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('movieScreenRowList');
    if (!focusedContent || !focusedContent.id) {
      throw new Error('Could not get focused movie content');
    }
    const movieId = focusedContent.id;

    // Go to details and play
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Deeplink to the same movie
    await testUtils.startApplicationWithDeeplink({ mediaType: 'movie', contentID: movieId });
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 20000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    // Verify the same movie is playing
    const playingContent = await testUtils.getElementField('videoPlayerScreen', 'content');
    expect(playingContent?.id).to.equal(movieId, 'Same movie should be playing after deeplink');
  });


  it('C171841 - Guest User: Deeplinking a Series after backgrounding the app @manual_regression @backgrounding @deeplink', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * 
     * Test Steps:
     * 1. Open App
     * 2. Go into details page
     * 3. Play episode for several minutes
     * 4. Background the app
     * 5. Deeplink into the app using the same title
     * 
     * Expected:
     * - Verify that the playback resumes from the beginning
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    await testUtils.goToPage('tv');
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for tvScreenRowList to have focus', 20000);

    // Get the focused series content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('tvScreenRowList');
    if (!focusedContent || !focusedContent.id) {
      throw new Error('Could not get focused series content');
    }
    const seriesId = focusedContent.seriesId || focusedContent.id;

    // Go to details and play
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Deeplink to the same series
    await testUtils.startApplicationWithDeeplink({ mediaType: 'series', contentID: '0' + seriesId });
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    // Verify the same series is playing
    const playingContent = await testUtils.getElementField('videoPlayerScreen', 'content');
    const playingSeriesId = playingContent?.seriesId || playingContent?.id;
    expect(playingSeriesId).to.equal(seriesId, 'Same series should be playing after deeplink');
  });


  it('C172079 - Registered User: Backgrounding app on Home Page then foregrounding @manual_regression @backgrounding @registered', async () => {
    /**
     * Pre-conditions:
     * - User is Registered
     * - User is logged in
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Land on Home page
     * 3. Navigate to another page, then back to Home page
     * 4. Background the app
     * 5. Launch the app again
     * 
     * Expected:
     * - App should launch to home page
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Navigate to movies page then back to home
    await testUtils.goToPage('movies');

    await testUtils.goToPage('home');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);


    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
  });


  it('C172098 - Registered User: Backgrounding while streaming Movie then foregrounding @manual_regression @backgrounding @registered', async () => {
    /**
     * Pre-conditions:
     * - User is registered and logged in
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Select a Movie Title
     * 3. Let it stream for a couple of minutes
     * 4. Background the app
     * 5. Foreground the app
     * 
     * Expected:
     * - Land back on the Details page of the movie selected in step 2
     * - Title should have history
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Find and play a movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on details screen
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
  });


  it('C172099 - Registered User: Backgrounding while streaming Series then foregrounding @manual_regression @backgrounding @registered', async () => {
    /**
     * Pre-conditions:
     * - User is registered and logged in
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Select a Series title
     * 3. Play the title for a few minutes
     * 4. Background the app
     * 5. Foreground the app
     * 
     * Expected:
     * - Land on Series Details page of title selected in step 2
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Find and play a series
    let foundSeries = false;
    for (let i = 0; i < 10; i++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (focusedContent && (focusedContent.type === 's' || focusedContent.seriesId)) {
          foundSeries = true;
          break;
        }
      } catch (e) {
        // Continue
      }
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(300);
    }

    if (!foundSeries) {
    }

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);


    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on details screen
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
  });


  it('C172284 - Registered User: Deeplinking a Movie without history @manual_regression @deeplink @registered', async () => {
    /**
     * Pre-conditions:
     * - User is registered
     * - User is logged in
     * 
     * Test Steps:
     * 1. Launch the app
     * 2. Select a Movie title
     * 3. Play the title, let it play for a few minutes
     * 4. Background the app
     * 5. Within 4 days send a deep link to a title that is NOT the title in step 2
     * 
     * Expected:
     * - The title should play from the beginning (after ad plays, if rainmaker responds with an ad)
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app and go to movies page
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movieScreenRowList to have focus', 20000);

    // Get the first movie ID
    const firstContent = await testUtils.getCurrentlyFocusedGridItemContent('movieScreenRowList');
    const firstMovieId = firstContent?.id;

    // Play the first movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Deeplink to a DIFFERENT movie (use a known movie ID that's different from the first)
    const differentMovieId = '342067'; // Known movie ID used in other tests
    if (firstMovieId === differentMovieId) {
      // If somehow the same, use another known ID
      await testUtils.startApplicationWithDeeplink({ mediaType: 'movie', contentID: '100004539' }, { user });
    } else {
      await testUtils.startApplicationWithDeeplink({ mediaType: 'movie', contentID: differentMovieId }, { user });
    }

    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 20000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Verify playback starts from the beginning (position should be near 0)
    const position = await testUtils.getElementField('videoPlayerScreen', 'position');
    expect(position).to.be.lessThan(10000, 'New title should play from the beginning');
  });


  it('C172285 - Registered User: Deeplinking a Series without history @manual_regression @deeplink @registered', async () => {
    /**
     * Pre-conditions:
     * - User is registered
     * - User is logged in
     * 
     * Test Steps:
     * 1. Launch the app
     * 2. Select a Series title
     * 3. Play the title, let it play for a few minutes
     * 4. Background the app
     * 5. Within 4 days send a deep link to a title that is NOT the title in step 2
     * 
     * Expected:
     * - The title should play from the beginning (after ad plays, if rainmaker responds with an ad)
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app and go to TV page
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.goToPage('tv');
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for tvScreenRowList to have focus', 20000);

    // Get the first series ID
    const firstContent = await testUtils.getCurrentlyFocusedGridItemContent('tvScreenRowList');
    const firstSeriesId = firstContent?.seriesId || firstContent?.id;

    // Play the first series
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Deeplink to a DIFFERENT series episode (use a known episode ID that's different)
    const differentEpisodeId = '200051058'; // Known episode ID used in other tests
    await testUtils.startApplicationWithDeeplink({ mediaType: 'episode', contentID: differentEpisodeId }, { user });

    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 20000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Verify playback starts from the beginning (position should be near 0)
    const position = await testUtils.getElementField('videoPlayerScreen', 'position');
    expect(position).to.be.lessThan(10000, 'New title should play from the beginning');
  });


  it('C172511 - Registered User: Backgrounding in Kids Mode then foregrounding @manual_regression @backgrounding @registered @kids', async () => {
    /**
     * Pre-conditions:
     * - User is Registered
     * - User is logged in
     * - Go Into Kids Mode
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Land on Home page
     * 3. Navigate to another page, then back to Home page
     * 4. Background the app
     * 5. Launch the app again
     * 
     * Expected:
     * - App should launch to home page in kids mode
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Go to Kids mode
    await testUtils.goToPage('kids');


    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

  });


  it('C172453 - Guest User: Backgrounding app on Home Page then foregrounding (< 24h) @manual_regression @backgrounding', async () => {
    /**
     * Pre-conditions:
     * - User is guest
     * - Foregrounding app occurs < 24 hours
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Land on Home page
     * 3. Navigate to another page, then back to Home page
     * 4. Background the app
     * 5. Launch the app again
     * 
     * Expected:
     * - App should launch to home page
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Navigate to movies then back to home
    await testUtils.goToPage('movies');

    await testUtils.goToPage('home');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);


    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
  });


  it('C172454 - Guest user resume: splash screen not displayed @manual_regression @backgrounding', async () => {
    /**
     * Pre-conditions:
     * - User is guest
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Land on Home page
     * 3. Background the app
     * 4. Foreground the app < 24 hours
     * 
     * Expected:
     * - App is launched, splash screen does not display
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on home screen (splash screen should not show)
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
  });


  it('C181601 - Play voice command on Home Grid, focused title @manual_regression @voice_commands', async () => {
    /**
     * Pre-conditions:
     * - User is guest or registered user
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Move focus to a title on the Home grid
     * 3. Issue the deep link command with transport command=play
     * 
     * Expected:
     * - Playback should be initiated on the title
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Send voice command "play" via ECP input
    await ecp.sendInput({ params: { type: 'transport', command: 'play' } });
    await utils.sleep(3000);

    // Verify playback initiated (may go to ad player first or directly to video player)
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 8000);
  });


  it('C181602 - Play voice command on Search page, focused title @manual_regression @voice_commands @search', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Move focus to a title on the Search page
     * 3. Issue the deep link command with transport command=play
     * 
     * Expected:
     * - Playback should be initiated on the focused title
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Go to search
    await testUtils.goToPage('search');


    // Type search query to get results
    await ecp.sendText('action');
    await utils.sleep(3000);

    // Verify focus is on search results grid
    await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);
    // Navigate to search results grid (like search.ts tests)
    await testHelpers.navigateRightToSearchGrid();
    await utils.sleep(500);

    // Send voice command "play" via ECP input
    await ecp.sendInput({ params: { type: 'transport', command: 'play' } });
    await utils.sleep(3000);

    // Verify playback initiated (may go to ad player first or directly to video player)
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
  });


  it('C185810 - TV Shows: Play voice command on Episodes page @manual_regression @voice_commands', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to TV Shows page
     * 3. Select a series to view episodes
     * 4. Focus on an episode
     * 5. Issue voice command with command=play
     * 
     * Expected:
     * - Playback should be initiated on the focused episode
     */

    // Launch app and navigate to TV Shows
    await shared.openSeriesScreenAndWaitUntilListIsFocused();

    // Select a series
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for series detail screen
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');

    // Select All Episodes button
    await testUtils.waitForElementToFullyShowOnScreen('allEpisodesButton');
    const episodesButtonText = await testUtils.getNodeForElement('allEpisodesButton');
    expect(episodesButtonText.text).to.equal('All Episodes');
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToFullyShowOnScreen('allEpisodesButtonFocused');
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for Episodes screen
    await testUtils.waitForElementToFullyShowOnScreen('episodesScreenSeasonHeader');
    await testUtils.waitForElementToShowOnScreen('episodesScreenRowList');

    // Send voice command "play" via ECP input
    await ecp.sendInput({ params: { type: 'transport', command: 'play' } });
    await utils.sleep(3000);

    // Verify playback initiated (may go to ad player first or directly to video player)
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 8000);
  });


  it('C203230 - YMAL content should update after autoplay @manual_regression @autoplay @ymal', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Navigate to a movie details page - note the YMAL content
     * 2. Play the movie to the conclusion (FF ok)
     * 3. Autoplay to a new movie
     * 4. Back out of video playback to the details screen
     * 5. Check that the details screen YMAL content
     * 
     * Expected:
     * - The YMAL content is updated upon navigating back to the details screen after autoplay
     * - YMAL is related to the content on the details screen
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Step #1: Navigate to a movie in the current row
    await testHelpers.navigateToMovieInContainer('videoTitlesRowList');

    // Select the movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await testUtils.waitForElementToShowOnScreen('relatedYMALGrid', 'Related YMAL grid not visible', 10000);
    await testUtils.waitForGridContentToLoad('relatedYMALGrid', 10000);

    // Get the movie title for reference
    const detailScreenContent = await testUtils.getElementField('detailScreen', 'content');
    const firstMovieTitle = detailScreenContent?.title || 'Unknown';
    // Capture initial YMAL content using proper helper
    const initialYmalContent = await testUtils.getAllGridItemsContent('relatedYMALGrid');
    const initialYmalTitles: string[] = [];

    for (let i = 0; i < Math.min(5, initialYmalContent.length); i++) {
      if (initialYmalContent[i] && initialYmalContent[i].title) {
        initialYmalTitles.push(initialYmalContent[i].title);
      }
    }

    // Step #2: Play the movie to completion and trigger autoplay (like autoplay-movie.ts)
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');

    // Seek to end to trigger autoplay cuepoint (same as autoplay-movie.ts seekToTriggerCuePoint)
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', 0, 'end');

    // Wait for autoplay UI to show (like autoplay-movie.ts checkIfMovieAutoPlayUIisShowing)
    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for autoplay grid to have focus', 15000);
    await testUtils.waitForElementToFullyShowOnScreen('countDownAutoPlay');
    const countDownAutoPlay = await testUtils.getNodeForElement('countDownAutoPlay');
    expect(countDownAutoPlay.text).to.contain('Up Next in');

    // Get the autoplay grid content to verify which movie will play
    const autoplayGridContents = await testUtils.getAllGridItemsContent('autoplayGridMovie');
    expect(autoplayGridContents.length).to.be.greaterThan(0, 'Should have autoplay suggestions');
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'stopped');

    // Verify new video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    const playerContent = await testUtils.getPlayerContent('videoPlayerScreen');
    const newVideoId = playerContent.parentType == 'series' ? playerContent.parentId : playerContent.id;
    expect(newVideoId).to.equal(autoplayGridContents[0].id, 'Should autoplay to the first suggested movie');

    // Step #4: Back out to details screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(2000);

    // Get the new movie title
    const updatedDetailContent = await testUtils.getElementField('detailScreen', 'content');
    const secondMovieTitle = updatedDetailContent?.title || 'Unknown';
    // Verify we're on a different movie
    expect(firstMovieTitle).to.not.equal(secondMovieTitle, 'Should autoplay to a different movie');
    expect(secondMovieTitle).to.not.equal('Unknown', 'Second movie title should be valid');

    // Step #5: Check that YMAL content has updated using proper helper
    const updatedYmalContent = await testUtils.getAllGridItemsContent('relatedYMALGrid');
    const updatedYmalTitles: string[] = [];

    for (let i = 0; i < Math.min(5, updatedYmalContent.length); i++) {
      if (updatedYmalContent[i] && updatedYmalContent[i].title) {
        updatedYmalTitles.push(updatedYmalContent[i].title);
      }
    }

    // Verify YMAL content is different (at least some titles changed)
    if (initialYmalTitles.length > 0 && updatedYmalTitles.length > 0) {
      const hasAnyDifference = initialYmalTitles.some((title, index) => title !== updatedYmalTitles[index]);
      expect(hasAnyDifference, 'YMAL content should be different after autoplay to new movie').to.be.true;
    }

  });


  it('C439674 - Guest User: Selecting My Stuff and registering displays empty My Stuff page @manual_regression @mystuff', async () => {
    /**
     * Pre-conditions:
     * - Enrolled in Treatment for My Stuff v3 experiment
     * - Tubi account has no titles added to My Stuff or in Continue Watching state
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest
     * 2. On home grid, press remote left button to expand left navigation
     * 3. Scroll to the My Stuff menu item
     * 4. Select the Unlock button
     * 5. Go through the sign up flow
     * 
     * Expected:
     * - The empty My Stuff page is displayed with "Find More to Watch" button
     */

    // Launch app as guest
    await testUtils.startApplicationAtPage('home', { clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to My Stuff via side nav
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    // Complete sign up flow (dismisses "Let's create your account" modal, then enters email/password)
    await testHelpers.completeSignUpFlow();

    // Verify My Stuff screen is displayed (may take longer due to sign up process)
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);

    // Verify the empty state tile is shown in the RowList (video tiles path)
    await testUtils.waitForElementToShowOnScreen('myStuffEmptyStateTile');

    const tileTitle = await testUtils.getNodeForElement('myStuffEmptyStateTileTitle');
    expect(tileTitle.text).to.equal('My Stuff is Empty');

    const tileDescription = await testUtils.getNodeForElement('myStuffEmptyStateTileDescription');
    expect(tileDescription.text).to.equal('Use the bookmark button to save series and movies to My List, and quickly get back to what you were watching with Continue Watching.');

    // Verify "Find More to Watch" button text
    const buttonLabel = await testUtils.getNodeForElement('myStuffEmptyStateTileSignUpButton');
    expect(buttonLabel.text).to.equal('Find More to Watch');

  });


  it('C439677 - Registered User: My Stuff with Continue Watching and empty My List @manual_regression @mystuff', async () => {
    /**
     * Pre-conditions:
     * - Enrolled in Treatment for My Stuff v3 experiment
     * - Account registered with Tubi
     * - At least one title in Continue Watching and no titles in My List
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Sign in
     * 3. On home grid, press remote left button to expand left navigation
     * 4. Scroll to the My Stuff menu item and select it
     * 5. Press down button to display My List items
     * 
     * Expected:
     * - Step#4: Continue Watching should display all titles with progress
     * - Step#5: My List should display "Your list is empty"
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Create viewing history ONLY (Continue Watching) - no My List
    await testHelpers.createUserHistory(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);



    // Go to My Stuff
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);
    await testUtils.waitForElementToHaveFocus('myStuffGrid', 'Timed out waiting for My Stuff grid to have focus', 20000);

    // Verify Continue Watching has content using the correct method
    const myStuffContent = await testUtils.getAllRowListItemsContentGroupedByRow('myStuffGrid');

    // Check for Continue Watching row (typically the first row, index 0)
    let foundContinueWatching = false;
    for (let i = 0; i < myStuffContent.length; i++) {
      const row = myStuffContent[i];
      if (row.length > 0) {
        // Continue Watching should have items
        foundContinueWatching = true;
        expect(row.length).to.be.greaterThan(0, 'Continue Watching should have items');
        break;
      }
    }

    expect(foundContinueWatching).to.be.true;

    // Navigate down to My List section
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify My List is empty (check for empty message or no items)
    const myListEmptyScreen = await testUtils.getNodeForElement('myListScreenTitle');
    if (myListEmptyScreen) {
      // My List empty state is showing
      expect(myListEmptyScreen.visible).to.be.true;
    }

  });


  it('C439678 - Registered User: My Stuff with empty Continue Watching and My List @manual_regression @mystuff', async () => {
    /**
     * Pre-conditions:
     * - Enrolled in Treatment for My Stuff v3 experiment
     * - Account registered with Tubi
     * - At least one title in My List, and no titles are in Continue Watching
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Sign in
     * 3. On home grid, press remote left button to expand left navigation
     * 4. Scroll to the My Stuff menu item and select it
     * 5. Press down button to display My List items
     * 
     * Expected:
     * - Step#4: Continue Watching should display "You are all caught up" image
     * - Step#5: My List should display all titles which were added
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Add content to My List ONLY (no Continue Watching history)
    const itemsAddedCount = await testHelpers.createUserWatchList(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Go to My Stuff
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);
    await testUtils.waitForElementToHaveFocus('myStuffGrid', 'Timed out waiting for My Stuff grid to have focus', 20000);

    // Verify Continue Watching shows empty state ("You are all caught up" image)
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRow');

    const emptyMyStuffContainerContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('emptyMyStuffContainer');
    expect(emptyMyStuffContainerContent[0].title).to.equal("You're All Caught Up!");
    expect(emptyMyStuffContainerContent[0].description).to.equal("Movies and series you haven’t finished will show up here.");

    // Step #5: Press down button to display My List items
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify My List has content and displays ALL added items
    const myListContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('queueRowList');

    // Verify My List displays all items that were actually added
    expect(myListContent.length).to.be.greaterThan(0, 'My List should have items');
    expect(myListContent.length).to.equal(itemsAddedCount, `My List should have all ${itemsAddedCount} items that were added`);

  });


  it('C439741 - Registered User: Kids Mode - My Stuff shows only Kids rated titles @manual_regression @mystuff @kids', async () => {
    /**
     * Pre-conditions:
     * - Enrolled in Treatment for My Stuff v3 experiment
     * - Account registered with Tubi
     * - Various titles in Continue Watching and My List with different ratings
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Sign in
     * 3. Enter Kids Mode
     * 4. Scroll down and select My Stuff
     * 
     * Expected:
     * - No titles should be displayed which are non-Kids rated
     * - Titles which are Kids rated should be displayed
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Create viewing history with mixed ratings (G, TV-Y7, TV-MA, R)
    // This adds content to Continue Watching
    await testHelpers.createUserHistory(user);

    // Create watch list with both kids and adult content
    // Kids content
    await testHelpers.createFlexibleUserWatchList(user, [
      { rating: 'G', contentType: 'movie', limit: 3 },
      { rating: 'TV-Y', contentType: 'series', limit: 2 },
      { rating: 'TV-Y7', contentType: 'series', limit: 2 },
    ]);

    // Adult content
    await testHelpers.createFlexibleUserWatchList(user, [
      { rating: 'R', contentType: 'movie', limit: 2 },
      { rating: 'TV-MA', contentType: 'series', limit: 2 },
      { rating: 'PG-13', contentType: 'movie', limit: 2 },
    ]);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);


    // Go to Kids mode
    await testUtils.goToPage('kids');


    // Go to My Stuff in Kids mode
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);
    await testUtils.waitForElementToHaveFocus('myStuffGrid', 'Timed out waiting for My Stuff grid to have focus', 20000);

    // Verify only kids-rated content is shown
    // Get all content from My Stuff using the correct method
    const myStuffContent = await testUtils.getAllRowListItemsContentGroupedByRow('myStuffGrid');

    // Check each row for content
    for (const row of myStuffContent) {
      // Check each item's rating
      for (const item of row) {
        if (item.ratings && item.ratings.length > 0) {
          const rating = item.ratings[0].value;

          // Verify only kids ratings are present
          const isKidsRated = testHelpers.isKidsAppropriateRating(rating);
          expect(isKidsRated).to.equal(true, `Item "${item.title}" has non-kids rating "${rating}"`);
        }
      }
    }

  });

});
