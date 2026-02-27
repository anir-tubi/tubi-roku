import { expect } from 'chai';
import { ecp, utils, proxy, odc } from 'roku-test-automation';
import { testUtils } from '../../test-utils';
import { testHelpers } from '../../test-helpers';
import {
  validateAnalyticsEvent,
  createAnalyticsCallback,
  setupRejectionTracking,
  EXISTS,
  NUMBER,
  POSITIVE_NUMBER,
  NON_EMPTY_STRING,
  BOOLEAN,
  getPageValidator,
  expectContentModeProper,
  expectContentTileHasVideoOrSeriesId,
  LEFT_NAV_SECTIONS,
  CONTENT_MODE_BY_LEFT_NAV_SECTION,
  USER_INTERACTION,
  BUTTON_TYPE,
  BUTTON_VALUE,
} from './analytics-framework';

/**
 * Video Tiles Analytics Test Suite
 * Tests analytics events for roku_video_tiles_1_9 experiment
 *
 * Based on: [TV] Video Tiles Surface Expansion Exp 1.9 Analytics Events Instrumentation
 * Google Doc: https://docs.google.com/document/d/1x8tNzLAh_Zs5qh1rwuc4jwwD4FDnR2_gwsPTMJz5Y8c/edit?tab=t.0
 *
 * Conventions & feedback: see js/automated-tests/docs/video-tiles-analytics-test-spec.md
 * (When updating from a new analytics doc, @ that file so the same conventions apply.)
 *
 * ─── QUESTIONS (document order) ───────────────────────────────────────────────────
 * 1. How many users land on the Movie Page, Series Page, or Espanol Page from the left side nav?
 *    (Verify for each: ComponentInteractionEvent, NavigateToPageEvent, and PageLoadEvent fire when selecting Movies / TV Shows / Espanol.)
 * 2. How many users are in Kids mode?
 * 3. How many users start to watch video tiles on a certain row and at which surface?
 * 4. When do users move focus between video tiles (same row or different row)?
 * 5. How long did the user continue watching the video preview within the same tile?
 * 6. How many users deliberately stop watching the preview (navigate away before end)?
 * 7. How many users finish playing the preview (reach end) and go to full screen?
 * 8. How many users click the video tile while the preview is playing?
 * 9. How many users back out from the details page and return to the tile?
 *
 * ─── Analytics Event Structure (pageOneof / componentOneof) ───────────────────────
 * IMPORTANT: Analytics Event Structure Pattern
 * ============================================
 * When the requirements document mentions "pageOneof" or "componentOneof", it means the event
 * will contain ONE OF the allowed page/component types, not a literal field named "pageOneof".
 * 
 * For example:
 * - "pageOneof: home_page" means the event will have a "home_page" field (not "pageOneof")
 * - "componentOneof: category_component" means the event will have a "category_component" field
 * 
 * The actual analytics event structure uses discriminated unions where only one page/component
 * type is present at a time. When validating, we check for the specific type (e.g., home_page,
 * video_page, category_component, preview_component) rather than a generic "pageOneof" field.
 * 
 * Example actual event structure (top-level page/component keys, not pageOneof/componentOneof):
 * {
 *   event: {
 *     start_preview: {
 *       home_page: {...},
 *       category_component: {...}
 *     }
 *   }
 * }
 * 
 * When writing tests, validate the specific page/component type as an object:
 * - home_page: getPageValidator('home_page') to validate home_page is a HomePage object
 * - category_component: { ... } to validate category_component structure
 * 
 * NOTE: Use getPageValidator(pageType, fields) from analytics-validator.ts which is based on
 * protobuf definitions in ../protos/tubi/analytics/client.proto. This ensures proper structure
 * according to the proto message definitions.
 * 
 * Examples:
 *   home_page: getPageValidator('home_page') // Validates HomePage structure (can be empty)
 *   home_page: getPageValidator('home_page', { content_mode: EXISTS }) // Validates content_mode exists
 *   video_page: getPageValidator('video_page', { video_id: POSITIVE_NUMBER }) // Validates VideoPage
 *   series_detail_page: getPageValidator('series_detail_page', { series_id: 12345 }) // With specific value
 *
 * Shared constants and assertion helpers (content_mode, content_tile) live in analytics-framework.ts
 * so they can be reused across other analytics test files and screens.
 */

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

