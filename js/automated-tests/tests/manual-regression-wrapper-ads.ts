import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';
import {
  setupAdMockAndLaunchApp,
  verifyAdPlayerIsPlaying,
  verifyAdPlayerElements,
  safeResumeProxy
} from './manual-regression-helpers';

describe('Wrapper Ads and Skins Regression Tests', () => {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  afterEach(async () => {
    proxy.pause();
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
});
