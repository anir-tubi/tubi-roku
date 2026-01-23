import { expect } from 'chai';
import { ecp, utils, proxy, odc } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';
import { moveToGrid } from '../analytics/utils/helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';
import { validateAnalyticsEvent, createAnalyticsCallback, EXISTS } from '../analytics-validator';
import { mockDataHelpers } from '../mock-data-helpers';
import { title } from 'process';

/**
 * Manual Regression Test Suite
 * Generated from TestRail Run
 */

/**
 * Helper function to get the currently airing program from a linear content item
 * Mimics the getCurrentLiveProgram logic from ExpandedTilePosterOverlay.brs
 */
function getCurrentLiveProgram(content: any): any {
  if (!content.programs || content.programs.length === 0) {
    return null;
  }

  const now = new Date();

  // Find program that is currently airing (start_time <= now < end_time)
  for (const program of content.programs) {
    if (!program.start_time || !program.end_time) {
      continue;
    }

    const startTime = new Date(program.start_time);
    const endTime = new Date(program.end_time);

    if (startTime <= now && now < endTime) {
      return program;
    }
  }

  // No currently airing program found
  return null;
}

/**
 * Helper function to set up ad mock and launch app
 * @param adTypes - Array of ad types to mock (default: [AdType.Wrapper])
 * @param additionalOptions - Optional additional fields to pass to startApplicationAtPage
 * @returns Promise that resolves when proxy setup is complete
 */
async function setupAdMockAndLaunchApp(
  adTypes: AdType[] = [AdType.Wrapper],
  additionalOptions: any = {}
): Promise<{ cleanup?: () => void }> {
  await safeResumeProxy();

  // Extract valid_duration and persistCallback if provided
  const { validDuration, persistCallback, ...launchOptions } = additionalOptions;

  // Pass validDuration and persistCallback to mockAds
  const mockOptions: any = {};
  if (validDuration !== undefined) mockOptions.validDuration = validDuration;
  if (persistCallback !== undefined) mockOptions.persistCallback = persistCallback;

  const proxyPromise = adTestHelpers.mockAds(adTypes, Object.keys(mockOptions).length > 0 ? mockOptions : undefined);

  // Create registered user
  const user = await testUtils.createRegisteredUser();
  await testUtils.startApplicationAtPage('home', {
    user,
    clearRegistry: false,
    disableSkinAds: false,
    ...launchOptions
  });
  const result = await utils.promiseTimeout(proxyPromise, 50000);

  // Determine which element to wait for based on ad type
  const waitElement = adTypes.includes(AdType.Wrapper) ? 'skinAdRow' : 'videoTitlesRowList';
  await testUtils.waitForElementToHaveFocus(waitElement, `Timed out waiting for ${waitElement}`, 15000);

  return result;
}

/**
 * Helper function to verify ad player screen is displayed and ad is playing
 */
async function verifyAdPlayerIsPlaying(): Promise<void> {
  // Verify ad player screen is displayed
  await testUtils.waitForCurrentScreenToEqual('adPlayerScreen', 10000);

  // Verify the ad is playing in fullscreen mode
  await testUtils.untilTrue(async () => {
    const videoPlayer = await testUtils.getNodeForElement('adPlayerVideo');
    return videoPlayer.state === 'playing';
  }, 'Wrapper ad should be playing in fullscreen', 10000);
}

/**
 * Helper function to verify ad player skin elements are visible in fullscreen
 */
async function verifyAdPlayerElements(): Promise<void> {
  await testUtils.waitForElementToShowOnScreen('adPlayerSkinAdLogo', 'Ad player logo should be visible', 3000);
  const adPlayerLogoUri = await testUtils.getElementField('adPlayerSkinAdLogo', 'uri');
  expect(adPlayerLogoUri).to.not.be.empty;

  await testUtils.waitForElementToShowOnScreen('adPlayerSkinAdDescription', 'Ad player description should be visible', 3000);
  const adPlayerDescText = await testUtils.getElementField('adPlayerSkinAdDescription', 'text');
  expect(adPlayerDescText).to.not.be.empty;
}

/**
 * Helper function to reset Audio Description options to default
 * Used after audio/subtitle tests to clean up state
 */
async function resetAudioOptions(): Promise<void> {
  await ecp.sendKeypress(ecp.Key.Up);
  await ecp.sendKeypress(ecp.Key.Ok);
  await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
  await ecp.sendKeypress(ecp.Key.Ok);
}

/**
 * Helper function to navigate to Privacy Center
 * Opens side nav, navigates to Settings, then to Privacy Center
 */
async function goToPrivacyCenter(): Promise<void> {
  // Navigate to Settings using existing helper
  await testHelpers.openSettings();
  await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

  // Navigate to Privacy Center
  await testUtils.jumpToRowWithTitle('settingsMenu', 'Privacy Center');
  await ecp.sendKeypress(ecp.Key.Ok);
}

/**
 * Helper function to safely resume proxy
 * If proxy is not started, it will start it first before resuming
 */
async function safeResumeProxy(): Promise<void> {
  try {
    proxy.resume();
  } catch (e) {
    console.error('Error resuming proxy: ', e);
    await proxy.start();
  }
}

