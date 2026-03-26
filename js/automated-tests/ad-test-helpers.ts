/**
 * ═══════════════════════════════════════════════════════════════════
 * AD TEST HELPER FUNCTIONS
 * ═══════════════════════════════════════════════════════════════════
 *
 * PURPOSE: Centralized helpers for testing ad functionality
 *
 * USAGE: Import adTestHelpers and AdType enum in your test file:
 *   import { adTestHelpers, AdType } from '../ad-test-helpers';
 *   await adTestHelpers.mockAds([AdType.Wrapper, AdType.Spotlight]);
 *
 * FEATURES:
 *   - Type-safe ad type selection with enums
 *   - Mock multiple ad types in one call
 *   - Simple, clean API with no unnecessary interfaces
 *   - Automatic proxy setup and cleanup
 *   - Uses existing mock JSON files
 *
 * ═══════════════════════════════════════════════════════════════════
 */

import { proxy, utils } from 'roku-test-automation';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Ad types that can be mocked
 */
export enum AdType {
  /** Wrapper ads - Autoplay fullscreen (homepage_video / tubi_app_homepage) */
  Wrapper = 'wrapper',
  /** Spotlight container ads - Looping in grid (hdc_row) */
  Spotlight = 'spotlight',
  /** Carousel ads - Brand elements with rotation (hdc_row) */
  Carousel = 'carousel',
  /** Thematic Takeover ads - Apply branded theme to existing containers */
  ThematicTakeover = 'thematicTakeover'
}

/**
 * AD TEST HELPERS CLASS
 * 
 * Provides utilities for mocking and testing ads in the Roku app
 */
class AdTestHelpers {
  /**
   * PRIVATE: Load ad data from mock file
   * 
   * @param filename - Name of the mock file (e.g., 'ads_wrapper.json')
   * @returns Parsed ad data
   */
  private loadAdMockFile(filename: string): any {
    const filePath = path.join(__dirname, 'mocks', filename);
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(fileContent);
  }

  /**
   * HELPER: Mock ads endpoint with flexible ad type selection
   * 
   * USE WHEN:
   *   - Need to test wrapper ads (autoplay fullscreen)
   *   - Need to test spotlight ads (looping in grid)
   *   - Need to test carousel ads (brand elements with rotation)
   *   - Need to test thematic takeover ads (branded themes on containers)
   *   - Need to test multiple ad types together
   * 
   * PROVIDES:
   *   - Automatic proxy callback setup
   *   - Reads from existing mock JSON files
   *   - Promise that resolves when proxy intercepts request
   *   - Type-safe ad type selection with enums
   * 
   * @param types - Array of ad types to mock
   * @returns Promise that resolves when ads are mocked
   * 
   * @example
   * // Mock only wrapper ads
   * await adTestHelpers.mockAds([AdType.Wrapper]);
   * 
   * @example
   * // Mock spotlight ads
   * await adTestHelpers.mockAds([AdType.Spotlight]);
   * 
   * @example
   * // Mock thematic takeover ads (applies brand theme to containers)
   * await adTestHelpers.mockAds([AdType.ThematicTakeover]);
   * 
   * @example
   * // Mock multiple ad types
   * await adTestHelpers.mockAds([AdType.Wrapper, AdType.Spotlight]);
   * 
   * @example
   * // Use in test with timeout
   * proxy.resume();
   * const proxyPromise = adTestHelpers.mockAds([AdType.Wrapper]);
   * await testUtils.startApplicationAtPage('home');
   * await utils.promiseTimeout(proxyPromise, 50000);
   * 
   * @example
   * // Use persistCallback for tests that need multiple /inapp requests
   * const { cleanup } = await adTestHelpers.mockAds([AdType.Carousel], { persistCallback: true });
   * // ... test logic that navigates away and back to home screen ...
   * if (cleanup) cleanup(); // Remove callback when done
   */
  /**
   * PRIVATE: Rewrite tracker URLs to route through proxy (like Charles does)
   * Format: http://PROXY_HOST:PROXY_PORT/;;ORIGINAL_URL
   * Only rewrites URLs inside "trackers" objects (pixel tracking URLs)
   */
  private rewriteUrlsForProxy(obj: any, proxyUrl: string, isInsideTrackers: boolean = false): any {
    if (typeof obj === 'string') {
      // Only rewrite if we're inside a "trackers" object and it's a tracking pixel URL
      if (isInsideTrackers && obj.startsWith('https://') && obj.includes('ads.production-public.tubi.io/pixel')) {
        return `${proxyUrl}/;;${obj}`;
      }
      return obj;
    }

    if (Array.isArray(obj)) {
      return obj.map(item => this.rewriteUrlsForProxy(item, proxyUrl, isInsideTrackers));
    }

    if (obj !== null && typeof obj === 'object') {
      const result: any = {};
      for (const key in obj) {
        // Check if we're entering a "trackers" object
        const isTrackersKey = key === 'trackers';
        result[key] = this.rewriteUrlsForProxy(obj[key], proxyUrl, isInsideTrackers || isTrackersKey);
      }
      return result;
    }

    return obj;
  }