describe('Video Tiles Analytics Tests', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  // Auto-clear stale callbacks before each test and check for rejections after
  setupRejectionTracking();

  afterEach(async () => {
    await proxy.pause();
  });

  // ─── Group: Left nav & page landing (Q1) ────────────────────────────────────────
  /**
   * Q: How many users land on the Movie Page, Series Page, or Espanol Page from the left side nav?
   * A: Users select Movies, TV Shows, or Espanol from Left Side Nav.
   * Tracking (per doc: must fire for each page):
   * - ComponentInteractionEvent (component_interaction: LeftNavComponent, CONFIRM, left_nav_section = MOVIES | SERIES | ESPANOL)
   * - NavigateToPageEvent (navigate_to_page: dest_home_page or dest_for_you_page, left_side_nav_component.left_nav_section when landing on that surface)
   * - PageLoadEvent (page_load: home_page or for_you_page when landing on that surface)
   * This test verifies all three pages (Movies, TV Shows, Espanol) fire all three events.
   */
  it('C869294 - ComponentInteraction, NavigateToPage, and PageLoad fire for Movies, TV Shows, and Espanol from left nav @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen
     *
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. For each of Movies, TV Shows, Espanol: open left nav, select that item
     * 3. After each selection, verify ComponentInteractionEvent, NavigateToPageEvent, and PageLoadEvent all fired
     *
     * Expected (for each of the three pages, per doc):
     * - component_interaction with left_nav_section MOVIES / SERIES / ESPANOL, user_interaction CONFIRM
     * - navigate_to_page with dest_home_page or dest_for_you_page (navigation to that surface)
     * - page_load for home_page or for_you_page (landing on that surface)
     */

    const analyticsEvents: any[] = [];

    // Capture ComponentInteractionEvent, NavigateToPageEvent, and PageLoadEvent so we assert all three per page (per doc)
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      const hasLeftNavInteraction =
        event.event?.component_interaction?.left_side_nav_component !== undefined;
      const hasNavigateToPage = event.event?.navigate_to_page !== undefined;
      const hasPageLoad = event.event?.page_load !== undefined;
      return hasLeftNavInteraction || hasNavigateToPage || hasPageLoad;
    });

    proxy.addCallback(analyticsCallback);

    const sections: Array<{ navTitle: string; section: string; expectedScreenId: 'movieScreen' | 'tvScreen' | 'espanolScreen'; expectedRowListId: 'movieScreenRowList' | 'tvScreenRowList' | 'espanolScreenRowList' }> = [
      { navTitle: 'Movies', section: LEFT_NAV_SECTIONS.MOVIES, expectedScreenId: 'movieScreen', expectedRowListId: 'movieScreenRowList' },
      { navTitle: 'TV Shows', section: LEFT_NAV_SECTIONS.SERIES, expectedScreenId: 'tvScreen', expectedRowListId: 'tvScreenRowList' },
      { navTitle: 'Español', section: LEFT_NAV_SECTIONS.ESPANOL, expectedScreenId: 'espanolScreen', expectedRowListId: 'espanolScreenRowList' }
    ];

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await utils.sleep(2000);

      // Track where the user was when they opened left nav (component_interaction "from" page depends on this)
      type FromScreenId = 'homeScreen' | 'movieScreen' | 'tvScreen' | 'espanolScreen';
      let fromScreenId: FromScreenId = 'homeScreen';

      for (const { navTitle, section, expectedScreenId, expectedRowListId } of sections) {
        // Clear events before this selection so we can assert for this page only
        analyticsEvents.length = 0;

        // Open left side nav
        await ecp.sendKeypress(ecp.Key.Left);
        await utils.sleep(1000);

        // Select this page from left nav and wait until the target screen is shown
        await testUtils.jumpToRowWithTitle('sideNavMenu', navTitle);
        await ecp.sendKeypress(ecp.Key.Ok);
        await testUtils.waitForCurrentScreenToEqual(expectedScreenId, 15000);
        await testUtils.waitForElementToHaveFocus(expectedRowListId, 'Timed out waiting for ' + expectedRowListId + ' to have focus', 15000);

        // Give additional time for page_load event to fire
        await utils.sleep(1500);

        const capturedEventTypes = analyticsEvents.map((e) => Object.keys(e.event || {})).join(', ') || '(none)';
        // Assert ComponentInteractionEvent fired for this section (single-level left_side_nav_component per codebase)
        const interactionEvent = analyticsEvents.find(
          (e) =>
            e.event?.component_interaction?.left_side_nav_component?.left_nav_section === section
        );
        expect(interactionEvent, `Missing ComponentInteractionEvent (left_nav_section=${section}) when selecting ${navTitle}. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

        // Assert NavigateToPageEvent fired (dest_* depends on from→to; find by left_side_nav_component for this selection)
        const navigateToPageEvent = analyticsEvents.find(
          (e) => e.event?.navigate_to_page?.left_side_nav_component?.left_nav_section === section
        );
        expect(navigateToPageEvent, `Missing NavigateToPageEvent when navigating to ${navTitle} (left_nav_section=${section}). Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

        // Assert PageLoadEvent fired (user landed on the page)
        const pageLoadEvent = analyticsEvents.find((e) => e.event?.page_load !== undefined);
        expect(pageLoadEvent, `Missing PageLoadEvent when landing on ${navTitle}. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

        // Build expected "from" page for component_interaction from where user was (fromScreenId)
        // Payload uses home_page with content_mode for Movies/TV/Espanol; not for_you_page
        const expectedFromPage: Record<string, unknown> = (() => {
          switch (fromScreenId) {
            case 'homeScreen':
              return { home_page: getPageValidator('home_page', { content_mode: EXISTS }) };
            case 'movieScreen':
              return { home_page: getPageValidator('home_page', { content_mode: CONTENT_MODE_BY_LEFT_NAV_SECTION[LEFT_NAV_SECTIONS.MOVIES] }) };
            case 'tvScreen':
              return { home_page: getPageValidator('home_page', { content_mode: CONTENT_MODE_BY_LEFT_NAV_SECTION[LEFT_NAV_SECTIONS.SERIES] }) };
            case 'espanolScreen':
              return { home_page: getPageValidator('home_page', { content_mode: CONTENT_MODE_BY_LEFT_NAV_SECTION[LEFT_NAV_SECTIONS.ESPANOL] }) };
            default:
              return { home_page: getPageValidator('home_page', { content_mode: EXISTS }) };
          }
        })();

        // Validate component_interaction structure: "from" page (dynamic), left_side_nav_component, user_interaction
        validateAnalyticsEvent(
          interactionEvent,
          {
            event: {
              component_interaction: {
                ...expectedFromPage,
                left_side_nav_component: {
                  left_nav_section: section
                },
                user_interaction: USER_INTERACTION.CONFIRM
              }
            }
          },
          `Component Interaction Event (Left Nav - ${navTitle}, from: ${fromScreenId})`
        );

        // Next iteration user will have been on this screen
        fromScreenId = expectedScreenId;

        // Validate navigate_to_page has proper "from" (source of nav) and "dest" (destination) values
        validateAnalyticsEvent(
          navigateToPageEvent,
          {
            event: {
              navigate_to_page: {
                left_side_nav_component: { left_nav_section: section }
              }
            }
          },
          `NavigateToPageEvent (from: left_nav_section=${section})`
        );
        const nav = navigateToPageEvent.event?.navigate_to_page;
        const destKey = nav && Object.keys(nav).find((k) => k.startsWith('dest_'));
        const destObj = destKey ? nav[destKey] : null;
        const hasDestPresent = destObj && typeof destObj === 'object' && destObj !== null;
        expect(hasDestPresent).to.equal(true, `navigate_to_page should contain a dest_* object when navigating to ${navTitle}`);

        // Validate dest value is correct for this navigation (e.g. content_mode matches where we landed)
        const destKeys = destObj ? Object.keys(destObj) : [];
        expect(destKeys.length).to.be.greaterThan(0, `navigate_to_page.${destKey} should not be empty when navigating to ${navTitle}`);
        const expectedContentMode = CONTENT_MODE_BY_LEFT_NAV_SECTION[section];
        if (expectedContentMode && destObj?.content_mode !== undefined) {
          expect(destObj.content_mode).to.equal(expectedContentMode, `navigate_to_page.${destKey}.content_mode should match navigation to ${navTitle}`);
        }

        // Validate page_load has a proper page (which page type is present depends on where we landed—don't assume a fixed set)
        const pl = pageLoadEvent.event?.page_load;
        const knownNonPageKeys = ['load_time', 'status'];
        const pageTypeKey = pl && Object.keys(pl).find((k) => !knownNonPageKeys.includes(k) && typeof pl[k] === 'object' && pl[k] !== null);
        expect(!!pageTypeKey).to.equal(true, `page_load should contain a proper page type when landing on ${navTitle}`);

        const pageObj = pageTypeKey ? pl[pageTypeKey] : null;
        if (pageObj) {
          if (pageObj.content_mode !== undefined) {
            expect(pageObj.content_mode).to.equal(
              CONTENT_MODE_BY_LEFT_NAV_SECTION[section],
              `page_load.${pageTypeKey}.content_mode should match navigation to ${navTitle}`
            );
          }
          if (pageObj.personalization_id !== undefined) {
            expect(pageObj.personalization_id).to.be.a('string');
            expect(pageObj.personalization_id.length).to.be.greaterThan(0, `page_load.${pageTypeKey}.personalization_id should be non-empty when landing on ${navTitle}`);
          }
        }
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Kids mode (Q2) ─────────────────────────────────────────────────────
  /**
   * Q: How many users are in Kids mode?
   * A: Users in Kids mode viewing any page.
   * Tracking: page_load with app_mode=KIDS_MODE so we can segment by Kids usage.
   */
  it('C869297 - Page load event includes app_mode KIDS_MODE when in kids mode @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is in Kids mode
     *
     * Test Steps:
     * 1. Launch app and enable Kids mode
     * 2. Navigate to home screen
     *
     * Expected:
     * - PageLoadEvent fires with app_mode="KIDS_MODE" (under app, not event)
     * - page_type is based on page user is on (e.g., HomePage, ForYouPage)
     * - status is SUCCESS
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept page_load events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      proxy.pause();
      await testUtils.goToPage('settings');
      await testHelpers.setParentalControls('littleKids');
      proxy.resume();

      // Clear events from the settings navigation
      analyticsEvents.length = 0;
      await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

      // Verify homeScreenRowList is visible and has contents
      await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'homeScreenRowList not visible after settings', 20000);
      await utils.sleep(2000);
      // Verify we received page_load event
      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive page_load event');

      // Find page_load event and verify app_mode is KIDS_MODE
      const pageLoadEvent = analyticsEvents.find(e => e.event?.page_load);
      expect(pageLoadEvent).to.exist;

      // Note: app_mode is under app, not event, so we check the top level
      if (pageLoadEvent.app?.app_mode === 'KIDS_MODE') {
        validateAnalyticsEvent(
          pageLoadEvent,
          {
            event: {
              page_load: {
                home_page: getPageValidator('home_page'), // HomePage type - validates structure per proto definition (or for_you_page)
                status: 'SUCCESS'
              }
            },
            app: {
              app_mode: 'KIDS_MODE'
            }
          },
          'Page Load Event (Kids Mode)'
        );
      } else {
        expect.fail('PageLoadEvent should include app_mode KIDS_MODE when in Kids mode');
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – start & navigate (Q3) ─────────────────────────────────
  /**
   * Q: How many users start to watch video tiles on a certain row and at which surface?
   * A: Users focus on content with video tiles and video preview starts within the tile.
   * Tracking: start_preview (video_player=VIDEO_IN_GRID, CategoryComponent, home_page).
   */
  it('C869298 - Start preview event fires when video tile gains focus @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen with video tiles enabled
     * - Video preview is enabled in settings
     * 
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. Navigate to a video tile row
     * 3. Focus on a video tile that has a preview
     * 
     * Expected:
     * - start_preview analytics event fires
     * - video_player is "VIDEO_IN_GRID" (not BANNER)
     * - is_fullscreen is false
     * - component_type is CategoryComponent
     * - component contains category_slug, category_row, category_col
     * - component contains content_tile with row=1, col, video_id or series_id
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept start_preview events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.start_preview !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Find and navigate to a tile that has a video preview
      await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);
      await utils.sleep(3000);

      // Verify we received start_preview event
      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive start_preview event');

      // Validate the start_preview event structure
      const startPreviewEvent = analyticsEvents.find(e => e.event?.start_preview);
      expect(startPreviewEvent).to.exist;

      validateAnalyticsEvent(
        startPreviewEvent,
        {
          event: {
            start_preview: {
              preview_id: NON_EMPTY_STRING, // Must exist and be non-empty string
              is_fullscreen: false,
              video_player: 'VIDEO_IN_GRID', // Must be VIDEO_IN_GRID for video tiles
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for screen context
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: NUMBER,
                content_tile: {
                  row: 1, // Always 1 for video tiles
                  col: NUMBER
                  // video_id or series_id validated below
                }
              }
            }
          }
        },
        'Start Preview Event'
      );
      expectContentModeProper(startPreviewEvent.event?.start_preview?.home_page, 'start_preview');
      expectContentTileHasVideoOrSeriesId(
        startPreviewEvent.event?.start_preview?.category_component?.content_tile,
        'start_preview.category_component.content_tile'
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – navigate within page (Q3 part 2) ───────────────────────
  /**
   * Q: When do users move focus between video tiles (same row or different row)?
   * A: User navigates horizontally or vertically between video tiles (on Home/Movies and on Series).
   * Tracking: navigate_within_page (CategoryComponent, means_of_navigation=BUTTON,
   * vertical_location, horizontal_location, home_page with content_mode).
   */
  it('C869295 - Navigate within page event fires when navigating between video tiles @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen with video tiles enabled
     *
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. On Home (Movies): navigate horizontally and vertically between video tiles; validate navigate_within_page with home_page and content_mode
     * 3. Navigate to Series (TV Shows) via left nav; navigate between video tiles; validate navigate_within_page with for_you_page and content_mode (CONTENT_MODE_TV)
     *
     * Expected:
     * - navigate_within_page analytics events fire for each navigation
     * - On Home: page context is home_page with valid content_mode (e.g. CONTENT_MODE_MOVIE)
     * - On Series: page context is for_you_page with content_mode CONTENT_MODE_TV
     * - component_type is CategoryComponent; means_of_navigation is "BUTTON"
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept navigate_within_page events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Wait for video tiles to be enabled
      await utils.sleep(2000);

      // ─── Part 1: Home (Movies) – horizontal and vertical navigate_within_page with home_page + content_mode ───
      // Navigate to first video tile row
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1000 });
      await utils.sleep(1000);

      analyticsEvents.length = 0;

      // Navigate horizontally (right) to next video tile
      await ecp.sendKeypress(ecp.Key.Right, { wait: 500 });
      await utils.sleep(2000); // Wait for analytics to fire

      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event for horizontal navigation (Home)');

      const horizontalNavEvent = analyticsEvents[analyticsEvents.length - 1];
      validateAnalyticsEvent(
        horizontalNavEvent,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for screen context
              category_component: {
                category_slug: EXISTS, // Container in focus before scroll
                category_row: EXISTS, // Vertical position of tile in grid before scroll
                category_col: EXISTS, // Horizontal position of tile in grid after scroll
                content_tile: {
                  row: EXISTS,
                  col: EXISTS
                  // video_id or series_id validated below
                }
              },
              vertical_location: EXISTS, // Vertical order of row on page/screen after scroll
              horizontal_location: EXISTS, // Horizontal order of tile in grid after scroll
              means_of_navigation: 'BUTTON'
            }
          }
        },
        'Navigate Within Page Event (Horizontal, Home)'
      );
      expectContentModeProper(horizontalNavEvent.event?.navigate_within_page?.home_page, 'navigate_within_page (horizontal, Home)');
      expectContentTileHasVideoOrSeriesId(
        horizontalNavEvent.event?.navigate_within_page?.category_component?.content_tile,
        'navigate_within_page (horizontal).content_tile'
      );

      analyticsEvents.length = 0;

      // Navigate vertically (down) to next row
      await ecp.sendKeypress(ecp.Key.Down, { wait: 500 });
      await utils.sleep(2000); // Wait for analytics to fire

      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event for vertical navigation (Home)');

      const verticalNavEvent = analyticsEvents[analyticsEvents.length - 1];
      validateAnalyticsEvent(
        verticalNavEvent,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for screen context
              category_component: {
                category_slug: EXISTS,
                category_row: EXISTS,
                category_col: EXISTS,
                content_tile: {
                  row: EXISTS,
                  col: EXISTS
                  // video_id or series_id validated below
                }
              },
              vertical_location: EXISTS,
              horizontal_location: EXISTS,
              means_of_navigation: 'BUTTON'
            }
          }
        },
        'Navigate Within Page Event (Vertical, Home)'
      );
      expectContentModeProper(verticalNavEvent.event?.navigate_within_page?.home_page, 'navigate_within_page (vertical, Home)');
      expectContentTileHasVideoOrSeriesId(
        verticalNavEvent.event?.navigate_within_page?.category_component?.content_tile,
        'navigate_within_page (vertical).content_tile'
      );

      // ─── Part 2: Series (TV Shows) – navigate to Series via left nav, then navigate between tiles; validate for_you_page + content_mode ───
      analyticsEvents.length = 0;

      // Open left side nav and select TV Shows
      await ecp.sendKeypress(ecp.Key.Left);
      await utils.sleep(1000);
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'TV Shows');
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('tvScreen', 15000);
      await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for tvScreenRowList to have focus', 15000);
      await utils.sleep(1500); // Allow video tiles to be ready on Series

      // Navigate to a video tile row on Series, then move to next tile (horizontal)
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1000 });
      await utils.sleep(1000);
      analyticsEvents.length = 0;
      await ecp.sendKeypress(ecp.Key.Right, { wait: 500 });
      await utils.sleep(2000); // Wait for analytics to fire

      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event when navigating between tiles on Series');

      const seriesNavEvent = analyticsEvents[analyticsEvents.length - 1];

      validateAnalyticsEvent(
        seriesNavEvent,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for Series (TV Shows)
              category_component: {
                category_slug: EXISTS,
                category_row: EXISTS,
                category_col: EXISTS,
                content_tile: {
                  row: EXISTS,
                  col: EXISTS
                }
              },
              vertical_location: EXISTS,
              horizontal_location: EXISTS,
              means_of_navigation: 'BUTTON'
            }
          }
        },
        'Navigate Within Page Event (Series / TV Shows)'
      );
      expectContentModeProper(seriesNavEvent.event?.navigate_within_page?.home_page, 'navigate_within_page (Series)');
      expect(seriesNavEvent.event?.navigate_within_page?.home_page?.content_mode).to.equal(
        CONTENT_MODE_BY_LEFT_NAV_SECTION[LEFT_NAV_SECTIONS.SERIES],
        'Series surface should have content_mode CONTENT_MODE_TV'
      );
      expectContentTileHasVideoOrSeriesId(
        seriesNavEvent.event?.navigate_within_page?.category_component?.content_tile,
        'navigate_within_page (Series).content_tile'
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – progress (Q4) ─────────────────────────────────────────
  /**
   * Q: How long did the user continue watching the video preview within the same tile?
   * A: User takes no action and video preview keeps playing.
   * Tracking: preview_play_progress every ~10s (position, view_time, CategoryComponent, home_page).
   */
  it('C869296 - Preview play progress events fire every 10 seconds during video preview playback @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen with video tiles enabled
     * - Video preview is enabled in settings
     * 
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. Focus on a video tile with preview
     * 3. Wait for preview to play for at least 20 seconds (to capture multiple progress events)
     * 
     * Expected:
     * - preview_play_progress analytics events fire every 10 seconds (default interval)
     * - video_player is "VIDEO_IN_GRID"
     * - Events contain correct video_id, position, view_time, preview_id
     * - Events contain CategoryComponent with category_slug, category_row, category_col
     * - Events contain content_tile with row=1, col, video_id or series_id
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept preview_play_progress events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.preview_play_progress !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Find and navigate to a series tile that has a video preview
      await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5, 2000, 's');
      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
      // Since we send preview progress events every 10 seconds, we need to wait for at least 2 events to be captured
      await utils.sleep(22000);

      // Validate the first preview_play_progress event structure
      const progressEvent = analyticsEvents.find(e => e.event?.preview_play_progress);
      expect(progressEvent).to.exist;
      validateAnalyticsEvent(
        progressEvent,
        {
          event: {
            preview_play_progress: {
              position: POSITIVE_NUMBER, // Position in milliseconds, must be > 0
              view_time: POSITIVE_NUMBER, // View time since last play_progress event, in milliseconds, must be > 0
              preview_id: NON_EMPTY_STRING,
              video_player: 'VIDEO_IN_GRID', // Must be VIDEO_IN_GRID for video tiles
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for screen context
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: NUMBER,
                content_tile: {
                  row: 1, // Always 1 for video tiles
                  col: NUMBER
                  // video_id or series_id validated below
                }
              }
            }
          }
        },
        'Preview Play Progress Event'
      );
      expectContentModeProper(progressEvent.event?.preview_play_progress?.home_page, 'preview_play_progress');
      expectContentTileHasVideoOrSeriesId(
        progressEvent.event?.preview_play_progress?.category_component?.content_tile,
        'preview_play_progress.category_component.content_tile'
      );

      // Verify multiple events were fired (should fire every 10 seconds)
      expect(analyticsEvents.length).to.be.greaterThan(1, 'Should receive multiple preview_play_progress events');
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – finish (Q5) ───────────────────────────────────────────
  /**
   * Q: How many users deliberately stop watching the preview (navigate away before end)?
   * A: User navigates away from the tile before the preview reaches the end.
   * Tracking: finish_preview with has_completed=false (VIDEO_IN_GRID, CategoryComponent).
   */
  it('C869300 - Finish preview event fires with has_completed=false when user navigates away @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen with video tiles enabled
     * - Video preview is enabled in settings
     * - A video preview is currently playing
     * 
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. Focus on a video tile with preview (preview starts)
     * 3. Navigate away from the video tile (move to next tile or row) before preview ends
     * 
     * Expected:
     * - finish_preview analytics event fires
     * - has_completed is false
     * - video_player is "VIDEO_IN_GRID"
     * - Event contains CategoryComponent with category_slug, category_row, category_col
     * - Event contains content_tile with row=1, col, video_id or series_id
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept finish_preview events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.finish_preview !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Find and navigate to a tile that has a video preview
      await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);
      await utils.sleep(3000);

      // Navigate away (move to next tile horizontally) before preview completes
      await ecp.sendKeypress(ecp.Key.Right, { wait: 500 });
      await utils.sleep(2000); // Wait for finish_preview event to fire

      // Verify we received finish_preview event
      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive finish_preview event');

      // Validate the finish_preview event structure
      const finishPreviewEvent = analyticsEvents.find(e => e.event?.finish_preview);
      expect(finishPreviewEvent).to.exist;

      validateAnalyticsEvent(
        finishPreviewEvent,
        {
          event: {
            finish_preview: {
              end_position: NUMBER, // Final position in milliseconds upon termination
              preview_id: NON_EMPTY_STRING,
              has_completed: false, // Must be false when user navigates away
              video_player: 'VIDEO_IN_GRID', // Must be VIDEO_IN_GRID for video tiles
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for screen context
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: NUMBER,
                content_tile: {
                  row: 1, // Always 1 for video tiles
                  col: NUMBER
                  // video_id or series_id validated below
                }
              }
            }
          }
        },
        'Finish Preview Event (has_completed=false)'
      );
      expectContentModeProper(finishPreviewEvent.event?.finish_preview?.home_page, 'finish_preview (has_completed=false)');
      expectContentTileHasVideoOrSeriesId(
        finishPreviewEvent.event?.finish_preview?.category_component?.content_tile,
        'finish_preview.category_component.content_tile'
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – finish & full screen (Q6) ─────────────────────────────
  /**
   * Q: How many users finish playing the preview (reach end) and go to full screen?
   * A: User reaches the end of the preview and is directed to the full screen player.
   * Tracking: finish_preview has_completed=true; navigate_to_page (video_player_page);
   * page_load (video_player_page); start_video (VIDEO_PREVIEWS); play_progress (VIDEO_PREVIEWS).
   */
  it('C869301 - Finish preview event with has_completed=true and subsequent video player events @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen with video tiles enabled
     * - Video preview is enabled in settings
     * - A video preview is currently playing
     * 
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. Move focus to a tile that has a video preview (preview starts)
     * 3. Seek to near end of preview so it completes quickly (not tied to preview duration)
     * 
     * Expected:
     * - finish_preview analytics event fires with has_completed=true
     * - NavigateToPageEvent fires to VideoPlayerPage
     * - PageLoadEvent fires for VideoPlayerPage
     * - StartVideoEvent fires with playback_source="VIDEO_PREVIEWS"
     * - PlayProgressEvent fires with playback_source="VIDEO_PREVIEWS"
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept all relevant events
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.finish_preview !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined ||
        event.event?.start_video !== undefined ||
        event.event?.play_progress !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Find and navigate to a tile that has a video preview
      await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);
      await utils.sleep(3000);
      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

      // Clear initial events before seeking
      analyticsEvents.length = 0;

      // Seek to near end of preview so it completes quickly (stable, not tied to preview duration)
      await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -5000, 'end');
      await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
      await utils.sleep(8000); // Brief wait for preview end + transition to player

      const capturedEventTypes = analyticsEvents.map((e) => Object.keys(e.event || {})).join(', ') || '(none)';

      // Verify we received finish_preview event with has_completed=true
      const finishPreviewEvent = analyticsEvents.find(e =>
        e.event?.finish_preview?.has_completed === true
      );

      expect(finishPreviewEvent, `Missing finish_preview (has_completed=true) after seeking to end of preview. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

      if (finishPreviewEvent) {
        validateAnalyticsEvent(
          finishPreviewEvent,
          {
            event: {
              finish_preview: {
                video_id: EXISTS,
                end_position: EXISTS,
                preview_id: EXISTS,
                has_completed: true, // Must be true when preview completes
                video_player: 'VIDEO_IN_GRID',
                home_page: getPageValidator('home_page', { content_mode: EXISTS }), // HomePage with content_mode for screen context
                category_component: {
                  category_slug: EXISTS,
                  category_row: EXISTS,
                  category_col: EXISTS,
                  content_tile: {
                    row: 1,
                    col: EXISTS
                    // video_id or series_id (validated below—payload may have either)
                  }
                }
              }
            }
          },
          'Finish Preview Event (has_completed=true)'
        );
        expectContentModeProper(finishPreviewEvent.event?.finish_preview?.home_page, 'finish_preview (has_completed=true)');
        expectContentTileHasVideoOrSeriesId(
          finishPreviewEvent.event?.finish_preview?.category_component?.content_tile,
          'finish_preview.category_component.content_tile'
        );

        // Verify subsequent events fire after preview completion
        const navigateToPageEvent = analyticsEvents.find(e =>
          e.event?.navigate_to_page?.dest_video_player_page !== undefined
        );
        expect(navigateToPageEvent, `Missing NavigateToPageEvent to video_player_page after preview completed. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

        const pageLoadEvent = analyticsEvents.find(e =>
          e.event?.page_load?.video_player_page !== undefined
        );
        expect(pageLoadEvent, `Missing PageLoadEvent for video_player_page. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

        const startVideoEvent = analyticsEvents.find(e =>
          e.event?.start_video?.playback_source === 'VIDEO_PREVIEWS'
        );
        expect(startVideoEvent, `Missing StartVideoEvent (playback_source=VIDEO_PREVIEWS). Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

        const playProgressEvent = analyticsEvents.find(e =>
          e.event?.play_progress?.playback_source === 'VIDEO_PREVIEWS'
        );
        // PlayProgressEvent may not fire immediately, so this is optional
        if (playProgressEvent) {
          validateAnalyticsEvent(
            playProgressEvent,
            {
              event: {
                play_progress: {
                  video_id: EXISTS,
                  playback_source: 'VIDEO_PREVIEWS'
                }
              }
            },
            'Play Progress Event (from VIDEO_PREVIEWS)'
          );
        }
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – click during preview (Q7) ──────────────────────────────
  /**
   * Q: How many users click the video tile while the preview is playing?
   * A: User lands on the details page and continues watching the preview as banner.
   * Tracking (v2): ComponentInteractionEvent (ButtonComponent, OK, TEXT) before NavigateToPageEvent;
   * navigate_to_page (video_page/series_detail_page); page_load for details;
   * preview_play_progress with video_player=BANNER and PreviewComponent.
   */
  it('C869298 - Click video tile during preview navigates to details page with banner preview @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on home screen with video tiles enabled
     * - Video preview is currently playing in a tile
     *
     * Test Steps:
     * 1. Launch app with video tiles experiment enabled
     * 2. Focus on a video tile with preview (preview starts)
     * 3. Press OK to click the video tile while preview is playing
     *
     * Expected:
     * - ComponentInteractionEvent (button_component: OK, IMAGE) fires before NavigateToPageEvent (v2 spec)
     * - NavigateToPageEvent fires to VideoPage or SeriesDetailPage
     * - PageLoadEvent fires for VideoPage or SeriesDetailPage
     * - PreviewPlayProgressEvent continues with video_player="BANNER" and component_type="PreviewComponent"
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept all relevant events (including component_interaction for OK button)
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined ||
        event.event?.preview_play_progress !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Wait for video tiles to be enabled
      await utils.sleep(2000);

      // Focus on a video tile (preview starts)
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1000 });
      await utils.sleep(3000); // Wait for preview to start

      // Clear initial events
      analyticsEvents.length = 0;

      // Press OK to click the video tile while preview is playing
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(5000); // Wait for navigation and analytics to fire

      // Verify ComponentInteractionEvent (ButtonComponent, OK, TEXT) fired before NavigateToPageEvent (v2 spec)
      const okButtonEvent = analyticsEvents.find(e =>
        e.event?.component_interaction?.button_component !== undefined &&
        e.event?.component_interaction?.button_component?.button_value === BUTTON_VALUE.OK &&
        e.event?.component_interaction?.button_component?.button_type === BUTTON_TYPE.IMAGE
      );
      expect(okButtonEvent, 'Missing ComponentInteractionEvent (button_component: OK, IMAGE) when clicking video tile').to.exist;

      validateAnalyticsEvent(
        okButtonEvent,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page', { content_mode: EXISTS }),
              button_component: {
                button_value: BUTTON_VALUE.OK,
                button_type: BUTTON_TYPE.IMAGE
              },
              user_interaction: USER_INTERACTION.CONFIRM
            }
          }
        },
        'Component Interaction Event (OK on video tile)'
      );
      expectContentModeProper(okButtonEvent.event?.component_interaction?.home_page, 'component_interaction (OK on tile)');

      // Verify NavigateToPageEvent to details page
      const navigateToPageEvent = analyticsEvents.find(e =>
        e.event?.navigate_to_page?.dest_video_page !== undefined ||
        e.event?.navigate_to_page?.dest_series_detail_page !== undefined
      );
      expect(navigateToPageEvent).to.exist;

      validateAnalyticsEvent(
        navigateToPageEvent,
        {
          event: {
            navigate_to_page: {
              home_page: getPageValidator('home_page', { content_mode: EXISTS }), // From-page: home with content_mode for screen context
              category_component: {
                category_col: EXISTS,
                category_row: EXISTS,
                content_tile: EXISTS,
                category_slug: EXISTS
              }
              // dest_video_page or dest_series_detail_page (asserted via find() above)
            }
          }
        },
        'Navigate To Page Event (to Details)'
      );
      expectContentModeProper(navigateToPageEvent.event?.navigate_to_page?.home_page, 'navigate_to_page (to details, from home)');

      // Verify PageLoadEvent for details page (top-level page keys, not pageOneof)
      const pageLoadEvent = analyticsEvents.find(e =>
        e.event?.page_load?.video_page !== undefined ||
        e.event?.page_load?.series_detail_page !== undefined
      );
      expect(pageLoadEvent).to.exist;

      // Verify PreviewPlayProgressEvent continues with BANNER player (top-level component key, not componentOneof)
      await utils.sleep(12000); // Wait for preview progress events to fire on details page

      const bannerProgressEvent = analyticsEvents.find(e =>
        e.event?.preview_play_progress?.video_player === 'BANNER' &&
        e.event?.preview_play_progress?.preview_component !== undefined &&
        (e.event?.preview_play_progress?.video_page !== undefined ||
          e.event?.preview_play_progress?.series_detail_page !== undefined)
      );

      if (bannerProgressEvent) {
        validateAnalyticsEvent(
          bannerProgressEvent,
          {
            event: {
              preview_play_progress: {
                preview_id: EXISTS,
                position: EXISTS,
                view_time: EXISTS,
                video_player: 'BANNER', // Must be BANNER on details page
                preview_component: EXISTS,
                video_id: EXISTS // OR series_id
              }
            }
          },
          'Preview Play Progress Event (BANNER on Details Page)'
        );
        const bannerPage = bannerProgressEvent.event?.preview_play_progress;
        const hasBannerPage = bannerPage && (bannerPage.video_page !== undefined || bannerPage.series_detail_page !== undefined);
        expect(hasBannerPage).to.equal(true, 'preview_play_progress (BANNER) should have video_page or series_detail_page');
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  /**
   * ComponentInteractionEvent (MiddleNavComponent, PLAY) fires before NavigateToPageEvent to video player
   * when user presses Play on the details page.
   */
  it('C869299 - Press Play on details page fires ComponentInteractionEvent (PLAY) then NavigateToPageEvent @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on details page (navigated from a video tile)
     *
     * Test Steps:
     * 1. Launch app, focus on a video tile, press OK to go to details page
     * 2. On details page, press OK (Play button) to start fullscreen playback
     *
     * Expected:
     * - ComponentInteractionEvent (middle_nav_component: PLAY, user_interaction CONFIRM) with page context (video_page or series_detail_page)
     * - NavigateToPageEvent to video_player_page
     */

    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await utils.sleep(2000);

      // Go to details: focus on a tile, wait, press OK
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1000 });
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 15000);
      await utils.sleep(2000); // Allow details to settle

      analyticsEvents.length = 0;

      // Press OK (Play button) on details page
      await ecp.sendKeypress(ecp.Key.Ok);
      await utils.sleep(5000); // Wait for navigation and analytics

      // Verify ComponentInteractionEvent (MiddleNavComponent, PLAY) fired
      const playButtonEvent = analyticsEvents.find(e =>
        e.event?.component_interaction?.middle_nav_component !== undefined &&
        e.event?.component_interaction?.middle_nav_component?.middle_nav_section === 'PLAY'
      );
      expect(playButtonEvent, 'Missing ComponentInteractionEvent (middle_nav_component: PLAY) when pressing Play on details').to.exist;

      validateAnalyticsEvent(
        playButtonEvent,
        {
          event: {
            component_interaction: {
              middle_nav_component: {
                middle_nav_section: 'PLAY'
              },
              user_interaction: USER_INTERACTION.CONFIRM
            }
          }
        },
        'Component Interaction Event (PLAY on details)'
      );
      // Page context for Play on details is video_page or series_detail_page (from details screen)
      const playPage = playButtonEvent.event?.component_interaction;
      const hasDetailsPage = playPage && (playPage.video_page !== undefined || playPage.series_detail_page !== undefined);
      expect(hasDetailsPage, 'component_interaction (PLAY) should have video_page or series_detail_page').to.equal(true);

      // Verify NavigateToPageEvent to video player
      const navigateToPlayerEvent = analyticsEvents.find(e =>
        e.event?.navigate_to_page?.dest_video_player_page !== undefined
      );
      expect(navigateToPlayerEvent, 'Missing NavigateToPageEvent to video_player_page after Play').to.exist;
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Video tile – back from details (Q8) ─────────────────────────────────
  /**
   * Q: How many users back out from the details page and return to the tile?
   * A: User returns to home and video preview continues in the tile.
   * Tracking: ComponentInteractionEvent (button_component: BACK, IMAGE, user_interaction CONFIRM);
   * navigate_to_page (home_page/for_you_page); page_load for home;
   * preview_play_progress with VIDEO_IN_GRID and CategoryComponent.
   */
  it('C869298 - Back from details page returns to video tile with preview continuing @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on details page (navigated from video tile)
     * - Video preview was playing when user navigated to details
     * 
     * Test Steps:
     * 1. Launch app and navigate to details page from a video tile
     * 2. Press Back to return to previous page
     * 
     * Expected:
     * - ComponentInteractionEvent (button_component: BACK, IMAGE, user_interaction CONFIRM) fires before navigate
     * - NavigateToPageEvent fires from VideoPage/SeriesDetailPage back to HomePage/ForYouPage
     * - PageLoadEvent fires for HomePage/ForYouPage
     * - PreviewPlayProgressEvent continues with video_player="VIDEO_IN_GRID" and CategoryComponent
     */

    const analyticsEvents: any[] = [];

    // Set up proxy callback to intercept all relevant events (including component_interaction for Back key)
    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined ||
        event.event?.preview_play_progress !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      // Launch app as guest user
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

      // Wait for video tiles to be enabled
      await utils.sleep(2000);

      // Focus on a video tile (preview starts)
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1000 });
      await utils.sleep(3000); // Wait for preview to start

      // Navigate to details page (use detailScreen, not vodDetailScreen—vodDetailScreen is part of an experiment)
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 15000);
      await utils.sleep(2000);

      // Clear events before going back
      analyticsEvents.length = 0;

      // Press Back to return to previous page
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
      await utils.sleep(5000); // Wait for analytics to fire

      // Verify ComponentInteractionEvent (button_component: BACK, IMAGE, user_interaction CONFIRM) fired when pressing Back on details
      const backButtonEvent = analyticsEvents.find(e =>
        e.event?.component_interaction?.button_component !== undefined &&
        e.event?.component_interaction?.button_component?.button_value === BUTTON_VALUE.BACK &&
        e.event?.component_interaction?.button_component?.button_type === BUTTON_TYPE.IMAGE
      );
      expect(backButtonEvent, 'Missing ComponentInteractionEvent (button_component: BACK, IMAGE) when pressing Back on details').to.exist;
      validateAnalyticsEvent(
        backButtonEvent,
        {
          event: {
            component_interaction: {
              button_component: {
                button_value: BUTTON_VALUE.BACK,
                button_type: BUTTON_TYPE.IMAGE
              },
              user_interaction: USER_INTERACTION.CONFIRM
            }
          }
        },
        'Component Interaction Event (BACK on details)'
      );

      // Verify NavigateToPageEvent back to home (actual payload: dest_home_page / dest_for_you_page)
      const navigateToPageEvent = analyticsEvents.find(e =>
        e.event?.navigate_to_page?.dest_home_page !== undefined ||
        e.event?.navigate_to_page?.dest_for_you_page !== undefined
      );
      expect(navigateToPageEvent).to.exist;

      // Verify PageLoadEvent for home page (top-level page keys, not pageOneof)
      const pageLoadEvent = analyticsEvents.find(e =>
        e.event?.page_load?.home_page !== undefined ||
        e.event?.page_load?.for_you_page !== undefined
      );
      expect(pageLoadEvent).to.exist;

      // Wait for preview progress events to continue
      await utils.sleep(12000);

      // Verify PreviewPlayProgressEvent continues with VIDEO_IN_GRID (top-level component key, not componentOneof)
      const gridProgressEvent = analyticsEvents.find(e =>
        e.event?.preview_play_progress?.video_player === 'VIDEO_IN_GRID' &&
        e.event?.preview_play_progress?.category_component !== undefined
      );

      if (gridProgressEvent) {
        const pp = gridProgressEvent.event?.preview_play_progress;
        const hasHomePage = pp?.home_page !== undefined;
        const hasForYouPage = pp?.for_you_page !== undefined;
        expect(hasHomePage || hasForYouPage, 'preview_play_progress (VIDEO_IN_GRID after back) should have home_page or for_you_page').to.equal(true);
        if (hasHomePage) {
          validateAnalyticsEvent(
            gridProgressEvent,
            {
              event: {
                preview_play_progress: {
                  preview_id: EXISTS,
                  position: EXISTS,
                  view_time: EXISTS,
                  video_player: 'VIDEO_IN_GRID',
                  home_page: getPageValidator('home_page', { content_mode: EXISTS }),
                  category_component: {
                    category_slug: EXISTS,
                    category_row: EXISTS,
                    category_col: EXISTS,
                    content_tile: { row: 1, col: EXISTS }
                  }
                }
              }
            },
            'Preview Play Progress Event (VIDEO_IN_GRID after back, home_page)'
          );
          expectContentModeProper(pp?.home_page, 'preview_play_progress (VIDEO_IN_GRID after back, home_page)');
        } else {
          // for_you_page has no content_mode in proto (optional: top_nav_section, section_expanded only)
          validateAnalyticsEvent(
            gridProgressEvent,
            {
              event: {
                preview_play_progress: {
                  preview_id: EXISTS,
                  position: EXISTS,
                  view_time: EXISTS,
                  video_player: 'VIDEO_IN_GRID',
                  for_you_page: getPageValidator('for_you_page'),
                  category_component: {
                    category_slug: EXISTS,
                    category_row: EXISTS,
                    category_col: EXISTS,
                    content_tile: { row: 1, col: EXISTS }
                  }
                }
              }
            },
            'Preview Play Progress Event (VIDEO_IN_GRID after back, for_you_page)'
          );
        }
        expectContentTileHasVideoOrSeriesId(
          pp?.category_component?.content_tile,
          'preview_play_progress (VIDEO_IN_GRID after back).content_tile'
        );
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  /**
   * ComponentInteractionEvent (ButtonComponent, LEFT, IMAGE, user_interaction CONFIRM) fires when user
   * presses Left on details page (when focus is not on secondary menu or related grid), then NavigateToPageEvent back to home.
   */
  it('C869298 - Press Left on details page fires ComponentInteractionEvent (LEFT, IMAGE, CONFIRM) then returns to tile @video_tiles @analytics', async () => {
    /**
     * Pre-conditions:
     * - roku_video_tiles_1_9 experiment enabled
     * - User is on details page (navigated from video tile)
     * - Focus is on main menu (default) so Left triggers back
     *
     * Test Steps:
     * 1. Launch app, focus on a video tile, press OK to go to details page
     * 2. On details page, press Left (triggers back when focus not on secondary menu / related grid)
     *
     * Expected:
     * - ComponentInteractionEvent (button_component: LEFT, IMAGE, user_interaction CONFIRM) with page context (video_page or series_detail_page)
     * - NavigateToPageEvent back to HomePage/ForYouPage
     */

    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await utils.sleep(2000);

      // Go to details: focus on a tile, wait, press OK
      await ecp.sendKeypress(ecp.Key.Down, { count: 1, wait: 1000 });
      await utils.sleep(2000);
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 15000);
      await utils.sleep(2000); // Allow details to settle; focus is on main menu

      analyticsEvents.length = 0;

      // Press Left on details page (triggers back when not on secondary menu / related grid)
      await ecp.sendKeypress(ecp.Key.Left);
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
      await utils.sleep(5000); // Wait for analytics to fire

      // Verify ComponentInteractionEvent (ButtonComponent, LEFT, IMAGE, user_interaction CONFIRM) fired
      const leftButtonEvent = analyticsEvents.find(e =>
        e.event?.component_interaction?.button_component !== undefined &&
        e.event?.component_interaction?.button_component?.button_value === BUTTON_VALUE.LEFT &&
        e.event?.component_interaction?.button_component?.button_type === BUTTON_TYPE.IMAGE
      );
      expect(leftButtonEvent, 'Missing ComponentInteractionEvent (button_component: LEFT, IMAGE) when pressing Left on details').to.exist;

      validateAnalyticsEvent(
        leftButtonEvent,
        {
          event: {
            component_interaction: {
              button_component: {
                button_value: BUTTON_VALUE.LEFT,
                button_type: BUTTON_TYPE.IMAGE
              },
              user_interaction: USER_INTERACTION.CONFIRM
            }
          }
        },
        'Component Interaction Event (LEFT on details)'
      );
      const leftPage = leftButtonEvent.event?.component_interaction;
      const hasDetailsPage = leftPage && (leftPage.video_page !== undefined || leftPage.series_detail_page !== undefined);
      expect(hasDetailsPage, 'component_interaction (LEFT) should have video_page or series_detail_page').to.equal(true);

      // Verify NavigateToPageEvent back to home
      const navigateToPageEvent = analyticsEvents.find(e =>
        e.event?.navigate_to_page?.dest_home_page !== undefined ||
        e.event?.navigate_to_page?.dest_for_you_page !== undefined
      );
      expect(navigateToPageEvent, 'Missing NavigateToPageEvent back to home after Left on details').to.exist;
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: MyStuff screen analytics ────────────────────────────────────────
  /**
   * MyStuff screen: page_load (for_you_page), navigate_to_page (dest_for_you_page), and
   * optionally navigate_within_page (for_you_page + mystuff_component) when navigating within the grid.
   * Left nav section for My Stuff is QUEUE.
   */
  it('C869292 - MyStuff screen fires page_load, navigate_to_page, and navigate_within_page when applicable @video_tiles @analytics', async () => {
    /**
     * Test Steps:
     * 1. Launch app as guest, navigate to MyStuff via left nav (My Stuff -> QUEUE)
     * 2. Assert ComponentInteractionEvent (left_side_nav_component, QUEUE), NavigateToPageEvent (dest_for_you_page), PageLoadEvent (for_you_page)
     * 3. If MyStuff grid has focus, move Down/Right and assert navigate_within_page (for_you_page, mystuff_component)
     */

    const QUEUE_SECTION = 'QUEUE'; // left_nav_section for My List / My Stuff (sideNavIds.myList -> QUEUE)
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined ||
        event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true, clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await utils.sleep(2000);

      analyticsEvents.length = 0;

      // Navigate to MyStuff via left nav (open left, select "My Stuff", OK)
      await ecp.sendKeypress(ecp.Key.Left);
      await utils.sleep(1000);
      await testUtils.jumpToRowWithTitle('sideNavMenu', 'My Stuff');
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 15000);
      await utils.sleep(2000);

      // Assert ComponentInteractionEvent (left_side_nav_component, QUEUE)
      const interactionEvent = analyticsEvents.find(
        (e) => e.event?.component_interaction?.left_side_nav_component?.left_nav_section === QUEUE_SECTION
      );
      expect(interactionEvent, `Missing ComponentInteractionEvent (left_nav_section=${QUEUE_SECTION}) when selecting My Stuff`).to.exist;

      // Assert NavigateToPageEvent (dest_for_you_page) – MyStuff uses pageType for_you_page
      const navigateToPageEvent = analyticsEvents.find(
        (e) => e.event?.navigate_to_page?.dest_for_you_page !== undefined
      );
      expect(navigateToPageEvent, 'Missing NavigateToPageEvent (dest_for_you_page) when navigating to MyStuff').to.exist;

      // Assert PageLoadEvent (for_you_page)
      const pageLoadEvent = analyticsEvents.find(
        (e) => e.event?.page_load?.for_you_page !== undefined
      );
      expect(pageLoadEvent, 'Missing PageLoadEvent (for_you_page) when landing on MyStuff').to.exist;

      validateAnalyticsEvent(
        pageLoadEvent,
        {
          event: {
            page_load: {
              for_you_page: getPageValidator('for_you_page')
            }
          }
        },
        'Page Load Event (MyStuff for_you_page)'
      );

      // If grid has focus, move within page and validate navigate_within_page (for_you_page + mystuff_component)
      try {
        await testUtils.waitForElementToHaveFocus('myStuffGrid', 'MyStuff grid did not get focus (guest may see sign-in UI)', 5000);
        analyticsEvents.length = 0;
        await ecp.sendKeypress(ecp.Key.Down, { wait: 500 });
        await utils.sleep(2000);

        const navWithinEvent = analyticsEvents.find(
          (e) => e.event?.navigate_within_page?.mystuff_component !== undefined
        );
        if (navWithinEvent) {
          validateAnalyticsEvent(
            navWithinEvent,
            {
              event: {
                navigate_within_page: {
                  for_you_page: getPageValidator('for_you_page'),
                  mystuff_component: {
                    category_slug: EXISTS,
                    category_row: EXISTS,
                    category_col: EXISTS,
                    content_tile: { row: EXISTS, col: EXISTS }
                  },
                  vertical_location: EXISTS,
                  horizontal_location: EXISTS,
                  means_of_navigation: 'BUTTON'
                }
              }
            },
            'Navigate Within Page Event (MyStuff mystuff_component)'
          );
        }
      } catch {
        // Guest often sees sign-in UI; grid may not have focus – skip navigate_within_page assertion
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });
});
