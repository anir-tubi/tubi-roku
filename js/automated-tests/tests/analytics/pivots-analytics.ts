import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../../test-utils';
import { testHelpers } from '../../test-helpers';
import {
  validateAnalyticsEvent,
  createAnalyticsCallback,
  setupRejectionTracking,
  findAnalyticsEvent,
  EXISTS,
  NUMBER,
  POSITIVE_NUMBER,
  NON_EMPTY_STRING,
  getPageValidator,
  expectContentTileHasVideoOrSeriesId,
  USER_INTERACTION,
  BUTTON_TYPE,
  BUTTON_VALUE,
  VIDEO_PLAYER,
  PLAYBACK_SOURCE,
} from './analytics-framework';

/**
 * Pivots Analytics Test Suite
 * Tests analytics events for roku_pivots_v1_2 experiment
 *
 * Based on: [TV] Homegrid Pivots Exp 1.1 Analytics Event Instrumentation
 * Doc: js/automated-tests/docs/[TV] Pivots Analytics Event Instrumentation.md
 *
 * ─── QUESTIONS (document order) ───────────────────────────────────────────────────
 * 1. How many users land on the pivot menu in homegrid and focus on the first pill? (Up/Back)
 * 2. How many users land on the pivot menu in homegrid and focus on the first pill? (Right from nav)
 * 3. How many users navigate between the pivots within the pivot menu on homegrid?
 * 4. How many users move focus away from the pivot menu without clicking into the pivot?
 * 5. How many users move focus from the pivot row to the left nav?
 * 6. How many users select the search button at the last of the pivot row and land on the search page?
 * 7. How many users select one of the pivots on the pivot menu and land on the pivot page?
 * 8. How many users start to watch video previews on pivot page?
 * 9. How many users browse or navigate between the tiles within the pivot page?
 * 10. How long did the user continue watching the video preview within the same tile on the pivot page?
 * 11. How many users deliberately stop watching the video previews within the tiles?
 * 12. How many users select a title on the pivot page and land on content details page?
 * 13. How many users deliberately play a content on the pivot page and immediately enter playback?
 * 14. How many users start to watch linear/live content on pivot page?
 * 15. How long did the user continue watching the linear content within the same tile on the pivot page?
 * 16. How many users initially watch a linear content on the pivot page and continue watching in fullscreen player?
 * 17. How many users get back from search to the homepage and return to the search pivot?
 * 18. How many users get back to the homepage and return to the last selected pivot?
 * 19. How many users get back to the pivot page and return to the previous focus?
 * 20. How many users finish watching the video previews within the tiles on the pivot page?
 *
 * ─── Analytics Event Structure (pageOneof / componentOneof) ───────────────────────
 * IMPORTANT: When the doc mentions "pageOneof" or "componentOneof", the event contains
 * ONE OF the allowed page/component types as a top-level key, not a literal "pageOneof" field.
 *
 * For pivot page events:
 *   collection_page: { section: "PIVOT", id: "[pivot name]" }
 *
 * For home page events:
 *   home_page: { content_mode: ... }
 */

/**
 * Helper: start application with pivot experiment overrides
 */
async function startApplicationWithPivotExperiment(args: any = {}) {
  return await testUtils.startApplicationAtPage('home' as any, {
    ...args,
    experimentOverrides: {
      roku_pivots_v1_2: {
        default: { "enabled": true, "treatment_group": "hard-coded", "background_enabled": false, "remove_pivots": [] }
      }
    }
  });
}

/**
 * Helper: safely resume proxy (start if not started)
 */
async function safeResumeProxy(): Promise<void> {
  try {
    proxy.resume();
  } catch (e) {
    await proxy.start();
  }
}

/**
 * Helper: navigate up to pivot list and wait for focus
 */
async function navigateToPivotList(): Promise<void> {
  await ecp.sendKeypress(ecp.Key.Up);
  await testUtils.waitForElementToHaveFocus(
    'pivotList',
    'Pivot list should have focus after navigating up',
    5000,
  );
}

/**
 * Helper: select a pivot and wait for pivot detail screen
 */
async function selectPivotAndWaitForDetailScreen(): Promise<void> {
  await ecp.sendKeypress(ecp.Key.Ok);
  await testUtils.waitForCurrentScreenToEqual('pivotDetailScreen', 10000);
  await testUtils.waitForElementToHaveFocus('pivotDetailRowList', 'Pivot detail row list should have focus', 10000);
}

