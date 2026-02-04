/**
 * ═══════════════════════════════════════════════════════════════════
 * ANALYTICS TESTING FRAMEWORK
 * ═══════════════════════════════════════════════════════════════════
 *
 * PURPOSE: Reusable building blocks for analytics automated tests across
 * events, screens, and experiments. Use this layer on top of analytics-validator
 * for shared constants, assertions, and patterns.
 *
 * USAGE:
 *   import {
 *     validateAnalyticsEvent,
 *     createAnalyticsCallback,
 *     getPageValidator,
 *     EXPECT_CONTENT_MODE,
 *     expectContentTileHasVideoOrSeriesId,
 *     AnalyticsConstants,
 *   } from './analytics-framework';
 *
 * LAYERS:
 *   1. analytics-validator.ts  – Low-level: validateAnalyticsEvent, getPageValidator, markers (EXISTS, NUMBER, etc.)
 *   2. analytics-framework.ts – Shared constants, page/component assertions, event finders (this file)
 *   3. Test files (e.g. video-tiles-analytics.ts) – Scenario-specific tests using framework + validator
 *
 * When adding new analytics tests for other events/screens:
 *   - Reuse constants (AnalyticsConstants, VALID_CONTENT_MODES, LEFT_NAV_SECTIONS, etc.)
 *   - Reuse assertion helpers (expectContentModeProper, expectContentTileHasVideoOrSeriesId)
 *   - Reuse getPageValidator / validateAnalyticsEvent (re-exported here)
 *   - Add new shared constants or assertions to this file when they apply to multiple tests
 *
 * HOW TO ADD NEW ANALYTICS TESTS (new event or new screen):
 *   1. Import from this file: validateAnalyticsEvent, createAnalyticsCallback, getPageValidator,
 *      EXISTS/NUMBER/…, expectContentModeProper, expectContentTileHasVideoOrSeriesId, findAnalyticsEvent.
 *   2. Use createAnalyticsCallback(eventsArray, eventFilter) to capture events; addCallback to proxy.
 *   3. Build expected structure with getPageValidator('page_type', { field: EXISTS }) and validateAnalyticsEvent.
 *   4. For events with home_page (Movies/TV/Espanol), use getPageValidator('home_page', { content_mode: EXISTS })
 *      and expectContentModeProper(pageObj, context). For for_you_page use getPageValidator('for_you_page') only
 *      (proto has no content_mode on ForYouPage).
 *   5. For content_tile, use expectContentTileHasVideoOrSeriesId(contentTile, context).
 *   6. Use findAnalyticsEvent(events, 'event_key', { predicate, description }) for clearer "missing event" errors.
 *   7. Add new shared constants (e.g. new content_mode, new section) to AnalyticsConstants or this file.
 *
 * PROTO SOURCE (single source of truth for event/page/enum shapes):
 *   Protobuf definitions live in the protos repo (e.g. Documents/protos or ../protos relative to repo).
 *   Key files:
 *   - tubi/analytics/client.proto   – Pages (HomePage, ForYouPage, VideoPage, …), ContentTile, LeftSideNavComponent,
 *     CategoryComponent, PreviewComponent, NavigationMenu.Section; HomePage.content_mode (common.ContentMode).
 *   - tubi/analytics/events.proto   – AppEvent oneof (page_load, navigate_to_page, start_preview,
 *     preview_play_progress, finish_preview, component_interaction, …); PageLoadEvent, NavigateToPageEvent, etc.
 *   - tubi/common/constants.proto   – ContentMode enum (CONTENT_MODE_MOVIE, CONTENT_MODE_TV, CONTENT_MODE_LATINO, …).
 *   When adding or changing constants/validators, align with these protos. getPageValidator() in
 *   analytics-validator.ts is hand-maintained to match client.proto page message shapes.
 *
 * ═══════════════════════════════════════════════════════════════════
 */

import { expect } from 'chai';
import {
  getPageValidator,
  EXISTS,
  validateAnalyticsEvent,
  createAnalyticsCallback,
  createLogCustomExposureCallback,
  assertEventExists,
  assertEventCount,
  extractEventsByType,
  extractNavigateWithinPageEvents,
  ANY_VALUE,
  NUMBER,
  STRING,
  BOOLEAN,
  POSITIVE_NUMBER,
  NON_EMPTY_STRING,
  type ExpectedValue,
  type AnalyticsEvent,
  type ProxyArgs,
  type AnalyticsCallbackConfig,
  type LogCustomExposureFilter,
} from './analytics-validator';