  public async mockAds(types: AdType[], options?: { validDuration?: number; persistCallback?: boolean }): Promise<{ cleanup?: () => void }> {
    // Helper to check if a type is included
    const includesType = (type: AdType) => types.includes(type);

    // Determine if callback should persist (default: false for backwards compatibility)
    const persistCallback = options?.persistCallback ?? false;

    // Build response by merging specific ad type files
    const adsResponse = { ads: { ad_units: {} } };

    // Load wrapper ads if requested
    if (includesType(AdType.Wrapper)) {
      const wrapperData = this.loadAdMockFile('ads_wrapper.json');
      Object.assign(adsResponse.ads.ad_units, wrapperData.ads.ad_units);
    }

    // Load spotlight OR carousel ads (mutually exclusive for hdc_row)
    if (includesType(AdType.Carousel)) {
      const carouselData = this.loadAdMockFile('ad_carousel.json');
      Object.assign(adsResponse.ads.ad_units, carouselData.ads.ad_units);

      // Override valid_duration if specified
      if (options?.validDuration !== undefined && adsResponse.ads.ad_units['hdc_row']) {
        adsResponse.ads.ad_units['hdc_row'].valid_duration = options.validDuration;
      }
    } else if (includesType(AdType.Spotlight)) {
      const spotlightData = this.loadAdMockFile('ads_spotlight.json');
      Object.assign(adsResponse.ads.ad_units, spotlightData.ads.ad_units);

      // Override valid_duration if specified
      if (options?.validDuration !== undefined && adsResponse.ads.ad_units['hdc_row']) {
        adsResponse.ads.ad_units['hdc_row'].valid_duration = options.validDuration;
      }
    }

    // Load thematic takeover ads if requested (can be combined with other ad types)
    if (includesType(AdType.ThematicTakeover)) {
      const thematicData = this.loadAdMockFile('ads_thematic_takeover.json');
      Object.assign(adsResponse.ads.ad_units, thematicData.ads.ad_units);
    }

    return new Promise((resolve) => {
      let callbackArgs: any = null;

      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/inapp');
        },
        processRequest: (args) => {
          // Store callback args so we can remove it later
          if (!callbackArgs) {
            callbackArgs = args;
          }

          // If we have a parsed body from express.json(), re-write it
          // because express.json() consumed the request stream
          if (args.requestBody && Object.keys(args.requestBody).length > 0) {
            const bodyData = JSON.stringify(args.requestBody);
            const bodyBuffer = Buffer.from(bodyData);

            args.proxyReq.setHeader('Content-Type', 'application/json');
            args.proxyReq.setHeader('Content-Length', bodyBuffer.length);

            return bodyBuffer;
          }
        },
        processResponse: (args) => {
          // Extract proxy IP and port from the request Host header
          // The Roku device sends requests to the proxy, so args.req.headers.host contains the proxy address
          const proxyHost = args.req.headers.host;
          const proxyUrl = `http://${proxyHost}`;

          // Rewrite all URLs in the response to route through proxy
          const rewrittenResponse = this.rewriteUrlsForProxy(adsResponse, proxyUrl);

          // Handle callback persistence based on options
          if (persistCallback) {
            // For tests that need multiple /inapp requests (e.g., returning to home screen)
            // Resolve with cleanup function on first request, but keep callback active
            if (!callbackArgs.resolved) {
              callbackArgs.resolved = true;
              resolve({
                cleanup: () => {
                  if (callbackArgs) {
                    callbackArgs.removeCallback();
                  }
                }
              });
            }
          } else {
            // Default behavior: resolve and remove callback after first request
            resolve({});
            args.removeCallback();
          }

          // Return the mocked response body as string (proxy handles headers)
          return JSON.stringify(rewrittenResponse);
        }
      });
    });
  }

  /**
   * HELPER: Create custom ad response for testing edge cases
   * 
   * USE WHEN:
   *   - Need to test specific ad configurations
   *   - Want to test error scenarios
   *   - Need custom ad unit data
   * 
   * @param customData - Custom ad response data
   * @returns Promise that resolves when ads are mocked
   * 
   * @example
   * // Mock empty ads response
   * await adTestHelpers.mockCustomAds({ ads: { ad_units: {} } });
   * 
   * @example
   * // Mock ads with custom tracking URLs
   * await adTestHelpers.mockCustomAds({
   *   ads: {
   *     ad_units: {
   *       wrapper_ad: { /* custom config *\/ }
   *     }
   *   }
   * });
   */
  public async mockCustomAds(customData: any): Promise<void> {
    return new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/inapp');
        },
        processRequest: (args) => {
          // If we have a parsed body from express.json(), re-write it
          if (args.requestBody && Object.keys(args.requestBody).length > 0) {
            const bodyData = JSON.stringify(args.requestBody);
            const bodyBuffer = Buffer.from(bodyData);

            args.proxyReq.setHeader('Content-Type', 'application/json');
            args.proxyReq.setHeader('Content-Length', bodyBuffer.length);

            return bodyBuffer;
          }
        },
        processResponse: (args) => {
          resolve(null);
          args.removeCallback();

          // Return the mocked response body as string (proxy handles headers)
          return JSON.stringify(customData);
        }
      });
    });
  }

  /**
   * HELPER: Mock no ads (empty response)
   * 
   * USE WHEN:
   *   - Testing ad-free experience
   *   - Testing graceful degradation when ads fail
   * 
   * @returns Promise that resolves when empty ads are mocked
   * 
   * @example
   * await adTestHelpers.mockNoAds();
   */
  public async mockNoAds(): Promise<void> {
    return this.mockCustomAds({
      ads: {
        ad_units: {}
      }
    });
  }
}

// Export singleton instance
export const adTestHelpers = new AdTestHelpers();

