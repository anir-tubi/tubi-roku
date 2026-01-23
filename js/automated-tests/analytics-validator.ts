/**
 * ═══════════════════════════════════════════════════════════════════
 * ANALYTICS VALIDATOR
 * ═══════════════════════════════════════════════════════════════════
 *
 * PURPOSE: Centralized validation for analytics events
 *
 * USAGE:
 *   import { validateAnalyticsEvent, EXISTS } from '../analytics-validator';
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
 * Type for expected values - can be primitive, object, or special markers
 */
export type ExpectedValue =
  | string
  | number
  | boolean
  | null
  | typeof ANY_VALUE
  | typeof EXISTS
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
 */
export interface ProxyArgs {
  url: string;
  requestBody?: any;
}

/**
 * Analytics proxy callback configuration
 */
export type AnalyticsCallbackConfig = {
  shouldProcess: (args: ProxyArgs) => boolean;
  processRequest: (args: ProxyArgs) => undefined;
};

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
 * Check if value is a special marker (ANY_VALUE or EXISTS)
 */
function isSpecialMarker(value: any): boolean {
  return isAnyValue(value) || isExists(value);
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
 * Validate primitive value
 */
function validatePrimitive(actual: any, expected: string | number | boolean | null, description: string, path: string): void {
  if (actual !== expected) {
    throw new Error(
      `\n${description}: Field "${path}" validation failed` +
      `\n  Expected: ${JSON.stringify(expected)} (${typeof expected})` +
      `\n  Received: ${JSON.stringify(actual)} (${typeof actual})`
    );
  }
}

/**
 * Validate array
 */
function validateArray(actual: any, expected: ExpectedValue[], description: string, path: string): void {
  if (actual === undefined || actual === null) {
    throw new Error(
      `\n${description}: Field "${path}" validation failed` +
      `\n  Expected: array` +
      `\n  Received: ${actual}`
    );
  }

  if (!Array.isArray(actual)) {
    throw new Error(
      `\n${description}: Field "${path}" validation failed` +
      `\n  Expected: array` +
      `\n  Received: ${typeof actual} - ${JSON.stringify(actual)}`
    );
  }

  if (expected.length > 0 && actual.length < expected.length) {
    throw new Error(
      `\n${description}: Field "${path}" validation failed` +
      `\n  Expected: array with at least ${expected.length} items` +
      `\n  Received: array with ${actual.length} items`
    );
  }

  if (expected.length > 0) {

    // Validate each expected array item
    expected.forEach((expectedItem, index) => {
      const itemPath = buildPath(path, index);

      // Handle EXISTS marker for array elements
      if (isExists(expectedItem)) {
        if (actual[index] === undefined || actual[index] === null) {
          throw new Error(
            `\n${description}: Field "${itemPath}" validation failed` +
            `\n  Expected: field to exist (any value)` +
            `\n  Received: ${actual[index]}`
          );
        }
        return; // Skip to next iteration
      }

      // Handle ANY_VALUE marker for array elements
      if (isAnyValue(expectedItem)) {
        if (actual[index] === undefined) {
          throw new Error(
            `\n${description}: Field "${itemPath}" validation failed` +
            `\n  Expected: any defined value` +
            `\n  Received: undefined`
          );
        }
        return; // Skip to next iteration
      }

      // Handle nested objects (excluding special markers)
      if (isPlainObject(expectedItem) && !isSpecialMarker(expectedItem)) {
        if (actual[index] === undefined || actual[index] === null) {
          throw new Error(
            `\n${description}: Field "${itemPath}" validation failed` +
            `\n  Expected: nested object` +
            `\n  Received: ${actual[index]}`
          );
        }
        if (typeof actual[index] !== 'object') {
          throw new Error(
            `\n${description}: Field "${itemPath}" validation failed` +
            `\n  Expected: object` +
            `\n  Received: ${typeof actual[index]} - ${JSON.stringify(actual[index])}`
          );
        }
        validateAnalyticsEvent(actual[index], expectedItem as { [key: string]: ExpectedValue }, description, itemPath);
      } else if (!isSpecialMarker(expectedItem)) {
        // Handle primitive values
        if (actual[index] !== expectedItem) {
          throw new Error(
            `\n${description}: Field "${itemPath}" validation failed` +
            `\n  Expected: ${JSON.stringify(expectedItem)} (${typeof expectedItem})` +
            `\n  Received: ${JSON.stringify(actual[index])} (${typeof actual[index]})`
          );
        }
      }
    });
  }
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
 * @throws {AssertionError} When validation fails
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
export function validateAnalyticsEvent(actual: any, expected: { [key: string]: ExpectedValue }, description: string = 'Analytics event', path: string = ''): void {
  for (const key in expected) {
    const expectedValue = expected[key];
    const actualValue = actual?.[key];
    const currentPath = buildPath(path, key);

    // Handle EXISTS marker - just check field exists
    if (isExists(expectedValue)) {
      if (actualValue === undefined || actualValue === null) {
        throw new Error(
          `\n${description}: Field "${currentPath}" validation failed` +
          `\n  Expected: field to exist (any value)` +
          `\n  Received: ${actualValue}`
        );
      }
      continue;
    }

    // Handle ANY_VALUE marker - just check field is defined
    if (isAnyValue(expectedValue)) {
      if (actualValue === undefined) {
        throw new Error(
          `\n${description}: Field "${currentPath}" validation failed` +
          `\n  Expected: any defined value` +
          `\n  Received: undefined`
        );
      }
      continue;
    }

    // Handle nested objects
    if (isPlainObject(expectedValue)) {
      if (actualValue === undefined || actualValue === null) {
        throw new Error(
          `\n${description}: Field "${currentPath}" validation failed` +
          `\n  Expected: nested object` +
          `\n  Received: ${actualValue}`
        );
      }

      if (typeof actualValue !== 'object') {
        throw new Error(
          `\n${description}: Field "${currentPath}" validation failed` +
          `\n  Expected: object` +
          `\n  Received: ${typeof actualValue} - ${JSON.stringify(actualValue)}`
        );
      }

      validateAnalyticsEvent(actualValue, expectedValue as { [key: string]: ExpectedValue }, description, currentPath);
      continue;
    }

    // Handle arrays
    if (Array.isArray(expectedValue)) {
      validateArray(actualValue, expectedValue, description, currentPath);
      continue;
    }

    // Handle primitive values
    validatePrimitive(actualValue, expectedValue as string | number | boolean | null, description, currentPath);
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
 * @param eventType - Event type to filter by (e.g., 'page_view', 'navigate_within_page')
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
 * Create a proxy callback for capturing analytics events
 * 
 * @param eventsArray - Array to push captured events into
 * @param eventFilter - Optional filter function to determine which events to capture
 * @returns Proxy callback configuration object
 * 
 * @example Basic usage
 * const events: any[] = [];
 * proxy.addCallback(createAnalyticsCallback(events));
 * 
 * @example With filter
 * const carouselEvents: any[] = [];
 * proxy.addCallback(
 *   createAnalyticsCallback(carouselEvents, (event) => 
 *     event.event?.navigate_within_page?.category_component?.category_slug === 'hdc_carousel'
 *   )
 * );
 */
export function createAnalyticsCallback(eventsArray: any[], eventFilter?: (event: any) => boolean): AnalyticsCallbackConfig {
  return {
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
    }
  };
}