describe('Pivots Analytics Tests', function () {
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

  // ─── Group: Home Page – Focus on pivot menu via Up/Back (Q1) ────────────────────
  /**
   * Q1: How many users land on the pivot menu in homegrid and focus on the first pill?
   * A: Users click the "Up" button using the remote
   * Tracking:
   *   - ComponentInteractionEvent (ButtonComponent, button_value=UP_FOCUS_PIVOT, CONFIRM)
   *   - ComponentInteractionEvent (CollectionComponent, sub_type=PIVOT, TOGGLE_ON)
   *   - NavigateWithinPageEvent (CategoryComponent → CollectionComponent dest)
   */
  it('C855177 - ComponentInteraction and NavigateWithinPage fire when pressing Up to focus pivot menu @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Clear events before pressing Up
      analyticsEvents.length = 0;

      // Press Up to focus on pivot list
      await ecp.sendKeypress(ecp.Key.Up);
      await testUtils.waitForElementToHaveFocus('pivotList', 'Pivot list should have focus', 5000);
      await utils.sleep(1500);

      // Verify ComponentInteractionEvent with ButtonComponent UP_FOCUS_PIVOT
      const buttonInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.button_component?.button_value === 'UP_FOCUS_PIVOT',
        description: 'ComponentInteractionEvent (UP_FOCUS_PIVOT)',
      });

      validateAnalyticsEvent(
        buttonInteraction,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              button_component: {
                button_value: 'UP_FOCUS_PIVOT',
                button_type: BUTTON_TYPE.IMAGE,
              },
              user_interaction: USER_INTERACTION.CONFIRM,
            }
          }
        },
        'ComponentInteraction (Up → Pivot, ButtonComponent)',
      );

      // Verify ComponentInteractionEvent with CollectionComponent TOGGLE_ON
      const toggleOnInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.collection_component?.sub_type === 'PIVOT' &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.TOGGLE_ON,
        description: 'ComponentInteractionEvent (CollectionComponent PIVOT, TOGGLE_ON)',
      });

      validateAnalyticsEvent(
        toggleOnInteraction,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                },
              },
              user_interaction: USER_INTERACTION.TOGGLE_ON,
            }
          }
        },
        'ComponentInteraction (Up → Pivot, CollectionComponent TOGGLE_ON)',
      );

      // Verify NavigateWithinPageEvent
      const navWithinPage = findAnalyticsEvent(analyticsEvents, 'navigate_within_page', {
        description: 'NavigateWithinPageEvent (content row → pivot)',
      });

      validateAnalyticsEvent(
        navWithinPage,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page'),
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: 1,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
              dest_collection_component: {
                row: 1,
                utility_tile: {
                  id: NON_EMPTY_STRING,
                  row: 1,
                  col: NUMBER,
                },
                nav_section_dynamic: 'STICKY',
              },
              means_of_navigation: 'BUTTON',
            }
          }
        },
        'NavigateWithinPage (content row → pivot)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Focus on pivot menu via Back (Q1b) ──────────────────────
  /**
   * Q1b: How many users land on the pivot menu in homegrid and focus on the first pill?
   * A: Users click the "Back" button using the remote
   * Tracking:
   *   - ComponentInteractionEvent (ButtonComponent, button_value=BACK_FOCUS_PIVOT, button_type=IMAGE, CONFIRM)
   */
  it('C855092 - ComponentInteraction fires when pressing Back to focus pivot menu @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate up to pivot list first, then back down to rowList
      await navigateToPivotList();
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Rowlist should have focus after Down', 5000);
      await utils.sleep(500);

      // Clear events before pressing Back
      analyticsEvents.length = 0;

      // Press Back to focus on pivot list
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForElementToHaveFocus('pivotList', 'Pivot list should have focus after Back', 5000);
      await utils.sleep(1500);

      // Verify ComponentInteractionEvent with ButtonComponent BACK_FOCUS_PIVOT
      const buttonInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.button_component?.button_value === 'BACK_FOCUS_PIVOT',
        description: 'ComponentInteractionEvent (BACK_FOCUS_PIVOT)',
      });

      validateAnalyticsEvent(
        buttonInteraction,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              button_component: {
                button_value: 'BACK_FOCUS_PIVOT',
                button_type: BUTTON_TYPE.IMAGE,
              },
              user_interaction: USER_INTERACTION.CONFIRM,
            }
          }
        },
        'ComponentInteraction (Back → Pivot, ButtonComponent)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Focus on pivot from nav bar (Q2) ────────────────────────
  /**
   * Q2: How many users land on the pivot menu in homegrid and focus on the first pill?
   * A: Users click "Right" from the nav bar using the remote.
   * Tracking:
   *   - ComponentInteractionEvent (LeftSideNavComponent, TOGGLE_OFF)
   *   - ComponentInteractionEvent (CollectionComponent, sub_type=PIVOT, TOGGLE_ON)
   *   - NavigateWithinPageEvent (LeftSideNavComponent → CollectionComponent dest)
   */
  it('C855190 - ComponentInteraction and NavigateWithinPage fire when pressing Right from nav to focus pivot menu @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      await ecp.sendKeypress(ecp.Key.Left);
      await testUtils.waitForElementToHaveFocus('sideNavMenu', 'Side nav menu should have focus', 5000);

      // Press Rewind to ensure we are at the top of the nav
      await ecp.sendKeypress(ecp.Key.Rewind);
      await testUtils.waitForElementFieldToEqual('sideNavMenu', 'itemFocused', 0, 5000);

      // Clear events before pressing Right to focus pivot list
      analyticsEvents.length = 0;

      await utils.sleep(1000);

      // Press Right to close nav and focus on pivot list
      await ecp.sendKeypress(ecp.Key.Right);
      await testUtils.waitForElementToHaveFocus('pivotList', 'Pivot list should have focus after pressing Right from nav', 5000);
      await utils.sleep(2000);

      // Verify ComponentInteractionEvent LeftSideNavComponent TOGGLE_OFF
      const navToggleOff = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.left_side_nav_component !== undefined &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.TOGGLE_OFF,
        description: 'ComponentInteractionEvent (LeftSideNavComponent TOGGLE_OFF)',
      });

      validateAnalyticsEvent(
        navToggleOff,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              left_side_nav_component: {
                left_nav_section: NON_EMPTY_STRING,
              },
              user_interaction: USER_INTERACTION.TOGGLE_OFF,
            }
          }
        },
        'ComponentInteraction (nav TOGGLE_OFF → pivot)',
      );

      // Verify ComponentInteractionEvent CollectionComponent PIVOT TOGGLE_ON
      const pivotToggleOn = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.collection_component?.sub_type === 'PIVOT' &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.TOGGLE_ON,
        description: 'ComponentInteractionEvent (CollectionComponent PIVOT TOGGLE_ON)',
      });

      validateAnalyticsEvent(
        pivotToggleOn,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                },
              },
              user_interaction: USER_INTERACTION.TOGGLE_ON,
            }
          }
        },
        'ComponentInteraction (nav → pivot, CollectionComponent TOGGLE_ON)',
      );

      // Verify NavigateWithinPageEvent (LeftSideNavComponent → CollectionComponent)
      const navWithinPage = findAnalyticsEvent(analyticsEvents, 'navigate_within_page', {
        description: 'NavigateWithinPageEvent (nav → pivot)',
      });

      validateAnalyticsEvent(
        navWithinPage,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page'),
              left_side_nav_component: {
                left_nav_section: NON_EMPTY_STRING,
              },
              dest_collection_component: {
                row: 1,
                utility_tile: {
                  id: NON_EMPTY_STRING,
                  row: 1,
                  col: NUMBER,
                },
                nav_section_dynamic: 'STICKY',
              },
              means_of_navigation: 'BUTTON',
            }
          }
        },
        'NavigateWithinPage (nav → pivot)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Navigate between pivots (Q3) ───────────────────────────
  /**
   * Q3: How many users navigate between the pivots within the pivot menu on homegrid?
   * A: Users scroll left/right within the pivot row.
   * Tracking:
   *   - NavigateWithinPageEvent (CollectionComponent, sub_type=PIVOT, means_of_navigation=SCROLL)
   */
  it('C855178 - NavigateWithinPage fires when scrolling between pivots @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate up to pivot list
      await navigateToPivotList();
      await utils.sleep(1000);

      // Clear events before navigating between pivots
      analyticsEvents.length = 0;

      // Navigate right to the next pivot
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(1500);

      // Verify NavigateWithinPageEvent with CollectionComponent PIVOT
      const navEvent = findAnalyticsEvent(analyticsEvents, 'navigate_within_page', {
        predicate: (e) => e.event?.navigate_within_page?.collection_component?.sub_type === 'PIVOT',
        description: 'NavigateWithinPageEvent (pivot → pivot, SCROLL)',
      });

      validateAnalyticsEvent(
        navEvent,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                row: 1,
                nav_section_dynamic: 'STICKY',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                  row: 1,
                  col: NUMBER,
                },
              },
              means_of_navigation: 'SCROLL',
            }
          }
        },
        'NavigateWithinPage (pivot → pivot)',
      );

      // Verify dest utility_tile exists and is different from source
      const sourceTile = navEvent.event?.navigate_within_page?.collection_component?.utility_tile;
      const destTile = navEvent.event?.navigate_within_page?.dest_collection_component?.utility_tile;
      expect(destTile, 'dest_collection_component.utility_tile should exist').to.exist;
      expect(destTile?.id, 'dest utility_tile.id should be a non-empty string').to.be.a('string').and.not.be.empty;
      expect(destTile?.id, 'dest utility_tile.id should differ from source utility_tile.id').to.not.equal(sourceTile?.id);
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Focus away from pivots (Q4) ────────────────────────────
  /**
   * Q4: How many users move focus away from the pivot menu without clicking into the pivot?
   * A: Users press Down from the pivot row.
   * Tracking:
   *   - ComponentInteractionEvent (CollectionComponent, sub_type=PIVOT, TOGGLE_OFF)
   */
  it('C855179 - ComponentInteraction TOGGLE_OFF fires when moving focus away from pivots @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate up to pivot list
      await navigateToPivotList();
      await utils.sleep(1000);

      // Clear events before pressing Down
      analyticsEvents.length = 0;

      // Press Down to move focus away from pivots
      await ecp.sendKeypress(ecp.Key.Down);
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Row list should have focus', 5000);
      await utils.sleep(1500);

      // Verify ComponentInteractionEvent with TOGGLE_OFF
      const toggleOffEvent = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.collection_component?.sub_type === 'PIVOT' &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.TOGGLE_OFF,
        description: 'ComponentInteractionEvent (CollectionComponent PIVOT, TOGGLE_OFF)',
      });

      validateAnalyticsEvent(
        toggleOffEvent,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                },
              },
              user_interaction: USER_INTERACTION.TOGGLE_OFF,
            }
          }
        },
        'ComponentInteraction (TOGGLE_OFF, focus away from pivot)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Focus from pivot to left nav (Q5) ──────────────────────
  /**
   * Q5: How many users move focus from the pivot row to the left nav?
   * A: Users press "Left" from the pivot row.
   * Tracking:
   *   - ComponentInteractionEvent (LeftSideNavComponent, TOGGLE_ON)
   *   - ComponentInteractionEvent (CollectionComponent PIVOT, TOGGLE_OFF)
   *   - NavigateWithinPageEvent (CollectionComponent → LeftSideNavComponent)
   */
  it('C855178 - Analytics fire when pressing Left from pivot row to open left nav @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate up to pivot list
      await navigateToPivotList();
      await utils.sleep(1000);

      // Clear events before pressing Left
      analyticsEvents.length = 0;

      // Press Left to open left nav from pivot row
      await ecp.sendKeypress(ecp.Key.Left);
      await utils.sleep(2000);

      // Verify ComponentInteractionEvent LeftSideNavComponent TOGGLE_ON
      const navToggleOn = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.left_side_nav_component !== undefined &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.TOGGLE_ON,
        description: 'ComponentInteractionEvent (LeftSideNavComponent TOGGLE_ON)',
      });

      validateAnalyticsEvent(
        navToggleOn,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              left_side_nav_component: {
                left_nav_section: NON_EMPTY_STRING,
              },
              user_interaction: USER_INTERACTION.TOGGLE_ON,
            }
          }
        },
        'ComponentInteraction (LeftSideNavComponent TOGGLE_ON from pivot)',
      );

      // Verify ComponentInteractionEvent CollectionComponent PIVOT TOGGLE_OFF
      const pivotToggleOff = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.collection_component?.sub_type === 'PIVOT' &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.TOGGLE_OFF,
        description: 'ComponentInteractionEvent (CollectionComponent PIVOT TOGGLE_OFF)',
      });

      validateAnalyticsEvent(
        pivotToggleOff,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                },
              },
              user_interaction: USER_INTERACTION.TOGGLE_OFF,
            }
          }
        },
        'ComponentInteraction (CollectionComponent PIVOT TOGGLE_OFF)',
      );

      // Verify NavigateWithinPageEvent
      const navWithinPage = findAnalyticsEvent(analyticsEvents, 'navigate_within_page', {
        description: 'NavigateWithinPageEvent (pivot → left nav)',
      });

      validateAnalyticsEvent(
        navWithinPage,
        {
          event: {
            navigate_within_page: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                row: 1,
                utility_tile: {
                  id: NON_EMPTY_STRING,
                  row: 1,
                  col: NUMBER,
                },
                nav_section_dynamic: 'STICKY',
              },
              dest_left_side_nav_component: {
                left_nav_section: NON_EMPTY_STRING,
              },
              means_of_navigation: 'BUTTON',
            }
          }
        },
        'NavigateWithinPage (pivot → left nav)',
      );

      // Close left nav
      await ecp.sendKeypress(ecp.Key.Back);
      await utils.sleep(500);
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Search from pivot (Q6) ─────────────────────────────────
  /**
   * Q6: How many users select the search button at the last of the pivot row and land on the search page?
   * A: User navigates to the search pill and presses OK.
   * Tracking:
   *   - ComponentInteractionEvent (CollectionComponent PIVOT, utility_tile_id=search, CONFIRM)
   *   - NavigateToPageEvent (CollectionComponent PIVOT → SearchPage)
   *   - PageLoadEvent (SearchPage, SUCCESS)
   */
  it('C855180 - Analytics fire when selecting search pivot pill @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate up to pivot list
      await navigateToPivotList();

      // Get pivot count to jump to the last one (search)
      const pivotItems = await testUtils.getRowListRowItemsContent('pivotList', 0);
      const pivotCount = pivotItems.length;

      // Jump to the search pill (last pivot)
      await testUtils.jumpToRowItem('pivotList', [0, pivotCount - 1]);
      await testUtils.waitForElementFieldToEqual('pivotList', 'currFocusColumn', pivotCount - 1, 5000);
      await utils.sleep(500);

      // Clear events before selecting search
      analyticsEvents.length = 0;

      // Select search pivot
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);
      await utils.sleep(1500);

      // Verify ComponentInteractionEvent for search pill
      const searchInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.collection_component?.sub_type === 'PIVOT' &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.CONFIRM,
        description: 'ComponentInteractionEvent (search pivot CONFIRM)',
      });

      validateAnalyticsEvent(
        searchInteraction,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                utility_tile: {
                  id: 'search',
                },
              },
              user_interaction: USER_INTERACTION.CONFIRM,
            }
          }
        },
        'ComponentInteraction (search pivot CONFIRM)',
      );

      // Verify NavigateToPageEvent (CollectionComponent PIVOT → SearchPage)
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        description: 'NavigateToPageEvent (pivot → SearchPage)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                row: 1,
                nav_section_dynamic: 'STICKY',
                utility_tile: {
                  id: 'search',
                  row: 1,
                  col: NUMBER,
                },
              },
              dest_search_page: {},
            }
          }
        },
        'NavigateToPage (search pivot → SearchPage)',
      );

      // Verify PageLoadEvent for SearchPage
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        description: 'PageLoadEvent (SearchPage)',
      });

      validateAnalyticsEvent(
        pageLoad,
        {
          event: {
            page_load: {
              search_page: getPageValidator('search_page'),
              status: 'SUCCESS',
            }
          }
        },
        'PageLoad (SearchPage)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Home Page – Select pivot and land on pivot page (Q7) ───────────────
  /**
   * Q7: How many users select one of the pivots on the pivot menu and land on the pivot page?
   * A: User presses OK on a pivot pill.
   * Tracking:
   *   - ComponentInteractionEvent (CollectionComponent PIVOT, CONFIRM)
   *   - NavigateToPageEvent (CollectionComponent PIVOT → CollectionPage, dest section=PIVOT)
   *   - PageLoadEvent (CollectionPage, section=PIVOT, SUCCESS)
   */
  it('C855181 - Analytics fire when selecting a pivot pill and landing on pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate up to pivot list
      await navigateToPivotList();
      await utils.sleep(500);

      // Clear events before selecting pivot
      analyticsEvents.length = 0;

      // Select the first pivot
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('pivotDetailScreen', 10000);
      await testUtils.waitForElementToHaveFocus('pivotDetailRowList', 'Pivot detail row list should have focus', 10000);
      await utils.sleep(1500);

      // Verify ComponentInteractionEvent for pivot CONFIRM
      const pivotInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.collection_component?.sub_type === 'PIVOT' &&
          e.event?.component_interaction?.user_interaction === USER_INTERACTION.CONFIRM,
        description: 'ComponentInteractionEvent (pivot CONFIRM)',
      });

      validateAnalyticsEvent(
        pivotInteraction,
        {
          event: {
            component_interaction: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                },
              },
              user_interaction: USER_INTERACTION.CONFIRM,
            }
          }
        },
        'ComponentInteraction (pivot CONFIRM)',
      );

      // Verify NavigateToPageEvent to CollectionPage with PIVOT section
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        description: 'NavigateToPageEvent (home → pivot page)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              home_page: getPageValidator('home_page'),
              collection_component: {
                sub_type: 'PIVOT',
                row: 1,
                nav_section_dynamic: 'STICKY',
                utility_tile: {
                  id: NON_EMPTY_STRING,
                  row: 1,
                  col: NUMBER,
                },
              },
              dest_collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
            }
          }
        },
        'NavigateToPage (home → pivot page)',
      );

      // Verify PageLoadEvent for CollectionPage
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        predicate: (e) => e.event?.page_load?.collection_page !== undefined,
        description: 'PageLoadEvent (CollectionPage PIVOT)',
      });

      validateAnalyticsEvent(
        pageLoad,
        {
          event: {
            page_load: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              status: 'SUCCESS',
            }
          }
        },
        'PageLoad (CollectionPage PIVOT)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Start preview (Q8) ────────────────────────────────────
  /**
   * Q8: How many users start to watch video previews on pivot page?
   * A: Users focus on content with video tiles and video preview starts.
   * Tracking:
   *   - StartPreviewEvent (VIDEO_IN_GRID, CollectionPage PIVOT, CategoryComponent)
   */
  it('C855182 - StartPreview fires when focusing on video tile on pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.start_preview !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select the first one
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');

      // Find a tile that has a video preview on the pivot detail page
      const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('pivotDetailRowList', true, 5);
      if (position.length === 0) {
        throw new Error('Could not find content with video preview in pivotDetailRowList');
      }
      await testHelpers.jumpToRowListPosition('pivotDetailRowList', position[0], position[1]);

      // Resume proxy and wait for preview to start
      await safeResumeProxy();
      analyticsEvents.length = 0;

      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
      await utils.sleep(3000); // Wait for analytics to fire

      // Assert events were captured
      const capturedEventTypes = analyticsEvents.map((e) => Object.keys(e.event || {})).join(', ') || '(none)';
      expect(analyticsEvents.length).to.be.greaterThan(0,
        `Should receive start_preview event. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`);

      const startPreview = findAnalyticsEvent(analyticsEvents, 'start_preview', {
        description: 'StartPreviewEvent on pivot page',
      });

      validateAnalyticsEvent(
        startPreview,
        {
          event: {
            start_preview: {
              preview_id: NON_EMPTY_STRING,
              is_fullscreen: false,
              video_player: VIDEO_PLAYER.VIDEO_IN_GRID,
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: NUMBER,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
            }
          }
        },
        'StartPreview (pivot page)',
      );
      expectContentTileHasVideoOrSeriesId(
        startPreview.event?.start_preview?.category_component?.content_tile,
        'start_preview.category_component.content_tile',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Navigate between tiles (Q9) ───────────────────────────
  /**
   * Q9: How many users browse or navigate between the tiles within the pivot page?
   * A: User presses arrow keys to navigate between tiles.
   * Tracking:
   *   - NavigateWithinPageEvent (CollectionPage PIVOT, CategoryComponent, means_of_navigation=BUTTON)
   */
  it('C855183 - NavigateWithinPage fires when navigating between tiles on pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_within_page !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select the first one
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');
      await safeResumeProxy();

      // Clear events before navigating
      analyticsEvents.length = 0;

      // Navigate right between tiles
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(2000);

      expect(analyticsEvents.length).to.be.greaterThan(0, 'Should receive navigate_within_page event');

      const navEvent = findAnalyticsEvent(analyticsEvents, 'navigate_within_page', {
        description: 'NavigateWithinPageEvent (pivot page tile navigation)',
      });

      validateAnalyticsEvent(
        navEvent,
        {
          event: {
            navigate_within_page: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_col: NUMBER,
                category_row: NUMBER,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
              means_of_navigation: 'BUTTON',
              horizontal_location: NUMBER,
              vertical_location: NUMBER,
            }
          }
        },
        'NavigateWithinPage (pivot page)',
      );
      expectContentTileHasVideoOrSeriesId(
        navEvent.event?.navigate_within_page?.category_component?.content_tile,
        'navigate_within_page.category_component.content_tile',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Preview progress (Q10) ────────────────────────────────
  /**
   * Q10: How long did the user continue watching the video preview within the same tile on the pivot page?
   * A: User takes no action and video preview keeps playing.
   * Tracking:
   *   - PreviewPlayProgressEvent every ~10s (VIDEO_IN_GRID, CollectionPage PIVOT, CategoryComponent)
   */
  it('C855184 - PreviewPlayProgress fires during video preview on pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.preview_play_progress !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select the first one
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');

      // Find a tile that has a video preview on the pivot detail page
      const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('pivotDetailRowList', true, 5);
      if (position.length === 0) {
        throw new Error('Could not find content with video preview in pivotDetailRowList');
      }
      await testHelpers.jumpToRowListPosition('pivotDetailRowList', position[0], position[1]);

      // Wait for the video preview to start playing
      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

      // Resume proxy and wait for progress events (~10s interval)
      await safeResumeProxy();
      analyticsEvents.length = 0;
      await utils.sleep(22000);

      // Assert events were captured
      const capturedEventTypes = analyticsEvents.map((e) => Object.keys(e.event || {})).join(', ') || '(none)';
      expect(analyticsEvents.length).to.be.greaterThan(0,
        `Should receive preview_play_progress event. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`);

      const progressEvent = findAnalyticsEvent(analyticsEvents, 'preview_play_progress', {
        description: 'PreviewPlayProgressEvent on pivot page',
      });

      validateAnalyticsEvent(
        progressEvent,
        {
          event: {
            preview_play_progress: {
              preview_id: NON_EMPTY_STRING,
              position: POSITIVE_NUMBER,
              view_time: POSITIVE_NUMBER,
              video_player: VIDEO_PLAYER.VIDEO_IN_GRID,
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: NUMBER,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
            }
          }
        },
        'PreviewPlayProgress (pivot page)',
      );
      expectContentTileHasVideoOrSeriesId(
        progressEvent.event?.preview_play_progress?.category_component?.content_tile,
        'preview_play_progress.category_component.content_tile',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Finish preview deliberately (Q11) ─────────────────────
  /**
   * Q11: How many users deliberately stop watching the video previews within the tiles?
   * A: User navigates away from tile before preview ends.
   * Tracking:
   *   - FinishPreviewEvent (has_completed=false, VIDEO_IN_GRID, CollectionPage PIVOT)
   */
  it('C855185 - FinishPreview fires with has_completed=false when navigating away from tile on pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.finish_preview !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select the first one
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');

      // Find a tile that has a video preview on the pivot detail page
      const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('pivotDetailRowList', true, 5);
      if (position.length === 0) {
        throw new Error('Could not find content with video preview in pivotDetailRowList');
      }
      await testHelpers.jumpToRowListPosition('pivotDetailRowList', position[0], position[1]);

      // Wait for the video preview to start playing
      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
      await utils.sleep(2000);

      // Clear events, resume proxy, and navigate away to trigger finish_preview
      await safeResumeProxy();
      analyticsEvents.length = 0;
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(3000);

      // Assert events were captured
      const capturedEventTypes = analyticsEvents.map((e) => Object.keys(e.event || {})).join(', ') || '(none)';
      expect(analyticsEvents.length).to.be.greaterThan(0,
        `Should receive finish_preview event. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`);

      const finishPreview = findAnalyticsEvent(analyticsEvents, 'finish_preview', {
        predicate: (e) => e.event?.finish_preview?.has_completed === false,
        description: 'FinishPreviewEvent (has_completed=false)',
      });

      validateAnalyticsEvent(
        finishPreview,
        {
          event: {
            finish_preview: {
              preview_id: NON_EMPTY_STRING,
              end_position: NUMBER,
              has_completed: false,
              video_player: VIDEO_PLAYER.VIDEO_IN_GRID,
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: NUMBER,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
            }
          }
        },
        'FinishPreview (pivot page, navigated away)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Select title and land on details (Q12) ────────────────
  /**
   * Q12: How many users select a title on the pivot page and land on content details page?
   * A: Users click "OK / Select" on a tile.
   * Tracking:
   *   - ComponentInteractionEvent (ButtonComponent, button_value=OK, CONFIRM)
   *   - NavigateToPageEvent (CategoryComponent → VideoPage or SeriesDetailPage)
   *   - PageLoadEvent (VideoPage or SeriesDetailPage, SUCCESS)
   */
  it('C855186 - Analytics fire when selecting a title on pivot page to go to details @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select the first one
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');
      await safeResumeProxy();

      // Clear events before selecting a title
      analyticsEvents.length = 0;

      // Select a title (press OK on current tile)
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 15000);
      await utils.sleep(2000);

      // Verify ComponentInteractionEvent with button_value OK
      const okInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.button_component?.button_value === BUTTON_VALUE.OK,
        description: 'ComponentInteractionEvent (OK button on pivot page)',
      });

      validateAnalyticsEvent(
        okInteraction,
        {
          event: {
            component_interaction: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              button_component: {
                button_value: BUTTON_VALUE.OK,
              },
              user_interaction: USER_INTERACTION.CONFIRM,
            }
          }
        },
        'ComponentInteraction (OK → details from pivot page)',
      );

      // Verify NavigateToPageEvent (CollectionPage PIVOT → VideoPage/SeriesDetailPage)
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        description: 'NavigateToPageEvent (pivot page → details)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: 1,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
            }
          }
        },
        'NavigateToPage (pivot page → details)',
      );

      // Verify PageLoadEvent (VideoPage or SeriesDetailPage)
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        description: 'PageLoadEvent (details page from pivot)',
      });
      expect(pageLoad.event?.page_load?.status).to.equal('SUCCESS');
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Play button enters fullscreen playback (Q13) ────────────
  /**
   * Q13: How many users deliberately play a content on the pivot page and immediately enter playback?
   * A: Users click the "Play" button using the remote and are directed to the full screen player.
   * Tracking:
   *   - ComponentInteractionEvent (ButtonComponent, button_value=PLAY, CONFIRM)
   *   - NavigateToPageEvent (CategoryComponent → VideoPlayerPage)
   *   - PageLoadEvent (VideoPlayerPage, SUCCESS)
   *   - StartVideoEvent (video_id, playback_source=UNKNOWN_PLAYBACK_SOURCE)
   */
  it('C855186 - Analytics fire when pressing Play on a tile on pivot page to enter playback @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.component_interaction !== undefined ||
        event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined ||
        event.event?.start_video !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select one to land on pivot detail screen
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');
      await safeResumeProxy();

      // Clear events before pressing Play
      analyticsEvents.length = 0;

      // Press Play on the currently focused content tile
      await ecp.sendKeypress(ecp.Key.Play);
      await utils.sleep(5000); // Wait for player to load and start_video to fire

      // Verify ComponentInteractionEvent with button_value PLAY
      const playInteraction = findAnalyticsEvent(analyticsEvents, 'component_interaction', {
        predicate: (e) => e.event?.component_interaction?.button_component?.button_value === BUTTON_VALUE.PLAY,
        description: 'ComponentInteractionEvent (PLAY button on pivot page)',
      });

      validateAnalyticsEvent(
        playInteraction,
        {
          event: {
            component_interaction: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              button_component: {
                button_value: BUTTON_VALUE.PLAY,
              },
              user_interaction: USER_INTERACTION.CONFIRM,
            }
          }
        },
        'ComponentInteraction (Play → fullscreen from pivot page)',
      );

      // Verify NavigateToPageEvent to VideoPlayerPage
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        description: 'NavigateToPageEvent (pivot page → VideoPlayerPage)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_col: 1,
                category_row: NUMBER,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
                category_slug: NON_EMPTY_STRING,
              },
              dest_video_player_page: {},
            }
          }
        },
        'NavigateToPage (pivot page → VideoPlayerPage)',
      );

      // Verify PageLoadEvent for VideoPlayerPage
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        description: 'PageLoadEvent (VideoPlayerPage)',
      });

      validateAnalyticsEvent(
        pageLoad,
        {
          event: {
            page_load: {
              video_player_page: {},
              status: 'SUCCESS',
            }
          }
        },
        'PageLoad (VideoPlayerPage from pivot page)',
      );

      // Verify StartVideoEvent
      const startVideo = findAnalyticsEvent(analyticsEvents, 'start_video', {
        description: 'StartVideoEvent (playback from pivot page)',
      });

      validateAnalyticsEvent(
        startVideo,
        {
          event: {
            start_video: {
              video_id: POSITIVE_NUMBER,
              playback_source: PLAYBACK_SOURCE.UNKNOWN_PLAYBACK_SOURCE,
            }
          }
        },
        'StartVideo (from pivot page Play button)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Pivot Page – Autostart after previews (Q20) ──────────────────────────
  /**
   * Q20: How many users finish watching the video previews within the tiles on the pivot page?
   * A: Users reach the end point of the preview and are then directed to the full screen player.
   * Tracking:
   *   - FinishPreviewEvent (has_completed=true, video_player=VIDEO_IN_GRID, CollectionPage PIVOT)
   *   - NavigateToPageEvent (CollectionPage PIVOT → VideoPlayerPage)
   *   - PageLoadEvent (VideoPlayerPage, SUCCESS)
   *   - StartVideoEvent (video_id, playback_source=VIDEO_PREVIEWS)
   *   - PlayProgressEvent (video_id, playback_source=VIDEO_PREVIEWS) [optional, may not fire immediately]
   */
  it('C855191 - Analytics fire when preview completes and autostarts playback on pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

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
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select one to land on pivot detail screen
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');

      // Find a tile that has a video preview on the pivot detail page
      const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('pivotDetailRowList', true, 5);
      if (position.length === 0) {
        throw new Error('Could not find content with video preview in pivotDetailRowList');
      }
      await testHelpers.jumpToRowListPosition('pivotDetailRowList', position[0], position[1]);

      // Wait for the video preview to start playing
      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

      // Clear events and resume proxy before seeking to end of preview
      await safeResumeProxy();
      analyticsEvents.length = 0;

      // Seek close to end of preview so it completes quickly
      await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -5000, 'end');

      // Wait for autostart to transition to full screen player
      await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 15000);
      await utils.sleep(8000); // Wait for all events to fire

      const capturedEventTypes = analyticsEvents.map((e) => Object.keys(e.event || {})).join(', ') || '(none)';

      // Verify FinishPreviewEvent with has_completed=true
      const finishPreview = analyticsEvents.find(e =>
        e.event?.finish_preview?.has_completed === true
      );
      expect(finishPreview, `Missing finish_preview (has_completed=true). Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

      if (finishPreview) {
        validateAnalyticsEvent(
          finishPreview,
          {
            event: {
              finish_preview: {
                video_id: EXISTS,
                end_position: EXISTS,
                preview_id: EXISTS,
                has_completed: true,
                video_player: VIDEO_PLAYER.VIDEO_IN_GRID,
                collection_page: {
                  section: 'PIVOT',
                  id: NON_EMPTY_STRING,
                },
                category_component: {
                  category_slug: EXISTS,
                  category_row: EXISTS,
                  category_col: EXISTS,
                  content_tile: {
                    row: 1,
                    col: EXISTS,
                  }
                }
              }
            }
          },
          'FinishPreview (has_completed=true, pivot page)',
        );
        expectContentTileHasVideoOrSeriesId(
          finishPreview.event?.finish_preview?.category_component?.content_tile,
          'finish_preview.category_component.content_tile',
        );
      }

      // Verify NavigateToPageEvent to VideoPlayerPage
      const navToPage = analyticsEvents.find(e =>
        e.event?.navigate_to_page?.dest_video_player_page !== undefined
      );
      expect(navToPage, `Missing NavigateToPageEvent to video_player_page. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

      if (navToPage) {
        validateAnalyticsEvent(
          navToPage,
          {
            event: {
              navigate_to_page: {
                collection_page: {
                  section: 'PIVOT',
                  id: NON_EMPTY_STRING,
                },
                category_component: {
                  category_col: 1,
                  category_row: NUMBER,
                  content_tile: {
                    row: 1,
                    col: NUMBER,
                  },
                  category_slug: NON_EMPTY_STRING,
                },
                dest_video_player_page: {},
              }
            }
          },
          'NavigateToPage (autostart pivot page → VideoPlayerPage)',
        );
      }

      // Verify PageLoadEvent for VideoPlayerPage
      const pageLoad = analyticsEvents.find(e =>
        e.event?.page_load?.video_player_page !== undefined
      );
      expect(pageLoad, `Missing PageLoadEvent for video_player_page. Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

      if (pageLoad) {
        validateAnalyticsEvent(
          pageLoad,
          {
            event: {
              page_load: {
                video_player_page: {},
                status: 'SUCCESS',
              }
            }
          },
          'PageLoad (VideoPlayerPage from autostart)',
        );
      }

      // Verify StartVideoEvent with playback_source=VIDEO_PREVIEWS
      const startVideo = analyticsEvents.find(e =>
        e.event?.start_video?.playback_source === 'VIDEO_PREVIEWS'
      );
      expect(startVideo, `Missing StartVideoEvent (playback_source=VIDEO_PREVIEWS). Received ${analyticsEvents.length} events; types: ${capturedEventTypes}`).to.exist;

      if (startVideo) {
        validateAnalyticsEvent(
          startVideo,
          {
            event: {
              start_video: {
                video_id: EXISTS,
                playback_source: 'VIDEO_PREVIEWS',
              }
            }
          },
          'StartVideo (playback_source=VIDEO_PREVIEWS from autostart)',
        );
      }

      // Verify PlayProgressEvent with playback_source=VIDEO_PREVIEWS (optional - may not fire immediately)
      const playProgress = analyticsEvents.find(e =>
        e.event?.play_progress?.playback_source === 'VIDEO_PREVIEWS'
      );
      if (playProgress) {
        validateAnalyticsEvent(
          playProgress,
          {
            event: {
              play_progress: {
                video_id: EXISTS,
                playback_source: 'VIDEO_PREVIEWS',
              }
            }
          },
          'PlayProgress (from VIDEO_PREVIEWS on pivot page)',
        );
      }
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Back Behavior – Back from search to home pivot (Q17) ───────────────
  /**
   * Q17: How many users get back from search to the homepage and return to the search pivot?
   * A: Users press Back while on search page.
   * Tracking:
   *   - NavigateToPageEvent (SearchPage → HomePage, dest CollectionComponent search)
   *   - PageLoadEvent (HomePage, SUCCESS)
   */
  it('C855187 - Analytics fire when pressing Back from search to return to pivot @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots, then to search
      await navigateToPivotList();
      const pivotItems = await testUtils.getRowListRowItemsContent('pivotList', 0);
      const pivotCount = pivotItems.length;
      await testUtils.jumpToRowItem('pivotList', [0, pivotCount - 1]);
      await testUtils.waitForElementFieldToEqual('pivotList', 'currFocusColumn', pivotCount - 1, 5000);
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);
      await utils.sleep(1000);

      // Clear events before pressing Back
      analyticsEvents.length = 0;

      // Press Back to return to home
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
      await utils.sleep(1500);

      // Verify NavigateToPageEvent from search back to home
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        description: 'NavigateToPageEvent (search → home)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              search_page: {},
              dest_home_page: {},
              dest_collection_component: {
                utility_tile: {
                  id: 'search',
                },
              },
            }
          }
        },
        'NavigateToPage (search → home with search pivot)',
      );

      // Verify PageLoadEvent for HomePage
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        description: 'PageLoadEvent (HomePage after back from search)',
      });

      validateAnalyticsEvent(
        pageLoad,
        {
          event: {
            page_load: {
              home_page: getPageValidator('home_page'),
              status: 'SUCCESS',
            }
          }
        },
        'PageLoad (HomePage after back from search)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Back Behavior – Back from pivot page to home (Q18) ─────────────────
  /**
   * Q18: How many users get back to the homepage and return to the last selected pivot?
   * A: Users press Back while on the pivot page.
   * Tracking:
   *   - NavigateToPageEvent (CollectionPage PIVOT → HomePage, dest CollectionComponent)
   *   - PageLoadEvent (HomePage, SUCCESS)
   */
  it('C855188 - Analytics fire when pressing Back from pivot page to return to home @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots and select one
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');
      await utils.sleep(1000);
      await safeResumeProxy();

      // Clear events before pressing Back
      analyticsEvents.length = 0;

      // Press Back to return to home
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
      await utils.sleep(1500);

      // Verify NavigateToPageEvent from pivot page to home
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        predicate: (e) => e.event?.navigate_to_page?.collection_page?.section === 'PIVOT',
        description: 'NavigateToPageEvent (pivot page → home)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              category_component: {
                category_slug: NON_EMPTY_STRING,
                category_row: NUMBER,
                category_col: 1,
                content_tile: {
                  row: 1,
                  col: NUMBER,
                },
              },
              dest_home_page: {},
              dest_collection_component: {
                utility_tile: {
                  id: NON_EMPTY_STRING,
                },
              },
            }
          }
        },
        'NavigateToPage (pivot page → home)',
      );

      // Verify PageLoadEvent for HomePage
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        description: 'PageLoadEvent (HomePage after back from pivot)',
      });

      validateAnalyticsEvent(
        pageLoad,
        {
          event: {
            page_load: {
              home_page: getPageValidator('home_page'),
              status: 'SUCCESS',
            }
          }
        },
        'PageLoad (HomePage after back from pivot)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });

  // ─── Group: Back Behavior – Back from details to pivot page (Q19) ──────────────
  /**
   * Q19: How many users get back to the pivot page and return to the previous focus?
   * A: Users press Back while on details page or player.
   * Tracking:
   *   - NavigateToPageEvent (VideoPage/SeriesDetailPage → CollectionPage PIVOT)
   *   - PageLoadEvent (CollectionPage PIVOT, SUCCESS)
   */
  it('C855189 - Analytics fire when pressing Back from details to return to pivot page @pivots @analytics', async () => {
    const analyticsEvents: any[] = [];

    await safeResumeProxy();
    const analyticsCallback = createAnalyticsCallback(analyticsEvents, (event) => {
      return event.event?.navigate_to_page !== undefined ||
        event.event?.page_load !== undefined;
    });

    proxy.addCallback(analyticsCallback);

    try {
      await startApplicationWithPivotExperiment({ clearRegistry: false });
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);
      await testUtils.waitForGridContentToLoad('pivotList');

      // Navigate to pivots, select one, then select a title
      proxy.pause();
      await navigateToPivotList();
      await selectPivotAndWaitForDetailScreen();
      await testUtils.waitForGridContentToLoad('pivotDetailRowList');
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual('detailScreen', 15000);
      await utils.sleep(1000);
      await safeResumeProxy();

      // Clear events before pressing Back
      analyticsEvents.length = 0;

      // Press Back to return to pivot page
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual('pivotDetailScreen', 10000);
      await utils.sleep(1500);

      // Verify NavigateToPageEvent back to pivot page
      const navToPage = findAnalyticsEvent(analyticsEvents, 'navigate_to_page', {
        description: 'NavigateToPageEvent (details → pivot page)',
      });

      validateAnalyticsEvent(
        navToPage,
        {
          event: {
            navigate_to_page: {
              dest_collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
            }
          }
        },
        'NavigateToPage (details → pivot page)',
      );

      // Verify PageLoadEvent for CollectionPage PIVOT
      const pageLoad = findAnalyticsEvent(analyticsEvents, 'page_load', {
        predicate: (e) => e.event?.page_load?.collection_page !== undefined,
        description: 'PageLoadEvent (CollectionPage PIVOT after back)',
      });

      validateAnalyticsEvent(
        pageLoad,
        {
          event: {
            page_load: {
              collection_page: {
                section: 'PIVOT',
                id: NON_EMPTY_STRING,
              },
              status: 'SUCCESS',
            }
          }
        },
        'PageLoad (back to pivot page)',
      );
    } finally {
      proxy.removeAllCallbacks();
      proxy.pause();
    }
  });
});
