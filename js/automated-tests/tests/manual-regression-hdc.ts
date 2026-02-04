import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';
import { validateAnalyticsEvent, createAnalyticsCallback, EXISTS } from './analytics/analytics-validator';
import { setupAdMockAndLaunchApp, safeResumeProxy } from './manual-regression-helpers';

/**
 * HDC (Home Display Carousel) Regression Tests
 * Extracted from manual-regression.ts
 */

describe('HDC (Home Display Carousel) Regression Tests', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  afterEach(async () => {
    await proxy.pause();
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

    const moviesContent = await testUtils.getAllRowListItemsContentGroupedByRow('movieScreenRowList');
    const hasHDCOnMovies = moviesContent.some(row =>
      row.some(item => item.gridItemType === 'adRowlistCarousel')
    );
    expect(hasHDCOnMovies).to.equal(false, 'HDC should NOT be present on Movies page');
    await testUtils.goToPage('home');
    await utils.sleep(1000);

    // Check TV Shows page
    await testUtils.goToPage('tv');

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
      await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
      await utils.sleep(5000); // Wait longer for impression pixel to fire

      // Verify carousel is now visible
      await testUtils.waitForElementToShowOnScreen('adCarouselContainerName', 'HDC carousel row should be visible', 5000);
      // Extra wait for pixel to fire
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
    const { cleanup } = await setupAdMockAndLaunchApp([AdType.Carousel], { disableSkinAds: true, validDuration: 5, persistCallback: true });

    try {
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
      await utils.sleep(6000);

      // Return to home screen
      await testUtils.goToPage('home');
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

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

    // Wait for player content to change (no longer spotlight ad)
    await testUtils.untilTrue(async () => {
      const newPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
      return newPlayerContent?.id !== 'hdc_spotlight';
    }, 'Player content should have changed from spotlight ad', 10000);

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

    // Wait for player content to change (no longer spotlight ad)
    await testUtils.untilTrue(async () => {
      const newPlayerContent = await testUtils.getElementField('previewVideoPlayer', 'content');
      return newPlayerContent?.id !== 'hdc_spotlight';
    }, 'Player content should have changed from spotlight ad', 10000);

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
});