// Re-export everything from analytics-validator so tests can import from one place
export {
  validateAnalyticsEvent,
  createAnalyticsCallback,
  createLogCustomExposureCallback,
  assertEventExists,
  assertEventCount,
  extractEventsByType,
  extractNavigateWithinPageEvents,
  getPageValidator,
  ANY_VALUE,
  EXISTS,
  NUMBER,
  STRING,
  BOOLEAN,
  POSITIVE_NUMBER,
  NON_EMPTY_STRING,
  type ExpectedValue,
  type AnalyticsEvent,
  type ProxyArgs,
  type AnalyticsCallbackConfig,
  type LogCustomExposureFilter,
};

/**
 * ═══════════════════════════════════════════════════════════════════
 * SHARED CONSTANTS (reusable across events and screens)
 * Derived from tubi/analytics/client.proto, events.proto, tubi/common/constants.proto.
 * ═══════════════════════════════════════════════════════════════════
 */

/** ContentMode enum from common/constants.proto (full set for any test/screen). */
export const CONTENT_MODE = {
  CONTENT_MODE_UNKNOWN: 'CONTENT_MODE_UNKNOWN',
  CONTENT_MODE_MOVIE: 'CONTENT_MODE_MOVIE',
  CONTENT_MODE_TV: 'CONTENT_MODE_TV',
  CONTENT_MODE_LATINO: 'CONTENT_MODE_LATINO',
  CONTENT_MODE_NEWS: 'CONTENT_MODE_NEWS',
  CONTENT_MODE_LINEAR: 'CONTENT_MODE_LINEAR',
  CONTENT_MODE_COMEDY: 'CONTENT_MODE_COMEDY',
  CONTENT_MODE_DRAMA: 'CONTENT_MODE_DRAMA',
  CONTENT_MODE_HORROR: 'CONTENT_MODE_HORROR',
  CONTENT_MODE_CUSTOM_CONTAINERS: 'CONTENT_MODE_CUSTOM_CONTAINERS',
  CONTENT_MODE_ALIST: 'CONTENT_MODE_ALIST',
  CONTENT_MODE_NOSTALGIA: 'CONTENT_MODE_NOSTALGIA',
} as const;

/** Subset of ContentMode used for home/left-nav (Movies, TV Shows, Español) and generic home (UNKNOWN). Use for expectContentModeProper. */
export const VALID_CONTENT_MODES = [
  CONTENT_MODE.CONTENT_MODE_UNKNOWN,
  CONTENT_MODE.CONTENT_MODE_MOVIE,
  CONTENT_MODE.CONTENT_MODE_TV,
  CONTENT_MODE.CONTENT_MODE_LATINO,
] as const;

export type ContentMode = typeof VALID_CONTENT_MODES[number];

/** Left nav section names (NavigationMenu.Section in client.proto: MOVIES=11, SERIES=12, ESPANOL=14). */
export const LEFT_NAV_SECTIONS = {
  MOVIES: 'MOVIES',
  SERIES: 'SERIES',
  ESPANOL: 'ESPANOL',
} as const;

/** AppEvent oneof keys from events.proto – use for findAnalyticsEvent, createAnalyticsCallback filters. */
export const ANALYTICS_EVENT_KEYS = [
  'page_load',
  'navigate_to_page',
  'navigate_within_page',
  'component_interaction',
  'start_preview',
  'preview_play_progress',
  'finish_preview',
  'start_video',
  'play_progress',
  'seek',
  'bookmark',
  'search',
  'dialog',
  'explicit_feedback',
  'account',
  'request_for_info',
  'exposure',
  'auto_play',
  'finish_trailer',
  'start_trailer',
  'trailer_play_progress',
] as const;

export type AnalyticsEventKey = typeof ANALYTICS_EVENT_KEYS[number];

/** Map left nav section to expected content_mode on home_page / dest (client.proto HomePage.content_mode). */
export const CONTENT_MODE_BY_LEFT_NAV_SECTION: Record<string, string> = {
  [LEFT_NAV_SECTIONS.MOVIES]: CONTENT_MODE.CONTENT_MODE_MOVIE,
  [LEFT_NAV_SECTIONS.SERIES]: CONTENT_MODE.CONTENT_MODE_TV,
  [LEFT_NAV_SECTIONS.ESPANOL]: CONTENT_MODE.CONTENT_MODE_LATINO,
};

/** Video player context (VIDEO_IN_GRID for tiles, BANNER for details banner). */
export const VIDEO_PLAYER = {
  VIDEO_IN_GRID: 'VIDEO_IN_GRID',
  BANNER: 'BANNER',
} as const;

