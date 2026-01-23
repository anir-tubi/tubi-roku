/**
 * ═══════════════════════════════════════════════════════════════════
 * MOCK DATA HELPER FUNCTIONS
 * ═══════════════════════════════════════════════════════════════════
 *
 * PURPOSE: Centralized helpers for mocking content data in tests
 *
 * USAGE: Import mockDataHelpers in your test file:
 *   import { mockDataHelpers } from '../mock-data-helpers';
 *   await mockDataHelpers.mockSportsContent();
 *
 * FEATURES:
 *   - Dynamic timestamp generation for live content
 *   - Sports/live content mocking
 *   - Automatic proxy setup and cleanup
 *   - Uses existing mock JSON files
 *
 * ═══════════════════════════════════════════════════════════════════
 */

import { proxy } from 'roku-test-automation';
import * as fs from 'fs';
import * as path from 'path';

/**
 * MOCK DATA HELPERS CLASS
 * 
 * Provides utilities for mocking content data in the Roku app
 */
class MockDataHelpers {
  /**
   * PRIVATE: Load mock data from file
   * 
   * @param filename - Name of the mock file (e.g., 'sports-mock.json')
   * @returns Parsed mock data
   */
  private loadMockFile(filename: string): any {
    const filePath = path.join(__dirname, 'mocks', filename);
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(fileContent);
  }

  /**
   * PRIVATE: Add live timestamps to sports data
   * 
   * @param sportsData - Sports mock data to update
   * @returns Updated sports data with live timestamps
   */
  private addLiveTimestampsToSportsData(sportsData: any): any {
    const now = new Date();
    const startTime = new Date(now.getTime() - 60 * 60 * 1000); // 1 hour ago
    const endTime = new Date(now.getTime() + 60 * 60 * 1000);   // 1 hour from now

    // Update the schedule with dynamic times for Real Madrid channel (ID: 613762)
    if (sportsData['613762'] && sportsData['613762'].schedules) {
      sportsData['613762'].schedules[0].start_time = startTime.toISOString();
      sportsData['613762'].schedules[0].end_time = endTime.toISOString();
      sportsData['613762'].schedules[0].live = true;
    }

    return sportsData;
  }

  /**
   * PRIVATE: Mock sports content in a specific container
   * 
   * @param containerSlug - Container slug to inject sports content into
   * @param containerTitle - Container title for display
   * @returns Promise that resolves when sports content is mocked
   */
  private async mockSportsContentInContainer(containerSlug: string, containerTitle: string): Promise<void> {
    // Load the sports mock file and add live timestamps
    let sportsData = this.loadMockFile('sports-mock.json');
    sportsData = this.addLiveTimestampsToSportsData(sportsData);

    // Mock home screen endpoint to inject Real Madrid into specified container
    return new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/api/v7/homescreen');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Find the specified container
          const container = responseJson.containers?.find((c: any) => c.slug === containerSlug);

          if (container) {
            // Prepend Real Madrid to existing container
            if (!container.children) {
              container.children = [];
            }
            if (!container.children.includes('613762')) {
              container.children.unshift('613762');
            }
          } else {
            // Create the container if it doesn't exist
            if (!responseJson.containers) {
              responseJson.containers = [];
            }
            responseJson.containers.push({
              id: containerSlug,
              slug: containerSlug,
              title: containerTitle,
              children: ['613762']
            });
          }

          // Add sports content data to contents map
          if (!responseJson.contents) {
            responseJson.contents = {};
          }
          Object.assign(responseJson.contents, sportsData);

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });
  }

  /**
   * HELPER: Mock sports/live content with dynamic timestamps in On Now row
   * 
   * USE WHEN:
   *   - Testing sports programme display
   *   - Testing live content in On Now row
   *   - Need live event to always appear as "currently airing"
   * 
   * PROVIDES:
   *   - Real Madrid channel with live program
   *   - Dynamic start/end times (always shows as live)
   *   - Automatic proxy callback setup
   *   - Mocks home screen to inject Real Madrid into recommended_linear_channels row
   * 
   * @returns Promise that resolves when sports content is mocked
   * 
   * @example
   * // Mock sports content with Real Madrid channel
   * proxy.resume();
   * const proxyPromise = mockDataHelpers.mockSportsContent();
   * await testUtils.startApplicationAtPage('home');
   * await utils.promiseTimeout(proxyPromise, 50000);
   * 
   * @example
   * // Use in a test
   * it('should display live sports event', async () => {
   *   proxy.resume();
   *   await mockDataHelpers.mockSportsContent();
   *   await testUtils.startApplicationAtPage('home');
   *   // Real Madrid channel will appear as live in On Now row
   * });
   */
  public async mockSportsContent(): Promise<void> {
    return this.mockSportsContentInContainer('recommended_linear_channels', 'On Now');
  }

  /**
   * HELPER: Mock sports content in Featured row
   * 
   * USE WHEN:
   *   - Testing sports programme display in Featured row
   *   - Testing live content in Featured row
   *   - Need live event to always appear as "currently airing" in Featured
   * 
   * PROVIDES:
   *   - Real Madrid channel with live program
   *   - Dynamic start/end times (always shows as live)
   *   - Automatic proxy callback setup
   *   - Mocks home screen to inject Real Madrid into featured row
   * 
   * @returns Promise that resolves when sports content is mocked
   * 
   * @example
   * // Mock sports content in Featured row
   * proxy.resume();
   * const proxyPromise = mockDataHelpers.mockSportsContentInFeatured();
   * await testUtils.startApplicationAtPage('home');
   * await utils.promiseTimeout(proxyPromise, 50000);
   */
  public async mockSportsContentInFeatured(): Promise<void> {
    return this.mockSportsContentInContainer('featured', 'Featured');
  }

  /**
   * HELPER: Get sports mock data with dynamic timestamps (without proxy)
   * 
   * USE WHEN:
   *   - Need sports data for custom proxy setup
   *   - Want to modify sports data before mocking
   * 
   * @returns Sports mock data with updated timestamps
   * 
   * @example
   * const sportsData = mockDataHelpers.getSportsDataWithLiveTimestamps();
   * // Modify sportsData as needed
   * // Then use with custom proxy callback
   */
  public getSportsDataWithLiveTimestamps(): any {
    let sportsData = this.loadMockFile('sports-mock.json');
    return this.addLiveTimestampsToSportsData(sportsData);
  }
}

// Export singleton instance
export const mockDataHelpers = new MockDataHelpers();
