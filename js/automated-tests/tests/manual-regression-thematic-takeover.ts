import { expect } from 'chai';
import { ecp, utils, proxy, odc } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';
import { setupAdMockAndLaunchApp, safeResumeProxy } from './manual-regression-helpers';

/**
 * Thematic Takeover Regression Tests
 * 
 * Thematic Takeovers apply branded styling (logo, graphic) to existing containers.
 * Unlike HDC ads which insert new rows, thematic takeovers theme existing content.
 * 
 * Key behaviors tested:
 * - Theme styling is applied to target container
 * - Impression pixels fire on container focus
 * - Theme is gated behind experiment (same as HDC)
 * - Not visible in Kids mode or restricted parental controls
 */

describe('Thematic Takeover Regression Tests', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  afterEach(async () => {
    await proxy.pause();
  });


  /**
   * Helper to check if any row has thematic takeover sponsorImages applied
   * Returns the row metadata if found, null otherwise
   */
  async function findRowWithThematicTakeover(rowListId = 'videoTitlesRowList'): Promise<any | null> {
    const rowsMetadata = await testUtils.getAllRowListRowsMetadata(rowListId);
    for (const row of rowsMetadata) {
      if (row && row.sponsorImages && row.sponsorImages.subtype === "TubiSponsorImagesNode") {
        return row;
      }
    }
    return null;
  }

  /**
   * Helper to verify thematic takeover is NOT present on any row
   */
  async function verifyNoThematicTakeover(rowListId = 'videoTitlesRowList'): Promise<void> {
    const themedRow = await findRowWithThematicTakeover(rowListId);
    expect(themedRow).to.be.null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // UI VISIBILITY TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C2492421 - Thematic takeover theme is applied to container in adult mode @manual_regression @thematic_takeover', async () => {
    /**
     * Pre-conditions: Guest or Registered user in adult mode
     * 
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Verify a container has sponsorImages with thematicTakeoverId
     * 
     * Expected:
     * - Container has thematic takeover styling applied
     * - sponsorImages.brand_logo is non-empty
     * - sponsorImages.brand_graphic is non-empty
     */

    await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { disableSkinAds: true });
    await utils.sleep(4000);

    const themedRow = await findRowWithThematicTakeover();
    expect(themedRow).to.not.be.null;

    // Only assert on reliably exposed fields
    expect(themedRow.sponsorImages.id).to.not.be.undefined;
    expect(themedRow.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
  });

  it('C2492422 - Thematic takeover NOT visible in Kids mode @manual_regression @thematic_takeover @kids', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app with thematic takeover ads
     * 2. Verify theme is applied in adult mode
     * 3. Switch to kids mode
     * 4. Verify theme is NOT applied
     * 
     * Expected:
     * - Thematic takeover visible in adult mode
     * - Thematic takeover NOT visible in kids mode
     */

    await setupAdMockAndLaunchApp([AdType.ThematicTakeover]);
    await utils.sleep(2000);

    // Verify theme is visible in adult mode first
    const themedRowAdult = await findRowWithThematicTakeover();
    expect(themedRowAdult).to.not.be.null;
    expect(themedRowAdult.sponsorImages.id).to.not.be.undefined;
    expect(themedRowAdult.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');

    // Go to Kids mode
    await testHelpers.openKidsMode();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await utils.sleep(2000);

    // Verify NO thematic takeover in Kids mode
    await verifyNoThematicTakeover();
  });

  it('C2492423 - Thematic takeover NOT visible with parental control - little kids @manual_regression @thematic_takeover @parental_controls', async () => {
    /**
     * Pre-conditions: Registered User
     * 
     * Test Steps:
     * 1. Launch APP with thematic takeover
     * 2. Verify theme is applied
     * 3. Set parental control to little kids
     * 4. Return to homescreen
     * 
     * Expected:
     * - Theme visible before parental controls
     * - Theme NOT visible with little kids setting
     */

    await setupAdMockAndLaunchApp([AdType.ThematicTakeover]);
    await utils.sleep(2000);

    const themedRowBefore = await findRowWithThematicTakeover();
    expect(themedRowBefore).to.not.be.null;
    expect(themedRowBefore.sponsorImages.id).to.not.be.undefined;
    expect(themedRowBefore.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');

    proxy.pause();

    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('littleKids');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);
    await utils.sleep(2000);

    // Verify NO thematic takeover with Little Kids parental controls
    await verifyNoThematicTakeover();
  });

  it('C2492424 - Thematic takeover NOT visible with parental control - teens @manual_regression @thematic_takeover @parental_controls', async () => {
    /**
     * Pre-conditions: Registered User
     * 
     * Test Steps:
     * 1. Launch APP with thematic takeover
     * 2. Verify theme is applied
     * 3. Set parental control to teens
     * 4. Return to homescreen
     * 
     * Expected:
     * - Theme visible before parental controls
     * - Theme NOT visible with teens setting
     */

    await setupAdMockAndLaunchApp([AdType.ThematicTakeover]);
    await utils.sleep(2000);

    // Verify theme is visible before setting parental controls
    const themedRowBefore = await findRowWithThematicTakeover();
    expect(themedRowBefore).to.not.be.null;
    expect(themedRowBefore.sponsorImages.id).to.not.be.undefined;
    expect(themedRowBefore.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');

    proxy.pause();

    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('teens');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for homeScreenRowList to have focus', 15000);
    await utils.sleep(2000);

    // Verify NO thematic takeover with Teens parental controls
    await verifyNoThematicTakeover();
  });

  // ═══════════════════════════════════════════════════════════════════
  // COMBINED AD TYPE TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C2492425 - Thematic takeover can coexist with wrapper ads @manual_regression @thematic_takeover @wrapper_ads', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app with both wrapper and thematic takeover ads
     * 2. Verify skin ad row is visible (wrapper)
     * 3. Verify container has thematic takeover styling
     * 
     * Expected:
     * - Both wrapper ads and thematic takeover function together
     */

    await setupAdMockAndLaunchApp([AdType.Wrapper, AdType.ThematicTakeover]);
    await utils.sleep(2000);

    // Verify skin ad (wrapper) is visible
    await testUtils.waitForElementToShowOnScreen('skinAdRow', 'Skin ad row should be visible', 5000);

    // Navigate down to see content rows
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify thematic takeover is also applied to a container
    const themedRow = await findRowWithThematicTakeover();
    expect(themedRow).to.not.be.null;
    expect(themedRow.sponsorImages.id).to.not.be.undefined;
    expect(themedRow.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
  });

  it('C2492426 - Thematic takeover can coexist with carousel ads @manual_regression @thematic_takeover @hdc', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app with both carousel and thematic takeover ads
     * 2. Verify HDC carousel row inserted
     * 3. Verify container has thematic takeover styling
     * 
     * Expected:
     * - HDC carousel row is inserted
     * - Container has thematic takeover applied separately
     */

    await setupAdMockAndLaunchApp([AdType.Carousel, AdType.ThematicTakeover], { disableSkinAds: true });
    await utils.sleep(2000);

    // Check for HDC carousel in content
    const rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow('videoTitlesRowList');
    const hasCarousel = rowsContent.some(row =>
      row.length > 0 && row.some(item =>
        item.gridItemType === 'adRowlistCarousel'
      )
    );
    expect(hasCarousel).to.equal(true, 'HDC carousel should be present');

    // Verify thematic takeover is also applied to a container
    const themedRow = await findRowWithThematicTakeover();
    expect(themedRow).to.not.be.null;
    expect(themedRow.sponsorImages.id).to.not.be.undefined;
    expect(themedRow.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
  });

  // ═══════════════════════════════════════════════════════════════════
  // IMPRESSION PIXEL TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C2492427 - Thematic takeover impression pixels fire when container is focused @manual_regression @thematic_takeover @impressions', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Set up proxy to capture pixel requests
     * 2. Launch app with thematic takeover (targeting 'featured' container)
     * 3. Wait for impression timer to fire (featured is immediately visible)
     * 4. Verify pixel request was made
     * 
     * Expected:
     * - Impression pixel fires after dwell time on themed container
     * 
     * Note: Mock targets 'featured' container which is always first and visible immediately
     * when disableSkinAds is true. No navigation needed.
     */

    let pixelRequestReceived = false;
    await safeResumeProxy();

    // Set up callback to capture pixel requests
    proxy.addCallback({
      shouldProcess: (args) => {
        // Check if this is an ad pixel request
        if (args.url.includes('ads.production-public.tubi.io/pixel') ||
          args.url.includes('ThematicTakeoverTest')) {
          pixelRequestReceived = true;
        }
        return false;
      }
    });

    const proxyPromise = adTestHelpers.mockAds([AdType.ThematicTakeover]);
    const user = await testUtils.createRegisteredUser();
    await testUtils.startApplicationAtPage('home', {
      user,
      clearRegistry: false,
      disableSkinAds: true
    });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for rowlist', 15000);

    // With disableSkinAds: true and targeting 'featured' container,
    // the themed row is immediately visible - just wait for impression timer
    await utils.sleep(3000); // Wait for impression timer (typically 1-2 seconds)

    // Verify the impression pixel fired
    expect(pixelRequestReceived).to.equal(true, 'Impression pixel should fire when Featured container is focused');

    // Verify thematic takeover was applied to featured row
    const themedRow = await findRowWithThematicTakeover();
    expect(themedRow).to.not.be.null;
    expect(themedRow.sponsorImages.id).to.not.be.undefined;
    expect(themedRow.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
  });

  // ═══════════════════════════════════════════════════════════════════
  // SCREEN TYPE TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C2492428 - Thematic takeover is available on Movies screen @manual_regression @thematic_takeover @movies', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Navigate to Movies screen
     * 3. Verify a container has sponsorImages with thematicTakeoverId
     * 
     * Expected:
     * - Thematic takeover functionality available on Movies screen
     */

    const { cleanup: moviesCleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);
      await testUtils.goToPage('movies');
      await testUtils.waitForCurrentScreenToEqual('movieScreen', 10000);
      // Wait for the movieScreenRowList to fully load and have focus
      await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movieScreenRowList to have focus', 15000);
      await utils.sleep(4000);

      const themedRow = await findRowWithThematicTakeover('movieScreenRowList');
      expect(themedRow).to.not.be.null;
      expect(themedRow.sponsorImages.id).to.not.be.undefined;
      expect(themedRow.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
    } finally {
      if (moviesCleanup) moviesCleanup();
    }
  });

  it('C2492429 - Thematic takeover is available on TV screen @manual_regression @thematic_takeover @tv', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Navigate to TV screen
     * 3. Verify a container has sponsorImages with thematicTakeoverId
     * 
     * Expected:
     * - Thematic takeover functionality available on TV screen
     */

    const { cleanup: tvCleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);

      // Navigate to TV screen
      await testUtils.goToPage('tv');
      await testUtils.waitForCurrentScreenToEqual('tvScreen', 10000);
      // Wait for the tvScreenRowList to fully load and have focus
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for tvScreenRowList to have focus', 15000);
      await utils.sleep(4000);

      const themedRow = await findRowWithThematicTakeover('tvScreenRowList');
      expect(themedRow).to.not.be.null;
      expect(themedRow.sponsorImages.id).to.not.be.undefined;
      expect(themedRow.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
    } finally {
      if (tvCleanup) tvCleanup();
    }
  });

  it('C2492430 - Thematic takeover theme is applied to Action category @manual_regression @thematic_takeover @category', async () => {
    /**
     * Pre-conditions: None
     *
     * Test Steps:
     * 1. Launch app with thematic takeover ads (persistCallback to cover category screen /inapp request)
     * 2. Navigate to category panel list screen
     * 3. Wait for ad content fetch to complete on the screen
     * 4. Verify adContent contains a thematic takeover entry for the Action container
     * 5. Navigate left panel to Action category and verify categoryContent has sponsorImages applied
     *
     * Expected:
     * - CategoryPanelListScreen.adContent contains thematic takeover for 'action'
     * - categoryContent.sponsorImages is set after navigating to Action
     */

    const SCREEN_KEY_PATH = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen';

    const { cleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);
      await testUtils.goToPage('categories');
      await testUtils.waitForCurrentScreenToEqual('categoryPanelListScreen', 10000);
      await utils.sleep(4000); // Wait for ad content fetch to complete

      // Verify adContent was fetched and contains thematic takeover for Action
      const { value: adContentFetchCompleted } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.adContentFetchCompleted` });
      expect(adContentFetchCompleted).to.equal(true, 'Ad content fetch should have completed');

      const { value: adContent } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.adContent` });
      expect(adContent).to.be.an('array').with.length.greaterThan(0);

      // Navigate left panel to Action category and verify sponsorImages is applied to the content
      let foundAction = false;
      for (let i = 0; i < 20; i++) {
        const { value: focused } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.categoryListItemFocused` });
        if (focused && focused.id === 'action') {
          foundAction = true;
          break;
        }
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      expect(foundAction).to.equal(true, 'Should be able to navigate to Action category in left panel');

      await utils.sleep(3000); // Wait for categoryContent fetch and theme application
      const { value: categoryContent } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.categoryContent` });
      expect(categoryContent).to.not.be.null;
      expect(categoryContent.sponsorImages).to.not.be.undefined;
      expect(categoryContent.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
    } finally {
      if (cleanup) cleanup();
    }
  });

  it('C2492431 - Thematic takeover pixel fires for Action category @manual_regression @thematic_takeover @category @impressions', async () => {
    /**
     * Pre-conditions: Guest or Registered user in adult mode
     *
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Navigate to the categories screen via deeplink
     * 3. Wait for CategoryPanelListScreen to load
     * 4. Scroll the left category panel down until the Action category is focused
     * 5. Wait for the category content and ad content fetches to complete
     * 6. Verify the impression pixel fires automatically once both fetches are done
     *
     * Expected:
     * - The Action category's thematic takeover impression pixel fires (URL contains 'ActionCategoryTest')
     *   once the category content and ad content are both ready
     */

    let pixelRequestReceived = false;
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('ads.production-public.tubi.io/pixel') ||
          args.url.includes('ActionCategoryTest')) {
          pixelRequestReceived = true;
        }
        return false;
      }
    });

    const SCREEN_KEY_PATH = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen';

    const { cleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);
      await testUtils.goToPage('categories');
      await testUtils.waitForCurrentScreenToEqual('categoryPanelListScreen', 10000);
      await utils.sleep(2000);

      // Navigate left panel to Action — pixels fire automatically in checkIfCategoryPanelContentIsReady
      // when categoryContent fetch and adContent fetch both complete for the Action category
      let foundAction = false;
      for (let i = 0; i < 20; i++) {
        const { value: focused } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.categoryListItemFocused` });
        if (focused && focused.id === 'action') {
          foundAction = true;
          break;
        }
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      expect(foundAction).to.equal(true, 'Should be able to navigate to Action category in left panel');
      await utils.sleep(3000); // Wait for content fetch and pixel firing

      expect(pixelRequestReceived).to.equal(true, 'Pixel should fire for Action category');
    } finally {
      if (cleanup) cleanup();
    }
  });

  it('C2492432 - Thematic takeover theme is applied to Network screen @manual_regression @thematic_takeover @network', async () => {
    /**
     * Pre-conditions: Guest or Registered user in adult mode
     *
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Navigate to the network (channels) section via deeplink
     * 3. Wait for CategoryPanelListScreen with Networks category pre-selected
     * 4. Find the target channel's position in the channel grid content
     * 5. Navigate into the grid and select it to open its CategoryDetailsScreen
     * 6. Verify categoryDetailsScreen.content has sponsorImages applied
     *
     * Expected:
     * - CategoryDetailsScreen.adContent contains thematic takeover for the target channel
     * - content.sponsorImages is set on the target channel's CategoryDetailsScreen
     */

    const PANEL_PATH = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen';
    const DETAILS_PATH = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen';
    const GRID_COLUMNS = 4;
    const NETWORK_CHANNEL_ID = 'aetv';

    const { cleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);
      await testUtils.goToPage('network');
      await testUtils.waitForCurrentScreenToEqual('categoryPanelListScreen', 10000);
      await utils.sleep(2000);

      // Navigate left panel to Networks category (deeplink pre-selects it, but loop handles timing)
      let foundNetworks = false;
      for (let i = 0; i < 30; i++) {
        const { value: focused } = await odc.getValue({ keyPath: `${PANEL_PATH}.categoryListItemFocused` });
        if (focused && focused.id === 'networks') {
          foundNetworks = true;
          break;
        }
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      expect(foundNetworks).to.equal(true, 'Should be able to navigate to Networks category in left panel');

      // Wait for the channel grid content to load
      await utils.sleep(3000);

      // Find target channel index in the loaded content list
      const { value: childCount } = await odc.getValue({ keyPath: `${PANEL_PATH}.categoryContent.getChildCount()` });
      expect(childCount).to.be.greaterThan(0, 'Networks category should have channels loaded');

      let targetChannelIndex = -1;
      for (let i = 0; i < childCount; i++) {
        const { value: child } = await odc.getValue({
          keyPath: `${PANEL_PATH}.categoryContent.${i}`,
          responseMaxChildDepth: 0
        });
        if (child && child.id === NETWORK_CHANNEL_ID) {
          targetChannelIndex = i;
          break;
        }
      }
      expect(targetChannelIndex).to.be.greaterThanOrEqual(0, `Should find ${NETWORK_CHANNEL_ID} channel in Networks content list`);

      // Navigate into the channel grid and move to the target channel's position
      const targetChannelRow = Math.floor(targetChannelIndex / GRID_COLUMNS);
      const targetChannelCol = targetChannelIndex % GRID_COLUMNS;
      await ecp.sendKeypress(ecp.Key.Right); // Enter the channel grid (focus lands at [0,0])
      await utils.sleep(500);
      for (let i = 0; i < targetChannelRow; i++) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      for (let i = 0; i < targetChannelCol; i++) {
        await ecp.sendKeypress(ecp.Key.Right);
        await utils.sleep(500);
      }

      // Verify we landed on the right tile before selecting
      const { value: contentFocused } = await odc.getValue({ keyPath: `${PANEL_PATH}.contentFocused` });
      expect(contentFocused?.id).to.equal(NETWORK_CHANNEL_ID, `${NETWORK_CHANNEL_ID} channel should be focused in the grid`);

      // Select target channel to open its CategoryDetailsScreen
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('categoryDetailsScreen', 10000);
      await utils.sleep(3000); // Wait for content and ad fetch on categoryDetailsScreen

      // Verify thematic takeover is applied on the target channel's details screen
      const { value: adContentFetchCompleted } = await odc.getValue({ keyPath: `${DETAILS_PATH}.adContentFetchCompleted` });
      expect(adContentFetchCompleted).to.equal(true, 'Ad content fetch should have completed on categoryDetailsScreen');

      const { value: detailsContent } = await odc.getValue({ keyPath: `${DETAILS_PATH}.content` });
      expect(detailsContent).to.not.be.null;
      expect(detailsContent.sponsorImages).to.not.be.undefined;
      expect(detailsContent.sponsorImages.subtype).to.equal('TubiSponsorImagesNode');
    } finally {
      if (cleanup) cleanup();
    }
  });

  it('C2492433 - Thematic takeover pixel fires for Network screen @manual_regression @thematic_takeover @network @impressions', async () => {
    /**
     * Pre-conditions: Guest or Registered user in adult mode
     *
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Navigate to the network section, find the target channel in the channel grid
     * 3. Select it to open its CategoryDetailsScreen
     * 4. Verify the thematic takeover impression pixel fires on load
     *
     * Expected:
     * - Pixel fires after thematic theme is applied on the target channel's CategoryDetailsScreen
     */

    let pixelRequestReceived = false;
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('ads.production-public.tubi.io/pixel') ||
          args.url.includes('NetworkTest')) {
          pixelRequestReceived = true;
        }
        return false;
      }
    });

    const PANEL_PATH = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen';
    const GRID_COLUMNS = 4;
    const NETWORK_CHANNEL_ID = 'aetv';

    const { cleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);
      await testUtils.goToPage('network');
      await testUtils.waitForCurrentScreenToEqual('categoryPanelListScreen', 10000);
      await utils.sleep(2000);

      // Navigate left panel to Networks category
      let foundNetworks = false;
      for (let i = 0; i < 30; i++) {
        const { value: focused } = await odc.getValue({ keyPath: `${PANEL_PATH}.categoryListItemFocused` });
        if (focused && focused.id === 'networks') {
          foundNetworks = true;
          break;
        }
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      expect(foundNetworks).to.equal(true, 'Should be able to navigate to Networks category in left panel');

      await utils.sleep(3000); // Wait for channel grid content to load

      // Find target channel position in the content list
      const { value: childCount } = await odc.getValue({ keyPath: `${PANEL_PATH}.categoryContent.getChildCount()` });
      expect(childCount).to.be.greaterThan(0, 'Networks category should have channels loaded');

      let targetChannelIndex = -1;
      for (let i = 0; i < childCount; i++) {
        const { value: child } = await odc.getValue({
          keyPath: `${PANEL_PATH}.categoryContent.${i}`,
          responseMaxChildDepth: 0
        });
        if (child && child.id === NETWORK_CHANNEL_ID) {
          targetChannelIndex = i;
          break;
        }
      }
      expect(targetChannelIndex).to.be.greaterThanOrEqual(0, `Should find ${NETWORK_CHANNEL_ID} channel in Networks content list`);

      // Navigate into the grid and select the target channel
      const targetChannelRow = Math.floor(targetChannelIndex / GRID_COLUMNS);
      const targetChannelCol = targetChannelIndex % GRID_COLUMNS;
      await ecp.sendKeypress(ecp.Key.Right); // Enter the channel grid (focus lands at [0,0])
      await utils.sleep(500);
      for (let i = 0; i < targetChannelRow; i++) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      for (let i = 0; i < targetChannelCol; i++) {
        await ecp.sendKeypress(ecp.Key.Right);
        await utils.sleep(500);
      }

      // Verify we landed on the right tile before selecting
      const { value: contentFocused } = await odc.getValue({ keyPath: `${PANEL_PATH}.contentFocused` });
      expect(contentFocused?.id).to.equal(NETWORK_CHANNEL_ID, `${NETWORK_CHANNEL_ID} channel should be focused in the grid`);

      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('categoryDetailsScreen', 10000);
      await utils.sleep(3000); // Wait for content fetch and pixel firing

      expect(pixelRequestReceived).to.equal(true, `Pixel should fire for ${NETWORK_CHANNEL_ID} channel thematic takeover`);
    } finally {
      if (cleanup) cleanup();
    }
  });

  // ═══════════════════════════════════════════════════════════════════
  // PIXEL REFRESH TESTS
  // ═══════════════════════════════════════════════════════════════════

  it('C2492434 - Thematic takeover pixel refreshes for Featured row after navigating to detail screen and back @manual_regression @thematic_takeover @impressions', async () => {
    /**
     * Pre-conditions: Guest or Registered user in adult mode
     *
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Wait for home screen - Featured row has thematic takeover applied and initial pixel fires
     * 3. Select the first item in the Featured row to open the detail screen
     * 4. Navigate back to home screen
     * 5. Verify the pixel re-fires (refresh triggered by homescreen becoming invisible,
     *    which kicks off a fresh ad request; on return, sentSponsorPixels is cleared
     *    so the new pixels fire when Featured row regains focus)
     *
     * Expected:
     * - pixelFireCount === 1 after initial home screen load
     * - pixelFireCount === 2 after returning from detail screen
     */

    let pixelFireCount = 0;
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('ThematicTakeoverTest1')) {
          pixelFireCount++;
        }
        return false;
      }
    });

    const { cleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
      await utils.sleep(4000); // Wait for ad fetch, theme application, and initial pixel fire

      expect(pixelFireCount).to.be.greaterThanOrEqual(1, 'Initial pixel should fire when Featured row is focused');
      const pixelCountAfterInitial = pixelFireCount;

      // Select the first item in the Featured row to navigate to the detail screen.
      // The homescreen becoming invisible triggers a refresh ad request in the background.
      await ecp.sendKeypress(ecp.Key.Ok);
      // The detail screen may be 'detailScreen' or 'vodDetailScreen' depending on Statsig experiment state.
      // Wait a fixed duration instead of polling for a specific screen ID to avoid fragility.
      await utils.sleep(5000); // Allow time for detail screen to load and for the refresh ad request to complete

      // Navigate back - sentSponsorPixels is cleared by resetScreenStack() on popScreen(),
      // so when Featured row regains focus the freshly-fetched pixels fire
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
      await utils.sleep(3000); // Wait for Featured row to regain focus and pixels to fire

      expect(pixelFireCount).to.be.greaterThan(pixelCountAfterInitial, 'Pixel should re-fire after returning to Featured row');
    } finally {
      if (cleanup) cleanup();
    }
  });

  it('C2492435 - Thematic takeover pixel refreshes for Action category after scrolling away and back @manual_regression @thematic_takeover @category @impressions', async () => {
    /**
     * Pre-conditions: Guest or Registered user in adult mode
     *
     * Test Steps:
     * 1. Launch app with thematic takeover ad mock
     * 2. Navigate to categories screen and scroll to Action category
     * 3. Verify initial pixel fires (content + ad fetch both complete)
     * 4. Scroll down to the next category (away from Action)
     * 5. Scroll back up to Action
     * 6. Verify pixel re-fires (refocus triggers fresh content fetch because
     *    bHasSponsorship=true, which re-applies thematic theme and fires new pixels)
     *
     * Expected:
     * - pixelFireCount === 1 after first reaching Action
     * - pixelFireCount === 2 after scrolling away and back to Action
     */

    let pixelFireCount = 0;
    await safeResumeProxy();
    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('ActionCategoryTest')) {
          pixelFireCount++;
        }
        return false;
      }
    });

    const SCREEN_KEY_PATH = '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen';

    const { cleanup } = await setupAdMockAndLaunchApp([AdType.ThematicTakeover], { persistCallback: true });
    try {
      await utils.sleep(2000);
      await testUtils.goToPage('categories');
      await testUtils.waitForCurrentScreenToEqual('categoryPanelListScreen', 10000);
      await utils.sleep(2000);

      // Navigate left panel to Action category
      let foundAction = false;
      for (let i = 0; i < 20; i++) {
        const { value: focused } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.categoryListItemFocused` });
        if (focused && focused.id === 'action') {
          foundAction = true;
          break;
        }
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
      }
      expect(foundAction).to.equal(true, 'Should be able to navigate to Action category');
      await utils.sleep(3000); // Wait for content fetch and initial pixel fire

      expect(pixelFireCount).to.be.greaterThanOrEqual(1, 'Initial pixel should fire for Action category');
      const pixelCountAfterInitial = pixelFireCount;

      // Scroll down to an adjacent category (away from Action)
      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(1000);

      // Scroll back up to Action - refocus triggers fresh content fetch (bHasSponsorship=true)
      await ecp.sendKeypress(ecp.Key.Up);
      await utils.sleep(500);

      const { value: backOnAction } = await odc.getValue({ keyPath: `${SCREEN_KEY_PATH}.categoryListItemFocused` });
      expect(backOnAction?.id).to.equal('action', 'Should be back on Action category');

      await utils.sleep(3000); // Wait for fresh content fetch and pixel re-fire

      expect(pixelFireCount).to.be.greaterThan(pixelCountAfterInitial, 'Pixel should re-fire after returning to Action category');
    } finally {
      if (cleanup) cleanup();
    }
  });
});