/** Playback source for start_video / play_progress. */
export const PLAYBACK_SOURCE = {
  VIDEO_PREVIEWS: 'VIDEO_PREVIEWS',
  AUTOPLAY_AUTOMATIC: 'AUTOPLAY_AUTOMATIC',
  AUTOPLAY_DELIBERATE: 'AUTOPLAY_DELIBERATE',
  UNKNOWN_PLAYBACK_SOURCE: 'UNKNOWN_PLAYBACK_SOURCE',
} as const;

/** User interaction for component_interaction. */
export const USER_INTERACTION = {
  CONFIRM: 'CONFIRM',
  TOGGLE_ON: 'TOGGLE_ON',
  TOGGLE_OFF: 'TOGGLE_OFF',
} as const;

/** Single object for tests that need all analytics-related constants. */
export const AnalyticsConstants = {
  CONTENT_MODE,
  VALID_CONTENT_MODES,
  LEFT_NAV_SECTIONS,
  CONTENT_MODE_BY_LEFT_NAV_SECTION,
  VIDEO_PLAYER,
  PLAYBACK_SOURCE,
  USER_INTERACTION,
  ANALYTICS_EVENT_KEYS,
};

/**
 * ═══════════════════════════════════════════════════════════════════
 * PAGE / COMPONENT ASSERTION HELPERS (reusable across events and screens)
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Asserts content_mode is present and valid on a page object (home_page or for_you_page).
 * Use after validating preview/navigation events that include a home/for_you page context.
 *
 * @param pageObj - The page object (e.g. event.start_preview.home_page)
 * @param context - Description for error messages (e.g. 'start_preview', 'navigate_to_page (to details)')
 */
export function expectContentModeProper(
  pageObj: { content_mode?: string } | undefined,
  context: string
): void {
  expect(pageObj, `${context}: page object should exist`).to.exist;
  expect(pageObj!.content_mode, `${context}: content_mode should be present`).to.exist;
  expect(pageObj!.content_mode).to.be.a('string');
  expect(
    VALID_CONTENT_MODES.includes(pageObj!.content_mode as ContentMode),
    `${context}: content_mode should be one of ${VALID_CONTENT_MODES.join(', ')}; got ${pageObj!.content_mode}`
  ).to.equal(true);
}

/**
 * Asserts content_tile has either video_id or series_id (and type if video_id).
 * Use for start_preview, preview_play_progress, finish_preview, navigate_within_page.
 *
 * @param contentTile - The content_tile object (e.g. event.start_preview.category_component.content_tile)
 * @param context - Description for error messages (e.g. 'start_preview.category_component.content_tile')
 */
export function expectContentTileHasVideoOrSeriesId(
  contentTile: { video_id?: number; series_id?: number } | undefined,
  context: string
): void {
  const hasId =
    contentTile &&
    (contentTile.video_id !== undefined || contentTile.series_id !== undefined);
  expect(
    hasId,
    `${context} should have video_id or series_id`
  ).to.equal(true);
  if (contentTile?.video_id !== undefined) {
    expect(typeof contentTile.video_id).to.equal('number');
  }
}

/**
 * Returns the first event in the array that has the given event type and passes the optional predicate.
 * Throws with a clear message if not found (including list of received event types).
 *
 * @param events - Array of captured analytics events (payloads)
 * @param eventKey - Top-level event key (e.g. 'start_preview', 'page_load', 'navigate_to_page')
 * @param predicate - Optional filter (e.g. (e) => e.event?.finish_preview?.has_completed === true)
 * @param description - Short description for error message (e.g. 'finish_preview (has_completed=true)')
 */
export function findAnalyticsEvent<T = any>(
  events: any[],
  eventKey: string,
  options?: {
    predicate?: (event: any) => boolean;
    description?: string;
  }
): T {
  const predicate = options?.predicate ?? (e => e.event?.[eventKey] !== undefined);
  const description = options?.description ?? eventKey;
  const found = events.find(e => e.event?.[eventKey] !== undefined && predicate(e));
  const capturedTypes = events.map(e => Object.keys(e.event || {})[0]).filter(Boolean).join(', ') || '(none)';
  expect(
    found,
    `Missing ${description}. Received ${events.length} events; types: ${capturedTypes}`
  ).to.exist;
  return found as T;
}

/**
 * Returns getPageValidator('home_page', { content_mode: EXISTS }) or getPageValidator('home_page').
 * Use in expected structures for events that include home context (preview, navigate_within_page, etc.).
 */
export function homePageWithContentMode(requireContentMode = true): ExpectedValue {
  return getPageValidator('home_page', requireContentMode ? { content_mode: EXISTS } : {});
}
