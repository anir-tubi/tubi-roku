/**
 * ═══════════════════════════════════════════════════════════════════
 * ANALYTICS VALIDATOR
 * ═══════════════════════════════════════════════════════════════════
 *
 * PURPOSE: Centralized validation for analytics events
 *
 * USAGE:
 *   import { validateAnalyticsEvent, EXISTS } from './analytics-validator';
 *   validateAnalyticsEvent(actualEvent, expectedStructure, 'Event description');
 *
 * FEATURES:
 *   - Deep object comparison with partial matching
 *   - Clear error messages with field paths
 *   - Support for "any" values (use ANY_VALUE to skip validation)
 *   - Support for existence checks (use EXISTS)
 *   - Reusable utility functions for common patterns
 *
 * ═══════════════════════════════════════════════════════════════════
 */

import { expect } from 'chai';

/**
 * ═══════════════════════════════════════════════════════════════════
 * TYPE DEFINITIONS
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Special marker to indicate a field should exist but value doesn't matter
 */
export const ANY_VALUE = Symbol('ANY_VALUE');

/**
 * Special marker to indicate a field should exist (for objects/arrays)
 */
export const EXISTS = Symbol('EXISTS');

/**
 * Type validator markers - check both existence and type
 */
export const NUMBER = Symbol('NUMBER');
export const STRING = Symbol('STRING');
export const BOOLEAN = Symbol('BOOLEAN');
export const POSITIVE_NUMBER = Symbol('POSITIVE_NUMBER');
export const NON_EMPTY_STRING = Symbol('NON_EMPTY_STRING');

/**
 * Type for expected values - can be primitive, object, or special markers
 */
export type ExpectedValue =
  | string
  | number
  | boolean
  | null
  | typeof ANY_VALUE
  | typeof EXISTS
  | typeof NUMBER
  | typeof STRING
  | typeof BOOLEAN
  | typeof POSITIVE_NUMBER
  | typeof NON_EMPTY_STRING
  | { [key: string]: ExpectedValue }
  | ExpectedValue[];

/**
 * Basic analytics event structure
 */
export interface AnalyticsEvent {
  event?: Record<string, any>;
  [key: string]: any;
}

/**
 * Proxy callback arguments
 *
 * Fields available vary by callback phase:
 *   - shouldProcess / processRequest: url, requestBody
 *   - processResponse:                url, requestBody, responseBuffer, proxyRes
 */
export interface ProxyArgs {
  url: string;
  requestBody?: any;
  responseBuffer?: Buffer;
  proxyRes?: { statusCode?: number };
  removeCallback?: () => void;
}

/**
 * Analytics proxy callback configuration.
 *
 * processResponse is optional — when provided the proxy will invoke it
 * after the upstream server replies, giving access to responseBuffer.
 *
 * rejections is populated automatically by createAnalyticsCallback with
 * any events the backend rejected (non-zero status code).
 */
export type AnalyticsCallbackConfig = {
  shouldProcess: (args: ProxyArgs) => boolean;
  processRequest: (args: ProxyArgs) => Buffer | string | void;
  processResponse?: (args: ProxyArgs) => Buffer | string | void;
  /** Automatically populated with backend rejections. Use assertNoRejections() to validate. */
  rejections: AnalyticsRejection[];
};

/**
 * Information about an analytics event that was rejected by the backend.
 */