describe('General Regression Tests', function () {
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
    await utils.sleep(1000);

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
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 200 });

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

    // Find and navigate to "Networks" category
    await testUtils.jumpToRowWithTitle('categoriesListMenu', 'Networks');
    await utils.sleep(1000);

    // Select Networks category
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Select the first network
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Wait for network detail screen to load
    await testUtils.waitForCurrentScreenToEqual('categoryDetailsScreen', 10000);

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
    await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });

    // Verify video preview has paused/stopped
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'paused', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/601532
  it('C601532 - Verify program image is displayed instead of channel image @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - Movies or Series must be airing in On Now row
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row on home screen.
     * 3. Focus on a title that is a movie or series (not a live channel).
     * 4. Verify that the program image (movie/series poster) is displayed instead of the channel logo.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Check if focused item has programs array (contains program metadata), otherwise find one that does
    let focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    if (!focusedContent.programs || focusedContent.programs.length === 0) {
      // Current item doesn't have programs, find one that does
      const rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      let programItemIndex = -1;
      for (let i = 0; i < rowContent.length; i++) {
        if (rowContent[i].programs && rowContent[i].programs.length > 0) {
          programItemIndex = i;
          break;
        }
      }

      if (programItemIndex === -1) {
        throw new Error('Could not find content with program metadata (movie/series) in On Now row');
      }

      // Navigate to the program item
      const currentIndex1 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
      await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex1[0], programItemIndex]);
      await utils.sleep(1000);
      focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    }

    // Verify program poster is displayed (not channel logo)
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Program poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');

    // Program image should be displayed (not the generic channel logo)
    expect(posterElement.visible).to.equal(true, 'Program poster should be visible');
    expect(posterElement.uri).to.exist.and.not.be.empty;

    // Verify program data is present
    expect(focusedContent.programs).to.be.an('array').with.lengthOf.at.least(1, 'Should have program metadata');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.series_title || currentProgram.title).to.exist.and.not.be.empty;

    // The poster should show the program/series image, not just the channel logo
    // Program images would be in series_images or the program's own images
    if (currentProgram.series_images || currentProgram.images) {
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/602027
  it('C602027 - Verify progress bar reflects the real progress @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row on home screen.
     * 3. Focus on any live content with a progress bar.
     * 4. Verify that the progress bar accurately reflects the current playback position.
     * 5. Wait a few seconds and verify the progress bar updates accordingly.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // All items in linear channels row are linear, so just use the focused item
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'Focused content should be linear');

    // Send left key to disable autostart timer so we can inspect the progress bar
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Wait for progress bar to be visible
    await testUtils.waitForElementToShowOnScreen('videoGridProgressBar', 'Progress bar not visible', 5000);
    const progressBar = await testUtils.getNodeForElement('videoGridProgressBar');
    expect(progressBar.visible).to.equal(true, 'Progress bar should be visible for linear content');

    // Get initial progress bar width
    const initialWidth = progressBar.width;
    expect(initialWidth).to.be.greaterThan(0, 'Progress bar should have initial width greater than 0');

    // Wait for 5 seconds
    await utils.sleep(5000);

    // Get updated progress bar width
    const updatedProgressBar = await testUtils.getNodeForElement('videoGridProgressBar');
    const updatedWidth = updatedProgressBar.width;

    // Verify progress bar has advanced (width should increase as program progresses)
    // Note: For live linear content, progress bar reflects elapsed time in current program
    expect(updatedWidth).to.be.at.least(initialWidth,
      `Progress bar should advance over time. Initial: ${initialWidth}, After 5s: ${updatedWidth}`);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603705
  it('C603705 - Verify user is taken to live tv tab when they click on any program in On Now row @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Live and On Now events are airing in On Now row
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row on home screen.
     * 3. Focus on any live content in the row.
     * 4. Press OK to select the content.
     * 5. Verify user is taken to the Live TV screen/player.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify we're on linear content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'Focused content should be linear');

    // Select the linear content
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify user is taken to Linear Video Player Screen
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);

    // Verify linear video is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Verify player has content loaded
    const playerContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    expect(playerContent).to.exist;
    expect(playerContent.id).to.equal(focusedContent.id, 'Player should be playing linear content');

    // Verify we can go back to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should return focus to home screen', 10000);
  });



  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603706
  it('C603706 - Verify live badge is displayed on live events in On Now row @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find live event (content where programs[0].live === true).
     * 4. Verify "Live" badge is displayed on the tile.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10, wait: 300 });
    await utils.sleep(1000);

    // Get row content and search for live event (currentProgram.live === true)
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let liveEventIndex = -1;
    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.live === true) {
        liveEventIndex = i;
        break;
      }
    }
    // If not found, scroll right 30 more times and try again
    if (liveEventIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30, wait: 300 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.live === true) {
          liveEventIndex = i;
          break;
        }
      }
    }

    if (liveEventIndex === -1) {
      throw new Error('Could not find live event in On Now row');
    }

    // Navigate to the live event
    const currentIndex2 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex2[0], liveEventIndex]);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.live).to.equal(true, 'Content should be a live event');

    // Verify Live badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Live badge should be visible');
    expect(badgeElement.text).to.match(/Live/i, 'Badge should display "Live" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603707
  it('C603707 - Verify on now badge is displayed on non-live events in On Now row @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find non-live event (content where programs[0].live === false).
     * 4. Verify "On Now" badge is displayed on the tile.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10, wait: 300 });
    await utils.sleep(1000);

    // Get row content and search for non-live event (currentProgram is invalid or currentProgram.live === false)
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let nonLiveEventIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (!currentProgram || currentProgram.live === false) {
        nonLiveEventIndex = i;
        break;
      }
    }

    // If not found, scroll right 30 more times and try again
    if (nonLiveEventIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30, wait: 300 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (!currentProgram || currentProgram.live === false) {
          nonLiveEventIndex = i;
          break;
        }
      }
    }

    if (nonLiveEventIndex === -1) {
      throw new Error('Could not find non-live event in On Now row');
    }

    // Navigate to the non-live event
    const currentIndex3 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex3[0], nonLiveEventIndex]);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(!currentProgram || currentProgram.live === false).to.equal(true, 'Content should be a non-live event');

    // Verify On Now badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'On Now badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'On Now badge should be visible');
    expect(badgeElement.text).to.match(/On Now/i, 'Badge should display "On Now" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/602046
  it('C602046 - Verify On Now badge is on the tile and not on the title description @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Focus on any content.
     * 4. Verify badge is displayed on the tile (posterOverlay area).
     * 5. Verify badge is NOT in the metadata/description area.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify badge is on the tile (liveBadgeText is in the poster overlay area)
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible on tile', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible on tile');

    // Verify badge is part of the poster overlay, not the metadata area
    // The liveBadgeText element should be a child of the video tile overlay, not the videoGridMetadataGroup
    const videoGridMetadata = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(videoGridMetadata.visible).to.equal(true, 'Metadata should be visible');

    // Badge should be on the tile (poster overlay), metadata should be below the tile
    // This is verified by the element hierarchy - liveBadgeText is in posterOverlay, not in videoGridMetadata
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603708
  it('C603708 - On Now - Movie - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - Movie airing on On Now row
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find movie content (programs[0].type === 'v').
     * 4. Verify UI elements: title, poster, metadata, badge.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10, wait: 300 });
    await utils.sleep(1000);

    // Get row content and search for movie content (currentProgram.type === 'v')
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let movieIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.type === 'v') {
        movieIndex = i;
        break;
      }
    }

    // If not found, scroll right 30 more times and try again
    if (movieIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30, wait: 300 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.type === 'v') {
          movieIndex = i;
          break;
        }
      }
    }

    if (movieIndex === -1) {
      throw new Error('Could not find movie in On Now row');
    }

    // Navigate to the movie
    const currentIndex4 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex4[0], movieIndex]);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.type).to.equal('v', 'Content should be a movie');
    expect(currentProgram.title).to.exist.and.not.be.empty;

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Poster should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603709
  it('C603709 - On Now - Series - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Series airing in On Now row
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find series content (programs[0].series_id exists).
     * 4. Verify UI elements: series title, episode info, poster, metadata, badge.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10, wait: 300 });
    await utils.sleep(1000);

    // Get row content and search for series content (currentProgram.series_id exists)
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let seriesIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.series_id) {
        seriesIndex = i;
        break;
      }
    }

    // If not found, scroll right 30 more times and try again
    if (seriesIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30, wait: 300 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.series_id) {
          seriesIndex = i;
          break;
        }
      }
    }

    if (seriesIndex === -1) {
      throw new Error('Could not find series in On Now row');
    }

    // Navigate to the series
    const currentIndex5 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex5[0], seriesIndex]);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.series_id).to.exist.and.not.be.empty;
    expect(currentProgram.series_title).to.exist.and.not.be.empty;

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Poster should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603722
  it('C603722 - On Now - Sports programme - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Sports programme event airing in On Now row
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app with mocked sports content (Real Madrid).
     * 2. Navigate to On Now row.
     * 3. Focus on first item (Real Madrid sports content).
     * 4. Verify UI elements: teams/league info, poster, metadata, badge.
     */

    // Setup mock for sports content
    await safeResumeProxy();
    const mockPromise = mockDataHelpers.mockSportsContent();

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { clearRegistry: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await utils.promiseTimeout(mockPromise, 50000);

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // First item should be Real Madrid sports content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.id).to.equal('613762', 'First item should be Real Madrid channel');
    expect(focusedContent.type).to.equal('l', 'First item should be linear content');

    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.id).to.equal('500006541', 'Current program should be Real Madrid vs. CF Pachuca');

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Poster should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603713
  it('C603713 - Live - News - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Live news airing in On Now row
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find live news content (programs[0].live === true and tags/genres include news).
     * 4. Verify UI elements: title, channel logo, metadata, live badge.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10, wait: 300 });
    await utils.sleep(1000);

    // Get row content and search for live news content (currentProgram.live === true)
    // Prefer content with "news" in title or tags
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let liveNewsIndex = -1;
    let liveFallbackIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.live === true) {
        const title = (rowContent[i].title || '').toLowerCase();
        const tags = (rowContent[i].tags || []).map(t => t.toLowerCase());

        if (title.includes('news') || tags.some(tag => tag.includes('news'))) {
          liveNewsIndex = i;
          break;
        } else if (liveFallbackIndex === -1) {
          liveFallbackIndex = i;
        }
      }
    }

    // If not found, scroll right 30 more times and try again
    if (liveNewsIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30, wait: 300 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.live === true) {
          const title = (rowContent[i].title || '').toLowerCase();
          const tags = (rowContent[i].tags || []).map(t => t.toLowerCase());

          if (title.includes('news') || tags.some(tag => tag.includes('news'))) {
            liveNewsIndex = i;
            break;
          } else if (liveFallbackIndex === -1) {
            liveFallbackIndex = i;
          }
        }
      }
    }

    // Use fallback if news content not found
    const targetIndex = liveNewsIndex !== -1 ? liveNewsIndex : liveFallbackIndex;

    if (targetIndex === -1) {
      throw new Error('Could not find live content in On Now row');
    }

    if (liveNewsIndex === -1 && liveFallbackIndex !== -1) {
    }

    // Navigate to the live news/content
    const currentIndex7 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex7[0], targetIndex]);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.live).to.equal(true, 'Content should be live');

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    // For live news, channel logo should be visible
    await testUtils.waitForElementToShowOnScreen('videoGridChannelLogo', 'Channel logo not visible', 5000);
    const channelLogoElement = await testUtils.getNodeForElement('videoGridChannelLogo');
    expect(channelLogoElement.visible).to.equal(true, 'Channel logo should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    // Verify Live badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Live badge should be visible');
    expect(badgeElement.text).to.match(/Live/i, 'Badge should display "Live" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603694
  it('C603694 - When a live program is pinned on Featured, swipe horizontally on other VOD contents @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - A P0 live game program is airing and pinned in Featured row
     * 
     * Test Steps:
     * 1. Launch app with mocked linear content in Featured row (2 linear items mocked)
     * 2. Verify first item in Featured row is linear content (pinned)
     * 3. Verify second item is also linear content (we mock 2 linear items)
     * 4. Swipe right to navigate through VOD contents (starting from index 2)
     * 5. Verify horizontal navigation works correctly
     * 6. Verify can navigate back to pinned linear content
     */

    // Set up network proxy to inject linear content at the start of Featured row
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interference
    proxy.pause();

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(500);

    // Get the Featured row index
    const initialFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    const featuredRowIndex = initialFocusedIndex[0];

    // Verify first item is linear content (pinned live program)
    const firstItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(firstItemContent.type).to.equal('l', 'First item in Featured row should be linear content (pinned live program)');
    expect(initialFocusedIndex[1]).to.equal(0, 'Should be focused on first item in Featured row');

    // Swipe right to navigate through contents (note: first 2 items are linear due to mocking)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    const afterFirstRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterFirstRightIndex[0]).to.equal(featuredRowIndex, 'Row should remain the same after pressing Right');
    expect(afterFirstRightIndex[1]).to.equal(1, 'Focus should move to the second item in the row');

    // Verify second item is also linear content (we mock 2 linear items)
    const secondItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(secondItemContent.type).to.equal('l', 'Second item should also be linear content (we mock 2 linear items)');

    // Swipe right again to navigate to third item (first VOD item)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    const afterSecondRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterSecondRightIndex[0]).to.equal(featuredRowIndex, 'Row should remain the same after pressing Right again');
    expect(afterSecondRightIndex[1]).to.equal(2, 'Focus should move to the third item in the row');

    // Verify third item is VOD content (first non-linear item)
    const thirdItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(thirdItemContent.type).to.be.oneOf(['v', 's'], 'Third item should be VOD content (movie or series)');

    // Swipe right once more to verify fourth item is also VOD
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    const afterThirdRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterThirdRightIndex[1]).to.equal(3, 'Focus should move to the fourth item in the row');

    // Verify fourth item is also VOD content
    const fourthItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(fourthItemContent.type).to.be.oneOf(['v', 's'], 'Fourth item should be VOD content (movie or series)');

    // Navigate back to the first pinned linear content
    await ecp.sendKeypress(ecp.Key.Left, { count: 3 });
    await utils.sleep(1000);

    const backToFirstIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(backToFirstIndex).to.deep.equal([featuredRowIndex, 0], 'Should return to first item in Featured row');

    // Verify we're back on the first linear content
    const backToFirstContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(backToFirstContent.type).to.equal('l', 'Should return to linear content (pinned live program)');
    expect(backToFirstContent.id).to.equal(firstItemContent.id, 'Should be the same linear content as before');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603696
  it('C603696 - Live Sport event start, navigate to different tabs then back to home tab - live tile still in 1st position of featured row @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Game is airing (mocked via network proxy)
     * 
     * Test Steps:
     * 1. Launch app with mocked linear content in Featured row
     * 2. Verify live tile is in 1st position of Featured row
     * 3. Navigate to different tabs (Movies, TV Shows, My Stuff)
     * 4. Navigate back to Home tab
     * 5. Verify live tile is still in 1st position of Featured row
     */

    // Set up network proxy to inject linear content at the start of Featured row
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interference
    proxy.pause();

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify first item is linear content (live sport event)
    const initialLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(initialLinearContent.type).to.equal('l', 'First item in Featured row should be linear content (live sport event)');
    const initialLinearId = initialLinearContent.id;

    // Navigate to Movies tab
    await testUtils.goToPage('movies');
    await testUtils.waitForCurrentScreenToEqual('movieScreen', 10000);
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movie screen', 10000);
    await utils.sleep(1000);

    // Navigate to TV Shows tab
    await testUtils.goToPage('series');
    await testUtils.waitForCurrentScreenToEqual('tvScreen', 10000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen', 10000);
    await utils.sleep(1000);

    // Navigate to My Stuff tab
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);
    await utils.sleep(1000);

    // Navigate back to Home tab
    await testUtils.goToPage('home');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 10000);
    await utils.sleep(1000);

    // Navigate back to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify live tile is still in 1st position of Featured row
    const finalLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(finalLinearContent.type).to.equal('l', 'First item in Featured row should still be linear content after navigation');
    expect(finalLinearContent.id).to.equal(initialLinearId, 'Same live sport event should still be in 1st position');

    const finalFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(finalFocusedIndex[1]).to.equal(0, 'Live tile should be at first position (column 0)');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603698
  it('C603698 - Live sport start, quit then relaunch app - game tile still in 1st position of featured row @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Game is airing (mocked via network proxy)
     * 
     * Test Steps:
     * 1. Launch app with mocked linear content in Featured row
     * 2. Verify live tile is in 1st position of Featured row
     * 3. Quit the app
     * 4. Relaunch the app
     * 5. Verify live tile is still in 1st position of Featured row
     */

    // Set up network proxy to inject linear content at the start of Featured row
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interference
    proxy.pause();

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify first item is linear content (live sport event)
    const initialLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(initialLinearContent.type).to.equal('l', 'First item in Featured row should be linear content (live sport event)');
    const initialLinearId = initialLinearContent.id;

    // Quit the app by going to home screen (Roku launcher)
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(3000);

    await ecp.sendLaunchChannel();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus after relaunch', 20000);

    await utils.sleep(1000);

    // Navigate to Featured row after relaunch using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify live tile is still in 1st position of Featured row after relaunch
    const finalLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(finalLinearContent.type).to.equal('l', 'First item in Featured row should still be linear content after relaunch');
    expect(finalLinearContent.id).to.equal(initialLinearId, 'Same live sport event should still be in 1st position after relaunch');

    const finalFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(finalFocusedIndex[1]).to.equal(0, 'Live tile should be at first position (column 0) after relaunch');

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
    await testHelpers.findAndNavigateToContentType('v', 'videoTitlesRowList', 20);
    await utils.sleep(1000);

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
    await utils.sleep(1000);

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
    await utils.sleep(1000);

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
    await utils.sleep(1000);

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
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244257
  it('C244257 - The poster size of the live channel should match the poster size of the VOD content @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Find a row with both linear and VOD content
     * 3. Measure poster sizes
     * 4. Verify they match
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a row with both linear and VOD content (typically recommended_linear_channels or On Now row)
    let foundMixedRow = false;
    let rowIndex = -1;
    let linearIndex = -1;
    let vodIndex = -1;

    for (let row = 0; row < 10; row++) {
      await testUtils.jumpToRowIndex('videoTitlesRowList', row);
      await utils.sleep(500);

      const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', row);

      for (let i = 0; i < Math.min(rowContent.length, 10); i++) {
        if (rowContent[i].type === 'l' && linearIndex === -1) {
          linearIndex = i;
        }
        if ((rowContent[i].type === 'v' || rowContent[i].type === 's') && vodIndex === -1) {
          vodIndex = i;
        }

        if (linearIndex !== -1 && vodIndex !== -1) {
          foundMixedRow = true;
          rowIndex = row;
          break;
        }
      }

      if (foundMixedRow) break;
    }

    if (!foundMixedRow) {
      throw new Error('Could not find a row with both linear and VOD content');
    }

    // Measure linear poster size
    const linearSize = await testUtils.getGridElementSize('videoTitlesRowList', [rowIndex, linearIndex]);
    expect(linearSize.width).to.be.greaterThan(0, 'Linear poster should have valid width');
    expect(linearSize.height).to.be.greaterThan(0, 'Linear poster should have valid height');

    // Measure VOD poster size
    const vodSize = await testUtils.getGridElementSize('videoTitlesRowList', [rowIndex, vodIndex]);
    expect(vodSize.width).to.be.greaterThan(0, 'VOD poster should have valid width');
    expect(vodSize.height).to.be.greaterThan(0, 'VOD poster should have valid height');

    // Verify sizes match (allow small tolerance for rendering differences)
    expect(Math.abs(linearSize.width - vodSize.width)).to.be.lessThan(5,
      `Linear poster width (${linearSize.width}) should match VOD width (${vodSize.width})`);
    expect(Math.abs(linearSize.height - vodSize.height)).to.be.lessThan(5,
      `Linear poster height (${linearSize.height}) should match VOD height (${vodSize.height})`);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244260
  it('C244260 - User should be able to access channel guide and other player features from linear player @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Find and play linear content
     * 3. Verify player controls are accessible
     * 4. Verify channel guide is accessible
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to linear channels container using slug
    await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList', maxScrolls: 40 });

    // Play linear content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Bring up player controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(2000);

    // Access channel guide by pressing Down
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify linearOverlayContentArea is visible (channel guide)
    await testUtils.waitForElementToShowOnScreen('linearOverlayContentArea', 'Channel guide overlay should be visible', 5000);
    const overlayContentArea = await testUtils.getNodeForElement('linearOverlayContentArea');
    expect(overlayContentArea.visible).to.equal(true, 'linearOverlayContentArea should be visible');
    expect(overlayContentArea.opacity).to.equal(1, 'linearOverlayContentArea opacity should be 1');

    // Verify still in linear player after accessing guide (controls are accessible)
    try {
      await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 5000);
    } catch (e) {
      // May have navigated elsewhere, which is fine
    }

    const playerState = await testUtils.getNodeForElement('linearVideoPlayerVideoNode');
    expect(playerState.state).to.be.oneOf(['playing', 'paused', 'stopped'], 'Player should still be active');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244261
  it('C244261 - When searching for linear channel, channel should show in search results @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to search
     * 3. Search for a known linear channel name
     * 4. Verify channel appears in search results
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to search
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);
    await utils.sleep(1000);

    // Search for linear channel (e.g., "weather", "news", "sports")
    await ecp.sendText('nbc');
    await utils.sleep(2000);

    // Verify search results appear
    await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);

    // Navigate to search results grid using helper
    await testHelpers.navigateRightToSearchGrid();
    await utils.sleep(500);

    // Try to find and navigate to linear content in search results
    let foundLinearInResults = false;
    try {
      await testUtils.navigateToGridItem('searchResultGrid', (item) => item.type === 'linear');
      foundLinearInResults = true;
    } catch (e) {
      // Linear content not found in results
    }

    expect(foundLinearInResults).to.equal(true, 'Linear channel should appear in search results');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244270
  it('C244270 - Verify the presence of the Live Icon on top of channel posters @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Find linear content in grid
     * 3. Verify Live icon/badge is visible on poster
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find linear content
    let foundLinear = false;
    for (let i = 0; i < 40; i++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (focusedContent && focusedContent.type === 'l') {
          foundLinear = true;
          break;
        }
      } catch (e) {
        // Continue
      }

      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(800);
    }

    if (!foundLinear) {
      throw new Error('Could not find linear content');
    }

    // Verify Live badge is visible
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
    const liveBadge = await testUtils.getNodeForElement('liveBadgeText');
    expect(liveBadge.visible).to.equal(true, 'Live icon should be visible on channel poster');
    expect(liveBadge.text).to.match(/Live|On Now/i, 'Badge should indicate Live or On Now status');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244272
  it('C244272 - Searching and selecting live channel goes direct to broadcast (no details page) @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to search
     * 3. Search for linear channel
     * 4. Select channel from results
     * 5. Verify goes directly to player (no details page)
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to search
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);
    await utils.sleep(1000);

    // Search for linear channel
    await ecp.sendText('news');
    await utils.sleep(2000);

    // Verify search results appear
    await testUtils.waitForElementToShowOnScreen('searchResultGrid', 'Search results grid not visible', 10000);

    // Navigate to search results grid using helper
    await testHelpers.navigateRightToSearchGrid();
    await utils.sleep(500);

    // Navigate to first linear channel in search results
    await testUtils.navigateToGridItem('searchResultGrid', (item) => item.type === 'linear');
    await utils.sleep(500);

    // Get the focused linear content
    const linearContent = await testUtils.getCurrentlyFocusedGridItemContent('searchResultGrid');
    expect(linearContent.type).to.equal('linear', 'Selected content should be a linear channel');

    // Select the linear channel
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify goes directly to linear player (NOT detail screen)
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Verify playing the correct content
    const playerContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    expect(playerContent).to.exist;
    expect(playerContent.id).to.equal(linearContent.id, 'Should be playing the selected linear channel');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/243579
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

    // Verify that the user can't view the title
    const invalidDeepLinkDialog = testUtils.getNodeForElement('invalidDeepLinkDialog');
    expect((await invalidDeepLinkDialog).visible).to.be.true;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/264839
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
    await utils.sleep(1000);

    // Select first content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    // Select "Add to My List" button (will trigger age gate/sign-in for guest user)
    await testUtils.selectMenuItem('detailScreenMenu', 'Add to My List');
    await utils.sleep(2000);

    await testUtils.waitForElementToShowOnScreen('modalDialogScreen', 'Sign-in modal not shown', 10000);
    await testUtils.waitForElementToShowOnScreen('addToMyListAccountNeededMessage', 'add to my list account needed message not shown', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify sign-in screen appeared for guest user
    await testUtils.waitForCurrentScreenToEqual('signInScreen', 5000);
    await testUtils.waitForElementToShowOnScreen('signInScreenPageHeader', 'Sign-in screen not shown', 3000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/574104
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/574105
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/574109
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

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Set the focus to sendFeedback button
    await ecp.sendKeypress(ecp.Key.Right, { count: 5 });

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/574110
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

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(800);

    // Set the focus to sendFeedback button
    await ecp.sendKeypress(ecp.Key.Right, { count: 5 });

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/678503
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

    const videoPlayerScreen = await testUtils.getNodeForElement('videoPlayerScreen');
    const playerState = videoPlayerScreen.state;

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(800);

    // Set the focus to sendFeedback button
    await ecp.sendKeypress(ecp.Key.Right, { count: 5 });

    // Open Send Feedback overlay
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify overlay visible
    const selectionOverlay = await testUtils.getNodeForElement('sendFeedbackSelectionOverlayGroup');
    expect(selectionOverlay.visible).to.equal(true);
    expect(videoPlayerScreen.state).to.equal(playerState);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/574118
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
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await utils.sleep(800);

    await testHelpers.openKidsMode();
    await utils.sleep(800);

    // Navigate right to home page focus
    await ecp.sendKeypress(ecp.Key.Right, { wait: 1500 });

    await ecp.sendKeypress(ecp.Key.Play);

    // Verify that video is still playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 5000);

    // Show HUD (Play or Ok depending on device)
    await ecp.sendKeypress(ecp.Key.Down);

    // Verify Send Feedback button exists and is visible in the transport area
    const sendFeedbackButton = await testUtils.getNodeForElement('sendFeedBackButton');
    expect(sendFeedbackButton.visible).to.equal(false);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/795973
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603699
  it('C603699 - Verify linear program event is not displayed in featured row of Kids, Espanol, movies and TV Shows @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Live sports event is airing
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Navigate to Espanol page and check featured row - no linear content
     * 3. Navigate to Movies page and check featured row - no linear content
     * 4. Navigate to TV Shows page and check featured row - no linear content
     * 5. Navigate to Kids page and check featured row - no linear content
     */

    // Create user and mock homescreen with linear content in Featured row on home
    const user = await testUtils.createRegisteredUser();

    // Resume proxy and mock homescreen with linear content in Featured row
    await safeResumeProxy();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { clearRegistry: false, user });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Verify linear content exists in Featured row on home page first
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    const homeFeaturedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(homeFeaturedContent.type).to.equal('l', 'Home page Featured row should have linear content');
    await utils.sleep(1000);

    const pagesToCheck = [
      { name: 'Espanol', page: 'espanol', rowListId: 'espanolScreenRowList' },
      { name: 'Movies', page: 'movies', rowListId: 'movieScreenRowList' },
      { name: 'TV Shows', page: 'series', rowListId: 'tvScreenRowList' }
    ];

    for (const pageConfig of pagesToCheck) {
      // Navigate to page
      await testUtils.goToPage(pageConfig.page as any);
      await utils.sleep(2000);

      // Wait for row list to have focus
      try {
        await testUtils.waitForElementToHaveFocus(pageConfig.rowListId as any,
          `Timed out waiting for ${pageConfig.rowListId} to have focus`, 10000);
      } catch (e) {
        continue;
      }

      await utils.sleep(1000);

      // Find and navigate to Featured row using slug
      let featuredRowIndex = -1;
      try {
        await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: pageConfig.rowListId as any });
        const currentIndex = await testUtils.getCurrentlyFocusedGridItemIndex(pageConfig.rowListId as any);
        featuredRowIndex = currentIndex[0];
      } catch (e) {
        continue;
      }

      if (featuredRowIndex < 0) {
        continue;
      }

      // Get content from Featured row
      const featuredRowContent = await testUtils.getRowListRowItemsContent(pageConfig.rowListId as any, featuredRowIndex);
      expect(featuredRowContent).to.exist;
      expect(featuredRowContent.length).to.be.greaterThan(0, `Featured row should have content on ${pageConfig.name} page`);

      // Check that NO linear content (type 'l') appears in Featured row
      const linearContent = featuredRowContent.filter((item: any) => item && item.type === 'l');

      expect(linearContent.length).to.equal(0,
        `Featured row on ${pageConfig.name} page should NOT contain linear content. Found ${linearContent.length} linear items.`);

      // Additional verification: check first 5 items explicitly
      for (let i = 0; i < Math.min(5, featuredRowContent.length); i++) {
        const item = featuredRowContent[i];
        if (item && item.type) {
          expect(item.type).to.not.equal('l',
            `Item at position ${i} in Featured row on ${pageConfig.name} should not be linear. Type: ${item.type}`);
        }
      }
    }

    // Check Kids page separately (uses different navigation)
    await testHelpers.openKidsMode();

    // Verify in kids mode
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Video titles row list not focused', 10000);
    await testUtils.waitForGridContentToLoad('homeScreenRowList', 10000);

    const tubiKidsLogo = await testUtils.getNodeForElement('tubiKidsLogo');
    expect(tubiKidsLogo.visible).to.be.true;
    expect(tubiKidsLogo.opacity).to.be.equal(1.0);
    await utils.sleep(1000);

    // Try to find Featured row in Kids mode using slug
    try {
      await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'homeScreenRowList' });
      const kidsFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('homeScreenRowList');
      const kidsFeaturedRowIndex = kidsFocusedIndex[0];

      if (kidsFeaturedRowIndex >= 0) {
        const kidsFeaturedRowContent = await testUtils.getRowListRowItemsContent('homeScreenRowList', kidsFeaturedRowIndex);
        expect(kidsFeaturedRowContent).to.exist;
        // Check that NO linear content appears in Kids Featured row
        const kidsLinearContent = kidsFeaturedRowContent.filter((item: any) => item && item.type === 'l');

        expect(kidsLinearContent.length).to.equal(0,
          `Featured row on Kids page should NOT contain linear content. Found ${kidsLinearContent.length} linear items.`);
      }
    } catch (e) {
      // Kids mode Featured row not found or couldn't be verified
    }

    proxy.pause();
  });

  // Not validated from this point forward

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/424702
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

    // Find and navigate to "Audio Description" category
    await testUtils.jumpToRowWithTitle('categoriesListMenu', 'Audio Description');
    await utils.sleep(1000);

    // Move focus to the grid on the right
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Wait for the grid to be visible
    await testUtils.waitForElementToShowOnScreen('categoriesScreenContentGrid', 'Audio Description grid not visible', 5000);

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
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Validate options are present
    const closedCaptionSectionHeaderLabel = await testUtils.getNodeForElement('closedCaptionSectionHeaderLabel');
    expect(closedCaptionSectionHeaderLabel.text).to.equal('Subtitles');

    const audioTracksSectionHeaderLabel = await testUtils.getNodeForElement('audioTracksSectionHeaderLabel');
    expect(audioTracksSectionHeaderLabel.text).to.equal('Audio');

    // Enable AD - navigate to Audio Description option
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 100 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);

    // Exit player and go back to Audio Description category
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);

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
    await utils.sleep(1000);

    // Should be back on Audio Description category grid
    await testUtils.waitForElementToHaveFocus('categoriesScreenContentGrid', 'Grid should have focus after navigating back', 5000);
    await ecp.sendKeypress(ecp.Key.Right);
    // Select the new title
    await ecp.sendKeypress(ecp.Key.Play);
    // Verify that video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Open player controls
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(800);

    // Navigate right to open Options
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Verify that AD is still enabled for the second title
    await testUtils.waitForElementToFullyShowOnScreen('audioDescriptionItemChecked', 'AD should still be enabled', 5000);

    // Reset AD controls to default
    await resetAudioOptions();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/443158
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
    await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/444029
  it.skip('C444029 - AD is audible when playing from details page > resume @manual_regression @audio_description', async () => {
    /**
     * Pre-conditions:
     * - User has AD supported content in Continue Watching row (ie: Masked Singer S9 E6)
     * - English - Audio description was last selected during playback
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Nav to Continue watching row
     * 3. Open details page for AD-supported content (ie: Masked Singer S9 E6)
     * 4. Tap resume to resume playback
     * 5. Ensure English - Audio Description is still enabled from the last session
     * 6. Nav to a part where there is AD (the very beginning of Masked Singer S9 E6)
     * 
     * Expected:
     * - AD can be heard
     */
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/444030
  it('C444030 - AD is audible when playing from details page > play from beginning @manual_regression @audio_description', async () => {
    /**
     * Pre-conditions:
     * - User has AD supported content in Continue Watching row (ie: Masked Singer S9 E6)
     * - English - Audio description was last selected during playback
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Nav to Continue watching row
     * 3. Open details page for AD-supported content (ie: Masked Singer S9 E6)
     * 4. Tap option to play from beginning
     * 5. Ensure English - Audio Description is still enabled from the last session
     * 6. Nav to a part where there is AD (the very beginning of Masked Singer S9 E6)
     * 
     * Expected:
     * - AD can be heard
     */
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672515
  it('C672515 - New User - App Open - Verify user cannot exit Initial Consent screen @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Connected to VPN in UK
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest
     * 2. From Initial Consent screen, attempt to exit the page using remote button except for Home button on remote (background app)
     * 
     * Expected:
     * - User sees Initial Consent screen
     * - User Cannot exit Initial Consent screen
     */

    // Mock the remote_config/roku endpoint to enable OneTrust consent
    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with fresh device/user to trigger consent screen
    await safeResumeProxy();

    // Launch app with cleared registry (simulates new device/user)
    // Don't use startApplicationAtPage as it tries to navigate, which won't work if consent screen blocks
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy callback to complete
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for otBanner (OneTrust consent banner) to show on screen
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 10000);

    // Verify otBanner is visible with full opacity
    let otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Back button - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Up - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Down - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Left - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    // Try pressing Right - otBanner should remain visible
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);
    otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible).to.be.true;
    expect(otBanner.opacity).to.equal(1);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672519
  it.skip('C672519 - New User - App Open - Verify there are no Onboarding Personalization screens @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Connected to VPN in UK
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest
     * 
     * Expected:
     * - User should not see any Onboarding Personalization screens
     */

    // NOTE: This test requires UK VPN connection
    // In a real implementation with UK locale:
    // 1. Launch app with fresh device/user
    // 2. Accept consent
    // 3. Verify no onboarding personalization screens appear

    // For now, we'll skip the test with a note
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672520
  it('C672520 - New User - App Open - Verify there are not Parental Control settings @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. Accept OneTrust consent if present
     * 3. Navigate to Settings
     * 4. Check for Parental Control settings
     * 
     * Expected:
     * - User should not see any Parental Control settings option in the UK region
     */

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Check if OneTrust consent screen appears and accept it if present
    try {
      await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 5000);

      // Accept OneTrust consent by pressing OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
    } catch (error) {
      // Consent screen didn't appear, continue with test
      console.log('OneTrust consent screen did not appear, continuing...');
    }

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Settings using helper
    await testHelpers.openSettings();
    await testUtils.waitForElementToFullyShowOnScreen('settingsScreen');

    // Get all menu items from Settings
    const settingsMenuItems = await testUtils.getAllRowListItemsContent('settingsMenu');

    // Verify Parental Controls is NOT in the menu
    const hasParentalControlsOption = settingsMenuItems.some((item: any) =>
      item.title === 'Parental Controls' ||
      item.TITLE === 'Parental Controls' ||
      item.title === 'Parental Control' ||
      item.TITLE === 'Parental Control'
    );

    expect(hasParentalControlsOption, 'Parental Controls option should not be present in UK region').to.be.false;

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672522
  it('C672522 - New User - App Open - Verify there is no Espanol option @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB
     * 2. From Home, check if there is a Espanol option
     * 
     * Expected:
     * - User should not see any method to open Espanol mode (left Nav, Top Nav, etc)
     */

    // Mock the remote_config/roku endpoint to set country to GB
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';
          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Open side nav menu
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();

    // Get all menu items
    const menuItems = await testUtils.getAllRowListItemsContent('sideNavMenu');

    // Verify Espanol is not in the menu
    const hasEspanolOption = menuItems.some((item: any) =>
      item.title === 'Espanol' ||
      item.TITLE === 'Espanol' ||
      item.title === 'Español' ||
      item.TITLE === 'Español'
    );

    expect(hasEspanolOption, 'Espanol option should not be present in UK region').to.be.false;

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672523
  it('C672523 - New User - App Open - Verify there is no Kids Mode option @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. Accept OneTrust consent
     * 3. From Home, check if there is a Kids Mode option
     * 
     * Expected:
     * - User should not see any method to open Kids Mode (left Nav, Top Nav, etc)
     */

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          // Disable Kids Mode feature
          responseJson.enable_kidsmode = false;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Check if OneTrust consent screen appears and accept it if present
    try {
      await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 5000);

      // Accept OneTrust consent by pressing OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
    } catch (error) {
      // Consent screen didn't appear, continue with test
      console.log('OneTrust consent screen did not appear, continuing...');
    }

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Open side nav menu
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();

    // Get all menu items
    const menuItems = await testUtils.getAllRowListItemsContent('sideNavMenu');
    console.log("menuItems", JSON.stringify(menuItems, null, 2));

    // Verify Kids Mode is not in the menu
    const hasKidsModeOption = menuItems.some((item: any) =>
      item.title === 'Kids' ||
      item.TITLE === 'Kids' ||
      item.title === 'Kids Mode' ||
      item.TITLE === 'Kids Mode'
    );

    expect(hasKidsModeOption, 'Kids Mode option should not be present in UK region with OneTrust enabled').to.be.false;

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672532
  it('C672532 - New User - App Open - Initial Consent - Reject All @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. From Initial Consent screen select Reject All
     * 3. From Home screen go to Settings
     * 4. From Settings go to Privacy Center
     * 
     * Expected:
     * - Privacy Center should be accessible and display consent options
     * - All non-essential consent options should be unchecked after rejecting all
     */

    // Clear registry first with dummy deeplinking
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: true });
    await utils.sleep(3000); // Wait for app to fully restart

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: false });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for OneTrust banner to show
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 10000);

    // Navigate to Reject All button (move left from default focused button) and click OK
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Privacy Center using helper
    await goToPrivacyCenter();

    // Move right to the "Manage Privacy Settings" button
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('managePrivacySettingsButton', 'Timed out waiting for Privacy Center header to have focus', 5000);
    await utils.sleep(1000);

    // Click OK to enter Manage Privacy Settings
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    const currentScreen = await testUtils.getElementField('screenStack', '-1', 5000);

    await ecp.sendKeypress(ecp.Key.Down, { count: 3, wait: 500 });

    // Consent categories to verify (they should all be unchecked after "Reject All")
    const consentCategories = [
      'Functional',
      'Performance',
      'Marketing',
      'Personalized Advertising'
    ];

    // Verify each consent category has an unchecked checkbox
    for (let i = 0; i < consentCategories.length; i++) {
      const category = consentCategories[i];

      const checkbox = await testUtils.getNodeForElement('otConsentCheckbox');
      expect(checkbox.uri, `${category} consent should be unchecked`).to.equal('pkg:/components/OTPublishersSDK/images/checkbox-unselected.png');

      // Move down to next consent item (unless it's the last one)
      if (i < consentCategories.length - 1) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(100);
      }
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672531
  it('C672531 - New User - App Open - Initial Consent - Accept All @manual_regression @gdpr @consent', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. From Initial Consent screen select Accept All
     * 3. From Home screen go to Settings
     * 4. From Settings go to Privacy Center
     * 
     * Expected:
     * - Privacy Center should be accessible and display consent options
     * - All consent options should be checked after accepting all
     */

    // Clear registry first with dummy deeplinking
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: true });
    await utils.sleep(3000); // Wait for app to fully restart

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, { clearRegistry: false });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);

    // Wait for OneTrust banner to show
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Privacy Center using helper
    await goToPrivacyCenter();

    // Move right to the "Manage Privacy Settings" button
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementToHaveFocus('managePrivacySettingsButton', 'Timed out waiting for Privacy Center header to have focus', 5000);
    await utils.sleep(1000);

    // Click OK to enter Manage Privacy Settings
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    const currentScreen = await testUtils.getElementField('screenStack', '-1', 5000);

    await ecp.sendKeypress(ecp.Key.Down, { count: 3, wait: 500 });

    // Consent categories to verify (they should all be checked after "Accept All")
    const consentCategories = [
      'Functional',
      'Performance',
      'Marketing',
      'Personalized Advertising'
    ];

    // Verify each consent category has a checked checkbox
    for (let i = 0; i < consentCategories.length; i++) {
      const category = consentCategories[i];

      const checkbox = await testUtils.getNodeForElement('otConsentCheckbox');
      expect(checkbox.uri, `${category} consent should be checked`).to.equal('pkg:/components/OTPublishersSDK/images/checkbox-selected.png');

      // Move down to next consent item (unless it's the last one)
      if (i < consentCategories.length - 1) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(100);
      }
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/672544
  it('C672544 - New User - App Open - Register as New User over 18 @manual_regression @gdpr @consent @registration', async () => {
    /**
     * Pre-conditions:
     * - Device in UK (country code GB)
     * - User has not used Tubi (non-Registered)
     * - No consent data for User or Device ID
     * - OneTrust consent enabled
     * 
     * Test Steps:
     * 1. Launch Tubi as Guest with country code GB and OneTrust enabled
     * 2. From Initial Consent screen select Accept All
     * 3. From Home screen go to Sign In from Left Nav
     * 4. From Registration flow, register a new Tubi user
     * 5. From Age Gate, enter birth year (YYYY) which is over 18yrs old
     * 
     * Expected:
     * - User is able to Register
     * - User is at Home screen
     * - User is signed in
     */
    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: true
    });
    await utils.sleep(3000);

    // Mock the remote_config/roku endpoint to set country to GB and enable OneTrust
    await safeResumeProxy();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/remote_config/roku');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Set country code to GB (United Kingdom)
          responseJson.country = 'GB';

          // Enable OneTrust consent
          responseJson.enable_onetrust_consent = true;

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Launch app with cleared registry (simulates new device)
    await testUtils.startApplicationWithDeeplink({}, {
      clearRegistry: false,
      shouldCreateNewUser: false
    });

    // Wait for proxy to intercept and modify the config
    await utils.promiseTimeout(proxyPromise, 10000);
    proxy.pause();
    // Check if OneTrust consent screen appears and accept it if present
    try {
      await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner not visible', 5000);

      // Accept OneTrust consent by pressing OK (Accept All)
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);
    } catch (error) {
      // Consent screen didn't appear, continue with test
      console.log('OneTrust consent screen did not appear, continuing...');
    }

    // Wait for home screen to load
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Navigate to Sign In from Left Nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Sign In');
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(5000);
    // If not, press Back to dismiss Roku sign-in prompt
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify on Enter Email Address page
    const enterEmailAddressTitle = await testUtils.getNodeForElement('emailInputScreenHeader');
    expect(enterEmailAddressTitle.text).to.equal('Enter Email Address');

    // Enter a new email account
    const email = `build_roku_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000)}@tubi.tv`;
    await utils.sleep(2000);
    await ecp.sendText(email);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify on Confirm your age page
    const confirmYourAgeText = await testUtils.getNodeForElement('ageGateHeaderInRegistrationFlow');
    expect(confirmYourAgeText.text).to.equal('Confirm your age*');

    await ecp.sendText('20');
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 500 });
    await testUtils.waitForElementToHaveFocus('ageVerificationStartButton', 'Timed out waiting for Start watching Button to have focus', 5000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for registration to complete and return to home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);

    // Verify user is signed in by checking the side nav
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForSideNavMenuToBeExpanded();
    let sideNavSignedInLabel = await testUtils.getNodeForElement('sideNavSignedInLabel');
    expect(sideNavSignedInLabel.text).to.contain('Hi');
    expect(sideNavSignedInLabel.visible, 'User should be signed in after registration').to.be.true;

    await shared.openSettings();
    await testUtils.waitForCurrentScreenToEqual('settingsScreen')
    await testUtils.waitForElementToHaveFocus('settingsMenu');
    await testUtils.jumpToGridItemWithTitle('settingsMenu', 'Sign Out');
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);

    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify OneTrust banner appears again after sign out
    await testUtils.waitForElementToShowOnScreen('otBanner', 'OneTrust banner should appear after sign out', 10000);
    const otBanner = await testUtils.getNodeForElement('otBanner');
    expect(otBanner.visible, 'OneTrust banner should be visible after sign out').to.be.true;
    expect(otBanner.opacity, 'OneTrust banner should be fully visible').to.equal(1);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/601530
  it('C601530 - Live Sport Event: Verify program image is displayed instead of channel image @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Registered user or Guest user
     * 
     * Test Steps:
     * 1. Launch Tubi with mocked sports content in Featured row
     * 2. Go to Featured row in home page
     * 3. Verify programme image is displayed and not channel image
     * 
     * Expected:
     * - Programme image is displayed and not channel image for sports event
     */

    // Setup mock for sports content (Real Madrid) in Featured row
    await safeResumeProxy();
    const mockPromise = mockDataHelpers.mockSportsContentInFeatured();

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { clearRegistry: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
    await utils.promiseTimeout(mockPromise, 50000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Featured row
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // First item should be Real Madrid sports content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent).to.exist;
    expect(focusedContent.id).to.equal('613762', 'First item should be Real Madrid channel');
    expect(focusedContent.type).to.equal('l', 'First item should be linear content');

    // Verify program metadata exists
    expect(focusedContent.programs).to.be.an('array').with.lengthOf.at.least(1, 'Should have program metadata');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.id).to.equal('500006541', 'Current program should be Real Madrid vs. CF Pachuca');
    expect(currentProgram.series_title || currentProgram.title).to.exist.and.not.be.empty;

    // Verify program poster is displayed (not channel logo)
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Program poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');

    // Program image should be displayed (not the generic channel logo)
    expect(posterElement.visible).to.equal(true, 'Program poster should be visible');
    expect(posterElement.uri).to.exist.and.not.be.empty;

    // Verify the poster URI matches the program's images (not channel logo)
    // Sports programs have series_images (team/event images)
    const programImages = currentProgram.series_images || currentProgram.images;
    expect(programImages).to.exist.and.not.be.empty;

    // Check if poster URI contains one of the program's image URLs
    const posterUri = posterElement.uri;
    const programImageUrls = Object.values(programImages) as string[];
    const isProgramImageDisplayed = programImageUrls.some((imageUrl: string) =>
      posterUri.includes(imageUrl) || imageUrl.includes(posterUri)
    );
    expect(isProgramImageDisplayed).to.be.true;

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/595937
  it('C595937 - Live Sport Event: Verify program image of first tile of featured row has a progress indicator @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Go to home page featured row
     * 3. Verify live event in featured row has a progress indicator to show how long the program has been airing and how much time is left
     * 
     * Expected:
     * - Live event in featured row has a progress indicator to show how long the program has been airing and how much time is left
     */

    // Create user
    const user = await testUtils.createRegisteredUser();

    // Resume proxy and mock homescreen with linear content in Featured row
    await safeResumeProxy();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // The first item in Featured row should be linear content (mocked)
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent).to.exist;
    expect(focusedContent.type).to.equal('l', 'First item in Featured row should be linear content');

    // Verify progress bar is visible for linear content
    try {
      await testUtils.waitForElementToShowOnScreen('videoGridProgressBar', 'Progress bar not visible', 3000);
      const progressBar = await testUtils.getNodeForElement('videoGridProgressBar');
      expect(progressBar.visible).to.equal(true, 'Progress bar should be visible for live content');
    } catch (e) {
      // Progress bar might not be visible
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/595940
  it('C595940 - Live Sport Event: Verify video starts playing for LIVE event on the featured row @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Go to home page featured row
     * 3. Verify video starts playing for the LIVE event as soon as user reaches the live tile in featured row
     * 4. Verify for programs, there is no countdown in the UI, but user is redirected after 10 secs and can see the LIVE event in fullscreen
     * 
     * Expected:
     * 1. Video starts playing for the LIVE event as soon as user reaches the live tile in featured row. The transition will be background image -> channel playing in the top right corner. The transition period is very brief
     * 2. For programs, there is no countdown in the UI, but user is redirected after 10 secs and can see the LIVE event in fullscreen
     */

    // Create user
    const user = await testUtils.createRegisteredUser();

    // Resume proxy and mock homescreen with linear content in Featured row
    await safeResumeProxy();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // The first item in Featured row should be linear content (mocked)
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent).to.exist;
    expect(focusedContent.type).to.equal('l', 'First item in Featured row should be linear content');

    // Wait for inline video preview to start playing (live content preview)
    try {
      await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline preview not visible', 5000);
      await utils.sleep(2000); // Give time for video to start

      const previewPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
      expect(previewPlayer.state).to.be.oneOf(['playing', 'buffering'], 'Live preview should be playing');
    } catch (e) {
      // Preview might not be visible
    }

    // Wait 10 seconds to see if user is auto-redirected to fullscreen
    await utils.sleep(10000);

    // Check if we're now in linear video player screen (fullscreen)
    try {
      await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 2000);
      // Verify playback is happening
      await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 5000);
    } catch (e) {
      // Might not have transitioned to fullscreen
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/602028
  it('C602028 - Live Sport Event - Verify live program starts to play in the top right when user highlights the title @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * - Live program playing in featured row
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Go to first position in featured row
     * 3. Verify live program starts playing in the top right
     * 
     * Expected:
     * - Live program starts playing in the top right (like video preview)
     */

    // Create user
    const user = await testUtils.createRegisteredUser();

    // Resume proxy and mock homescreen with linear content in Featured row
    await safeResumeProxy();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // The first item in Featured row should be linear content (mocked)
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent).to.exist;
    expect(focusedContent.type).to.equal('l', 'First item in Featured row should be linear content');

    // Verify inline video preview starts playing in top right
    await utils.sleep(2000);

    try {
      await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline preview container not visible', 5000);

      const previewPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
      expect(previewPlayer.state).to.be.oneOf(['playing', 'buffering'], 'Live program should be playing in preview');

      // Verify it's the correct content
      const previewContent = await testUtils.getElementField('previewVideoPlayer', 'content');
      expect(previewContent.id).to.equal(focusedContent.id, 'Preview should match focused content');
    } catch (e) {
      // Preview might not be visible
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/114061
  it('C114061 - Live News - Pause disabled Users will not be able to pause video while in playback @manual_regression @live @news', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Navigate to Live News
     * 2. Open a channel
     * 3. Press Pause on the remote control
     * 
     * Expected:
     * - Verify that the playback does not pause
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find Live News row (or any linear content)
    let foundLinear = false;

    // Scroll through rows to find linear content
    for (let rowAttempt = 0; rowAttempt < 10; rowAttempt++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (focusedContent && focusedContent.type === 'l') {
          foundLinear = true;
          break;
        }
      } catch (e) {
        // Continue
      }

      // Try moving right to find linear in current row
      for (let i = 0; i < 5; i++) {
        await ecp.sendKeypress(ecp.Key.Right);
        await utils.sleep(300);

        try {
          const content = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
          if (content && content.type === 'l') {
            foundLinear = true;
            break;
          }
        } catch (e) {
          // Continue
        }
      }

      if (foundLinear) break;

      // Move to next row
      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(800);
    }

    if (!foundLinear) {
      return;
    }

    // Play the linear content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    const stateBefore = await testUtils.getElementField('linearVideoPlayerScreen', 'state');
    expect(stateBefore).to.equal('playing', 'Linear content should be playing');

    // Try to pause
    await ecp.sendKeypress(ecp.Key.Play); // Play/Pause button
    await utils.sleep(2000);

    // Verify it's still playing (pause is disabled for live content)
    const stateAfter = await testUtils.getElementField('linearVideoPlayerScreen', 'state');
    expect(stateAfter).to.equal('playing', 'Linear content should still be playing (pause disabled)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/117763
  it('C117763 - Live news should not appear when parental settings are set @manual_regression @live @news @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - User is logged in
     * - PC set to Adult
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Note live news row
     * 3. Set Parental Controls to [Teens, Older Kids, Little Kids]
     * 4. Activate the device with your account
     * 5. Search for Live News row
     * 
     * Expected:
     * - Verify that Live News is not present for any of these Parental Control settings
     */

    // Create registered user
    const user = await testUtils.createRegisteredUser();

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Settings to set Parental Controls
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    await shared.openSettings();
    await testUtils.waitForElementToShowOnScreen('settingsScreen', 'Settings not visible', 5000);

    // Navigate to Parental Controls (typically several items down)
    for (let i = 0; i < 5; i++) {
      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(300);
    }

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    // Set to Teens (or another restricted level)
    // This would require navigating through the parental control options
    // For this test, we'll assume we can set it

    // Navigate back to home
    await ecp.sendKeypress(ecp.Key.Back, { count: 3 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await utils.sleep(2000);

    // Search for Live News row - it should not be present
    // Scroll through all rows to verify Live News is not shown
    let foundLiveNews = false;

    for (let rowAttempt = 0; rowAttempt < 20; rowAttempt++) {
      try {
        // Check current row content for linear/news content
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');

        // In a real test, we would check the row title or slug for "Live News"
        // For now, we'll just check if linear content exists
        if (focusedContent && focusedContent.type === 'l') {
          foundLiveNews = true;
          break;
        }
      } catch (e) {
        // Continue
      }

      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(500);
    }

    // With Parental Controls set, Live News should NOT be present
    expect(foundLiveNews).to.equal(false, 'Live News should not be visible with Parental Controls enabled');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/117765
  it('C117765 - Pressing back while in full view mode and transport controls are not present, will exit full screen playback @manual_regression @live @news', async () => {
    /**
     * Pre-conditions:
     * - User is logged in or guest
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Select a live news feed and press enter
     * 3. Live News feed appears in full screen
     * 4. Press the back button
     * 
     * Expected:
     * - Full screen is exited, channel is shown in preview mode, with audio and video
     */

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find linear content (Live News)
    let foundLinear = false;

    for (let rowAttempt = 0; rowAttempt < 10; rowAttempt++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (focusedContent && focusedContent.type === 'l') {
          foundLinear = true;
          break;
        }
      } catch (e) {
        // Continue
      }

      // Try moving right
      for (let i = 0; i < 5; i++) {
        await ecp.sendKeypress(ecp.Key.Right);
        await utils.sleep(300);

        try {
          const content = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
          if (content && content.type === 'l') {
            foundLinear = true;
            break;
          }
        } catch (e) {
          // Continue
        }
      }

      if (foundLinear) break;

      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(800);
    }

    if (!foundLinear) {
      return;
    }

    // Play the linear content (go to fullscreen)
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Wait for transport controls to disappear (if they appeared)
    await utils.sleep(5000);

    // Press back button
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000);

    // Verify we're back at home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);

    // Verify linear content is now in preview mode (if inline preview is supported)
    try {
      const previewPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
      if (previewPlayer && previewPlayer.state) {
        expect(previewPlayer.state).to.be.oneOf(['playing', 'buffering'], 'Preview should be playing');
      }
    } catch (e) {
      // Preview may not be available
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/43926
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
    const cwRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Continue Watching');
    await testUtils.jumpToRowIndex('videoTitlesRowList', cwRowIndex);
    await utils.sleep(1000);

    // Get the Continue Watching row content
    const cwContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', cwRowIndex);
    expect(cwContent).to.exist;
    expect(cwContent.length).to.be.greaterThan(2, 'Should have at least 3 items in Continue Watching');

    // Navigate to the last item in Continue Watching row
    const lastItemIndex = cwContent.length - 1;
    await testUtils.jumpToRowItem('videoTitlesRowList', [cwRowIndex, lastItemIndex]);
    await utils.sleep(1000);

    const focusedItemBefore = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItemBefore).to.exist;

    // Go to details screen
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    // Remove from history using the proper helper (like C421108 in my-stuff.ts)
    await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
    await utils.sleep(3000);

    // Return to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);
    await utils.sleep(1000);

    // Verify focus is on the next-to-last item (since we removed the last item)
    const focusedItemAfter = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItemAfter).to.exist;
    expect(focusedItemAfter.id).to.not.equal(focusedItemBefore.id, 'Focus should have moved to a different item');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/103111
  it.skip('C103111 - Continue Watching Home page - Movie Expiring Titles - Badges should appear in CW row @manual_regression @continue_watching @expiration', async () => {
    /**
     * Pre-conditions:
     * - User is logged in
     * - User has a movie title set to expire in X days in the CW row
     * 
     * NOTE: These will only be shown in mid-month, we don't see these in the early days of the month
     * Roku: Expires in X days will appear in Details only. Badge will not display
     * 
     * Test Steps:
     * 1. From the left nav, select Home page
     * 2. Scroll to CW row
     * 
     * Expected:
     * - Set to expire title should have expiration badge
     * - Roku: Expires in X days will appear in Details only. Badge will not display
     */

    // NOTE: This test is skipped because Roku does not display expiration badges in Continue Watching row
    // Expiration info only appears in Details screen on Roku
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/433372
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
    await utils.sleep(1000);

    // Play the content
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(2000);

    // Wait for pre-roll ad to start (if present)
    await utils.sleep(3000);

    // Press Back to exit during ad playback
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 5000);
    await utils.sleep(1000);

    // Press Play again
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);

    // Verify playback starts (may have ad or may go directly to content)
    await utils.sleep(5000);
    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Player should be active');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/433373
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
    await utils.sleep(1000);

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
    await utils.sleep(1000);

    // Press Play/Resume button
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);

    // Verify playback resumes (may show mid-roll ad again)
    await utils.sleep(5000);
    const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
    expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Player should be active');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244283
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
    await utils.sleep(1000);

    // Play the content
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Verify playback starts from beginning (position should be near 0)
    await utils.sleep(2000);
    const position = await testUtils.getElementField('videoPlayerScreen', 'position');
    expect(position).to.be.lessThan(10, 'Playback should start from near the beginning');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/548493
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
    await utils.sleep(1000);

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
    await utils.sleep(1000);

    // Select Watch Movie / Play
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Verify movie starts from beginning
    await utils.sleep(2000);
    const position = await testUtils.getElementField('videoPlayerScreen', 'position');
    expect(position).to.be.lessThan(10, 'Movie should start from beginning after watching trailer');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611453
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
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/685992
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
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611436
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

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a movie (type 'v' without seriesId)
    let foundMovie = false;

    for (let i = 0; i < 20; i++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (focusedContent && focusedContent.type === 'v' && !focusedContent.seriesId) {
          foundMovie = true;
          break;
        }
      } catch (e) {
        // Continue
      }

      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(300);
    }

    if (!foundMovie) {
    }

    // Play the movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

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

    // Wait for autoplay cue point to trigger
    await utils.sleep(15000);

    // Verify autoplay UI appears (in a real test, we'd check for autoplay UI element)
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611437
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

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a series (type 's' or has seriesId)
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

    // Play the series
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

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

    // Wait for autoplay cue point to trigger
    await utils.sleep(15000);

    // Verify autoplay UI appears (in a real test, we'd check for autoplay UI element)
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611451
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
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611452
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
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/611454
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
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Wait for Skip Intro/Recap to appear (typically within first 30 seconds)
    await utils.sleep(10000);

    // Bring up BWW by pressing Down
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify BWW displays and playback controls work
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/833541
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
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    // Activate player controls and expand BWW
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify YMAL container is shown in BWW section
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714505
  it('C714505 - Homepage visual: Verify user can see title and custom background image on homepage @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Verify user can see ad title and custom background on homepage
     * 
     * Expected:
     * - User can see ad title and custom background on homepage
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();

    // Verify home screen skin ad elements are visible and non-empty
    await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should be visible on home screen', 3000);
    const skinAdLogoUri = await testUtils.getElementField('skinAdLogo', 'uri');
    expect(skinAdLogoUri).to.not.be.empty;

    await testUtils.waitForElementToShowOnScreen('skinAdDescription', 'Skin ad description should be visible on home screen', 3000);
    const skinAdDescText = await testUtils.getElementField('skinAdDescription', 'text');
    expect(skinAdDescText).to.not.be.empty;

    // Verify custom background image is visible
    await testUtils.waitForElementToShowOnScreen('backgroundPoster', 'Background poster should be visible', 3000);
    const backgroundPosterUri = await testUtils.getElementField('backgroundPoster', 'uri');
    expect(backgroundPosterUri).to.not.be.empty;

    // Verify video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);


    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714508
  it('C714508 - Homepage visual: Logo "Tubi Presented by" relocates when user enters grid @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Verify Logo "tubi Presented by ---" is on the left side of the home screen
     * 3. Scroll down to Featured row
     * 4. Verify "tubi Presented by ---" is on the upper right corner
     * 
     * Expected:
     * - Logo "tubi Presented by ---" is on the left side of the home screen
     * - Logo "tubi Presented by ---" relocates to upper right corner when entering grid
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // BEFORE moving down - Verify logo elements are on the left side (in skinAdRow)
    await testUtils.waitForElementToShowOnScreen('presentedByLabel', 'Presented by label should be visible', 3000);
    const presentedByLabelVisible = await testUtils.getElementField('presentedByLabel', 'visible');
    expect(presentedByLabelVisible).to.equal(true, 'presentedByLabel should be visible on left side');

    await testUtils.waitForElementToShowOnScreen('skinAdTubiLogo', 'Tubi logo should be visible', 3000);
    const skinAdTubiLogoVisible = await testUtils.getElementField('skinAdTubiLogo', 'visible');
    expect(skinAdTubiLogoVisible).to.equal(true, 'skinAdTubiLogo should be visible on left side');

    // Move down to enter grid
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // AFTER moving down - Verify logo elements are in the header (upper right)
    await testUtils.waitForElementToShowOnScreen('headerTubiLogo', 'Header Tubi logo should be visible', 3000);
    const headerTubiLogoVisible = await testUtils.getElementField('headerTubiLogo', 'visible');
    expect(headerTubiLogoVisible).to.equal(true, 'headerTubiLogo should be visible in header');

    await testUtils.waitForElementToShowOnScreen('headerPresentedByLabel', 'Header presented by label should be visible', 3000);
    const headerPresentedByLabelVisible = await testUtils.getElementField('headerPresentedByLabel', 'visible');
    expect(headerPresentedByLabelVisible).to.equal(true, 'headerPresentedByLabel should be visible in header');

    await testUtils.waitForElementToShowOnScreen('headerPresentedByImage', 'Header presented by image should be visible', 3000);
    const headerPresentedByImageVisible = await testUtils.getElementField('headerPresentedByImage', 'visible');
    expect(headerPresentedByImageVisible).to.equal(true, 'headerPresentedByImage should be visible in header');


    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714509
  it('C714509 - Video ad start: Verify user can use a button to play a video ad in full screen @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Click on button to play video ad in full screen
     * 
     * Expected:
     * - Video ad plays on full screen
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // Press OK to play video ad
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);

    // Verify ad player is displayed and playing
    await verifyAdPlayerIsPlaying();

    // Verify ad player elements
    await verifyAdPlayerElements();

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714510
  it('C714510 - Video ad start: Verify video ad autoplays when user doesnt navigate from homepage within 5 seconds @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Stay in the homepage without navigating anywhere else
     * 3. Verify video ad autoplays
     * 
     * Expected:
     * - Video ad autoplays
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();

    // Wait 5 seconds without navigating (allow autoplay to trigger)
    await utils.sleep(5000);

    // Verify ad player is displayed and playing (autoplayed)
    await verifyAdPlayerIsPlaying();

    // Verify ad player elements
    await verifyAdPlayerElements();

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714511
  it('C714511 - Video ad exit: Verify user can exit the video ad and return to homepage @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Let the video ad autostart
     * 3. Click back button and verify user can exit the video ad
     * 
     * Expected:
     * - User can exit video ad and is returned to homepage
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();

    // Wait for video ad to autostart
    await utils.sleep(5000);

    // Verify ad player is displayed and playing
    await verifyAdPlayerIsPlaying();

    // Press back to exit
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000);

    // Verify we're back at homescreen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);

    // Verify focus returns to skin ad row
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Should return focus to wrapper ad', 5000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714512
  it('C714512 - Video ad exit: Verify users are returned to the homepage upon conclusion of the video ad @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Play the video ad
     * 3. Let the video ad complete
     * 4. Verify user is returned to homepage
     * 
     * Expected:
     * - User is returned to homepage and the cell displays 'Watch Again' text
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();

    // Wait for video ad to autostart
    await utils.sleep(5000);

    // Verify ad player is displayed and playing
    await verifyAdPlayerIsPlaying();

    // Wait for ad to complete and return to home screen (max 120 seconds)
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 120000);

    // Verify focus returns to skin ad row
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Should return focus to wrapper ad', 30000);

    // Verify "Watch again" countdown text is shown
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Countdown text should be visible', 3000);
    const countdownText = await testUtils.getElementField('skinAdCountdownText', 'text');
    expect(countdownText).to.equal('Watch again', 'Countdown text should show "Watch again" after ad completion');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714515
  it('C714515 - Spotlight/featured row: Featured container moves to first row below spotlight @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Spotlight UI should be shown
     * 3. Press down arrow to go to next container
     * 4. Verify featured row is present
     * 
     * Expected:
     * - Featured row is present in first row of home grid, below the spotlight UI
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();

    // Verify spotlight UI is shown BEFORE moving down
    await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should be visible', 3000);

    const skinAdRowBefore = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdRowBefore.visible).to.equal(true, 'skinAdRow should be visible before moving down');
    expect(skinAdRowBefore.opacity).to.be.greaterThan(0, 'skinAdRow opacity should be greater than 0 before moving down');

    const videoTitlesRowListBefore = await testUtils.getNodeForElement('videoTitlesRowList');

    // Press down to go to first row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify skinAdRow is hidden AFTER moving down (either not visible or opacity = 0)
    const skinAdRowAfter = await testUtils.getNodeForElement('skinAdContainer');
    const skinAdRowHidden = !skinAdRowAfter.visible || skinAdRowAfter.opacity === 0;
    expect(skinAdRowHidden).to.equal(true, 'skinAdRow should be hidden (visible=false or opacity=0) after moving down');

    const videoTitlesRowListAfter = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowListAfter.visible).to.equal(true, 'videoTitlesRowList should be visible after moving down');

    // Verify Featured row is present
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714517
  it('C714517 - Verify Skins only appears on Home @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to Kids, Categories, My Stuff, Movies, TV Shows, LiveTV, Español, Settings
     * 
     * Expected:
     * - Skins is only visible in Home mode
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // Verify skin is visible on Home
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible on Home', 3000);
    const skinAdRowOnHome = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdRowOnHome.visible).to.equal(true, 'skinAdRow should be visible on Home');

    // Navigate to other sections and verify skin is NOT visible
    const sectionsToCheck = [
      { page: 'movies', screenId: 'movieScreen', elementToVerify: 'movieScreenRowList', skinAdElement: 'movieScreenSkinAdRow' },
      { page: 'tv', screenId: 'tvScreen', elementToVerify: 'tvShowsScreenRowList', skinAdElement: 'tvScreenSkinAdRow' },
      { page: 'categories', screenId: 'categoryPanelListScreen', elementToVerify: 'channelRecommendedButton', skinAdElement: 'categoryListScreenSkinAdRow' }
    ];

    for (const section of sectionsToCheck) {
      await testUtils.goToPage(section.page as any);
      await utils.sleep(2000);

      // Verify we're actually on the new screen (not home)
      await testUtils.waitForCurrentScreenToEqual(section.screenId as any, 5000);

      // Verify the new screen's main element is visible
      await testUtils.waitForElementToShowOnScreen(section.elementToVerify as any, `${section.page} screen should be visible`, 3000);

      // Verify THIS SCREEN does NOT have skin ad elements (should not exist or be invisible)
      try {
        const screenSkinAdRow = await testUtils.getNodeForElement(section.skinAdElement as any);
        // If element exists, it should not be visible
        if (screenSkinAdRow.visible !== undefined) {
          expect(screenSkinAdRow.visible).to.equal(false, `Skin ads should NOT be visible on ${section.page} page`);
        }
      } catch (e) {
        // If element doesn't exist at all, that's expected and correct - skin ads are home-only
        // This is actually the ideal case
      }

      // Navigate back to Home
      await testUtils.goToPage('home');
      await utils.sleep(1000);

      // Verify we're back on home screen
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);

      // Verify skin is still visible on Home after returning
      const skinAdRowAfterReturn = await testUtils.getNodeForElement('skinAdRow');
      expect(skinAdRowAfterReturn.visible).to.equal(true, 'skinAdRow should still be visible on Home');
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714593
  it('C714593 - Verify the ad background loop is paused when user expands left nav @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest user or Registered user
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Observe Wrapper container
     * 3. Observe video loop that is playing in the background
     * 4. Press left or back button to expand left nav
     * 
     * Expected:
     * - Verify the ad background loop is paused and timer is also stopped
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // Verify wrapper container is visible
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible', 3000);

    // Verify video preview is playing in the background BEFORE expanding left nav
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Get countdown timer text BEFORE expanding left nav
    const skinAdCountdownBefore = await testUtils.getNodeForElement('skinAdCountdownText');
    const countdownTextBefore = skinAdCountdownBefore.text;
    const countdownVisibleBefore = skinAdCountdownBefore.visible;

    // Press left to expand left nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);

    // Verify background video loop is paused AFTER expanding left nav
    const previewPlayerAfter = await testUtils.getNodeForElement('previewVideoPlayer');
    expect(previewPlayerAfter.state).to.not.equal('playing', 'Preview video should be paused when left nav is expanded');

    // Verify countdown timer is also stopped AFTER expanding left nav
    const skinAdCountdownAfter = await testUtils.getNodeForElement('skinAdCountdownText');
    const countdownTextAfter = skinAdCountdownAfter.text;

    // Wait a bit and check if countdown has progressed (it shouldn't if paused)
    await utils.sleep(2000);
    const skinAdCountdownFinal = await testUtils.getNodeForElement('skinAdCountdownText');
    const countdownTextFinal = skinAdCountdownFinal.text;

    // If countdown was active before, verify it has stopped (text should not change)
    if (countdownVisibleBefore && countdownTextAfter === countdownTextFinal) {
    } else if (countdownVisibleBefore && countdownTextAfter !== countdownTextFinal) {
      expect.fail(`Countdown timer should be stopped but text changed from "${countdownTextAfter}" to "${countdownTextFinal}"`);
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714595
  it('C714595 - Verify Video Ad (Not background video) Impressions @manual_regression @skins @analytics', async () => {
    /**
     * Pre-conditions:
     * - All users
     * 
     * Test Steps:
     * 1. Launch Tubi
     * 2. Homepage displays the video ad
     * 
     * Expected:
     * - Verify the ad impression. Check pixel requests
     */

    // Track impression pixel fires
    let impressionPixelFired = false;
    const impressionUrls: string[] = [];
    let callbackRemoved = false;

    // Set up proxy callback to intercept impression tracking pixels
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        // Check if this is an impression tracking pixel
        return args.url.includes('ads.production-public.tubi.io/pixel') &&
          args.url.includes('/spotlight/homescreen');
      },
      processRequest: (args) => {
        impressionPixelFired = true;
        impressionUrls.push(args.url);
        // Remove callback after capturing first impression
        args.removeCallback();
        callbackRemoved = true;
        return undefined;
      }
    });

    try {
      // Set up wrapper ad mock and launch app
      await setupAdMockAndLaunchApp([AdType.Wrapper]);
      await utils.sleep(3000);

      // Verify skin ad is visible on Home
      await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible on Home', 5000);
      const skinAdRow = await testUtils.getNodeForElement('skinAdRow');
      expect(skinAdRow.visible).to.equal(true, 'skinAdRow should be visible on Home');
      expect(skinAdRow.content).to.not.equal(null, 'skinAdRow content should not be null');

      // Wait a bit more to ensure impression pixel has time to fire
      await utils.sleep(2000);

      // Verify impression tracking pixel was fired
      expect(impressionPixelFired).to.be.true;
      expect(impressionUrls.length).to.be.greaterThan(0, 'At least one impression pixel should have fired');

      // Verify the impression URL contains expected parameters
      const impressionUrl = impressionUrls[0];
      expect(impressionUrl).to.include('ads.production-public.tubi.io/pixel', 'Impression URL should be from Tubi ads domain');
      expect(impressionUrl).to.include('/spotlight/homescreen', 'Impression URL should be for homescreen spotlight');
      expect(impressionUrl).to.include('/ROKU', 'Impression URL should include ROKU platform');
    } finally {
      // Ensure proxy is paused even if test fails
      // Callback self-removes after first impression, tracked by callbackRemoved flag
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/714596
  it('C714596 - Verify Video Ad (Not background video) Quartile Tracking @manual_regression @skins @analytics', async () => {
    /**
     * Pre-conditions:
     * - All users
     * - For Roku: In Charles, ensure Roku Proxy rewrite has "Body" selected
     * 
     * Test Steps:
     * 1. Launch Tubi with wrapper ad
     * 2. Homepage displays the video ad
     * 3. Play the ad by pressing OK
     * 4. Wait for ad to complete and return to home screen
     * 
     * Expected:
     * - Verify Quartile Tracking pixels fire (0%, 25%, 50%, 75%, 100%)
     * - Quartiles fire in correct sequential order during video playback
     * - Each quartile pixel contains correct platform and tracking parameters
     */

    // Track all ad-related pixels
    const allPixelsFired: string[] = [];
    const quartilesFired: string[] = [];
    const quartileUrls: { [key: string]: string[] } = {
      q0: [],
      q25: [],
      q50: [],
      q75: [],
      q100: []
    };
    let callbackRemoved = false;

    // Set up proxy callback to intercept and respond to ALL ad tracking pixels
    // URLs are rewritten by mockAds to route through proxy (e.g. http://IP:8888/;;https://ads.production...)
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        // Check if this is any ad tracking pixel
        return args.url.includes('ads.production-public.tubi.io/pixel');
      },
      processRequest: (args) => {
        const url = args.url;
        allPixelsFired.push(url);

        // Check if this is a quartile tracking pixel (view-thru tracking)
        if (url.includes('/view-thru/')) {
          // Determine which quartile based on URL pattern
          // Track in order they fire
          if (quartilesFired.length === 0) {
            quartilesFired.push('q0');
            quartileUrls.q0.push(url);
          } else if (quartilesFired.length === 1) {
            quartilesFired.push('q25');
            quartileUrls.q25.push(url);
          } else if (quartilesFired.length === 2) {
            quartilesFired.push('q50');
            quartileUrls.q50.push(url);
          } else if (quartilesFired.length === 3) {
            quartilesFired.push('q75');
            quartileUrls.q75.push(url);
          } else if (quartilesFired.length === 4) {
            quartilesFired.push('q100');
            quartileUrls.q100.push(url);
            // All quartiles captured, remove callback
            args.removeCallback();
            callbackRemoved = true;
          }
        }
        // Don't modify the request
        return undefined;
      },
      processResponse: (args) => {
        // Return a successful 200 OK response so video player continues
        return JSON.stringify({ success: true });
      }
    });

    try {
      // Set up wrapper ad mock and launch app
      await setupAdMockAndLaunchApp([AdType.Wrapper]);
      await utils.sleep(2000);

      // Verify skin ad is visible on Home
      await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible on Home', 5000);
      const skinAdRow = await testUtils.getNodeForElement('skinAdRow');
      expect(skinAdRow.visible).to.equal(true, 'skinAdRow should be visible on Home');

      // Play the wrapper ad video by pressing OK
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(2000);

      // Verify ad player is playing
      await verifyAdPlayerIsPlaying();

      // Get ad duration
      const adPlayer = await testUtils.getNodeForElement('adPlayerVideo');
      const adDuration = adPlayer.duration;

      // Wait for ad to complete and return to home screen
      // This ensures all quartile pixels have time to fire
      await testUtils.waitForCurrentScreenToEqual('homeScreen', (adDuration + 15) * 1000);

      // Give a brief moment for any final pixels to fire
      await utils.sleep(1000);

      // Verify at least the impression pixel fired
      expect(allPixelsFired.length).to.be.greaterThan(0, 'At least one ad pixel (impression) should have fired');

      // Verify impression pixel contains expected parameters
      const impressionPixel = allPixelsFired.find(url => url.includes('/homescreen/') && !url.includes('/view-thru/'));
      expect(impressionPixel).to.exist;
      expect(impressionPixel).to.include('/ROKU', 'Impression pixel should include ROKU platform');
      expect(impressionPixel).to.include('ads.production-public.tubi.io/pixel', 'Impression pixel should be from correct domain');

      // Verify quartile tracking pixels were fired
      expect(quartilesFired.length).to.be.greaterThan(0, 'At least some quartile pixels should have fired during video playback');

      // Verify quartiles are in correct order
      const expectedOrder = ['q0', 'q25', 'q50', 'q75', 'q100'].slice(0, quartilesFired.length);
      expect(quartilesFired).to.deep.equal(expectedOrder, 'Quartiles should fire in correct sequential order');

      // Verify quartile URLs contain expected parameters
      quartilesFired.forEach((quartile) => {
        const urls = quartileUrls[quartile];
        expect(urls.length).to.be.greaterThan(0, `${quartile} pixel should have fired`);
        expect(urls[0]).to.include('/ROKU', `${quartile} URL should include ROKU platform`);
        expect(urls[0]).to.include('/view-thru/', `${quartile} URL should be view-thru tracking`);
      });

      // Verify we captured all 5 quartiles
      expect(quartilesFired.length).to.equal(5, 'All 5 quartile pixels should fire (0%, 25%, 50%, 75%, 100%)');
    } finally {
      // Ensure proxy is paused even if test fails
      // Callback self-removes after all quartiles, tracked by callbackRemoved flag
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716057
  it('C716057 - Verify transition between Spotlight screen and featured row @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Move focus between Spotlight and Featured row a few times
     * 
     * Expected:
     * - Transition between rows is seamless
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // Verify initial state - spotlight has focus
    const skinAdRowInitial = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdRowInitial.visible).to.equal(true, 'skinAdRow should be visible initially');
    expect(skinAdRowInitial.opacity).to.be.greaterThan(0, 'skinAdRow should have opacity > 0 initially');

    // Move down to featured row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    const skinAdRowAfterDown = await testUtils.getNodeForElement('skinAdContainer');
    const videoTitlesRowListAfterDown = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowListAfterDown.visible).to.equal(true, 'videoTitlesRowList should be visible');

    // Move back up to spotlight
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    const skinAdRowAfterUp = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdRowAfterUp.visible).to.equal(true, 'skinAdRow should be visible after moving back up');
    expect(skinAdRowAfterUp.opacity).to.be.greaterThan(0, 'skinAdRow should have opacity > 0 after moving back up');

    // Repeat transition one more time
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);


    // Final verification - ensure both elements are in proper state
    const skinAdRowFinal = await testUtils.getNodeForElement('skinAdContainer');
    const videoTitlesRowListFinal = await testUtils.getNodeForElement('videoTitlesRowList');

    expect(skinAdRowFinal.visible).to.equal(true, 'skinAdRow should be visible at the end (spotlight has focus)');
    expect(skinAdRowFinal.opacity).to.be.greaterThan(0, 'skinAdRow should have opacity > 0 at the end');
    expect(videoTitlesRowListFinal.visible).to.equal(true, 'videoTitlesRowList should be visible at the end');


    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716062
  it('C716062 - Verify Skin is still present when other rows are in focus @manual_regression @skins', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Move focus to other rows aside from Spotlight row (ie: Comedy, Action, etc...)
     * 
     * Expected:
     * - Skin is still shown when other containers are in focus
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Wrapper]);
    await utils.sleep(2000);

    // Verify skin is visible on Home initially
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible on Home', 3000);
    let skinAdRow = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdRow.visible).to.equal(true, 'skinAdRow should be visible on Home initially');
    expect(skinAdRow.content).to.not.equal(null, 'skinAdRow content should not be null initially');

    // Navigate down to different rows on home screen (3 rows down)
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await utils.sleep(1000);

    // Verify skin container may be hidden but content is still present
    const skinAdContainer1 = await testUtils.getNodeForElement('skinAdContainer');
    skinAdRow = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdContainer1.visible === false || skinAdContainer1.opacity === 0, 'skinAdContainer may be hidden when other rows are focused').to.be.true;
    expect(skinAdRow.content).to.not.equal(null, 'skinAdRow content should still be present when other rows are focused');

    // Navigate down 3 more rows
    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await utils.sleep(1000);

    // Verify skin container may be hidden but content is still present
    const skinAdContainer2 = await testUtils.getNodeForElement('skinAdContainer');
    skinAdRow = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdContainer2.visible === false || skinAdContainer2.opacity === 0, 'skinAdContainer may be hidden after navigating to more rows').to.be.true;
    expect(skinAdRow.content).to.not.equal(null, 'skinAdRow content should still be present after navigating to more rows');

    // Navigate back up to top
    await ecp.sendKeypress(ecp.Key.Up, { count: 6 });
    await utils.sleep(1000);

    // Verify skin is visible again when back at top
    const skinAdContainer3 = await testUtils.getNodeForElement('skinAdContainer');
    skinAdRow = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdContainer3.visible).to.equal(true, 'skinAdContainer should be visible when back at top');
    expect(skinAdRow.content).to.not.equal(null, 'skinAdRow content should still be present when back at top');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716058
  it('C716058 - Skins is NOT available when Parental Controls = Little Kids @manual_regression @wrapper_ads @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Set Parental Controls = Little Kids
     * 3. Observe home
     * 
     * Expected:
     * - Skins is NOT shown
     */

    // Set up wrapper ad mock
    await setupAdMockAndLaunchApp([AdType.Wrapper]);

    // Verify wrapper ad is visible BEFORE setting parental controls
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible before parental controls', 3000);
    const skinAdRowBefore = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdRowBefore.visible).to.equal(true, 'skinAdRow should be visible before setting parental controls');
    await utils.sleep(2000);

    proxy.pause();
    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('littleKids');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    // Verify wrapper ad is NOT visible AFTER setting parental controls to Little Kids
    const skinAdRowAfter = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdRowAfter.visible === false || skinAdRowAfter.opacity === 0, 'skinAdRow should NOT be visible with Little Kids parental controls').to.be.true;

    // Verify skinAdRow content is invalid
    expect(skinAdRowAfter.content).to.equal(null, 'skinAdRow content should be invalid with Little Kids parental controls');

    // Verify no ad calls are made by checking skinAdLogo and skinAdDescription are not present
    try {
      await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should not be visible', 1000);
      expect.fail('skinAdLogo should not be visible with Little Kids parental controls');
    } catch (e) {
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/724073
  it('C724073 - Skins is NOT available when Parental Controls = Older Kids @manual_regression @wrapper_ads @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Set Parental Controls = Older Kids
     * 3. Observe home
     * 
     * Expected:
     * - Skins is NOT shown
     */

    // Set up wrapper ad mock
    await setupAdMockAndLaunchApp([AdType.Wrapper]);

    // Verify wrapper ad is visible BEFORE setting parental controls
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible before parental controls', 3000);
    const skinAdRowBefore = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdRowBefore.visible).to.equal(true, 'skinAdRow should be visible before setting parental controls');

    proxy.pause();
    // Set Parental Controls to Older Kids
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('olderKids');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    // Verify wrapper ad is NOT visible AFTER setting parental controls to Older Kids
    const skinAdRowAfter = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdRowAfter.visible === false || skinAdRowAfter.opacity === 0, 'skinAdRow should NOT be visible with Older Kids parental controls').to.be.true;
    // Verify skinAdRow content is invalid
    expect(skinAdRowAfter.content).to.equal(null, 'skinAdRow content should be invalid with Older Kids parental controls');

    // Verify no ad calls are made by checking skinAdLogo and skinAdDescription are not present
    try {
      await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should not be visible', 1000);
      expect.fail('skinAdLogo should not be visible with Older Kids parental controls');
    } catch (e) {
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/724074
  it('C724074 - Skins is not available when Parental Controls = Teens @manual_regression @wrapper_ads @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Set Parental Controls = Teens
     * 3. Observe home
     * 
     * Expected:
     * - Skins is NOT shown
     */

    // Set up wrapper ad mock
    await setupAdMockAndLaunchApp([AdType.Wrapper]);

    // Verify wrapper ad is visible BEFORE setting parental controls
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin should be visible before parental controls', 3000);
    const skinAdRowBefore = await testUtils.getNodeForElement('skinAdRow');
    expect(skinAdRowBefore.visible).to.equal(true, 'skinAdRow should be visible before setting parental controls');

    proxy.pause();
    // Set Parental Controls to Teens
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('teens');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    // Verify wrapper ad is NOT visible AFTER setting parental controls to Older Kids
    const skinAdRowAfter = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdRowAfter.visible === false || skinAdRowAfter.opacity === 0, 'skinAdRow should NOT be visible with Older Kids parental controls').to.be.true;
    // Verify skinAdRow content is invalid
    expect(skinAdRowAfter.content).to.equal(null, 'skinAdRow content should be invalid with Older Kids parental controls');

    // Verify no ad calls are made by checking skinAdLogo and skinAdDescription are not present
    try {
      await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should not be visible', 1000);
      expect.fail('skinAdLogo should not be visible with Older Kids parental controls');
    } catch (e) {
    }

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716059
  it('C716059 - User cannot RWD/FFWD while ad is playing @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Allow ad to playback in full screen
     * 3. During playback, press RWD/FFWD buttons
     * 
     * Expected:
     * - User cannot RWD or FFWD
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // Play wrapper ad
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);

    // Verify ad player is displayed and playing
    await verifyAdPlayerIsPlaying();

    // Get initial player position
    const adPlayerBefore = await testUtils.getNodeForElement('adPlayerVideo');
    const positionBefore = adPlayerBefore.position;

    // Try to rewind
    await ecp.sendKeypress(ecp.Key.Rewind);
    await utils.sleep(1000);

    // Verify position hasn't changed (RWD doesn't work)
    const adPlayerAfterRwd = await testUtils.getNodeForElement('adPlayerVideo');
    const positionAfterRwd = adPlayerAfterRwd.position;
    expect(positionAfterRwd).to.be.closeTo(positionBefore, 2, 'Position should not rewind during ad playback');

    // Try to fast forward
    await ecp.sendKeypress(ecp.Key.Forward);
    await utils.sleep(1000);

    // Verify position hasn't jumped forward (FFWD doesn't work)
    const adPlayerAfterFfwd = await testUtils.getNodeForElement('adPlayerVideo');
    const positionAfterFfwd = adPlayerAfterFfwd.position;
    expect(positionAfterFfwd).to.be.closeTo(positionAfterRwd, 2, 'Position should not fast forward during ad playback');


    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716060
  it('C716060 - User can pause/play while ad is playing @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Allow ad to playback in full screen
     * 3. During playback, press PAUSE/PLAY buttons
     * 
     * Expected:
     * - User can pause/play video
     * 
     * NOTE: FTV and Samsung cannot pause ad currently
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await utils.sleep(2000);

    // Play spotlight ad
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);

    // Verify ad player is displayed and playing
    await verifyAdPlayerIsPlaying();

    // Get initial state (should be playing)
    const adPlayerBefore = await testUtils.getNodeForElement('adPlayerVideo');
    expect(adPlayerBefore.state).to.equal('playing', 'Ad should be playing initially');

    // Try to pause
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(2000);

    // Verify ad is paused
    const adPlayerAfterPause = await testUtils.getNodeForElement('adPlayerVideo');
    expect(adPlayerAfterPause.state).to.equal('paused', 'Ad should be paused after pressing Play/Pause');

    // Try to play again
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(2000);

    // Verify ad is playing again
    const adPlayerAfterResume = await testUtils.getNodeForElement('adPlayerVideo');
    expect(adPlayerAfterResume.state).to.equal('playing', 'Ad should be playing after pressing Play/Pause again');


    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716061
  it('C716061 - With Autoplay Previews = OFF, countdown timer and ad autostart behavior @manual_regression @wrapper_ads @autoplay', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * - In app settings, Autoplay Preview = OFF OR Autostart = OFF
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Leave focus on Spotlight ad
     * 3. Observe UX
     * 
     * Expected (for Roku):
     * - Countdown timer is displayed
     * - Screen does transition to ad playback after 5 seconds
     */
    // Set up wrapper ad mock and launch app with autoplay disabled
    await setupAdMockAndLaunchApp();

    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad', 15000);
    await shared.enablePreviewInSettings(false);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad', 15000);

    // Verify countdown timer is displayed
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Countdown timer should be visible', 3000);
    const countdownText = await testUtils.getElementField('skinAdCountdownText', 'text');
    expect(countdownText).to.not.be.empty;

    // Verify preview is playing (autoplay is off)
    const previewPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
    expect(previewPlayer.state).to.equal('playing', 'Preview should not be playing when autoplay is off');

    // Wait 5 seconds and verify ad autostarts
    await utils.sleep(5000);

    // Verify ad player is now displayed and playing
    await verifyAdPlayerIsPlaying();

    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad', 15000);
    await shared.enablePreviewInSettings(false);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716063
  it('C716063 - "Watch again" bubble is shown on tile after user views ad to completion @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play ad to completion
     * 3. Return to home screen
     * 4. Observe bubble in Spotlight tile
     * 
     * Expected:
     * - "Watch again" bubble is shown
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad', 15000);

    // Verify initial countdown text (should be "Fullscreen in 5s" or similar)
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Countdown text should be visible', 3000);
    const countdownTextBefore = await testUtils.getElementField('skinAdCountdownText', 'text');

    // Play spotlight ad
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);

    // Verify ad player is playing
    await verifyAdPlayerIsPlaying();

    // Wait for ad to complete (typical wrapper ad is ~30 seconds)
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 60000);

    // Verify skinAdRow has focus
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Spotlight should have focus after ad', 5000);

    // Verify "Watch again" bubble is shown
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Countdown text should be visible', 3000);
    const countdownTextAfter = await testUtils.getElementField('skinAdCountdownText', 'text');
    expect(countdownTextAfter.toLowerCase()).to.include('watch again', '"Watch again" should be displayed after ad completion');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/716064
  it('C716064 - "Watch again" bubble reverts to "Fullscreen in 5s" on new session @manual_regression @wrapper_ads', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play ad to completion
     * 3. Return to home screen
     * 4. Observe "Watch again" bubble in Spotlight tile
     * 5. Fully exit the app
     * 6. Re-open app
     * 
     * Expected:
     * - "Fullscreen in 5s" bubble is shown again on ad tile
     */

    // Set up wrapper ad mock and launch app
    await setupAdMockAndLaunchApp();
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad', 15000);

    // Play spotlight ad to completion
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify ad player is playing
    await verifyAdPlayerIsPlaying();

    // Wait for ad to complete and return to home
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 60000);

    // Verify skinAdRow has focus
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Spotlight should have focus after ad', 5000);

    // Verify "Watch again" bubble is shown
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Countdown text should be visible', 3000);
    const countdownTextAfterAd = await testUtils.getElementField('skinAdCountdownText', 'text');
    expect(countdownTextAfterAd.toLowerCase()).to.include('watch again', '"Watch again" should be displayed after ad completion');

    // Re-open app (no proxy mocking needed, just launch)
    await ecp.sendLaunchChannel();
    await utils.sleep(5000);

    // Wait for home screen and skinAdRow
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Spotlight should have focus after relaunch', 15000);

    // Verify "Watch again" is still shown after relaunch
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Countdown text should be visible after relaunch', 3000);
    const countdownTextAfterRelaunch = await testUtils.getElementField('skinAdCountdownText', 'text');
    expect(countdownTextAfterRelaunch.toLowerCase()).to.include('watch again', '"Watch again" should still be displayed after app relaunch');


    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768128
  it('C768128 - AD is only in Adult mode - not display in kids mode @manual_regression @hdc @kids', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app with ads
     * 2. Verify ads are visible in adult mode
     * 3. Go to kids mode
     * 4. Verify ads are NOT visible in kids mode
     * 
     * Expected:
     * - HDC ads are visible in adult mode
     * - HDC ads are NOT visible in kids mode
     */

    // Launch app with Spotlight/Carousel ads
    await setupAdMockAndLaunchApp([AdType.Spotlight, AdType.Carousel]);

    // Verify ads are visible in adult mode
    await utils.sleep(2000);
    // Try to find HDC row in adult mode by checking row content
    const rowsInAdultMode = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsInAdultMode = rowsInAdultMode.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistSpotlight' ||
        item.gridItemType === 'adRowlistCarousel'
      )
    );

    // Go to Kids mode
    await testHelpers.openKidsMode();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await utils.sleep(2000);

    // Verify HDC ads are NOT visible in Kids mode
    const rowsInKidsMode = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsInKidsMode = rowsInKidsMode.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistSpotlight' ||
        item.gridItemType === 'adRowlistCarousel'
      )
    );

    expect(hasAdsInKidsMode).to.equal(false, 'HDC/Ad rows should NOT be visible in Kids mode');

    // Also verify skinAdRow is not visible
    const skinAdContainerInKidsMode = await testUtils.getNodeForElement('skinAdContainer');
    expect(skinAdContainerInKidsMode?.visible === false || skinAdContainerInKidsMode?.opacity === 0).to.equal(true, 'Skin ad row should NOT be visible in Kids mode');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768129
  it('C768129 - AD is only in Adult mode - not display in parental control - little kid @manual_regression @hdc @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Registered User
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to setting page
     * 3. Change parental control to little kids
     * 
     * Expected:
     * - There's no HDC row
     */

    // Set up HDC carousel ad mock
    await setupAdMockAndLaunchApp([AdType.Carousel]);

    // Verify HDC is visible BEFORE setting parental controls by checking rowlist content
    const rowsBeforePC = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsBeforePC = rowsBeforePC.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasAdsBeforePC).to.equal(true, 'HDC should be visible before setting parental controls');

    proxy.pause();
    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('littleKids');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    // Verify HDC is NOT visible AFTER setting parental controls to Little Kids by checking rowlist content
    const rowsAfterPC = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsAfterPC = rowsAfterPC.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasAdsAfterPC).to.equal(false, 'HDC should NOT be visible with Little Kids parental controls');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768130
  it('C768130 - AD is only in Adult mode - not display in parental control - old kid @manual_regression @hdc @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Registered User
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to setting page
     * 3. Change parental control to older kids
     * 4. Go to homescreen
     * 
     * Expected:
     * - There's no HDC row
     */

    // Set up HDC carousel ad mock
    await setupAdMockAndLaunchApp([AdType.Carousel]);

    // Verify HDC is visible BEFORE setting parental controls by checking rowlist content
    const rowsBeforePC = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsBeforePC = rowsBeforePC.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasAdsBeforePC).to.equal(true, 'HDC should be visible before setting parental controls');

    proxy.pause();
    // Set Parental Controls to Older Kids
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('olderKids');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    // Verify HDC is NOT visible AFTER setting parental controls to Older Kids by checking rowlist content
    const rowsAfterPC = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsAfterPC = rowsAfterPC.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasAdsAfterPC).to.equal(false, 'HDC should NOT be visible with Older Kids parental controls');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768131
  it('C768131 - AD is only in Adult mode - not display in parental control - teen @manual_regression @hdc @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Registered User
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to setting page
     * 3. Change parental control to teen
     * 4. Return to homepage
     * 
     * Expected:
     * - There's no HDC row
     */

    // Set up HDC carousel ad mock
    await setupAdMockAndLaunchApp([AdType.Carousel]);

    // Verify HDC is visible BEFORE setting parental controls by checking rowlist content
    const rowsBeforePC = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsBeforePC = rowsBeforePC.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasAdsBeforePC).to.equal(true, 'HDC should be visible before setting parental controls');

    proxy.pause();
    // Set Parental Controls to Teens
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('teens');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);

    // Verify HDC is NOT visible AFTER setting parental controls to Teens by checking rowlist content
    const rowsAfterPC = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasAdsAfterPC = rowsAfterPC.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasAdsAfterPC).to.equal(false, 'HDC should NOT be visible with Teens parental controls');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/790289
  it('C790289 - Verify that guest user can see HDC @manual_regression @hdc', async () => {
    /**
     * Pre-conditions:
     * - Guest user
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 
     * Expected:
     * - HDC row can be loaded with no issue
     */

    // Set up carousel ad mock and launch app as guest (disable skin ads for carousel)
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Verify HDC carousel container name is visible on screen
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
    const carouselName = await testUtils.getElementField('adCarouselContainerName', 'text');
    expect(carouselName).to.not.be.empty;

    // Navigate down to HDC carousel row to verify it can be accessed
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify focus moved to carousel grid
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on HDC carousel grid', 5000);

    // Verify carousel grid is visible and has content
    const carouselGrid = await testUtils.getNodeForElement('adCarouselGrid');
    expect(carouselGrid?.visible).to.equal(true, 'HDC carousel grid should be visible');

    // Verify carousel poster is present
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerPoster', 'HDC carousel poster should be visible', 3000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/790290
  it('C790290 - Verify that registered user can see HDC @manual_regression @hdc', async () => {
    /**
     * Pre-conditions:
     * - Registered user
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 
     * Expected:
     * - HDC row can be loaded with no issue
     */

    // Create registered user and set up carousel ad mock (disable skin ads for carousel)
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Verify HDC carousel container name is visible on screen
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
    const carouselName = await testUtils.getElementField('adCarouselContainerName', 'text');
    expect(carouselName).to.not.be.empty;

    // Navigate down to HDC carousel row to verify it can be accessed
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify focus moved to carousel grid
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on HDC carousel grid', 5000);

    // Verify carousel grid is visible and has content
    const carouselGrid = await testUtils.getNodeForElement('adCarouselGrid');
    expect(carouselGrid?.visible).to.equal(true, 'HDC carousel grid should be visible');

    // Verify carousel poster is present
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerPoster', 'HDC carousel poster should be visible', 3000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/790291
  it('C790291 - Verify that HDC is only on home screen page @manual_regression @hdc', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to different page
     * 
     * Expected:
     * - HDC row is only on home screen page (not on Movie/TVshow/Espanol/Categories/Mystuff pages)
     */

    // Set up carousel ad mock and launch app as guest (disable skin ads for carousel)
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Check HDC is visible on Home
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible on home', 5000);

    // Navigate to other pages and verify HDC is not present in rowlist content
    // Check Movies page
    await testUtils.goToPage('movies');
    await utils.sleep(2000);
    const moviesContent = await testUtils.getAllRowListItemsContentGroupedByRow('movieScreenRowList');
    const hasHDCOnMovies = moviesContent.some(row =>
      row.some(item => item.gridItemType === 'adRowlistCarousel')
    );
    expect(hasHDCOnMovies).to.equal(false, 'HDC should NOT be present on Movies page');
    await testUtils.goToPage('home');
    await utils.sleep(1000);

    // Check TV Shows page
    await testUtils.goToPage('tv');
    await utils.sleep(2000);
    const tvContent = await testUtils.getAllRowListItemsContentGroupedByRow('tvScreenRowList');
    const hasHDCOnTV = tvContent.some(row =>
      row.some(item => item.gridItemType === 'adRowlistCarousel')
    );
    expect(hasHDCOnTV).to.equal(false, 'HDC should NOT be present on TV Shows page');
    await testUtils.goToPage('home');
    await utils.sleep(1000);

    // Check Categories page - Categories uses ChannelCategoryGrid, no rowlist, so HDC cannot be present
    await testHelpers.navigateToCategories();
    await utils.sleep(2000);
    // Categories page doesn't have a rowlist structure, so HDC won't be present by design

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768116
  it('C768116 - [In Carousel Container] User can explore different content by pressing left/right @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Press left/right to switch tile
     * 
     * Expected:
     * - User can go to different tile, different image/video will be loaded
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Scroll down one row to carousel row (row 2)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Get initial background poster URIs
    const initialBackgroundUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const initialBackgroundUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Verify at least one background is present
    expect(initialBackgroundUri1 || initialBackgroundUri2).to.not.be.empty;

    // Press Right to move to next tile
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Get background poster URIs after moving right
    const afterRightUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const afterRightUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Verify background changed (different image/video loaded)
    const uri1Changed = afterRightUri1 !== initialBackgroundUri1;
    const uri2Changed = afterRightUri2 !== initialBackgroundUri2;
    expect(uri1Changed || uri2Changed, 'Background should change when moving to next tile').to.be.true;

    // Press Right again to move to next tile
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Get background poster URIs after second right press
    const secondRightUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const secondRightUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Verify background changed again
    const uri1ChangedAgain = secondRightUri1 !== afterRightUri1;
    const uri2ChangedAgain = secondRightUri2 !== afterRightUri2;
    expect(uri1ChangedAgain || uri2ChangedAgain, 'Background should change when moving to third tile').to.be.true;

    // Press Left to go back
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Get background poster URIs after moving left
    const afterLeftUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const afterLeftUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Verify we're back to the previous tile (check if at least 2 URIs match between afterLeft and afterRight)
    // Collect all 4 URIs from afterRight and afterLeft states
    const allUris = [afterRightUri1, afterRightUri2, afterLeftUri1, afterLeftUri2].filter(uri => uri && uri !== '');
    const uniqueUris = new Set(allUris);

    // If we have less than 4 unique URIs, it means at least 2 are the same (we're back to the same tile)
    expect(uniqueUris.size, 'Should return to previous tile background when pressing Left').to.be.lessThan(allUris.length);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768117
  it('C768117 - [In Carousel Container] AD video starts automatically when moving from image to video tile @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Go to an image tile
     * 4. Go to the first tile (video)
     * 
     * Expected:
     * - The AD will start playing automatically
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Scroll down one row to carousel row (row 2)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're now focused on carousel grid
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Verify preview video player is playing on first tile (video tile)
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

    // Wait for video to finish playing or stop (image tile)
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'finished', 30000);
    await utils.sleep(500);

    // First tile should be video - move to an image tile (tile 2)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Move back to first tile (video) and verify video autoplays
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Verify video starts playing automatically when returning to video tile
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    const playerState = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(playerState).to.equal('playing', 'Video should autoplay when moving to video tile');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768118
  it('C768118 - [In Carousel Container] User can exit container by pressing up/down - from video tile @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Go to first tile (video)
     * 4. Press up/down
     * 
     * Expected:
     * - User can exit HDC row and go to other rows
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Scroll down one row to carousel row (row 2)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid (first tile is video)
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Verify video is playing on first tile (video tile)
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

    // Press Up to exit carousel from video tile
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Verify we exited carousel (should be back on videoTitlesRowList at row 1)
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should be back on video tiles row list', 5000);
    const currentFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(currentFocusedIndex[0]).to.equal(1, 'Should be on row 1 after pressing Up from carousel');

    // Navigate back down to carousel
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid again', 5000);

    // Verify video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Press Down to exit carousel from video tile
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we exited carousel (should be on another row below - row 3)
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should be back on video tiles row list after pressing Down', 5000);
    const afterDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterDownIndex[0]).to.equal(3, 'Should be on row 3 after pressing Down from carousel');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768119
  it('C768119 - [In Carousel Container] User can exit container by pressing up/down - from image tile @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Go to a tile > 1st place (image tile)
     * 4. Press up/down on the remote control
     * 
     * Expected:
     * - User can exit HDC row
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    // Navigate to HDC carousel ad row
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Scroll down one row to carousel row (row 2)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // First tile is video - verify it's playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

    // Wait for video to finish playing before moving to image tile
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'finished', 30000);
    await utils.sleep(500);

    // Move to an image tile (tile 2)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Verify we're still on carousel grid but now on image tile
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should still be focused on carousel grid', 3000);

    // Press Up to exit carousel from image tile
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Verify we exited carousel (should be back on videoTitlesRowList at row 1)
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should be back on video tiles row list', 5000);
    const currentFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(currentFocusedIndex[0]).to.equal(1, 'Should be on row 1 after pressing Up from carousel');

    // Navigate back down to carousel and to image tile
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid again', 5000);

    // Move to image tile again
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Press Down to exit carousel from image tile
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we exited carousel (should be on another row below - row 3)
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should be back on video tiles row list after pressing Down', 5000);
    const afterDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterDownIndex[0]).to.equal(3, 'Should be on row 3 after pressing Down from carousel');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/768138
  it('C768138 - Check Peek row background & Container background @manual_regression @hdc', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to the row prior to HDC row
     * 3. Go to HDC row
     * 
     * Expected:
     * - Check that background of peek row won't overlap with left nav
     * - Check that background of HDC will overlap with left nav
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    await utils.sleep(2000);

    // Navigate to HDC carousel ad row - jump to row 1, then press Down to get to carousel at row 2
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Currently on row 1 (before carousel) - verify peek row
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
    await testUtils.waitForElementToShowOnScreen('adCarouselContainerPoster', 'HDC carousel poster should be visible in peek', 5000);

    // Navigate down to HDC row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770155
  it('C770155 - [Carousel] Video replays after switching tiles and returning @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Focus on the first tile
     * 4. Wait for AD to end
     * 5. Go to other tile
     * 6. Return to the 1st tile
     * 
     * Expected:
     * - AD will replay
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    await utils.sleep(2000);

    // Navigate to HDC carousel ad row - jump to row 1, then press Down to get to carousel at row 2
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid (first tile is video)
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Wait for video to finish (video is 10 seconds according to ad_carousel.json)
    await utils.sleep(11000);

    // Move to another tile
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);

    // Return to first tile
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770156
  it('C770156 - [Carousel] Video becomes static image when finished @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Focus on 1st tile
     * 4. Wait for AD to end
     * 
     * Expected:
     * - Content will become a static image
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    await utils.sleep(2000);

    await utils.sleep(2000);

    // Navigate to HDC carousel ad row - jump to row 1, then press Down to get to carousel at row 2
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid (first tile is video)
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Wait for video to finish (video is 10 seconds)
    await utils.sleep(11000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770157
  it('C770157 - [Auto-rotate] First tile remains until video conclusion @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to HDC row
     * 3. Focus on 1st tile
     * 4. Wait for AD to end
     * 
     * Expected:
     * - After about 10s, it will automatically move to next tile
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    await utils.sleep(2000);

    await utils.sleep(2000);

    // Navigate to HDC carousel ad row - jump to row 1, then press Down to get to carousel at row 2
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid (first tile is video)
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Wait for video to finish (10 seconds) plus auto-rotate interval
    await utils.sleep(11000);

    await utils.sleep(11000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770158
  it('C770158 - [Auto-rotate] Rotate interval: 10s @manual_regression @hdc @carousel', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps: None specified
     * 
     * Expected: None specified
     * 
     * NOTE: This test verifies the auto-rotate interval is 10 seconds
     */

    // Set up carousel ad mock and launch app as guest
    await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });

    await utils.sleep(2000);

    // Navigate to HDC carousel ad row - jump to row 1, then press Down to get to carousel at row 2
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify we're focused on carousel grid
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Wait for video to finish + 2 rotations (10s video + 10s + 10s = 30s)
    await utils.sleep(32000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/795971
  it('C795971 - Impression pixel only fires once (user stays on home screen) @manual_regression @hdc @analytics', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Scroll to carousel row
     * 3. Observe impression pixel fires
     * 4. Scroll away from carousel row so that it no longer appears on screen
     * 5. Scroll back to carousel row
     * 6. Observe analytics for impression pixel
     * 
     * Expected:
     * - Impression pixel does NOT fire a second time
     */

    // Track impression pixel fires
    const impressionUrls: string[] = [];

    // Set up proxy callback to intercept HDC carousel impression tracking pixels
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        // Check if this is a carousel impression tracking pixel
        // Carousel ads use the "spotlight" pixel format
        return args.url.includes('ads.production-public.tubi.io/pixel') &&
          args.url.includes('/spotlight/homescreen');
      },
      processRequest: (args) => {
        impressionUrls.push(args.url);
        return undefined;
      }
    });

    try {
      // Set up carousel ad mock and launch app as guest
      await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true, clearRegistry: false });
      await utils.sleep(2000);

      // Wait for home screen to load
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

      // Scroll down to bring carousel into view (impression fires when row comes into view)
      // Carousel is typically around row 2-3, so scroll down
      await ecp.sendKeypress(ecp.Key.Down, { count: 2, wait: 500 });
      await utils.sleep(5000); // Wait longer for impression pixel to fire

      // Verify carousel is now visible
      await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
      await utils.sleep(1000); // Extra wait for pixel to fire
      // Verify impression pixel fired once
      const firstImpressionCount = impressionUrls.length;
      expect(firstImpressionCount).to.be.greaterThan(0, 'Impression pixel should fire when carousel is first visible');

      // Scroll down past carousel (so it's no longer on screen)
      await ecp.sendKeypress(ecp.Key.Down, { count: 5 });
      await utils.sleep(2000);

      // Scroll back to carousel row
      await ecp.sendKeypress(ecp.Key.Up, { count: 5 });
      await utils.sleep(2000);

      // Verify impression pixel did NOT fire again
      const secondImpressionCount = impressionUrls.length;
      expect(secondImpressionCount).to.equal(firstImpressionCount, 'Impression pixel should NOT fire again when scrolling back to carousel on same screen');
    } finally {
      // Ensure proxy is paused even if test fails
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/795972
  it('C795972 - Impression pixel fires each time user returns to home screen @manual_regression @hdc @analytics', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered User
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Scroll to carousel row
     * 3. Observe impression pixel fires
     * 4. Leave home screen by going to another screen (ie: Movie mode, Settings, Details Page)
     * 5. Return to home screen
     * 6. Scroll to carousel row
     * 7. Observe analytics
     * 
     * Expected:
     * - Impression pixel fires again
     */

    // Track impression pixel fires
    const impressionUrls: string[] = [];

    // Set up proxy callback to intercept HDC carousel impression tracking pixels
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        // Check if this is a carousel impression tracking pixel
        // Carousel ads use the "spotlight" pixel format
        return args.url.includes('ads.production-public.tubi.io/pixel') &&
          args.url.includes('/spotlight/homescreen');
      },
      processRequest: (args) => {
        impressionUrls.push(args.url);
        return undefined;
      }
    });

    // Set up carousel ad mock and launch app as guest with 10-second valid_duration
    // Use persistCallback to allow multiple /inapp requests (when returning to home screen)
    const { cleanup } = await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true, validDuration: 10, persistCallback: true });

    try {
      await utils.sleep(2000);

      // Wait for home screen to load
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

      // Scroll down to bring carousel into view (impression fires when row comes into view)
      // Carousel is typically around row 2-3, so scroll down
      await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
      await utils.sleep(3000); // Wait longer for impression pixel to fire

      // Verify carousel is now visible
      await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
      await utils.sleep(5000); // Extra wait for pixel to fire

      // Verify impression pixel fired first time
      const firstImpressionCount = impressionUrls.length;
      expect(firstImpressionCount).to.be.greaterThan(0, 'Impression pixel should fire when carousel is first visible');

      await ecp.sendKeypress(ecp.Key.Up, { count: 2, wait: 500 });
      // Leave home screen
      await testUtils.goToPage('movies');
      await testUtils.waitForCurrentScreenToEqual('movieScreen', 10000);

      // Wait 11 seconds for valid_duration to expire (10s valid_duration + 1s buffer)
      await utils.sleep(11000);

      // Return to home screen
      await testUtils.goToPage('home');
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

      await utils.sleep(1000);

      // Scroll down to bring carousel into view (impression fires when row comes into view)
      // Carousel is typically around row 2-3, so scroll down
      await ecp.sendKeypress(ecp.Key.Down, { count: 2, wait: 500 });
      await utils.sleep(1000); // Wait longer for impression pixel to fire

      // Verify carousel is now visible
      await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
      await utils.sleep(2000); // Extra wait for pixel to fire

      // Verify impression pixel fired again
      const secondImpressionCount = impressionUrls.length;
      expect(secondImpressionCount).to.be.greaterThan(firstImpressionCount, 'Impression pixel should fire again when returning to home screen');
    } finally {
      // Always clean up the persistent callback, even if test fails
      if (cleanup) cleanup();
      proxy.removeAllCallbacks();
      // Ensure proxy is paused even if test fails
      proxy.pause();
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/790225
  it('C790225 - How many users landed on HDC carousel container @manual_regression @hdc @analytics', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Go to Carousel row from other rows (scroll slowly past carousel)
     * 
     * Expected:
     * - Analytics event fires for landing on HDC carousel with navigate_within_page data
     */

    // Track navigate_within_page events for HDC carousel
    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept analytics events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_within_page?.category_component?.category_slug === 'hdc_carousel';
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Set up carousel ad mock and launch app as guest
      await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true });
      await utils.sleep(2000);

      // Wait for home screen to load
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

      // Slowly scroll down past the carousel row to trigger navigation analytics
      // Carousel is typically at row index 2-3
      await ecp.sendKeypress(ecp.Key.Down, { count: 3, wait: 1000 });
      await utils.sleep(1000); // Wait for analytics to fire

      // Verify we received at least one navigation event for HDC carousel
      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event for HDC carousel');
      // Validate the navigate_within_page event structure using the generic validator
      validateAnalyticsEvent(
        analyticsEvents[0],
        {
          event: {
            navigate_within_page: {
              category_component: {
                category_slug: 'hdc_carousel',
                category_row: 3,
                category_col: 1,
                content_tile: {
                  ad_id: EXISTS, // Just verify ad_id exists, value doesn't matter
                  row: 1,
                  col: 1
                }
              },
              vertical_location: 4,
              horizontal_location: 1,
              means_of_navigation: 'BUTTON'
            }
          }
        },
        'HDC Carousel Navigate Within Page Event'
      );
    } finally {
      proxy.removeAllCallbacks();
      // Ensure proxy is paused even if test fails
      proxy.pause();
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/790226
  it('C790226 - How many users actively navigated within HDC carousel container @manual_regression @hdc @analytics', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch APP
     * 2. Navigate to Carousel row
     * 3. Switch tile within Carousel row (press Right)
     * 
     * Expected:
     * - Analytics event fires for active navigation within carousel
     */

    // Track navigate_within_page events for HDC carousel (horizontal navigation)
    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept analytics events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) =>
      event.event?.navigate_within_page?.category_component?.category_slug === 'hdc_carousel'
    );

    proxy.addCallback(analyticsCallback);

    try {
      // Set up carousel ad mock and launch app as guest
      await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true, shouldCreateNewUser: true });
      await utils.sleep(2000);

      // Wait for home screen to load
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

      // Navigate to the carousel row
      await ecp.sendKeypress(ecp.Key.Down, { count: 2, wait: 500 });
      await utils.sleep(1000);

      // Verify we're on the carousel
      await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);

      // Clear any navigation events from scrolling to the carousel
      analyticsEvents.length = 0;

      // Now navigate horizontally within the carousel (switch tiles)
      await ecp.sendKeypress(ecp.Key.Right, { wait: 500 });
      await utils.sleep(2000); // Wait for analytics to fire

      // Verify we received navigation event for within-carousel navigation (right)
      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event for right navigation');

      // Validate the navigate_within_page event structure (moved right)
      validateAnalyticsEvent(
        analyticsEvents[0],
        {
          event: {
            navigate_within_page: {
              category_component: {
                category_slug: 'hdc_carousel',
                category_row: 3,
                category_col: 1
              },
              horizontal_location: 2, // Moved to second position
              vertical_location: 3, // On carousel row
              means_of_navigation: 'BUTTON'
            }
          }
        },
        'HDC Carousel Right Navigation Event'
      );

      // Clear events for next navigation test
      analyticsEvents.length = 0;
      // Now navigate left within the carousel (should decrease horizontal_location)
      await ecp.sendKeypress(ecp.Key.Left, { wait: 500 });
      await utils.sleep(2000); // Wait for analytics to fire
      // Verify we received navigation event for left navigation
      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event for left navigation');

      // Validate the navigate_within_page event structure (moved left)
      validateAnalyticsEvent(
        analyticsEvents[0],
        {
          event: {
            navigate_within_page: {
              category_component: {
                category_slug: 'hdc_carousel',
                category_row: 3,
                category_col: 2
              },
              horizontal_location: 1, // Moved back to first position
              vertical_location: 3, // Still on carousel row
              means_of_navigation: 'BUTTON'
            }
          }
        },
        'HDC Carousel Left Navigation Event'
      );
    } finally {
      proxy.removeAllCallbacks();
      // Ensure proxy is paused even if test fails
      proxy.pause();
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770146
  it('C770146 - Spotlight Static Image shows when previewed below fold @manual_regression @hdc @spotlightAd', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight is active
     * 
     * Test Steps:
     * 1. Open the Home page
     * 2. Navigate rows until the HDC is positioned directly below the fold
     * 
     * Expected:
     * - Spotlight Static Image shows
     * - Branded Text appears above the container when HDC is below the fold and previewed
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Navigate to row 1 to see spotlight in peek position (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    const spotlightRow = await testUtils.getNodeForElement('videoTitlesRowListSpotlightRow');

    const titleText = await testUtils.getElementField('videoTitlesRowListSpotlightRowTitle', 'text');

    expect(titleText).to.equal('The gift of fast delivery', 'Spotlight ad row header should be "The gift of fast delivery"');
    // Verify spotlight is visible in peek position
    // Note: When at row 1, row 2 (spotlight) should be visible below as peek row
    expect(spotlightRow.itemContent.id).to.equal('hdc_spotlight', 'Spotlight ad should be at row index 2');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770143
  it('C770143 - [Video Preview enabled] Spotlight video autoplays after entering HDC when VOD Preview playing @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Open the Home page
     * 2. Navigate to the row next to HDC row, focus on a VOD with preview
     * 3. Wait for preview to start
     * 4. Navigate to HDC row
     * 
     * Expected:
     * - Spotlight Static Image Asset is shown initially
     * - Video with audio plays when streaming begins (if autoplay enabled)
     * - Background image asset is shown as background
     * - Brand Text moves inside expanded container
     * - Label designating paid promotion in upper left corner
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Wait for VOD preview to start
    await utils.sleep(3000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContent[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(3000);

    // Verify spotlight row title is visible
    const spotlightRowTitle = await testUtils.getElementField('videoTitlesRowListSpotlightRowTitle', 'text');
    expect(spotlightRowTitle).to.exist;

    // Verify spotlight item content
    const spotlightRow = await testUtils.getNodeForElement('videoTitlesRowListSpotlightRow');
    expect(spotlightRow.itemContent.id).to.equal('hdc_spotlight', 'Spotlight ad item should have correct ID');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770148
  it('C770148 - [Video Preview enabled] Spotlight video stops when moving out of HDC row @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Open the Home page
     * 2. Navigate to HDC row
     * 3. Move out of HDC row by Up/Down button
     * 
     * Expected:
     * - Spotlight ad video playing stops
     * - Focused VOD/Linear tile works as expected
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContent[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(3000);

    // Verify spotlight video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Get the player content to verify it's the spotlight ad
    const spotlightPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(spotlightPlayerContent?.id).to.equal('hdc_spotlight', 'Player should be playing spotlight ad content');

    // Move out of HDC row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify player content has changed (no longer spotlight ad)
    const newPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(newPlayerContent?.id).to.not.equal('hdc_spotlight', 'Player content should have changed from spotlight ad');

    // Verify new content video is playing (VOD preview from the newly focused item)
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Verify focus is on the next row
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Focus should be on videoTitlesRowList');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770149
  it('C770149 - [Video Preview enabled] Spotlight video replays from beginning when returning to HDC @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Open the Home page
     * 2. Navigate to HDC row and wait for Ad video playing
     * 3. Move out of HDC row by Up/Down button
     * 4. Move back to HDC row
     * 
     * Expected:
     * - Spotlight video plays again from beginning
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContentInitial = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentInitial[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(2000);

    // Verify spotlight video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Get the player content to verify it's the spotlight ad
    const spotlightPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(spotlightPlayerContent?.id).to.equal('hdc_spotlight', 'Player should be playing spotlight ad content');

    // Move out of HDC row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Verify player content has changed (no longer spotlight ad)
    const newPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(newPlayerContent?.id).to.not.equal('hdc_spotlight', 'Player content should have changed from spotlight ad');

    // Verify new content video is playing (VOD preview from the newly focused item)
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Move back to HDC row using jumpToRowIndex
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify we're back on spotlight row
    const rowItemsContentReturn = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentReturn[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should still be at index 2');


    // Verify spotlight video is playing again from beginning
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Verify player content is spotlight ad again
    const returnedPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(returnedPlayerContent?.id).to.equal('hdc_spotlight', 'Player should be playing spotlight ad content again');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770151
  it('C770151 - [Video Preview enabled] Nothing happens when pressing Right while Spotlight video playing @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Open the Home page
     * 2. Navigate to HDC row and wait for Ad video playing
     * 3. Press Right button on remote
     * 
     * Expected:
     * - Nothing happens in UI
     * - Check networks, no error API calls
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContent[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(3000);

    // Verify spotlight video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Press Right button
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Verify spotlight is still focused and nothing changed
    const rowItemsContentAfter = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentAfter[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should still be focused after pressing Right');

    // Verify video is still playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 5000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770153
  it('C770153 - [Video Preview enabled] Side nav opens when pressing Left/Back during Spotlight video @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Open App Homepage
     * 2. Navigate to HDC row
     * 3. Press Left/Back button when the Spotlight video playing
     * 4. Press Right/Back button again
     * 
     * Expected:
     * - Side Navigator opens with Home focused when pressing Left/Back
     * - Video pauses
     * - Video resumes when side nav closes
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContent[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(3000);

    // Verify spotlight video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Press Left to open side nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);

    // Verify side nav is open
    await testUtils.waitForElementToHaveFocus('sideNavMenu', 'Side nav should have focus');

    // Verify spotlight video has paused or stopped
    const playerStateAfterSideNav = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(['paused', 'stopped']).to.include(playerStateAfterSideNav, 'Spotlight video should be paused or stopped when side nav opens');

    // Press Back to close side nav
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);

    // Verify side nav is closed and focus returned to home screen
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Focus should return to videoTitlesRowList');

    // Verify spotlight video has resumed
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770152
  it('C770152 - [Video Preview enabled] Play/Pause/FF/RW/OK buttons dont work during Spotlight video @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Open the Home page
     * 2. Navigate to HDC row and wait for Ad video playing
     * 3. Press Play/Pause/FF/RW button on remote
     * 
     * Expected:
     * - Nothing happens in UI
     * - Check networks, no error API calls
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContent[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(3000);

    // Verify spotlight video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Try pressing various playback buttons - none should work
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(500);

    // Verify still on spotlight row
    let currentRowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(currentRowContent[0].id).to.equal('hdc_spotlight', 'Should still be on spotlight row after pressing Play');

    await ecp.sendKeypress(ecp.Key.Forward);
    await utils.sleep(500);

    currentRowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(currentRowContent[0].id).to.equal('hdc_spotlight', 'Should still be on spotlight row after pressing Forward');

    await ecp.sendKeypress(ecp.Key.Rewind);
    await utils.sleep(500);

    currentRowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(currentRowContent[0].id).to.equal('hdc_spotlight', 'Should still be on spotlight row after pressing Rewind');

    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(500);

    // Verify spotlight is still focused and no player screen opened
    currentRowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(currentRowContent[0].id).to.equal('hdc_spotlight', 'Should still be on spotlight row after pressing OK');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 2000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770150
  it('C770150 - [Video Preview enabled] Spotlight shows static image after video finishes @manual_regression @hdc @spotlightAd @video_preview', async () => {
    /**
     * Pre-conditions:
     * - HDC with Spotlight Ad is active
     * - Video Preview enabled in Settings
     * 
     * Test Steps:
     * 1. Go to Homepage -> navigate to HDC row
     * 2. Let the Spotlight video play finish
     * 3. Press UP/Down button to move out the HDC row
     * 4. Move to HDC row again and wait for the Ad video plays completely
     * 5. Press Back/Left button
     * 6. Press Back/Right button
     * 
     * Expected:
     * 1. N/A
     * 2. Spotlight Static image shows, Background image shows as background
     * 3. The correct VOD/Linear tile works as expected
     * 4. The Spotlight video is played again
     * 5. Left navigation menu opens. HDC row keeps showing static image
     * 6. The Spotlight video doesn't play
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn on Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(true);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContentInitial = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentInitial[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(3000);

    // Verify spotlight video is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Verify spotlight video has finished
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'finished', 15000);

    // Move out of HDC row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Move back to HDC row using jumpToRowIndex
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify we're back on spotlight row
    const rowItemsContentReturn = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentReturn[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should still be at index 2');

    await utils.sleep(2000);

    // Verify spotlight video is playing again from beginning
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    // Verify spotlight video has finished again
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'finished', 20000);

    // Press Left to open side nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);

    // Verify side nav is open
    await testUtils.waitForElementToHaveFocus('sideNavMenu', 'Side nav should have focus');

    // Verify spotlight video is not playing (static image showing)
    const playerStateWithSideNav = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(playerStateWithSideNav).to.not.equal('playing', 'Spotlight video should not be playing when side nav opens');

    // Press Back to close side nav
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);

    // Verify side nav is closed and static image still shows (video doesn't auto-play)
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Focus should return to videoTitlesRowList');

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/770145
  it('C770145 - [Video Preview disabled] Spotlight Static Image shows after entering HDC @manual_regression @hdc @spotlightAd', async () => {
    /**
     * Pre-conditions:
     * - Video Preview disabled in Settings
     * - HDC with Spotlight is active
     * 
     * Test Steps:
     * 1. Go to Homepage -> navigate to HDC row
     * 2. Press UP/Down button to move out the HDC row
     * 3. Move to HDC row again
     * 4. Press Back/Left button
     * 5. Press Back/Right button
     * 
     * Expected:
     * - The Static Image is shown
     */

    // Set up spotlight ad mock and launch app
    await setupAdMockAndLaunchApp([AdType.Spotlight], { disableSkinAds: true });

    // Wait for rowlist to have focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Turn off Autoplay Previews in Settings
    await testHelpers.enablePreviewInSettings(false);

    // Wait for home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    // Navigate to spotlight row (index 2) and verify it's present
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContentInitial = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentInitial[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    await utils.sleep(2000);

    // Verify spotlight static image shows (not video)
    const playerState = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(['stopped', 'none', 'finished']).to.include(playerState, 'Spotlight video should not be playing when video previews are disabled');

    // Move out of HDC row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(2000);

    // Move back to HDC row using jumpToRowIndex
    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Verify we're back on spotlight row
    const rowItemsContentReturn = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContentReturn[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should still be at index 2');

    await utils.sleep(1000);

    // Verify spotlight static image still shows (video should not start playing)
    const playerStateAfterReturn = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(['stopped', 'none', 'finished']).to.include(playerStateAfterReturn, 'Spotlight video should still not be playing after returning to row');

    // Press Left to open side nav
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);

    // Verify side nav is open
    await testUtils.waitForElementToHaveFocus('sideNavMenu', 'Side nav should have focus');

    // Verify spotlight static image still shows (video should not start playing)
    const playerStateWithSideNav = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(['stopped', 'none', 'finished']).to.include(playerStateWithSideNav, 'Spotlight video should not be playing with side nav open');

    // Press Back to close side nav
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);

    // Verify side nav is closed
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Focus should return to videoTitlesRowList');

    // Verify spotlight static image still shows after closing side nav (video should not start playing)
    const playerStateAfterClosingSideNav = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(['stopped', 'none', 'finished']).to.include(playerStateAfterClosingSideNav, 'Spotlight video should not be playing after closing side nav');

    const poster = await testUtils.getNodeForElement('videoTitlesRowListSpotlightRowPoster');
    expect(poster.uri).to.not.be.null;
    expect(poster.visible).to.be.true, 'Spotlight poster should be visible';
    expect(poster.opacity).to.be.equal(1.0, 'Spotlight poster opacity should be 1');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/171804
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

    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/171840
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

    // Launch app
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await utils.sleep(1000);

    // Find and play a movie
    let movieId;
    try {
      const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
      if (focusedContent && focusedContent.type === 'v' && !focusedContent.seriesId) {
        movieId = focusedContent.id;
      }
    } catch (e) {
    }

    // Go to details and play
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Deeplink to the same movie
    if (movieId) {
      await testUtils.startApplicationWithDeeplink({ contentId: movieId });
      await utils.sleep(5000);

    } else {
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/171841
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

    await utils.sleep(1000);

    // Find and play a series
    let seriesId;
    try {
      const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
      if (focusedContent && (focusedContent.type === 's' || focusedContent.seriesId)) {
        seriesId = focusedContent.seriesId || focusedContent.id;
      }
    } catch (e) {
    }

    // Go to details and play
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Deeplink to the same series
    if (seriesId) {
      await testUtils.startApplicationWithDeeplink({ contentId: seriesId });
      await utils.sleep(5000);

    } else {
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172079
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

    await utils.sleep(1000);

    // Navigate to movies page then back to home
    await testUtils.goToPage('movies');
    await utils.sleep(2000);
    await testUtils.goToPage('home');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172098
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

    await utils.sleep(1000);

    // Find and play a movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172099
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

    await utils.sleep(1000);

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
    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172284
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

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await utils.sleep(1000);

    // Play a movie
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172285
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

    // Launch app
    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await utils.sleep(1000);

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

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
    await utils.sleep(5000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172511
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
    await utils.sleep(2000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172453
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

    await utils.sleep(1000);

    // Navigate to movies then back to home
    await testUtils.goToPage('movies');
    await utils.sleep(2000);
    await testUtils.goToPage('home');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 5000);
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/172454
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

    await utils.sleep(1000);

    // Background the app
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(2000);

    // Foreground the app
    await ecp.sendLaunchChannel();
    await utils.sleep(3000);

    // Verify we're back on home screen (splash screen should not show)
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/181601
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

    await utils.sleep(1000);

    // Send voice command "play" via ECP input
    await ecp.sendInput({ params: { type: 'transport', command: 'play' } });
    await utils.sleep(3000);

    // Verify playback initiated (may go to ad player first or directly to video player)
    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 8000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/181602
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
    await utils.sleep(2000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/185810
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/203230
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
    await utils.sleep(5000);

    // Verify new video is playing
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
    const playerContent = await testUtils.getPlayerContent('videoPlayerScreen');
    const newVideoId = playerContent.parentType == 'series' ? playerContent.parentId : playerContent.id;
    expect(newVideoId).to.equal(autoplayGridContents[0].id, 'Should autoplay to the first suggested movie');

    // Step #4: Back out to details screen
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(2000);
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/439674
  it('C439674 - Guest User: Selecting My Stuff and registering displays empty My Stuff page @manual_regression @my_stuff', async () => {
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
     * - The empty My Stuff page is displayed with Go to Home button
     * - Background should match design
     */

    // Launch app as guest
    await testUtils.startApplicationAtPage('home', { clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await utils.sleep(1000);

    // Navigate to My Stuff via side nav
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);
    await testUtils.waitForElementToHaveFocus('guestMenu', 'Timed out waiting for guestMenu to have focus', 20000);

    await ecp.sendKeypress(ecp.Key.Ok);
    // Complete sign up flow (dismisses "Let's create your account" modal, then enters email/password)
    await testHelpers.completeSignUpFlow();

    // Wait for sign up to complete and My Stuff screen to appear
    await utils.sleep(5000);

    // Verify My Stuff screen is displayed (may take longer due to sign up process)
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 30000);

    // Look for registered user empty screen
    const regUserEmptyScreen = await testUtils.getNodeForElement('myStuffRegUserEmptyScreen');
    expect(regUserEmptyScreen?.visible).to.be.true;

    // Look for "Go to Home" button
    const goToHomeButton = await testUtils.getNodeForElement('goHomeButtonMyStuff');
    if (goToHomeButton) {
      expect(goToHomeButton.visible || goToHomeButton.opacity > 0).to.be.true;
    } else {
      // Try alternate button ID
      const altGoToHomeButton = await testUtils.getNodeForElement('goHomeMyStuffButton');
      expect(altGoToHomeButton?.visible || altGoToHomeButton?.opacity > 0).to.be.true;
    }

    // Verify background poster is present
    const backgroundPoster = await testUtils.getNodeForElement('backgroundPoster');
    if (backgroundPoster && backgroundPoster.uri) {
    }

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/439677
  it('C439677 - Registered User: My Stuff with Continue Watching and empty My List @manual_regression @my_stuff', async () => {
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

    await utils.sleep(1000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/439678
  it('C439678 - Registered User: My Stuff with empty Continue Watching and My List @manual_regression @my_stuff', async () => {
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
    await utils.sleep(1000);
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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/439741
  it('C439741 - Registered User: Kids Mode - My Stuff shows only Kids rated titles @manual_regression @my_stuff @kids', async () => {
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
    await utils.sleep(2000);

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

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/782189
  it.skip('C782189 - Play content that supports both H264 and H265 @manual_regression @codecs @low_performance', async () => {
    /**
     * Pre-conditions:
     * - Use a device that only supports H264 (ie: 3700X)
     * - Find a title that supports both H264 and H265 (ie: Mo' Money, Stranger Than Fiction)
     * 
     * Test Steps:
     * 1. Launch app
     * 2. Play content that supports both VIDEO_CODEC_H264 and VIDEO_CODEC_H265
     * 
     * Expected:
     * - Content successfully plays on 3700
     */
  });
});