export interface AnalyticsRejection {
  /** The analytics ingestion URL the event was sent to */
  url: string;
  /** The request body that was rejected (if available) */
  requestBody?: any;
  /** The parsed response body from the backend */
  responseBody: any;
  /** The gRPC / HTTP status code returned by the backend */
  statusCode: number;
  /** Human-readable error message from the backend */
  message: string;
  /** ISO timestamp when the rejection was captured */
  timestamp: string;
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * SYMBOL UTILITIES
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Check if value is the ANY_VALUE marker
 */
function isAnyValue(value: any): value is typeof ANY_VALUE {
  return value === ANY_VALUE;
}

/**
 * Check if value is the EXISTS marker
 */
function isExists(value: any): value is typeof EXISTS {
  return value === EXISTS;
}

/**
 * Check if value is NUMBER marker
 */
function isNumber(value: any): value is typeof NUMBER {
  return value === NUMBER;
}

/**
 * Check if value is STRING marker
 */
function isString(value: any): value is typeof STRING {
  return value === STRING;
}

/**
 * Check if value is BOOLEAN marker
 */
function isBoolean(value: any): value is typeof BOOLEAN {
  return value === BOOLEAN;
}

/**
 * Check if value is POSITIVE_NUMBER marker
 */
function isPositiveNumber(value: any): value is typeof POSITIVE_NUMBER {
  return value === POSITIVE_NUMBER;
}

/**
 * Check if value is NON_EMPTY_STRING marker
 */
function isNonEmptyString(value: any): value is typeof NON_EMPTY_STRING {
  return value === NON_EMPTY_STRING;
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * ERROR MESSAGE HELPERS
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Build path for nested fields
 */
function buildPath(currentPath: string, key: string | number): string {
  if (typeof key === 'number') {
    return `${currentPath}[${key}]`;
  }
  return currentPath ? `${currentPath}.${key}` : String(key);
}

/**
 * Check if value is a plain object (not array, not null)
 */
function isPlainObject(value: any): boolean {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * VALIDATION HELPERS
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Build a descriptive validation error message.
 *
 * Includes the field path, expected vs received values, and a truncated
 * JSON dump of the full actual event so the developer can immediately
 * see what was received without having to re-run or add extra logging.
 *
 * @param description - Human-readable label for the event (e.g. "NavigateWithinPage (nav → pivot)")
 * @param path - Dot-separated path to the failing field
 * @param expected - What was expected (human-readable string)
 * @param received - What was actually received (human-readable string)
 * @param rootActual - The root event object (optional, included when available)
 */
function buildValidationError(
  description: string,
  path: string,
  expected: string,
  received: string,
  rootActual?: any,
): Error {
  let msg =
    `\n${description}: Field "${path}" validation failed` +
    `\n  Expected: ${expected}` +
    `\n  Received: ${received}`;

  if (rootActual !== undefined) {
    try {
      const dump = JSON.stringify(rootActual, null, 2);
      // Cap at ~2000 chars so terminal output stays readable
      const truncated = dump.length > 2000 ? dump.slice(0, 2000) + '\n  ... (truncated)' : dump;
      msg += `\n\n  Actual event payload:\n${truncated}`;
    } catch {
      msg += `\n\n  Actual event payload: [unable to serialize]`;
    }
  }

  return new Error(msg);
}

/**
 * Validate type markers (NUMBER, STRING, BOOLEAN, etc.)
 */
function validateTypeMarker(actual: any, expected: typeof NUMBER | typeof STRING | typeof BOOLEAN | typeof POSITIVE_NUMBER | typeof NON_EMPTY_STRING, description: string, path: string, rootActual?: any): void {
  if (isNumber(expected)) {
    if (typeof actual !== 'number') {
      throw buildValidationError(description, path, 'number', `${typeof actual} - ${JSON.stringify(actual)}`, rootActual);
    }
    return;
  }

  if (isString(expected)) {
    if (typeof actual !== 'string') {
      throw buildValidationError(description, path, 'string', `${typeof actual} - ${JSON.stringify(actual)}`, rootActual);
    }
    return;
  }

  if (isBoolean(expected)) {
    if (typeof actual !== 'boolean') {
      throw buildValidationError(description, path, 'boolean', `${typeof actual} - ${JSON.stringify(actual)}`, rootActual);
    }
    return;
  }

  if (isPositiveNumber(expected)) {
    if (typeof actual !== 'number' || actual <= 0) {
      throw buildValidationError(description, path, 'positive number (> 0)', `${typeof actual} - ${JSON.stringify(actual)}`, rootActual);
    }
    return;
  }

  if (isNonEmptyString(expected)) {
    if (typeof actual !== 'string' || actual.length === 0) {
      throw buildValidationError(description, path, 'non-empty string', `${typeof actual} - ${JSON.stringify(actual)}`, rootActual);
    }
    return;
  }
}

/**
 * Validate primitive value
 */
function validatePrimitive(actual: any, expected: string | number | boolean | null, description: string, path: string, rootActual?: any): void {
  if (actual !== expected) {
    throw buildValidationError(
      description, path,
      `${JSON.stringify(expected)} (${typeof expected})`,
      `${JSON.stringify(actual)} (${typeof actual})`,
      rootActual,
    );
  }
}

/**
 * Validate a single expected value against an actual value.
 *
 * This is the shared dispatch logic used by both validateAnalyticsEvent (for
 * object keys) and validateArray (for array elements), avoiding duplicated
 * marker/type/object/primitive branching.
 */
function validateValue(actualValue: any, expectedValue: ExpectedValue, description: string, currentPath: string, rootActual?: any): void {
  // Handle EXISTS marker
  if (isExists(expectedValue)) {
    if (actualValue === undefined || actualValue === null) {
      throw buildValidationError(description, currentPath, 'field to exist (any value)', `${actualValue}`, rootActual);
    }
    return;
  }

  // Handle ANY_VALUE marker
  if (isAnyValue(expectedValue)) {
    if (actualValue === undefined) {
      throw buildValidationError(description, currentPath, 'any defined value', 'undefined', rootActual);
    }
    return;
  }

  // Handle type markers
  if (isNumber(expectedValue) || isString(expectedValue) || isBoolean(expectedValue) ||
    isPositiveNumber(expectedValue) || isNonEmptyString(expectedValue)) {
    if (actualValue === undefined || actualValue === null) {
      throw buildValidationError(description, currentPath, 'field to exist with correct type', `${actualValue}`, rootActual);
    }
    validateTypeMarker(actualValue, expectedValue, description, currentPath, rootActual);
    return;
  }

  // Handle nested objects
  if (isPlainObject(expectedValue)) {
    if (actualValue === undefined || actualValue === null) {
      throw buildValidationError(description, currentPath, 'nested object', `${actualValue}`, rootActual);
    }
    if (typeof actualValue !== 'object') {
      throw buildValidationError(description, currentPath, 'object', `${typeof actualValue} - ${JSON.stringify(actualValue)}`, rootActual);
    }
    validateAnalyticsEvent(actualValue, expectedValue as { [key: string]: ExpectedValue }, description, currentPath, rootActual);
    return;
  }

  // Handle arrays
  if (Array.isArray(expectedValue)) {
    validateArray(actualValue, expectedValue, description, currentPath, rootActual);
    return;
  }

  // Handle primitive values
  validatePrimitive(actualValue, expectedValue as string | number | boolean | null, description, currentPath, rootActual);
}

/**
 * Validate array
 */
function validateArray(actual: any, expected: ExpectedValue[], description: string, path: string, rootActual?: any): void {
  if (actual === undefined || actual === null) {
    throw buildValidationError(description, path, 'array', `${actual}`, rootActual);
  }

  if (!Array.isArray(actual)) {
    throw buildValidationError(description, path, 'array', `${typeof actual} - ${JSON.stringify(actual)}`, rootActual);
  }

  if (expected.length > 0 && actual.length < expected.length) {
    throw buildValidationError(
      description, path,
      `array with at least ${expected.length} items`,
      `array with ${actual.length} items`,
      rootActual,
    );
  }

  // Validate each expected array item using the shared dispatch
  expected.forEach((expectedItem, index) => {
    validateValue(actual[index], expectedItem, description, buildPath(path, index), rootActual);
  });
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * MAIN VALIDATION FUNCTION
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Validate an analytics event against expected structure
 *
 * This function performs deep validation of analytics events with flexible matching.
 * Only fields specified in 'expected' are validated - extra fields in 'actual' are ignored.
 *
 * @param actual - The actual analytics event data
 * @param expected - Expected structure with values to validate
 * @param description - Description for error messages (default: 'Analytics event')
 * @param path - Current path in object (used internally for recursion)
 *
 * @throws {Error} When validation fails (with field path and actual event payload)
 *
 * @example Basic validation
 * validateAnalyticsEvent(event, {
 *   event: {
 *     page_view: {
 *       page_name: 'home',
 *       page_type: 'main'
 *     }
 *   }
 * }, 'Page View Event');
 *
 * @example Using EXISTS marker - check field exists but don't validate value
 * validateAnalyticsEvent(event, {
 *   event: {
 *     navigate_within_page: {
 *       category_component: {
 *         ad_id: EXISTS,  // Just verify ad_id exists
 *         category_slug: 'hdc_carousel'
 *       }
 *     }
 *   }
 * }, 'Navigation Event');
 *
 * @example Using ANY_VALUE marker - field must be defined but value doesn't matter
 * validateAnalyticsEvent(event, {
 *   request: {
 *     key: ANY_VALUE  // Any non-undefined value is ok
 *   },
 *   user: {
 *     user_id: EXISTS
 *   }
 * }, 'User Event');
 *
 * @example Using type markers - check both existence and type
 * validateAnalyticsEvent(event, {
 *   event: {
 *     start_preview: {
 *       video_id: NUMBER,  // Must exist and be a number
 *       preview_id: NON_EMPTY_STRING,  // Must exist and be non-empty string
 *       position: POSITIVE_NUMBER,  // Must exist and be > 0
 *       is_fullscreen: BOOLEAN  // Must exist and be boolean
 *     }
 *   }
 * }, 'Start Preview Event');
 *
 * @example Nested object validation
 * validateAnalyticsEvent(event, {
 *   event: {
 *     navigate_within_page: {
 *       category_component: {
 *         category_slug: 'hdc_carousel',
 *         content_tile: {
 *           row: 1,
 *           col: 1
 *         }
 *       }
 *     }
 *   }
 * }, 'HDC Carousel Event');
 */
export function validateAnalyticsEvent(
  actual: any,
  expected: { [key: string]: ExpectedValue },
  description: string = 'Analytics event',
  path: string = '',
  rootActual?: any,
): void {
  // On the top-level call (path === '') capture the root so every nested error
  // can include the full event payload for easy debugging.
  const root = rootActual ?? actual;

  for (const key in expected) {
    validateValue(actual?.[key], expected[key], description, buildPath(path, key), root);
  }
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * COMMON UTILITY FUNCTIONS
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Assert that an event exists in the events array
 *
 * @param events - Array of captured events
 * @param matcher - Function to match the desired event
 * @param description - Description for error message
 * @returns The first matching event
 *
 * @example
 * const event = assertEventExists(
 *   analyticsEvents,
 *   (e) => e.event?.page_view?.page_name === 'home',
 *   'Home page view event'
 * );
 */
export function assertEventExists(events: any[], matcher: (event: any) => boolean, description: string): any {
  const event = events.find(matcher);
  expect(event, `${description}: Event should exist`).to.exist;
  return event;
}

/**
 * Assert the count of matching events
 *
 * @param events - Array of captured events
 * @param matcher - Function to match events
 * @param expectedCount - Expected number of matching events
 * @param description - Description for error message
 *
 * @example
 * assertEventCount(
 *   analyticsEvents,
 *   (e) => e.event?.navigate_within_page,
 *   3,
 *   'Navigate within page events'
 * );
 */
export function assertEventCount(events: any[], matcher: (event: any) => boolean, expectedCount: number, description: string): void {
  const matchingEvents = events.filter(matcher);
  expect(matchingEvents.length).to.equal(
    expectedCount,
    `${description}: Expected ${expectedCount} events, found ${matchingEvents.length}`
  );
}

/**
 * Extract events by event type
 *
 * @param events - Array of captured events
 * @param eventType - Event type to filter by (e.g. 'page_view', 'navigate_within_page')
 * @returns Array of matching events
 *
 * @example
 * const pageViews = extractEventsByType(analyticsEvents, 'page_view');
 * const navEvents = extractEventsByType(analyticsEvents, 'navigate_within_page');
 */
export function extractEventsByType<T = any>(events: any[], eventType: string): T[] {
  return events.filter(event => event.event?.[eventType]);
}

/**
 * Extract navigate_within_page events from analytics events array
 *
 * @param events - Array of analytics events
 * @param categorySlug - Optional category slug to filter by
 * @returns Array of navigate_within_page events
 *
 * @example
 * // Get all navigation events
 * const navEvents = extractNavigateWithinPageEvents(analyticsEvents);
 *
 * // Get only HDC carousel navigation events
 * const carouselEvents = extractNavigateWithinPageEvents(analyticsEvents, 'hdc_carousel');
 */
export function extractNavigateWithinPageEvents(events: any[], categorySlug?: string): any[] {
  const navEvents = extractEventsByType(events, 'navigate_within_page');

  if (categorySlug) {
    return navEvents.filter(event =>
      event.event.navigate_within_page.category_component?.category_slug === categorySlug
    );
  }

  return navEvents;
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * PROXY CALLBACK HELPERS
 * ═══════════════════════════════════════════════════════════════════
 */

/**
 * Internal registry of all callbacks created during the current test.
 * Cleared automatically by checkPendingRejections().
 *
 * NOTE: This is module-level mutable state scoped to the current process.
 * If tests ever run in parallel workers that share the same module instance,
 * callbacks from one suite could leak into another's checkPendingRejections().
 * For now Mocha runs serially so this is safe; revisit if switching to parallel.
 */
const _callbackRegistry: AnalyticsCallbackConfig[] = [];

/**
 * Reusable processResponse handler that detects backend rejections.
 *
 * Checks the HTTP status code from `proxyRes`; any non-200 is treated as a
 * rejection. Optionally parses the response body for a human-readable error
 * message. Rejections are logged to console and pushed into the provided array.
 *
 * Skips processing entirely when `proxyRes` is not available (e.g. network
 * failure) since there is no backend response to evaluate.
 */
function createRejectionHandler(rejections: AnalyticsRejection[]): (args: ProxyArgs) => void {
  return (args: ProxyArgs) => {
    try {
      const statusCode = args.proxyRes?.statusCode;

      // No proxyRes means a network-level failure, not a backend rejection — skip.
      if (statusCode === undefined) return;

      // Any non-200 status means the backend rejected the event.
      if (statusCode !== 200) {
        const eventType = args.requestBody?.event
          ? Object.keys(args.requestBody.event)[0] || 'unknown'
          : 'unknown';

        // Try to parse the response body for a human-readable error message
        let responseBody: any;
        let message = `HTTP ${statusCode}`;
        try {
          if (args.responseBuffer) {
            responseBody = JSON.parse(args.responseBuffer.toString());
            if (responseBody?.status?.message) {
              message = responseBody.status.message;
            }
          }
        } catch {
          // Response may not be JSON — use the raw status code as the message
        }

        const rejection: AnalyticsRejection = {
          url: args.url,
          requestBody: args.requestBody,
          responseBody: responseBody ?? args.responseBuffer?.toString(),
          statusCode,
          message,
          timestamp: new Date().toISOString(),
        };

        console.warn(
          `\n⚠ Analytics event REJECTED by backend (HTTP ${statusCode}, event: ${eventType}):\n` +
          `  Message: ${rejection.message}\n` +
          `  URL: ${rejection.url}\n`
        );

        rejections.push(rejection);
      }
    } catch (_e) {
      // Defensive — don't let rejection tracking break the test
    }
  };
}

/**
 * Create a proxy callback for capturing analytics events and detecting backend rejections.
 *
 * The callback intercepts both the outgoing request (to capture the event payload)
 * and the incoming response (to detect validation errors returned by the analytics backend).
 *
 * Rejections are always:
 *   1. Logged as console warnings (for immediate visibility in test output)
 *   2. Collected in the returned callback's `rejections` array
 *
 * Use `assertNoRejections(callback)` after your test actions to fail the test
 * if any captured events were rejected by the backend.
 *
 * @param eventsArray - Array to push captured events into
 * @param eventFilter - Optional filter function to determine which events to capture
 * @returns Proxy callback configuration object with a `rejections` array
 *
 * @example Basic usage (captures events, tracks rejections automatically)
 * const events: any[] = [];
 * const callback = createAnalyticsCallback(events);
 * proxy.addCallback(callback);
 * // ... run test actions ...
 * assertNoRejections(callback); // fails test if backend rejected any events
 *
 * @example With filter
 * const navEvents: any[] = [];
 * const callback = createAnalyticsCallback(navEvents, (event) =>
 *   event.event?.navigate_within_page !== undefined
 * );
 * proxy.addCallback(callback);
 * // ... run test actions ...
 * assertNoRejections(callback);
 */
export function createAnalyticsCallback(
  eventsArray: any[],
  eventFilter?: (event: any) => boolean,
): AnalyticsCallbackConfig {
  const rejections: AnalyticsRejection[] = [];

  const callback: AnalyticsCallbackConfig = {
    rejections,
    shouldProcess: (args: ProxyArgs) => {
      return args.url.includes('analytics-ingestion') &&
        args.url.includes('/single-event');
    },
    processRequest: (args: ProxyArgs) => {
      try {
        if (args.requestBody) {
          // Apply filter if provided
          if (!eventFilter || eventFilter(args.requestBody)) {
            eventsArray.push(args.requestBody);
          }
        }
      } catch (e) {
        // Log error but don't fail the test - analytics capture shouldn't break tests
        console.error('Failed to process analytics event:', e);
      }
      return undefined;
    },
    processResponse: createRejectionHandler(rejections),
  };

  _callbackRegistry.push(callback);
  return callback;
}

/**
 * Assert that no analytics events were rejected by the backend.
 *
 * Can be used for a specific callback or omitted to check all callbacks
 * created since the last call to checkPendingRejections().
 *
 * @param callback - The callback returned by createAnalyticsCallback
 * @param context - Optional context string for the assertion message
 */
export function assertNoRejections(callback: AnalyticsCallbackConfig, context?: string): void {
  const prefix = context ? `[${context}] ` : '';
  expect(
    callback.rejections,
    `${prefix}Analytics events were rejected by backend:\n${formatRejections(callback.rejections)}`
  ).to.have.lengthOf(0);
}

/**
 * Check all analytics callbacks created during the current test for backend rejections,
 * then clear the registry. Designed to be called from an `afterEach` hook so that
 * every test automatically validates that no events were rejected — no per-test
 * boilerplate needed.
 *
 * @example Inside a describe block (covers all tests in the suite):
 * describe('My Analytics Tests', () => {
 *   afterEach(() => {
 *     checkPendingRejections();
 *   });
 *
 *   it('fires event X', async () => {
 *     const events: any[] = [];
 *     proxy.addCallback(createAnalyticsCallback(events));
 *     // ... test actions and assertions ...
 *     // No need to call assertNoRejections — afterEach handles it
 *   });
 * });
 */
export function checkPendingRejections(): void {
  const allRejections = _callbackRegistry.flatMap(c => c.rejections);

  // Clear the registry regardless of outcome so the next test starts clean
  _callbackRegistry.length = 0;

  if (allRejections.length > 0) {
    // Use expect so it integrates with the test runner's assertion reporting
    expect(
      allRejections,
      `Analytics events were rejected by backend:\n${formatRejections(allRejections)}`
    ).to.have.lengthOf(0);
  }
}

/**
 * Register beforeEach/afterEach hooks that automatically clear stale callbacks
 * and check for backend rejections after every test in the suite.
 *
 * Call once inside a `describe` block — no per-test boilerplate needed.
 * The `beforeEach` clears any callbacks left over from other suites (prevents
 * cross-suite leakage), and the `afterEach` asserts no rejections occurred.
 *
 * @example
 * describe('My Analytics Tests', () => {
 *   setupRejectionTracking();
 *
 *   it('fires event X', async () => {
 *     const events: any[] = [];
 *     proxy.addCallback(createAnalyticsCallback(events));
 *     // ... test actions and assertions ...
 *   });
 * });
 */
export function setupRejectionTracking(): void {
  beforeEach(() => {
    // Discard stale callbacks from suites that never called checkPendingRejections
    _callbackRegistry.length = 0;
  });

  afterEach(() => {
    checkPendingRejections();
  });
}

/**
 * Format an array of AnalyticsRejection objects into a human-readable string
 * for use in assertion messages.
 *
 * @param rejections - Array of AnalyticsRejection objects
 * @returns Formatted multi-line string summarizing each rejection
 */
export function formatRejections(rejections: AnalyticsRejection[]): string {
  if (rejections.length === 0) return 'No rejections';
  return rejections
    .map((r, i) => {
      const eventType = r.requestBody?.event
        ? Object.keys(r.requestBody.event)[0] || 'unknown'
        : 'unknown';
      return `  [${i + 1}] ${eventType} (code ${r.statusCode}): ${r.message}`;
    })
    .join('\n');
}

/**
 * Options to filter which log_custom_exposure payloads to capture
 */
export type LogCustomExposureFilter = {
  experimentName?: string;
  group?: string;
};

/**
 * Create a proxy callback for capturing abproxy log_custom_exposure requests
 * (e.g. https://abproxy.staging-public.tubi.io/v1/log_custom_exposure).
 * Request body shape: { exposures: [{ experimentName, group, user, ... }] }
 *
 * @param payloadsArray - Array to push captured request bodies into
 * @param filter - Optional filter; only payloads with at least one matching exposure are captured
 * @returns Proxy callback configuration object
 */
export function createLogCustomExposureCallback(
  payloadsArray: any[],
  filter?: LogCustomExposureFilter
): AnalyticsCallbackConfig {
  const rejections: AnalyticsRejection[] = [];

  const callback: AnalyticsCallbackConfig = {
    rejections,
    shouldProcess: (args: ProxyArgs) => {
      return args.url.includes('log_custom_exposure');
    },
    processRequest: (args: ProxyArgs) => {
      try {
        if (args.requestBody && Array.isArray(args.requestBody.exposures)) {
          const matches =
            !filter ||
            args.requestBody.exposures.some(
              (e: any) =>
                (!filter.experimentName || e.experimentName === filter.experimentName) &&
                (!filter.group || e.group === filter.group)
            );
          if (matches) {
            payloadsArray.push(args.requestBody);
          }
        }
      } catch (e) {
        console.error('Failed to process log_custom_exposure:', e);
      }
      return undefined;
    },
    processResponse: createRejectionHandler(rejections),
  };

  _callbackRegistry.push(callback);
  return callback;
}

/**
 * ═══════════════════════════════════════════════════════════════════
 * PAGE TYPE VALIDATOR
 * ═══════════════════════════════════════════════════════════════════
 *
 * Unified validator for all page types. Page shapes are derived from protobuf definitions in:
 * - tubi/analytics/client.proto (HomePage, ForYouPage, VideoPage, SeriesDetailPage, VideoPlayerPage, etc.)
 * - tubi/common/constants.proto (ContentMode for HomePage.content_mode)
 * Protos repo path: e.g. Documents/protos or ../protos relative to this repo. Keep this validator
 * in sync when proto page messages or required/optional fields change.
 *
 * This function validates page objects according to their proto message definitions.
 * Each page type has specific required/optional fields as defined in the protos.
 *
 * @param pageType - The page type (e.g., 'home_page', 'video_page', 'series_detail_page')
 * @param fields - Optional field validations. If not provided, validates structure based on proto requirements.
 *                 Use field names as they appear in the proto (snake_case).
 *                 Use special markers (EXISTS, NUMBER, POSITIVE_NUMBER, etc.) for type validation.
 *
 * @returns ExpectedValue structure for the specified page type
 *
 * @example
 * // HomePage - content_mode is required per proto; getPageValidator('home_page') validates it
 * validateAnalyticsEvent(event, {
 *   event: {
 *     start_preview: {
 *       home_page: getPageValidator('home_page')
 *     }
 *   }
 * });
 *
 * @example
 * // HomePage with content_mode validation
 * validateAnalyticsEvent(event, {
 *   event: {
 *     start_preview: {
 *       home_page: getPageValidator('home_page', { content_mode: EXISTS })
 *     }
 *   }
 * });
 *
 * @example
 * // VideoPage - requires video_id, optional is_fullscreen
 * validateAnalyticsEvent(event, {
 *   event: {
 *     start_preview: {
 *       video_page: getPageValidator('video_page', { video_id: POSITIVE_NUMBER })
 *     }
 *   }
 * });
 *
 * @example
 * // SeriesDetailPage with specific values
 * validateAnalyticsEvent(event, {
 *   event: {
 *     start_preview: {
 *       series_detail_page: getPageValidator('series_detail_page', {
 *         series_id: 12345,
 *         is_fullscreen: false
 *       })
 *     }
 *   }
 * });
 */
export function getPageValidator(pageType: string, fields: { [key: string]: ExpectedValue } = {}): ExpectedValue {
  // Field type constants for type checking
  const FIELD_TYPES = {
    STRING: 'string',
    NUMBER: 'number',
    BOOLEAN: 'boolean',
    ENUM: 'enum' // For enum types (validated as string)
  };

  // Page type definitions based on protobuf messages
  // Each field definition: { type: string, required: boolean }
  const pageDefinitions: {
    [key: string]: {
      required: { [field: string]: string }, // field name -> type
      optional: { [field: string]: string }  // field name -> type
    }
  } = {
    'home_page': {
      required: {
        'content_mode': FIELD_TYPES.ENUM   // common.ContentMode enum (required per proto)
      },
      optional: {
        'personalization_id': FIELD_TYPES.STRING // deprecated
      }
    },
    'for_you_page': {
      required: {},
      optional: {
        'top_nav_section': FIELD_TYPES.ENUM,    // NavigationMenu.Section enum (deprecated)
        'section_expanded': FIELD_TYPES.BOOLEAN
      }
    },
    'video_page': {
      required: {
        'video_id': FIELD_TYPES.NUMBER // uint32
      },
      optional: {
        'is_fullscreen': FIELD_TYPES.BOOLEAN
      }
    },
    'series_detail_page': {
      required: {
        'series_id': FIELD_TYPES.NUMBER // uint32
      },
      optional: {
        'is_fullscreen': FIELD_TYPES.BOOLEAN
      }
    },
    'video_player_page': {
      required: {
        'video_id': FIELD_TYPES.NUMBER // uint32
      },
      optional: {}
    },
    'category_page': {
      required: {
        'category_slug': FIELD_TYPES.STRING
      },
      optional: {}
    },
    'sub_category_page': {
      required: {
        'category_slug': FIELD_TYPES.STRING,
        'sub_category_slug': FIELD_TYPES.STRING
      },
      optional: {}
    },
    'category_list_page': {
      required: {},
      optional: {
        'section': FIELD_TYPES.ENUM // PageSection.Section enum
      }
    },
    'channel_list_page': {
      required: {},
      optional: {}
    },
    'coming_soon_page': {
      required: {},
      optional: {}
    },
    'reviews_awards_page': {
      required: {},
      optional: {}
    },
    'history_page': {
      required: {},
      optional: {}
    },
    'search_page': {
      required: {},
      optional: {
        'query': FIELD_TYPES.STRING,
        'search_type': FIELD_TYPES.ENUM
      }
    },
    'browse_page': {
      required: {},
      optional: {
        'content_mode': FIELD_TYPES.ENUM // common.ContentMode enum
      }
    },
    'movie_browse_page': {
      required: {},
      optional: {}
    },
    'series_browse_page': {
      required: {},
      optional: {}
    },
    'linear_browse_page': {
      required: {},
      optional: {}
    },
    'linear_details_page': {
      required: {},
      optional: {
        'channel_id': FIELD_TYPES.NUMBER // uint32
      }
    }
  };

  const definition = pageDefinitions[pageType];
  if (!definition) {
    // Unknown page type - return fields as-is or empty object
    return Object.keys(fields).length > 0 ? fields : {};
  }

  const validator: { [key: string]: ExpectedValue } = {};

  // Helper function to get default validator based on field type
  const getDefaultValidator = (fieldType: string, fieldName: string): ExpectedValue => {
    switch (fieldType) {
      case FIELD_TYPES.NUMBER:
        // For numeric IDs, use POSITIVE_NUMBER; for other numbers, use NUMBER
        return fieldName.includes('_id') ? POSITIVE_NUMBER : NUMBER;
      case FIELD_TYPES.STRING:
        // For slugs, use NON_EMPTY_STRING; for other strings, use STRING
        return fieldName.includes('_slug') ? NON_EMPTY_STRING : STRING;
      case FIELD_TYPES.BOOLEAN:
        return BOOLEAN;
      case FIELD_TYPES.ENUM:
        return STRING; // Enums are validated as strings
      default:
        return EXISTS;
    }
  };

  // Add required fields if not provided
  for (const [requiredField, fieldType] of Object.entries(definition.required)) {
    if (fields[requiredField] !== undefined) {
      validator[requiredField] = fields[requiredField];
    } else {
      // Apply default validation based on field type
      validator[requiredField] = getDefaultValidator(fieldType, requiredField);
    }
  }

  // Add optional fields if provided
  for (const [optionalField, fieldType] of Object.entries(definition.optional)) {
    if (fields[optionalField] !== undefined) {
      validator[optionalField] = fields[optionalField];
    }
    // Note: Optional fields are only validated if explicitly provided in fields parameter
  }

  // Add any additional fields provided that aren't in the definition
  for (const [field, value] of Object.entries(fields)) {
    if (!(field in definition.required) && !(field in definition.optional)) {
      validator[field] = value;
    }
  }

  // For pages with no required fields and no provided fields, return empty object
  if (Object.keys(definition.required).length === 0 && Object.keys(fields).length === 0) {
    return {};
  }

  return validator;
}
