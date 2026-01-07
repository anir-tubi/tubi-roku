/**
 * ═══════════════════════════════════════════════════════════════════
 * TEST HELPER FUNCTIONS
 * ═══════════════════════════════════════════════════════════════════
 *
 * PURPOSE: Centralized, documented helper functions for Roku automated tests
 *
 * USAGE: Import testHelpers in your test file:
 *   import { testHelpers } from '../test-helpers';
 *   await testHelpers.createHistory();
 *
 * FOR AI: When generating tests, use these helpers instead of inventing new ones
 *
 * CATEGORIES:
 *   - Detail Screen Helpers
 *   - History & Playback Helpers
 *   - Navigation Helpers
 *   - Parental Controls Helpers
 *   - User Management Helpers
 *
 * ⚠️ CRITICAL LIMITATION: Accessing Nested Node Properties
 * ═══════════════════════════════════════════════════════════════════
 * CANNOT access nested nodes using findNode() OR property chaining!
 * Both are only available in Roku app runtime, NOT in test automation.
 *
 * ❌ WRONG - Using findNode():
 *   const button = await testUtils.getNodeForElement('vodDetailScreenMenu');
 *   const labelGroup = button.findNode('labelGroup'); // ERROR: Not available!
 *
 * ❌ WRONG - Using property chaining:
 *   const menu = await testUtils.getNodeForElement('vodDetailScreenMenu');
 *   const firstButton = menu.buttons[0];
 *   const labelGroup = firstButton.elementsGroup?.titleGroup?.labelGroup; // ERROR: Returns undefined!
 *
 * ❌ WRONG - Looping through buttons with nested access:
 *   const buttons = menu.buttons;
 *   for (let i = 0; i < buttons.length; i++) {
 *     const labelGroup = buttons[i].elementsGroup?.titleGroup?.labelGroup; // ERROR: Nested traversal not supported!
 *   }
 *
 * ✅ CORRECT - Define EACH nested element in elements.ts:
 *   1. In automated-tests-config/elements.ts, add entry for each nested node:
 *      likeButtonLabelGroup: {
 *        keyPath: '#ContentController...#actionButtonList.#like.#elementsGroup.#titleGroup.#labelGroup',
 *        xpath: '//EnhancedButton[@name="like"]//RenderableNode[@name="labelGroup"]'
 *      }
 *   2. Access in test using getNodeForElement:
 *      const labelGroup = await testUtils.getNodeForElement('likeButtonLabelGroup');
 *      const isVisible = labelGroup.visible && labelGroup.opacity > 0;
 *
 * WHY: Returned node objects don't have child nodes populated - only direct properties.
 *      You must define the full xpath to each nested element you need to access.
 *
 * ═══════════════════════════════════════════════════════════════════
 */

import { expect } from 'chai';
import { ecp, odc, utils, proxy } from 'roku-test-automation';
import { testUtils, auth } from './test-utils';
import { moveToGrid } from './analytics/utils/helpers';
import type { ElementOrElementId } from '../../automated-tests-config/elements';


class TestHelpers {
  /* ═══════════════════════════════════════════════════════════════════
   * GRID & CONTENT SEARCH HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Converts linear position to [row, column] coordinates
   * 
   * @param position - Linear position in grid (0-based)
   * @param columns - Number of columns per row (default: 5)
   * @returns [row, column] tuple
   * 
   * @example
   * const [row, col] = testHelpers.positionToRowCol(12, 5); // Returns [2, 2] (3rd row, 3rd column)
   */
  public positionToRowCol(position: number, columns = 5): [number, number] {
    const row = Math.floor(position / columns);
    const col = position % columns;
    return [row, col];
  }

  /**
   * HELPER: Finds content position in grid by title
   * 
   * @param title - Content title to search for
   * @param gridId - Grid element ID
   * @returns [row, column] array or empty array if not found
   */
  public async findContentPositionInGridByTitle({ title, gridId }: { title: string; gridId: any }) {
    let position = -1;
    const content = await testUtils.getAllGridItemsContent(gridId);

    for (const [index, item] of content.entries()) {
      if (item.title === title) {
        position = index;
        break;
      }
    }

    return position > -1 ? this.positionToRowCol(position) : [];
  }

  /**
   * HELPER: Finds content with or without video preview in grid
   * 
   * @param gridId - Grid element ID
   * @param hasVideoPreview - true to find WITH preview, false to find WITHOUT
   * @param columnsPerRow - Number of columns (default: 5)
   * @returns [row, column] array or empty array if not found
   */
  public async findContentPositionInGridThatContainsVideoPreview(gridId: any, hasVideoPreview = true, columnsPerRow = 5) {
    let position = -1;
    const content = await testUtils.getAllGridItemsContent(gridId);

    for (const [index, item] of content.entries()) {
      if (hasVideoPreview && item.videoPreviewUrl?.trim().length > 0) {
        position = index;
        break;
      } else if (!hasVideoPreview && (!item.videoPreviewUrl || item.videoPreviewUrl?.trim().length === 0)) {
        position = index;
        break;
      }
    }

    return position > -1 ? this.positionToRowCol(position, columnsPerRow) : [];
  }

  /**
   * HELPER: Navigates to content in search results by title
   * 
   * @param title - Content title to navigate to
   */
  public async navigateToContentInSearchResults({ title }: { title: string }) {
    await this.navigateRightToSearchGrid();
    const position = await this.findContentPositionInGridByTitle({ title, gridId: 'searchResultGrid' });
    if (position.length > 0) {
      await moveToGrid({ grid: { row: 0, col: 0 }, destRow: position[0], destCol: position[1] });
    }
  }


  /* ═══════════════════════════════════════════════════════════════════
   * HISTORY & PLAYBACK HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Creates playback history for currently playing content
   * 
   * ⚠️ CRITICAL: Use this when test mentions "movie has history" or "Remove from History"
   * 
   * USE WHEN:
   *   - Test mentions "movie has history", "title with history", "movie with history"
   *   - Testing "Resume Playing" functionality
   *   - Testing "Remove from History" functionality
   *   - Testing "Play from Beginning" (when history exists)
   * 
   * IMPORTANT:
   *   - Must call AFTER starting playback with ecp.sendKeypress(ecp.Key.Play)
   *   - Creates 2+ minutes of watch time (required for history to register)
   *   - Wait for 'playing' state before and after seeking
   * 
   * TYPICAL PATTERN:
   * 1. Navigate to detail screen
   * 2. Start playback: await ecp.sendKeypress(ecp.Key.Play);
   * 3. Create history: await testHelpers.createHistory();
   * 4. Return to detail: await ecp.sendKeypress(ecp.Key.Back);
   * 5. Now "Resume Playing" and "Remove from History" buttons will be available
   * 
   * @param seekTimeMs - Optional: Time to seek to in milliseconds (default: 120000 = 2 minutes)
   * @param useAbsolutePosition - Optional: If true, seeks to absolute position instead of relative (default: false)
   * 
   * @example
   * // Standard history creation pattern for detail screen tests
   * await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
   * await testUtils.waitForElementToHaveFocus('movieScreenRowList');
   * await ecp.sendKeypress(ecp.Key.Ok); // Open detail screen
   * 
   * // CREATE HISTORY
   * await ecp.sendKeypress(ecp.Key.Play); // Start playback
   * await testHelpers.createHistory(); // Seek to create 2min watch time
   * 
   * // Return to detail screen
   * await ecp.sendKeypress(ecp.Key.Back);
   * await testUtils.waitForCurrentScreenToEqual('detailScreen');
   * 
   * // Now can test history features
   * await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
   * 
   * @see Tests using this pattern: C535809, C535810, C535812, C535813, C535870
   */
  public async createHistory(seekTimeMs = 120000, useAbsolutePosition = false) {
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    if (useAbsolutePosition) {
      await testUtils.seekPlayerToAbsolutePosition('videoPlayerScreen', seekTimeMs);
    } else {
      await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', seekTimeMs, 'current');
    }
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    await utils.sleep(500);
  }

  /**
   * HELPER: Creates playback history using Forward key presses (alternative method)
   * 
   * USE WHEN:
   *   - Need to create history using fast-forward instead of seek
   *   - Testing scenarios that involve forward button presses
   * 
   * NOTE: This is an alternative to createHistory() that uses Forward key instead of seek
   */
  public async createHistoryWithForward() {
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    await ecp.sendKeypress(ecp.Key.Forward, { count: 3 });
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Play);
  }

  /**
   * HELPER: Verifies "Play from Beginning" starts playback at position 0
   * 
   * USE WHEN:
   *   - Testing "Play from Beginning" button functionality
   *   - Verifying playback starts at beginning (not resume position)
   * 
   * VERIFIES:
   *   - Playback state is 'playing'
   *   - Player position is within first second (0-1000ms)
   * 
   * PREREQUISITES:
   *   - Must be on detail screen
   *   - "Play from Beginning" button must be visible (requires history)
   * 
   * @param maxPositionMs - Maximum allowed position in ms (default: 1000ms)
   * 
   * @example
   * // After creating history and returning to detail screen
   * await testHelpers.verifyPlayFromBeginning();
   * // Test will fail if position > 1 second
   */
  public async verifyPlayFromBeginning(maxPositionMs = 1000) {
    await testUtils.selectAndVerifyDetailPageMenuItem('play');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    const position = await testUtils.getPlayerPosition('videoPlayerScreen');
    expect(position).to.be.greaterThanOrEqual(0);
    expect(position).to.be.lessThan(maxPositionMs);
  }

  /**
   * HELPER: Verifies "Resume Playing" resumes at correct position
   * 
   * USE WHEN:
   *   - Testing "Resume Playing" button functionality
   *   - Verifying playback resumes at saved history position
   * 
   * VERIFIES:
   *   - Resume position is within acceptable range of expected position
   * 
   * @param expectedPositionMs - Expected resume position in ms (default: 120000 = 2 min)
   * @param toleranceMs - Allowed variance in ms (default: 5000 = 5 seconds)
   * 
   * @example
   * // After creating history with default 2-minute seek
   * await ecp.sendKeypress(ecp.Key.Back); // Return to detail
   * await testHelpers.verifyResumeWithinRange();
   * // Test passes if resume position is 115-125 seconds (120±5)
   */
  public async verifyResumeWithinRange(expectedPositionMs = 120000, toleranceMs = 5000) {
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(2000);
    await this.createHistory();
    const currentPosition = await testUtils.getPlayerPosition('videoPlayerScreen');
    await utils.sleep(2000);
    await ecp.sendKeypress(ecp.Key.Back);

    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    await testUtils.selectAndVerifyDetailPageMenuItem('resume');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);

    const resumePosition = await testUtils.getPlayerPosition();
    const difference = resumePosition - currentPosition;

    expect(difference).greaterThanOrEqual(-toleranceMs);
    expect(difference).lessThanOrEqual(toleranceMs);
  }

  /**
   * HELPER: Seeks within acceptable range for fast-forward/rewind tests
   * 
   * USE WHEN:
   *   - Testing fast-forward 30s functionality
   *   - Testing rewind 30s functionality
   * 
   * @param startPosition - Starting position before seek
   * @param expectedDelta - Expected change in position (30000 for 30s forward, -30000 for rewind)
   * @param tolerance - Allowed variance in ms (default: 5000)
   */
  public async verifySeekWithinRange(startPosition: number, expectedDelta = 30000, tolerance = 5000) {
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(2000);

    const endPosition = await testUtils.getPlayerPosition();
    const actualDelta = endPosition - startPosition;
    const difference = Math.abs(actualDelta - expectedDelta);

    expect(difference).to.be.lessThan(tolerance);
  }

  /* ═══════════════════════════════════════════════════════════════════
   * NAVIGATION HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Opens left navigation menu (SideNav)
   * 
   * USE WHEN:
   *   - Need to access Settings, Categories, My List, etc.
   *   - Navigating to different sections of the app
   * 
   * @example
   * await testHelpers.openLeftNav();
   * // Now can navigate to side nav items
   */
  public async openLeftNav() {
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('sideNavMenu');
  }

  /**
   * HELPER: Navigates right from side nav to main content grid (simple version)
   * 
   * USE WHEN:
   *   - After opening side nav, need to get back to content
   *   - Testing grid/list navigation
   */
  public async navigateRightToGrid() {
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);
  }

  /**
   * HELPER: Navigates right until search grid has focus (search screen specific)
   * 
   * USE WHEN:
   *   - On search screen, need to navigate from keyboard to result grid
   *   - Testing search result navigation
   * 
   * IMPORTANT: This is specific to the Search screen
   */
  public async navigateRightToSearchGrid() {
    // Wait for ResultGrid to show first (prevents edge case bugs)
    await testUtils.waitForElementToShowOnScreen('searchResultGrid');
    await testUtils.untilTrue(async () => {
      await ecp.sendKeypress(ecp.Key.Right);
      const { value: id } = await odc.getValue({
        base: 'focusedNode',
        keyPath: 'id'
      });
      return id === 'ResultGrid';
    }, 'ResultGrid never obtained focus');
  }

  /**
   * HELPER: Opens Categories page from side navigation
   * 
   * USE WHEN:
   *   - Testing Categories page functionality
   *   - Need to navigate to Categories from any screen
   *   - Testing category-related features (My List, Continue Watching, Networks, etc.)
   * 
   * HOW IT WORKS:
   *   1. Jumps to "Categories" item in side nav menu
   *   2. Waits for selected state visual confirmation
   *   3. Presses OK to open Categories page
   *   4. Waits for Categories page to load (channelRecommendedButton shown)
   * 
   * COMMON USE CASES:
   *   - Access category filters and browsing
   *   - Test Continue Watching, My List, Networks sections
   *   - Verify category page layout and functionality
   * 
   * PRE-CONDITION: Side nav menu should be open (call openLeftNav() first if needed)
   * 
   * @param timeout - Optional timeout for page load (default: 15000ms)
   * 
   * @example
   * // From home screen
   * await testHelpers.openLeftNav();
   * await testHelpers.selectCategoriesFromSideNav();
   * // Now on Categories page
   * 
   * @example
   * // With custom timeout
   * await testHelpers.openLeftNav();
   * await testHelpers.selectCategoriesFromSideNav(20000);
   */
  public async selectCategoriesFromSideNav(timeout = 15000): Promise<void> {
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButtonSelected');
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });

    // Verify we're on Categories page
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton', 'Category page not shown', timeout);
  }

  /**
   * HELPER: Opens left nav and navigates to Categories page
   * 
   * USE WHEN:
   *   - Need to go directly to Categories from any screen with one call
   *   - Starting a test that requires Categories page
   * 
   * BENEFITS: Combines openLeftNav() and selectCategoriesFromSideNav() into one convenient method
   * 
   * @param timeout - Optional timeout for page load (default: 15000ms)
   * 
   * @example
   * // Quick navigation to Categories
   * await testHelpers.openLeftNav();
   * await testHelpers.selectCategoriesFromSideNav();
   * // Now on Categories page ready for testing
   */
  public async navigateToCategories(timeout = 15000): Promise<void> {
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu');
    await this.selectCategoriesFromSideNav(timeout);
  }

  /**
   * HELPER: Starts app at home screen and waits for home list focus
   * 
   * PATTERN: Used 245+ times - consolidates common startup pattern
   * 
   * @param shouldCreateNewUser - Whether to create new user (default: true)
   * @param user - Optional specific user to start with
   * 
   * @example
   * await testHelpers.startAtHomeScreen(); // New user
   * await testHelpers.startAtHomeScreen(false); // Guest user
   * 
   * const user = await testUtils.createRegisteredUser();
   * await testHelpers.startAtHomeScreen(true, user); // Specific user
   */
  public async startAtHomeScreen(shouldCreateNewUser = true, user?: any) {
    const options = user ? { user } : { shouldCreateNewUser };
    await testUtils.startApplicationAtPage('home', options);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
  }

  /**
   * HELPER: Generic page navigation with optional focus wait
   * 
   * @param page - Page to navigate to ('movies', 'series', 'settings', 'myStuff', etc.)
   * @param waitForElement - Optional element to wait for focus after navigation
   * @param errorMessage - Custom error message for wait timeout
   * 
   * @example
   * await testHelpers.navigateToPage('movies', 'movieScreenRowList');
   * await testHelpers.navigateToPage('settings'); // No wait
   */
  public async navigateToPage(page: any, waitForElement?: any, errorMessage?: string) {
    await testUtils.goToPage(page);
    if (waitForElement) {
      await testUtils.waitForElementToHaveFocus(waitForElement, errorMessage || `Timed out waiting for ${waitForElement}`);
    }
  }

  /**
   * HELPER: Opens a page and waits for element to be visible
   * 
   * @param page - Page to open
   * @param element - Element to wait for
   * @param timeout - Optional timeout in ms (default: 15000)
   */
  public async openPageAndWaitForElement(page: any, element: any, timeout = 15000) {
    await testUtils.goToPage(page);
    await testUtils.waitForElementToFullyShowOnScreen(element, `${element} not shown on ${page}`, timeout);
  }

  /**
   * BACKWARD COMPATIBILITY: Specific page navigation helpers
   * These are maintained for existing tests
   */
  public async openSettings() {
    await this.navigateToPage('settings');
  }

  public async openMovies() {
    await this.navigateToPage('movies');
  }

  public async openSeries() {
    await this.navigateToPage('series');
  }

  public async openMyStuff() {
    await this.navigateToPage('myStuff');
  }

  /**
   * BACKWARD COMPATIBILITY: Opens Series screen and waits until list is focused
   * 
   * @param shouldCreateNewUser - Whether to create new user (default: true)
   */
  public async openSeriesScreenAndWaitUntilListIsFocused(shouldCreateNewUser = true) {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await this.openSeries();
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
  }

  /**
   * BACKWARD COMPATIBILITY: Opens Movies screen and waits until list is focused
   * 
   * @param shouldCreateNewUser - Whether to create new user (default: true)
   */
  public async openMoviesScreenAndWaitUntilListIsFocused(shouldCreateNewUser = true) {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await this.openMovies();
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
  }

  /**
   * Navigates to a movie on home screen
   * 
   * USE WHEN:
   *   - Need to navigate to movie detail page
   *   - Testing movie-specific features
   *   - Need to find a movie (not a series) on home screen
   * 
   * PREREQUISITES:
   *   - Must already be on home screen with rowListElementId focused
   * 
   * @param rowListElementId - Element ID of the RowList to search in (default: 'videoTitlesRowList')
   * @example
   * // Navigate to movie on home screen
   * await testHelpers.navigateToMovieInContainer('tvScreenRowList');
   * // Now you're focused on a movie
   * await ecp.sendKeypress(ecp.Key.Ok); // Open detail screen
   */
  public async navigateToMovieInContainer(rowListElementId: ElementOrElementId = 'videoTitlesRowList') {
    const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent(rowListElementId);
    let colIndex = -1;
    for (const [index, item] of content.entries()) {
      if (item.type === 'v') {
        colIndex = index;
        break;
      }
    }
    if (colIndex === -1) {
      throw new Error(`No movie found in current row of ${rowListElementId}`);
    }
    await ecp.sendKeypress(ecp.Key.Right, { count: colIndex });
  }

  /**
   * HELPER: Finds and navigates to content of a specific type
   * 
   * USE WHEN:
   *   - Need to find and focus on a specific content type
   *   - Testing content-type-specific features
   *   - Want flexible navigation that searches current or multiple rows
   * 
   * @param contentType - Content type to find ('v' = movie, 's' = series, 'l' = live, etc.)
   * @param rowListElementId - Element ID of the row list (defaults to 'videoTitlesRowList')
   * @param maxRowsToCheck - Maximum number of rows to check (defaults to 20, set to 1 for current row only)
   * 
   * @throws Error if no content of specified type found
   * 
   * @example
   * // Find a series across multiple rows (default behavior)
   * await testHelpers.findAndNavigateToContentType('s', 'homeScreenRowList');
   * 
   * @example
   * // Find a movie in current row only
   * await testHelpers.findAndNavigateToContentType('v', 'movieScreenRowList', 1);
   * 
   * @example
   * // Find live content with custom max rows
   * await testHelpers.findAndNavigateToContentType('l', 'videoTitlesRowList', 10);
   */
  public async findAndNavigateToContentType(contentType: string, rowListElementId: ElementOrElementId = 'videoTitlesRowList', maxRowsToCheck: number = 20): Promise<void> {
    let foundContent = false;

    for (let rowAttempt = 0; rowAttempt < maxRowsToCheck; rowAttempt++) {
      await utils.sleep(300);

      try {
        // Get content from current row
        const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent(rowListElementId);
        let colIndex = -1;

        // Find content of specified type
        for (const [index, item] of content.entries()) {
          if (item.type === contentType) {
            colIndex = index;
            break;
          }
        }

        if (colIndex !== -1) {
          // Found content, navigate to it
          await ecp.sendKeypress(ecp.Key.Right, { count: colIndex });
          foundContent = true;
          break;
        }

        // No content of this type in current row, move to next row if we have more rows to check
        if (rowAttempt < maxRowsToCheck - 1) {
          await ecp.sendKeypress(ecp.Key.Down);
        }
      } catch (e) {
        // Error getting content, move to next row if we have more rows to check
        if (rowAttempt < maxRowsToCheck - 1) {
          await ecp.sendKeypress(ecp.Key.Down);
        }
      }
    }

    if (!foundContent) {
      const contentTypeName = contentType === 'v' ? 'movie' : contentType === 's' ? 'series' : contentType === 'l' ? 'live content' : `content type '${contentType}'`;
      const rowText = maxRowsToCheck === 1 ? 'current row' : `${maxRowsToCheck} rows`;
      throw new Error(`Could not find ${contentTypeName} in ${rowListElementId} after checking ${rowText}`);
    }
  }

  /**
   * HELPER: Selects Sign In from home screen
   */
  public async selectSignInFromHomeScreen() {
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up, { count: 3 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  /**
   * HELPER: Navigates to side nav menu item and selects it
   * 
   * @param menuItemTitle - Title of the menu item ('Categories', 'My Stuff', 'Settings', etc.)
   * @param confirmElement - Optional element to confirm navigation was successful
   * 
   * @example
   * await testHelpers.selectSideNavMenuItem('Categories', 'channelRecommendedButton');
   * await testHelpers.selectSideNavMenuItem('Settings');
   */
  public async selectSideNavMenuItem(menuItemTitle: string, confirmElement?: any) {
    await this.openLeftNav();
    await testUtils.jumpToRowWithTitle('sideNavMenu', menuItemTitle);
    await utils.sleep(1000);
    await ecp.sendKeypress(ecp.Key.Ok);

    if (confirmElement) {
      await testUtils.waitForElementToFullyShowOnScreen(confirmElement, `${confirmElement} not shown after selecting ${menuItemTitle}`, 15000);
    }
  }

  /**
   * HELPER: Opens Categories page from side nav
   * 
   * PATTERN: Used 29+ times across multiple test files
   * 
   * @example
   * await testHelpers.openCategoriesPage();
   * // Now on Categories page with 'channelRecommendedButton' visible
   */
  public async openCategoriesPage() {
    await this.openLeftNav();
    await testUtils.jumpToRowWithTitle('sideNavMenu', 'Categories');
    await utils.sleep(1000);
    await testUtils.waitForElementToFullyShowOnScreen('categoriesLeftNavButtonSelected');
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 2000 });
    await testUtils.waitForElementToFullyShowOnScreen('channelRecommendedButton', 'Category page not shown', 15000);
  }

  /**
   * HELPER: Opens My Stuff page
   * 
   * @example
   * await testHelpers.openMyStuffPage();
   */
  public async openMyStuffPage() {
    await testUtils.goToPage('myStuff');
  }

  /**
   * HELPER: Jumps to Continue Watching row on home screen
   * 
   * PATTERN: Used 12+ times across multiple files
   * 
   * @param listElement - List element ID (default: 'videoTitlesRowList')
   * 
   * @example
   * await testHelpers.jumpToContinueWatchingRow();
   * await testHelpers.jumpToContinueWatchingRow('customListElement');
   */
  public async jumpToContinueWatchingRow(listElement: any = 'videoTitlesRowList') {
    await this.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: listElement });
    await testUtils.waitForElementToFullyShowOnScreen('continueWatchingRowHome');
  }

  /* ═══════════════════════════════════════════════════════════════════
   * PARENTAL CONTROLS HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Generic parental control level selection
   * 
   * @param level - 'littleKids' | 'olderKids' | 'teens' | 'adults'
   * 
   * @example
   * await testHelpers.selectParentalControlLevel('littleKids');
   * await testHelpers.selectParentalControlLevel('teens');
   */
  public async selectParentalControlLevel(level: 'littleKids' | 'olderKids' | 'teens' | 'adults') {
    await testUtils.waitForElementToFullyShowOnScreen('parentalControlsSettingsGroup');
    await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });

    const levelMap = {
      littleKids: 3,
      olderKids: 2,
      teens: 1,
      adults: 0
    };

    const upCount = levelMap[level];
    if (upCount > 0) {
      await ecp.sendKeypress(ecp.Key.Up, { count: upCount, wait: 200 });
    }

    if (level === 'teens') {
      await utils.sleep(2000);
    }

    await ecp.sendKeypress(ecp.Key.Ok);
  }

  /**
   * HELPER: Sets parental controls and verifies confirmation
   * 
   * @param level - Parental control level
   * @param password - Password to use (default: '111111')
   * @param shouldDismiss - Whether to dismiss confirmation dialog (default: true)
   * 
   * @example
   * await testHelpers.setParentalControls('littleKids');
   * await testHelpers.setParentalControls('teens', '123456', false);
   */
  public async setParentalControls(level: 'littleKids' | 'olderKids' | 'teens' | 'adults', password = '111111', shouldDismiss = true) {
    await this.selectParentalControlLevel(level);
    await this.enterPassword(password);

    // Verify confirmation dialog
    const confirmationElements: Record<string, any> = {
      littleKids: 'parentalControlsSettingsLittleKids',
      olderKids: 'parentalControlsSettingsOlderKids',
      teens: 'parentalControlsSettingsTeens',
      adults: 'parentalControlsSettingsAdults'
    };

    const element: any = confirmationElements[level];
    if (element) {
      await testUtils.waitForElementToShowOnScreen(element);
      const dialog = await testUtils.getNodeForElement(element);
      const levelNames = { littleKids: 'Little Kids', olderKids: 'Older Kids', teens: 'Teens', adults: 'Adults' };
      expect(dialog.text).to.contain(levelNames[level]);

      if (shouldDismiss) {
        await ecp.sendKeypress(ecp.Key.Ok); // Dismiss dialog
        await ecp.sendKeypress(ecp.Key.Ok); // Exit settings
      }
    }
  }

  /**
   * HELPER: Generic password entry helper
   * 
   * @param password - Password to enter (default: '111111')
   * @param handleKeyboard - Whether to handle keyboard navigation (default: true)
   */
  public async enterPassword(password = '111111', handleKeyboard = true) {
    await ecp.sendKeypress(ecp.Key.Ok);
    await ecp.sendText(password);

    if (handleKeyboard) {
      await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 200 });
      const keyboardBackButton = await testUtils.getNodeForElement('keyboardBackButton');
      if (keyboardBackButton.opacity == 1) {
        await ecp.sendKeypress(ecp.Key.Right);
      }
    }

    await ecp.sendKeypress(ecp.Key.Ok);
  }

  /**
   * BACKWARD COMPATIBILITY: Keep old method names
   */
  public async selectLittleKidsFromParentalSettings() { await this.selectParentalControlLevel('littleKids'); }
  public async selectOlderKidsFromParentalSettings() { await this.selectParentalControlLevel('olderKids'); }
  public async selectTeensFromParentalSettings() { await this.selectParentalControlLevel('teens'); }
  public async selectAdultsFromParentalSettings() { await this.selectParentalControlLevel('adults'); }
  public async enterPasswordSettingsChange() { await this.enterPassword(); }

  /* ═══════════════════════════════════════════════════════════════════
   * USER MANAGEMENT HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Creates viewing history for a user (using API)
   * 
   * USE WHEN:
   *   - Setting up test data for "Continue Watching" tests
   *   - Populating My Stuff with history
   * 
   * CREATES:
   *   - Mix of G-rated movies (10 titles)
   *   - Mix of TV-Y7 series (3 titles)
   *   - Mix of TV-MA series (3 titles)
   *   - Mix of R-rated movies (2 titles)
   * 
   * @param user - User API instance from shared.ts
   * 
   * @example
   * await testHelpers.createUserHistory(user);
   * // Now user has mixed viewing history
   */
  public async createUserHistory(user: any) {
    const contentG = await user.getContent().withRating('G').ofContentType('movie').retrieve({ limit: 10 });
    await user.addContentToViewHistory(contentG, 600);

    const contentTVY7 = await user.getContent().withRating('TV-Y7').ofContentType('series').retrieve({ limit: 3 });
    await user.addContentToViewHistory(contentTVY7, 600);

    const contentTVMA = await user.getContent().withRating('TV-MA').ofContentType('series').retrieve({ limit: 3 });
    await user.addContentToViewHistory(contentTVMA, 600);

    const contentR = await user.getContent().withRating('R').ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(contentR, 600);
  }

  /**
   * HELPER: Creates watch list for a user (using API)
   * 
   * USE WHEN:
   *   - Setting up test data for "My List" tests
   *   - Testing watch list functionality
   * 
   * CREATES:
   *   - Mix of TV-G series (6 titles)
   *   - Mix of G-rated movies (6 titles)
   * 
   * @param user - User API instance from shared.ts
   */
  public async createUserWatchList(user: any) {
    const contentTVG = await user.getContent().ofContentType('series').withRating('TV-G').retrieve({ limit: 6 });
    await user.addContentToWatchList(contentTVG);

    const contentG = await user.getContent().ofContentType('movie').withRating('G').retrieve({ limit: 6 });
    await user.addContentToWatchList(contentG);
  }

  /**
   * HELPER: Adds specific evergreen movie to user's history
   * 
   * USE WHEN:
   *   - Need consistent test data (evergreen content doesn't expire)
   *   - Testing specific movie behavior
   * 
   * @param user - User API instance
   * @param contentId - Content ID (default: 342067 - reliable evergreen movie)
   * @param watchTimeSeconds - Watch time in seconds (default: 500)
   */
  public async createHistoryForEvergreenMovie(user: any, contentId = 342067, watchTimeSeconds = 500) {
    const content = await user.getContentById(contentId);
    await user.addContentToViewHistory(content, watchTimeSeconds);
  }

  /**
   * HELPER: Adds specific evergreen series to user's history
   * 
   * @param user - User API instance
   * @param contentId - Series ID (default: 300005163 - reliable evergreen series)
   * @param watchTimeSeconds - Watch time in seconds (default: 500)
   */
  public async createHistoryForEvergreenSeries(user: any, contentId = 300005163, watchTimeSeconds = 500) {
    const content = await user.getContentById(contentId);
    await user.addContentToViewHistory(content, watchTimeSeconds);
  }

  /* ═══════════════════════════════════════════════════════════════════
   * SETTINGS HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Generic settings toggle helper
   * 
   * @param menuElement - Settings menu element to focus
   * @param rowIndex - Row index to select (0 for On, 1 for Off)
   * @param skipElement - Optional element to skip (e.g., 'AutoplayPreviewMenu')
   * 
   * @example
   * await testHelpers.toggleSetting('autoplayNextVideoMenu', 0); // Turn ON
   * await testHelpers.toggleSetting('autoplayPreviewMenu', 1); // Turn OFF
   */
  public async toggleSetting(menuElement: any, rowIndex: number, skipElement?: string) {
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.goToPage('settings');

    await ecp.sendKeypress(ecp.Key.Down);
    await ecp.sendKeypress(ecp.Key.Ok);

    if (skipElement) {
      await ecp.sendKeypress(ecp.Key.Down);
      const { node } = await odc.getFocusedNode();
      if (node.id === skipElement) {
        await ecp.sendKeypress(ecp.Key.Down);
      }
    }

    await testUtils.waitForElementToHaveFocus(menuElement, `Timed out waiting for ${menuElement}`, 15000);
    await testUtils.jumpToRowIndex(menuElement, rowIndex);
    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
  }

  /**
   * HELPER: Navigates to settings and enables/disables autoplay (uses generic toggleSetting)
   */
  public async enableAutoplayInSettings(enabled: boolean) {
    await this.toggleSetting('autoplayNextVideoMenu', enabled ? 0 : 1, 'AutoplayPreviewMenu');
  }

  /**
   * HELPER: Navigates to settings and enables/disables video preview (uses generic toggleSetting)
   */
  public async enablePreviewInSettings(enabled: boolean) {
    await this.toggleSetting('autoplayPreviewMenu', enabled ? 0 : 1);
  }


  /* ═══════════════════════════════════════════════════════════════════
   * KIDS MODE HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Opens Kids Mode from side nav
   * 
   * USE WHEN:
   *   - Testing Kids Mode functionality
   *   - Setting up kids-safe testing environment
   * 
   * VERIFIES:
   *   - Exit Kids option becomes visible after entering Kids Mode
   */
  public async openKidsMode() {
    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(3000);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Ok);
    const exitKidsOption = await testUtils.getNodeForElement('exitKidsOption');
    expect(exitKidsOption.visible).to.be.true;
  }

  /**
   * HELPER: Exits Kids Mode
   * 
   * NOTE: Implementation TBD - would navigate to Exit Kids option in side nav
   */
  public async exitKidsMode() {
    // Implementation would go here
    // Navigate to Exit Kids option and select
  }

  /* ═══════════════════════════════════════════════════════════════════
   * GENERIC INTERACTION HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Navigate in a direction and wait for element
   * 
   * @param direction - 'Up', 'Down', 'Left', 'Right'
   * @param count - Number of times to press (default: 1)
   * @param waitForElement - Optional element to wait for after navigation
   * @param waitTime - Wait time between presses in ms (default: 200)
   */
  public async navigate(direction: 'Up' | 'Down' | 'Left' | 'Right', count = 1, waitForElement?: any, waitTime = 200) {
    await ecp.sendKeypress(ecp.Key[direction], { count, wait: waitTime });

    if (waitForElement) {
      await testUtils.waitForElementToFullyShowOnScreen(waitForElement);
    }
  }

  /**
   * HELPER: Press key and wait for element/screen
   * 
   * @param key - Key to press ('Ok', 'Back', 'Play', etc.)
   * @param count - Number of times to press (default: 1)
   * @param waitForElement - Optional element to wait for
   * @param waitForScreen - Optional screen to wait for
   */
  public async pressKeyAndWait(key: string, count = 1, waitForElement?: any, waitForScreen?: any) {
    await ecp.sendKeypress(ecp.Key[key], { count });

    if (waitForElement) {
      await testUtils.waitForElementToFullyShowOnScreen(waitForElement);
    }

    if (waitForScreen) {
      await testUtils.waitForCurrentScreenToEqual(waitForScreen);
    }
  }

  /**
   * HELPER: Jump to row by title and optionally select
   * 
   * @param listElement - List element ID
   * @param rowTitle - Row title to jump to
   * @param shouldSelect - Whether to press OK after jumping (default: false)
   * @param confirmElement - Optional element to wait for after selection
   */
  public async jumpToRowAndSelect(listElement: any, rowTitle: string, shouldSelect = false, confirmElement?: any) {
    await testUtils.jumpToRowWithTitle(listElement, rowTitle);
    await utils.sleep(1000);

    if (shouldSelect) {
      await ecp.sendKeypress(ecp.Key.Ok);

      if (confirmElement) {
        await testUtils.waitForElementToFullyShowOnScreen(confirmElement);
      }
    }
  }

  /**
   * HELPER: Wait for multiple conditions (element visible AND has focus)
   * 
   * @param elementId - Element to check
   * @param timeout - Timeout in ms (default: 15000)
   */
  public async waitForElementVisibleAndFocused(elementId: any, timeout = 15000) {
    await testUtils.waitForElementToFullyShowOnScreen(elementId, `${elementId} not visible`, timeout);
    await testUtils.waitForElementToHaveFocus(elementId, `${elementId} not focused`, timeout);
  }

  /**
   * HELPER: Navigate to grid position
   * 
   * @param gridElement - Grid element ID
   * @param targetRow - Target row index
   * @param targetCol - Target column index
   * @param startRow - Starting row (default: 0)
   * @param startCol - Starting column (default: 0)
   */
  public async navigateToGridPosition(gridElement: string, targetRow: number, targetCol: number, startRow = 0, startCol = 0) {
    await moveToGrid({
      grid: { row: startRow, col: startCol },
      destRow: targetRow,
      destCol: targetCol
    });
  }

  /* ═══════════════════════════════════════════════════════════════════
   * REGISTRATION & USER HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Generates unique test email address
   * 
   * @param prefix - Email prefix (default: 'build_roku')
   * @param domain - Email domain (default: 'tubi.tv')
   * @returns Unique email address
   */
  public generateTestEmail(prefix = 'build_roku', domain = 'tubi.tv'): string {
    return `${prefix}_${Math.floor(Date.now() / 1000)}@${domain}`;
  }

  /**
   * HELPER: Completes guest user registration flow
   * 
   * @param email - Optional custom email (generates unique one if not provided)
   * @param emailInputElement - Email input element ID (default: 'emailAddressBox')
   * 
   * @example
   * await testHelpers.completeRegistrationFlow();
   * await testHelpers.completeRegistrationFlow('custom@email.com');
   */
  public async completeRegistrationFlow(email?: string, emailInputElement: any = 'emailAddressBox') {
    // Wait for modal and navigate through it
    await utils.sleep(7000);
    await ecp.sendKeypress(ecp.Key.Down, { wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok, { wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen(emailInputElement);

    // Use provided email or generate unique one
    const emailToUse = email || this.generateTestEmail();

    // Enter email and submit
    await ecp.sendText(emailToUse);
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4, wait: 1000 });
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  /**
   * BACKWARD COMPATIBILITY
   */
  public async completeGuestUserRegistrationFlow() {
    await this.completeRegistrationFlow();
  }

  /* ═══════════════════════════════════════════════════════════════════
   * PLAYBACK HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Ensures focus is on playable content before pressing Play/OK
   *
   * USE WHEN:
   *   - About to press Play or OK to start playback from home screen
   *   - After video tiles redesign, focus can land on non-playable content
   *   - Need to ensure focused item is movie ('v'), series ('s'), or linear ('l')
   *
   * WHAT IT DOES:
   *   1. Checks currently focused content type
   *   2. If not playable (channel logo, promo tile), searches current row for playable content
   *   3. If current row has no playable content, scrolls down to next row
   *   4. Repeats until finding a row with playable content (up to 10 rows)
   *   5. Navigates to first playable content found
   *
   * IMPORTANT:
   *   - Only works on videoTitlesRowList (home screen) by default
   *   - Must be called AFTER waitForElementToHaveFocus('videoTitlesRowList')
   *   - Must be called BEFORE ecp.sendKeypress(ecp.Key.Play) or ecp.Key.Ok
   *   - Scrolls down automatically if current row has no playable content
   *
   * @param listElement - List element ID (default: 'videoTitlesRowList')
   * @param maxRowsToSearch - Maximum number of rows to search (default: 10)
   * @throws Error if no playable content found after searching maxRowsToSearch rows
   *
   * @example
   * await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
   * await testUtils.waitForElementToHaveFocus('videoTitlesRowList');
   * await testHelpers.ensurePlayableContentFocused(); // ADD THIS
   * await ecp.sendKeypress(ecp.Key.Play); // Now safe to play
   */
  public async ensurePlayableContentFocused(listElement: any = 'videoTitlesRowList', maxRowsToSearch = 10) {
    let rowsSearched = 0;

    while (rowsSearched < maxRowsToSearch) {
      const currentFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex(listElement);
      const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent(listElement);

      // If already on playable content, we're done
      if (focusedContent.type === 'v' || focusedContent.type === 's' || focusedContent.type === 'l') {
        return;
      }

      // Not on playable content - search current row
      const rowContent = await testUtils.getRowListRowItemsContent(listElement, currentFocusedIndex[0]);
      let playableCol = -1;
      for (let i = 0; i < rowContent.length; i++) {
        if (rowContent[i].type === 'v' || rowContent[i].type === 's' || rowContent[i].type === 'l') {
          playableCol = i;
          break;
        }
      }

      // Found playable content in current row - navigate to it
      if (playableCol !== -1) {
        await testUtils.jumpToRowItem(listElement, [currentFocusedIndex[0], playableCol]);
        await utils.sleep(500);
        return;
      }

      // No playable content in current row - move down to next row
      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(500);
      rowsSearched++;
    }

    // If we get here, we've searched maxRowsToSearch rows without finding playable content
    throw new Error(`No playable content found after searching ${maxRowsToSearch} rows`);
  }

  /**
   * HELPER: Starts playback and waits for playing state
   *
   * @param playerElement - Player element ID (default: 'videoPlayerScreen')
   * @param timeout - Timeout in ms (default: 15000)
   *
   * @example
   * await testHelpers.startPlaybackAndWait();
   * await testHelpers.startPlaybackAndWait('previewVideoPlayer', 10000);
   */
  public async startPlaybackAndWait(playerElement: any = 'videoPlayerScreen', timeout = 15000) {
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual(playerElement, 'playing', timeout);
  }

  /**
   * HELPER: Seeks to end of video to trigger cue point (for autoplay)
   * 
   * @param playerElement - Player element ID (default: 'videoPlayerScreen')
   */
  public async seekToEnd(playerElement: any = 'videoPlayerScreen') {
    await testUtils.waitForPlayerStateToEqual(playerElement, 'playing');
    await testUtils.seekPlayerToRelativePosition(playerElement, 0, 'end');
  }

  /**
   * HELPER: Exits playback with Back key and waits for screen
   * 
   * @param expectedScreen - Screen to wait for (default: 'detailScreen')
   * @param backCount - Number of times to press Back (default: 1)
   */
  public async exitPlayback(expectedScreen: any = 'detailScreen', backCount = 1) {
    await ecp.sendKeypress(ecp.Key.Back, { count: backCount });
    if (expectedScreen) {
      await testUtils.waitForCurrentScreenToEqual(expectedScreen);
    }
  }

  /* ═══════════════════════════════════════════════════════════════════
   * BUTTON LIST HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Navigates to a button by ID in a button list using jumpToIndex
   * 
   * USE WHEN:
   *   - Need to focus a specific button in EnhancedButtonList or FocusControlLayoutGroup
   *   - Want to navigate directly to a button without pressing arrow keys repeatedly
   *   - Testing button selection in menus or action bars
   * 
   * HOW IT WORKS:
   *   1. Gets all child nodes of the button list element
   *   2. Finds the button with matching ID
   *   3. Sets jumpToIndex field to navigate to that button
   * 
   * @param buttonListElementId - Element ID of the button list (EnhancedButtonList or FocusControlLayoutGroup)
   * @param buttonId - ID of the button to navigate to
   * @param waitForFocus - Whether to wait for button to have focus after jump (default: true)
   * @returns The index of the button that was jumped to
   * 
   * @example
   * // Navigate to "Resume Playing" button in VOD detail screen menu
   * await testHelpers.jumpToButtonById('vodDetailScreenMenu', 'resume');
   * 
   * @example
   * // Navigate to "Like" button without waiting for focus
   * const index = await testHelpers.jumpToButtonById('actionButtons', 'like', false);
   * expect(index).to.equal(2);
   * 
   * @throws Error if button with specified ID is not found
   */
  public async jumpToButtonById(buttonListElementId: any, buttonId: string, waitForFocus = true): Promise<number> {
    // Get the button list node
    const buttonList = await testUtils.getNodeForElement(buttonListElementId);
    // Find the button index by ID
    let buttonIndex = -1;

    for (let i = 0; i < buttonList.buttons.length; i++) {
      if (buttonList.buttons[i].id === buttonId) {
        buttonIndex = i;
        break;
      }
    }

    if (buttonIndex === -1) {
      throw new Error(`Button with ID "${buttonId}" not found in button list "${buttonListElementId}".`);
    }

    await odc.setValue(testUtils.getElementKeyPath(buttonListElementId, {
      field: 'jumpToIndex',
      value: buttonIndex
    }), { timeout: 10000 });


    // Optionally wait for the button to have focus
    if (waitForFocus) {
      await utils.sleep(500); // Give time for focus to update
      const { node } = await odc.getFocusedNode();
      if (node.id !== buttonId) {
        throw new Error(`Expected button "${buttonId}" to have focus, but "${node.id}" has focus instead`);
      }
    }

    return buttonIndex;
  }

  /* ═══════════════════════════════════════════════════════════════════
   * ROW LIST HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Navigates to a specific row and column position in a RowList using jumpToRowItemIndex
   * 
   * USE WHEN:
   *   - Need to focus a specific content item in a RowList (like HomeScreen, CategoryDetails, etc.)
   *   - Testing content navigation and selection
   *   - Need to jump directly to a position without manual arrow key navigation
   *   - Finding content with specific properties (e.g., content without video preview)
   * 
   * HOW IT WORKS:
   *   - Uses the RowList's `jumpToRowItemIndex` field with [row, column] array
   *   - This is the direct and efficient way to navigate in RowLists
   * 
   * COMMON USE CASES:
   *   - Navigate to content without video preview for testing
   *   - Jump to specific row/column for playback tests
   *   - Position focus for detail screen opening
   *   - Test navigation behavior at specific grid positions
   * 
   * @param rowListElementId - Element ID of the RowList (e.g., 'movieScreenRowList', 'videoTitlesRowList')
   * @param targetRow - Target row index (0-based)
   * @param targetCol - Target column index (0-based)
   * 
   * @example
   * // Navigate to row 2, column 3 in home screen
   * await testHelpers.jumpToRowListPosition('videoTitlesRowList', 2, 3);
   * 
   * @example
   * // Find content without video preview and navigate to it
   * const position = await testHelpers.findContentWithoutVideoPreview('movieScreenRowList');
   * if (position.length > 0) {
   *   const [row, col] = position;
   *   await testHelpers.jumpToRowListPosition('movieScreenRowList', row, col);
   * }
   */
  public async jumpToRowListPosition(rowListElementId: any, targetRow: number, targetCol: number): Promise<void> {
    await odc.setValue(testUtils.getElementKeyPath(rowListElementId, {
      field: 'jumpToRowItem',
      value: [targetRow, targetCol]
    }), { timeout: 10000 });
  }

  /**
   * HELPER: Finds content with or without video preview in a RowList
   * 
   * USE WHEN:
   *   - Testing static image display when video preview is not available
   *   - Finding content that has video previews for testing preview functionality
   *   - Testing behavior differences between content with/without previews
   * 
   * HOW IT WORKS:
   *   1. Gets all content items from the RowList (flattened from all rows)
   *   2. Iterates through each item checking for videoPreviewUrl
   *   3. Returns the [row, column] position of the first matching item
   *   4. Handles row-based structure by tracking cumulative item count
   * 
   * COMMON USE CASES:
   *   - Find content without video preview to test static image display
   *   - Find content with video preview to test preview playback
   *   - Navigate to specific content types for testing
   * 
   * @param rowListElementId - Element ID of the RowList (e.g., 'movieScreenRowList', 'videoTitlesRowList')
   * @param hasVideoPreview - true to find WITH preview, false to find WITHOUT (default: true)
   * @param maxRowsToSearch - Maximum number of rows to search (default: 5)
   * @returns [row, column] array or empty array if not found
   * 
   * @example
   * // Find content WITHOUT video preview in movies screen
   * const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('movieScreenRowList', false, 5);
   * if (position.length > 0) {
   *   const [row, col] = position;
   *   await testHelpers.jumpToRowListPosition('movieScreenRowList', row, col);
   * }
   * 
   * @example
   * // Find content WITH video preview
   * const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true);
   * if (position.length === 0) {
   *   throw new Error('Could not find content with video preview');
   * }
   */
  public async findContentPositionInRowListThatContainsVideoPreview(
    rowListElementId: any,
    hasVideoPreview = true,
    maxRowsToSearch = 5
  ): Promise<[number, number] | []> {
    // Get all content grouped by row
    const rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow(rowListElementId);
    // Search through rows up to maxRowsToSearch
    for (let rowIndex = 0; rowIndex < Math.min(rowsContent.length, maxRowsToSearch); rowIndex++) {
      const rowContent = rowsContent[rowIndex];
      // Search through items in this row
      for (let colIndex = 0; colIndex < rowContent.length; colIndex++) {
        const item = rowContent[colIndex];
        if (item.type.includes('ad')) {
          continue;
        }
        const videoPreviewUrl = item.video_preview_url?.trim();

        // Check if item matches the video preview criteria
        if (hasVideoPreview && videoPreviewUrl.length > 0) {
          return [rowIndex, colIndex];
        } else if (!hasVideoPreview && (videoPreviewUrl === undefined || videoPreviewUrl === null || videoPreviewUrl.length === 0)) {
          return [rowIndex, colIndex];
        }
      }
    }

    // Return empty array if not found
    return [];
  }

  /**
   * HELPER: Finds and navigates to content with/without video preview
   * 
   * PATTERN: Combines findContentPositionInRowListThatContainsVideoPreview + jumpToRowListPosition
   * 
   * USE WHEN:
   *   - Need to find AND navigate to content with/without video preview
   *   - Want automatic error handling if content not found
   *   - Want consistent sleep timing after navigation
   * 
   * @param rowListElementId - The row list element to search in
   * @param hasVideoPreview - Whether to find content with or without video preview (default: true)
   * @param maxRowsToSearch - Maximum number of rows to search (default: 5)
   * @param sleepAfterJump - Time to sleep after jumping to position (default: 2000ms)
   * @returns [row, column] position that was navigated to
   * @throws Error if no content matching criteria is found
   * 
   * @example
   * // Find and navigate to content WITH video preview
   * await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);
   * // Now focused on a title with video preview
   * 
   * @example
   * // Find and navigate to content WITHOUT video preview
   * const position = await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', false, 5);
   * // Can use returned position if needed: const [row, col] = position;
   */
  public async findAndNavigateToVideoPreviewContent(
    rowListElementId: string,
    hasVideoPreview: boolean = true,
    maxRowsToSearch: number = 5,
    sleepAfterJump: number = 2000
  ): Promise<[number, number]> {
    const position = await this.findContentPositionInRowListThatContainsVideoPreview(
      rowListElementId,
      hasVideoPreview,
      maxRowsToSearch
    );

    if (position.length === 0) {
      const previewType = hasVideoPreview ? 'with' : 'without';
      throw new Error(`Could not find content ${previewType} video preview in ${rowListElementId}`);
    }

    await this.jumpToRowListPosition(rowListElementId, position[0], position[1]);
    await utils.sleep(sleepAfterJump);

    return position as [number, number];
  }

  /* ═══════════════════════════════════════════════════════════════════
   * DETAIL SCREEN HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Opens detail screen from currently focused item
   * 
   * @param titleElement - Optional element to wait for on detail screen (default: 'detailScreenTitle')
   */
  public async openDetailScreen(titleElement: any = 'detailScreenTitle') {
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen(titleElement);
  }

  /**
   * HELPER: Selects Like button on detail screen
   * 
   * PATTERN: Used 7+ times in user-reactions.ts
   * 
   * @param confirmElement - Element to confirm Like was selected (default: 'reactionButtonLiked')
   * 
   * @example
   * await testHelpers.selectLikeOnDetailScreen();
   * // Like button is now active
   */
  public async selectLikeOnDetailScreen(confirmElement: any = 'reactionButtonLiked') {
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    // Delay to avoid race condition with app state updates
    await utils.sleep(500);
    await testUtils.selectAndVerifyDetailPageMenuItem('likeOrDislike');
    await ecp.sendKeypress(ecp.Key.Ok);

    if (confirmElement) {
      await testUtils.waitForElementToFullyShowOnScreen(confirmElement);
    }
  }

  /**
   * HELPER: Selects Dislike button on detail screen
   * 
   * PATTERN: Used 7+ times in user-reactions.ts
   * 
   * @param focusedElement - Element to wait for when Dislike is focused (default: 'DislikedButtonFocused')
   * 
   * @example
   * await testHelpers.selectDislikeOnDetailScreen();
   * // Dislike is now selected
   */
  public async selectDislikeOnDetailScreen(focusedElement: any = 'DislikedButtonFocused') {
    await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle');
    // Delay to avoid race condition with app state updates
    await utils.sleep(500);
    await testUtils.selectAndVerifyDetailPageMenuItem('likeOrDislike');

    // Secondary menu with Like/Dislike buttons appears
    await testUtils.waitForElementToFullyShowOnScreen('secondaryMenuButtonLike');
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToFullyShowOnScreen(focusedElement);
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  /* ═══════════════════════════════════════════════════════════════════
   * GENERIC VERIFICATION HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Verifies element is visible with retry
   * 
   * @param elementId - Element to verify
   * @param expectedValue - Optional expected value for visibility (default: true)
   * 
   * @example
   * await testHelpers.verifyElementVisible('ageGateScreen');
   * await testHelpers.verifyElementVisible('myButton', false); // Verify hidden
   */
  public async verifyElementVisible(elementId: any, expectedValue = true) {
    await testUtils.retryWithTimeOut(async () => {
      const element = await testUtils.getNodeForElement(elementId);
      expect(element.visible).to.equal(expectedValue);
    });
  }

  /**
   * HELPER: Verifies element text matches expected value
   * 
   * @param elementId - Element to check
   * @param expectedText - Expected text (exact match)
   * @param shouldContain - If true, uses 'contain' instead of 'equal' (default: false)
   */
  public async verifyElementText(elementId: any, expectedText: string, shouldContain = false) {
    await testUtils.retryWithTimeOut(async () => {
      const element = await testUtils.getNodeForElement(elementId);
      if (shouldContain) {
        expect(element.text).to.contain(expectedText);
      } else {
        expect(element.text).to.equal(expectedText);
      }
    });
  }

  /**
   * HELPER: Waits for element and verifies field value
   * 
   * @param elementId - Element to check
   * @param fieldName - Field name to check
   * @param expectedValue - Expected value
   */
  public async verifyElementField(elementId: any, fieldName: string, expectedValue: any) {
    const element = await testUtils.getNodeForElement(elementId);
    expect(element[fieldName]).to.equal(expectedValue);
  }

  /**
   * HELPER: Checks if specific rating is kids-appropriate
   * 
   * @param rating - Rating string (e.g., 'G', 'TV-Y', 'PG', 'R')
   * @returns boolean - true if rating is kids-appropriate
   */
  public isKidsAppropriateRating(rating: string): boolean {
    const kidsRatings = ['G', 'TV-Y', 'TV-Y7', 'TV-G', 'PG', 'TV-PG'];
    return kidsRatings.includes(rating);
  }

  /* ═══════════════════════════════════════════════════════════════════
   * MY STUFF SCREEN HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Verifies empty My Stuff screen for registered user
   * 
   * PATTERN: Used multiple times in my-stuff.ts
   * 
   * @example
   * await testHelpers.verifyEmptyMyStuffScreen();
   */
  public async verifyEmptyMyStuffScreen() {
    await testUtils.waitForElementToFullyShowOnScreen('myStuffRegUserEmptyScreen');
    await testUtils.waitForElementToFullyShowOnScreen('goHomeButtonMyStuff');

    const goHomeButton = await testUtils.getNodeForElement('goHomeButtonMyStuff');
    expect(goHomeButton.text).to.equal('Go Home');

    const title = await testUtils.getNodeForElement('myStuffRegScreenTitle');
    expect(title.text).to.equal('My Stuff is Empty');

    const subtitle1 = await testUtils.getNodeForElement('myStuffRegScreenSubTitle');
    expect(subtitle1.text).to.equal('Find your favorites fast, pick up where you left off–all in one place.');

    const subtitle2 = await testUtils.getNodeForElement('myStuffRegScreenSubTitle2');
    expect(subtitle2.text).to.equal('Use the bookmark button to save series and movies to your My List.');
  }

  /**
   * HELPER: Verifies guest user My Stuff unlock screen
   * 
   * @example
   * await testHelpers.verifyGuestMyStuffUnlockScreen();
   */
  public async verifyGuestMyStuffUnlockScreen() {
    await testUtils.waitForElementToFullyShowOnScreen('myStuffEmptyScreen');

    const unlockButton = await testUtils.getNodeForElement('unlockNowForMyStuff');
    expect(unlockButton.text).to.equal('Unlock Now');

    const title = await testUtils.getNodeForElement('myStuffGuestScreenTextTitle');
    expect(title.text).to.equal('Make Tubi Yours for Free (Forever)');

    const subtitle = await testUtils.getNodeForElement('myStuffGuestScreenTextSubTitle');
    expect(subtitle.text).to.equal('Find your favorites fast, pick up where you left off–all in one place.');

    const blurb = await testUtils.getNodeForElement('myStuffGuestScreenTextBlurb');
    expect(blurb.text).to.equal('And always free.');
  }

  /* ═══════════════════════════════════════════════════════════════════
   * AUTOPLAY HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Verifies autoplay UI is showing with countdown
   * 
   * @param countdownElement - Countdown element ID (default: 'countDownAutoPlay')
   * @param secondsElement - Seconds element ID (default: 'countDownSecondsAutoPlay')
   * @param verifyPlayerSize - Whether to verify player dimensions (default: false)
   */
  public async verifyAutoplayUIShowing(countdownElement: any = 'countDownAutoPlay', secondsElement: any = 'countDownSecondsAutoPlay', verifyPlayerSize = false) {
    await testUtils.waitForElementToFullyShowOnScreen(countdownElement);
    const countDown = await testUtils.getNodeForElement(countdownElement);
    expect(countDown.text).to.contain('Up Next in');

    // Verify countdown is counting down
    await testUtils.waitForElementToFullyShowOnScreen(secondsElement);
    await utils.sleep(1000);
    let countDownNode = await testUtils.getNodeForElement(secondsElement);
    let seconds = parseInt(countDownNode.text);

    // Retry if parsing fails (handles NaN edge case)
    if ((typeof seconds === 'number' && !Number.isNaN(seconds)) === false) {
      await utils.sleep(1000);
      countDownNode = await testUtils.getNodeForElement(secondsElement);
      seconds = parseInt(countDownNode.text);
    }

    await utils.sleep(2000);
    const countDownNode2 = await testUtils.getNodeForElement(secondsElement);
    expect(seconds).to.be.greaterThan(parseInt(countDownNode2.text));

    // Optionally verify player dimensions (640x360 for autoplay mini-player)
    if (verifyPlayerSize) {
      await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'width', 640, 10000);
      await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'height', 360, 10000);
    }
  }

  /**
   * HELPER: Verifies autoplay UI is NOT showing
   * 
   * @param countdownElement - Countdown element to check (default: 'autoplayCountdownTimerSection')
   * @param verifyPlayerSize - Whether to verify player dimensions (default: false)
   */
  public async verifyAutoplayUINotShowing(countdownElement: any = 'autoplayCountdownTimerSection', verifyPlayerSize = false) {
    await testUtils.waitForElementToNotShowOnScreen(countdownElement, 'Countdown timer section is still showing', 10000);

    if (verifyPlayerSize) {
      await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'width', 640, 10000);
      await testUtils.waitForElementFieldToEqual('videoPlayerActual', 'height', 360, 10000);
    }
  }

  /**
   * HELPER: Complete movie autoplay trigger flow
   * 
   * PATTERN: Used 12+ times in autoplay-movie.ts
   * 
   * @param shouldCreateNewUser - Whether to create new user (default: true)
   * @param verifyPlayerSize - Whether to verify player dimensions (default: false)
   * 
   * @example
   * await testHelpers.triggerMovieAutoplay();
   * // Now autoplay UI is showing with countdown
   */
  public async triggerMovieAutoplay(shouldCreateNewUser = true, verifyPlayerSize = false) {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser });
    await this.enableAutoplayInSettings(true);
    await this.navigateToPage('movies', 'movieScreenRowList');
    await ecp.sendKeypress(ecp.Key.Play);
    await this.seekToEnd();
    await this.verifyAutoplayUIShowing('countDownAutoPlay', 'countDownSecondsAutoPlay', verifyPlayerSize);
  }

  /**
   * HELPER: Validate that autoplay UI does NOT show (when autoplay is OFF)
   * 
   * @param verifyPlayerSize - Whether to verify player dimensions (default: false)
   */
  public async validateAutoplayNotTriggered(verifyPlayerSize = false) {
    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus', 15000);
    await ecp.sendKeypress(ecp.Key.Play);
    await this.seekToEnd();
    await testUtils.waitForElementToHaveFocus('autoplayGridMovie', 'Timed out waiting for Rowlist to have focus', 15000);
    await this.verifyAutoplayUINotShowing('autoplayCountdownTimerSection', verifyPlayerSize);
  }

  /* ═══════════════════════════════════════════════════════════════════
   * AGE GATE & REGISTRATION HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Completes age gate verification
   * 
   * @param age - Age to enter (default: '20')
   * @param acceptButton - Accept button element (default: 'continueWatchingConsentPageAcceptButton')
   */
  public async completeAgeGate(age = '20', acceptButton: any = 'continueWatchingConsentPageAcceptButton') {
    await testUtils.waitForElementToFullyShowOnScreen('ageVerificationPageHeader');
    await ecp.sendText(age);
    await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
    await ecp.sendKeypress(ecp.Key.Ok);

    if (acceptButton) {
      await testUtils.waitForElementToFullyShowOnScreen(acceptButton);
      await ecp.sendKeypress(ecp.Key.Ok);
    }
  }

  /* ═══════════════════════════════════════════════════════════════════
   * CONTENT MANAGEMENT HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Creates user content history with flexible configuration
   * 
   * USE WHEN:
   *   - Need to create user view history with specific ratings and content types
   *   - Testing parental controls, categories, or content filtering
   * 
   * @param user - User API instance
   * @param contentConfig - Array of {rating, contentType, limit, watchTime}
   * 
   * @example
   * await testHelpers.createFlexibleUserHistory(user, [
   *   { rating: 'G', contentType: 'movie', limit: 5, watchTime: 600 },
   *   { rating: 'PG', contentType: 'movie', limit: 3, watchTime: 500 }
   * ]);
   */
  public async createFlexibleUserHistory(user: any, contentConfig: Array<{ rating: string; contentType: string; limit: number; watchTime: number }>) {
    for (const config of contentConfig) {
      const content = await user.getContent()
        .withRating(config.rating)
        .ofContentType(config.contentType)
        .retrieve({ limit: config.limit });
      await user.addContentToViewHistory(content, config.watchTime);
    }
  }

  /**
   * HELPER: Creates user content history with comprehensive mix of ratings
   * 
   * USE WHEN:
   *   - Testing parental controls with various rating levels
   *   - Need history with mix of G, PG, PG-13, R, TV-G, TV-MA, TV-14, NR ratings
   *   - Testing content filtering based on ratings
   * 
   * CREATES HISTORY FOR:
   *   - G movies (25 items, 600s watch time)
   *   - TV-G series (3 items, 600s watch time)
   *   - TV-MA series (3 items, 600s watch time)
   *   - R movies (2 items, 500s watch time)
   *   - PG movies (2 items, 500s watch time)
   *   - PG-13 movies (2 items, 500s watch time)
   *   - TV-14 series (2 items, 500s watch time)
   *   - NR movies (2 items, 500s watch time)
   * 
   * @param user - User API instance
   * 
   * @example
   * const user = await testUtils.createRegisteredUser();
   * await testHelpers.createUserHistoryWithRatings(user);
   */
  public async createUserHistoryWithRatings(user: any) {
    // Create a user with mix of little kids and non-little kid rated titles with history
    const ContentG = await user.getContent().withRating('G').ofContentType('movie').retrieve({ limit: 25 });
    await user.addContentToViewHistory(ContentG, 600);
    const ContentTVY7 = await user.getContent().withRating('TV-G').ofContentType('series').retrieve({ limit: 3 });
    await user.addContentToViewHistory(ContentTVY7, 600);
    const movieContentTVMA = await user.getContent().withRating('TV-MA').ofContentType('series').retrieve({ limit: 3 });
    await user.addContentToViewHistory(movieContentTVMA, 600);
    const movieContentR = await user.getContent().withRating('R').ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentR, 500);
    const movieContentPG = await user.getContent().withRating('PG').ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentPG, 500);
    const movieContentPG13 = await user.getContent().withRating('PG-13').ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentPG13, 500);
    const movieContentTV14 = await user.getContent().withRating('TV-14').ofContentType('series').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentTV14, 500);
    const movieContentNR = await user.getContent().withRating('NR').ofContentType('movie').retrieve({ limit: 2 });
    await user.addContentToViewHistory(movieContentNR, 500);
  }

  /**
   * HELPER: Creates user watchlist with flexible configuration
   * 
   * @param user - User API instance
   * @param contentConfig - Array of {rating, contentType, limit}
   */
  public async createFlexibleUserWatchList(user: any, contentConfig: Array<{ rating: string; contentType: string; limit: number }>) {
    for (const config of contentConfig) {
      const content = await user.getContent()
        .ofContentType(config.contentType)
        .withRating(config.rating)
        .retrieve({ limit: config.limit });
      await user.addContentToWatchList(content);
    }
  }

  /**
   * HELPER: Creates mixed kids and adult content (watchlist + history)
   * 
   * PATTERN: Used in my-stuff.ts and kids-mode tests
   * 
   * @param user - User API instance
   * 
   * @example
   * await testHelpers.createMixedKidsAndAdultContent(user);
   * // User now has G, TV-Y, TV-Y7 content + R, TV-MA content
   */
  public async createMixedKidsAndAdultContent(user: any) {
    // Kids-appropriate content
    const kidsMoviesG = await user.getContent().ofContentType('movie').withRating('G').retrieve({ limit: 3, contentsLimit: 100 });
    await user.addContentToWatchList(kidsMoviesG);
    await user.addContentToViewHistory(kidsMoviesG, 300);

    const kidsSeriesTVY = await user.getContent().ofContentType('series').withRating('TV-Y').retrieve({ limit: 2, contentsLimit: 100 });
    await user.addContentToWatchList(kidsSeriesTVY);
    await user.addContentToViewHistory(kidsSeriesTVY, 400);

    const kidsSeriesTVY7 = await user.getContent().ofContentType('series').withRating('TV-Y7').retrieve({ limit: 2, contentsLimit: 100 });
    await user.addContentToWatchList(kidsSeriesTVY7);
    await user.addContentToViewHistory(kidsSeriesTVY7, 500);

    // Adult content
    const adultMoviesR = await user.getContent().ofContentType('movie').withRating('R').retrieve({ limit: 2, contentsLimit: 100 });
    await user.addContentToWatchList(adultMoviesR);
    await user.addContentToViewHistory(adultMoviesR, 600);

    const adultSeriesTVMA = await user.getContent().ofContentType('series').withRating('TV-MA').retrieve({ limit: 2, contentsLimit: 100 });
    await user.addContentToWatchList(adultSeriesTVMA);
    await user.addContentToViewHistory(adultSeriesTVMA, 700);
  }

  /**
   * HELPER: Creates history for a single title (movie or series)
   *
   * @param user - User API instance
   * @param contentType - 'movie' or 'series'
   * @param rating - Content rating (default: 'PG')
   * @param watchTime - Watch time in seconds (default: 500)
   * @param hasVideoPreview - For series, whether to filter by video preview (default: false)
   *
   * @example
   * await testHelpers.createHistoryForSingleTitle(user, 'movie', 'PG', 500);
   * await testHelpers.createHistoryForSingleTitle(user, 'series', 'TV-Y', 600, true);
   */
  public async createHistoryForSingleTitle(user: any, contentType: string, rating = 'PG', watchTime = 500, hasVideoPreview = false) {
    let query = user.getContent().ofContentType(contentType).withRating(rating);

    if (contentType === 'series' && hasVideoPreview) {
      query = query.hasVideoPreview();
    }

    const content = await query.retrieve({ limit: 1 });
    await user.addContentToViewHistory(content, watchTime);
  }

  /* ═══════════════════════════════════════════════════════════════════
   * NETWORK PROXY MOCKING HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Finds Featured container by id with fallback to first container
   *
   * @param containers - Array of containers from homescreen response
   * @returns Featured container or first container as fallback
   *
   * @private
   */
  private findFeaturedContainer(containers: any[]): any {
    let featuredContainer = containers.find((c: any) => c.id === 'featured');

    if (!featuredContainer) {
      featuredContainer = containers[0];
    }

    return featuredContainer;
  }

  /**
   * HELPER: Fetches linear content from Tubi API
   *
   * @param user - User instance for authenticated API calls
   * @param count - Number of linear items to fetch (default: 2)
   * @returns Array of linear content items
   *
   * @private
   */
  private async fetchLinearContent(user: any, count = 2): Promise<any[]> {
    const linearChannelsUrl = 'https://tensor-cdn.production-public.tubi.io/api/v7/containers/recommended_linear_channels?' +
      'images%5Bbackground_tb%5D=w1197h675_background&' +
      'images%5Blandscape_tb%5D=w520h292_landscape&' +
      'contents_limit=30&' +
      'content_mode=&' +
      'video_resources%5B%5D=dash_widevine_psshv0&' +
      'video_resources%5B%5D=hlsv6&' +
      'include_ui_customization=true&' +
      'is_kids_mode=false&' +
      'device_id=032760ab-cd00-5b65-958c-d0bdd972c7e2&' +
      'images%5Bcontrol_landscape_tb%5D=w360h201_hero&' +
      'images%5Bvideo_tiles_portrait_tb%5D=w310h442_poster&' +
      'images%5Btitle_art%5D=w0h80_title&' +
      'cursor=9&' +
      'app_id=tubitv&' +
      'images%5Bhero_tb%5D=w789h442_hero&' +
      'include_sponsorships=true&' +
      'platform=roku&' +
      'images%5Bposter_tb%5D=w252h360_poster&' +
      'limit_resolutions%5B%5D=H264_1080p&' +
      'limit_resolutions%5B%5D=H265_1080p';

    const linearChannelsResponse = await user.sendTubiAuthNetworkRequest({
      method: 'get',
      url: linearChannelsUrl
    });

    const childrenIds = linearChannelsResponse.container.children;
    const contentsMap = linearChannelsResponse.contents;

    if (!childrenIds || childrenIds.length < count) {
      throw new Error(`Not enough linear channel IDs. Found ${childrenIds?.length || 0}, need at least ${count}`);
    }

    return childrenIds.slice(0, count).map((id: string) => contentsMap[id]);
  }

  /**
   * HELPER: Sets up network proxy to inject linear content into homescreen Featured container
   *
   * USE WHEN:
   *   - Testing linear content autoplay in Featured row
   *   - Need to guarantee linear content appears in Featured container
   *
   * HOW IT WORKS:
   *   1. Fetches linear channels from Tubi API
   *   2. Extracts 2 linear content items
   *   3. Sets up proxy.observeRequest to intercept homescreen API call
   *   4. Modifies homescreen response to inject linear items at beginning of Featured container
   *
   * @param user - Registered user instance (for authentication)
   *
   * @example
   * const user = await testUtils.createRegisteredUser();
   * await testHelpers.mockHomescreenWithLinearContentInFeatured(user);
   * await testUtils.startApplicationAtPage('home', { user });
   * // Now Featured row will have 2 linear content items at the beginning
   */
  public async mockHomescreenWithLinearContentInFeatured(user: any) {
    // Fetch linear content from API
    const twoLinearItems = await this.fetchLinearContent(user, 2);

    return new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/api/v7/homescreen');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          // Find Featured container using helper
          if (responseJson.containers && responseJson.containers.length > 0) {
            const featuredContainer = this.findFeaturedContainer(responseJson.containers);

            // Add linear item IDs to the beginning of Featured container's children array
            if (featuredContainer.children) {
              const linearIds = twoLinearItems.map((item: any) => item.id);
              featuredContainer.children.unshift(...linearIds);
            }

            // Add linear items to top-level contents map so they're available by ID
            if (!responseJson.contents) {
              responseJson.contents = {};
            }
            twoLinearItems.forEach((item: any) => {
              responseJson.contents[item.id] = item;
            });
          }

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });
  }

  /**
   * HELPER: Sets up network proxy to inject/modify content with long titles in homescreen
   *
   * USE WHEN:
   *   - Testing long title display (2-line for non-linear, 1-line for linear)
   *   - Need to guarantee content with long titles appears in Featured container
   *
   * HOW IT WORKS FOR MOVIE/SERIES:
   *   1. Intercepts homescreen API response
   *   2. Searches ALL containers for first matching content type
   *   3. Overrides its title with a very long title (>60 characters)
   *   4. Moves it to the front of Featured container
   *
   * HOW IT WORKS FOR LINEAR:
   *   1. Fetches linear content from Tubi API
   *   2. Overrides the title with a very long title
   *   3. Intercepts homescreen response and injects linear content into Featured container
   *
   * @param contentType - Type of content to modify ('movie', 'series', or 'linear')
   * @param user - Optional user instance (required for linear content to make API calls)
   *
   * @example
   * // For non-linear content (C842109)
   * await testHelpers.mockHomescreenWithLongTitleContent('movie');
   * await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: false });
   *
   * // For linear content (C842110)
   * const user = await testUtils.createRegisteredUser();
   * await testHelpers.mockHomescreenWithLongTitleContent('linear', user);
   * await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
   */
  public async mockHomescreenWithLongTitleContent(contentType: 'movie' | 'series' | 'linear', user?: any) {
    // Create long title based on content type
    const longTitle = contentType === 'linear'
      ? 'This Is An Extremely Long Linear Channel Name That Will Definitely Exceed The Character Limit For Testing'
      : 'This Is An Extremely Long Movie Title That Will Definitely Exceed The Character Limit For Testing Purposes And Will Wrap To Multiple Lines';

    // Map content type to type code
    const typeCode = contentType === 'movie' ? 'v' : (contentType === 'series' ? 's' : 'l');

    // For linear content, fetch from API first
    let linearItemsWithLongTitle = null;
    if (contentType === 'linear') {
      if (!user) {
        throw new Error('User instance required for fetching linear content from API');
      }

      // Fetch linear content using helper method
      const linearItems = await this.fetchLinearContent(user, 2);

      // Override titles with long title
      linearItemsWithLongTitle = linearItems.map((item: any) => {
        item.title = longTitle;
        return item;
      });
    }

    return new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/api/v7/homescreen');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          if (responseJson.containers && responseJson.containers.length > 0 && responseJson.contents) {
            // Find Featured container using helper
            const featuredContainer = this.findFeaturedContainer(responseJson.containers);

            // Handle linear content injection
            if (contentType === 'linear' && linearItemsWithLongTitle) {
              // Add linear item IDs to the beginning of Featured container's children array
              if (featuredContainer.children) {
                const linearIds = linearItemsWithLongTitle.map((item: any) => item.id);
                featuredContainer.children.unshift(...linearIds);
              }

              // Add linear items to top-level contents map
              if (!responseJson.contents) {
                responseJson.contents = {};
              }
              linearItemsWithLongTitle.forEach((item: any) => {
                responseJson.contents[item.id] = item;
              });
            } else {
              // Handle movie/series by finding and modifying existing content
              let matchingContentId = null;

              // Search through ALL containers to find matching content type
              for (const container of responseJson.containers) {
                if (container.children && container.children.length > 0) {
                  for (const childId of container.children) {
                    const content = responseJson.contents[childId];
                    if (content && content.type === typeCode) {
                      // Override the title of this existing content
                      responseJson.contents[childId].title = longTitle;
                      matchingContentId = childId;
                      break;
                    }
                  }
                  if (matchingContentId) break;
                }
              }

              // Move the matching content to the front of Featured container
              if (matchingContentId) {
                // Remove from wherever it currently is
                featuredContainer.children = featuredContainer.children.filter(id => id !== matchingContentId);

                // Add to front of Featured
                featuredContainer.children.unshift(matchingContentId);
              }
            }
          }

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });
  }

  /**
   * HELPER: Mock homescreen response with content that has a very long description
   *
   * USE WHEN:
   *   - Testing description overflow behavior (C842129)
   *   - Testing UI layout with long descriptions
   *
   * HOW IT WORKS:
   *   1. Intercepts homescreen API response
   *   2. Searches ALL containers for first movie content
   *   3. Overrides its description with a very long description (>500 characters)
   *   4. Moves it to the front of Featured container
   *
   * @example
   * await testHelpers.mockHomescreenWithLongDescriptionContent();
   * await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: false });
   */
  public async mockHomescreenWithLongDescriptionContent() {
    // Create a very long description (>500 characters)
    const longDescription = 'This is an extremely long description that will definitely exceed the normal character limits for testing purposes. ' +
      'It contains multiple sentences and paragraphs to simulate real-world content that might have extensive plot summaries or detailed information. ' +
      'This description is intentionally verbose to test how the UI handles overflow scenarios and ensures that the text wrapping and truncation mechanisms work correctly. ' +
      'Additional filler text is added here to make absolutely certain that we exceed the 500 character threshold needed for proper width validation. ' +
      'More text continues here to ensure we have a truly long description that will cause the UI to properly display overflow handling behavior.';

    return new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/api/v7/homescreen');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          if (responseJson.containers && responseJson.containers.length > 0 && responseJson.contents) {
            // Find Featured container using helper
            const featuredContainer = this.findFeaturedContainer(responseJson.containers);

            // Find first movie content and override its description
            let matchingContentId = null;

            // Search through ALL containers to find movie content (type 'v')
            for (const container of responseJson.containers) {
              if (container.children && container.children.length > 0) {
                for (const childId of container.children) {
                  const content = responseJson.contents[childId];
                  if (content && content.type === 'v') {
                    // Override the description of this existing content
                    responseJson.contents[childId].description = longDescription;
                    matchingContentId = childId;
                    break;
                  }
                }
                if (matchingContentId) break;
              }
            }

            // Move the matching content to the front of Featured container
            if (matchingContentId) {
              // Remove from wherever it currently is
              featuredContainer.children = featuredContainer.children.filter(id => id !== matchingContentId);

              // Add to front of Featured
              featuredContainer.children.unshift(matchingContentId);
            }
          }

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });
  }

  /* ═══════════════════════════════════════════════════════════════════
   * CONTINUE WATCHING ROW HELPERS
   * ═══════════════════════════════════════════════════════════════════
   */

  /**
   * HELPER: Validates guest user Continue Watching row registration CTA
   *
   * USE WHEN:
   *   - Testing guest user Continue Watching row display
   *   - Verifying registration prompt appears for guest users in CW row
   *   - Test mentions "guest user", "sign up", "Continue Watching" together
   *
   * VALIDATES:
   *   - Title: "Sign Up to Save Your Progress"
   *   - Description: "Pick up right where you left off next time you play a TV Series or a Movie. Available upon sign up."
   *   - Sign up button visibility
   *   - Button label text: "Sign Up to Save Progress"
   *
   * PREREQUISITES:
   *   - Must be on home screen
   *   - Must already have navigated to Continue Watching row
   *   - User must be guest user (not registered)
   *
   * HOW IT WORKS:
   *   - Gets Continue Watching row index dynamically at runtime
   *   - Constructs element keypaths with row index
   *   - Uses getNodeWithDynamicPath() to access elements
   *   - Validates all 4 elements of the registration CTA
   *
   * COMMON USE CASES:
   *   - Test C842105: Validating guest CW row on home screen
   *   - Test C148846: Guest user registration flow from CW row
   *
   * @example
   * // Navigate to CW row first (scrollDownToFindRow handles scrolling and focusing)
   * await testHelpers.scrollDownToFindRow({ slug: 'continue_watching' });
   * // Then validate
   * await testHelpers.validateGuestContinueWatchingRow();
   */
  public async validateGuestContinueWatchingRow() {
    // Get row index dynamically
    const rowIndex = await testUtils.findRowIndexWithSlug('videoTitlesRowList', 'continue_watching');

    // Construct dynamic element objects with runtime row index
    const titleElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#FeaturedRowList.${rowIndex}.items.0.#contentSection.#title`
    };
    const descriptionElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#FeaturedRowList.${rowIndex}.items.0.#contentSection.#description`
    };
    const buttonElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#FeaturedRowList.${rowIndex}.items.0.#contentSection.#signUpButton`
    };
    const buttonLabelElement = {
      keyPath: `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#FeaturedRowList.${rowIndex}.items.0.#contentSection.#signUpButton.#label`
    };

    // Validate registration CTA title
    const titleNode = await testUtils.getNodeWithDynamicPath(titleElement, 10000);
    expect(titleNode.visible).to.equal(true, 'Guest user CW tile title should be visible');
    expect(titleNode.text).to.equal('Sign Up to Save Your Progress', 'CW tile should display "Sign Up to Save Your Progress" title');

    // Validate registration CTA description
    const descriptionNode = await testUtils.getNodeWithDynamicPath(descriptionElement, 10000);
    expect(descriptionNode.visible).to.equal(true, 'Guest user CW tile description should be visible');
    expect(descriptionNode.text).to.equal('Pick up right where you left off next time you play a TV Series or a Movie. Available upon sign up.',
      'CW tile should display correct description');

    // Validate sign up button is present and visible
    const buttonNode = await testUtils.getNodeWithDynamicPath(buttonElement, 10000);
    expect(buttonNode.visible).to.equal(true, 'Sign up button should be visible');

    // Validate button label text
    const buttonLabelNode = await testUtils.getNodeWithDynamicPath(buttonLabelElement, 10000);
    expect(buttonLabelNode.text).to.include('Sign Up to Save Progress', 'Button label should contain "Sign Up to Save Progress"');
  }

  /**
   * Scroll down until the focused row's title or slug matches one of the target values
   * @param options - Configuration object
   * @param options.title - Title(s) of the row to find. Can be a single string or array of strings (e.g., 'On Now' or ['Comedy', 'Action', 'Drama'])
   * @param options.slug - Slug(s) of the row to find. Can be a single string or array of strings (e.g., 'on-now' or ['comedy', 'action', 'drama'])
   * @param options.rowListElementId - Element ID of the RowList to search in (default: 'videoTitlesRowList')
   * @param options.maxScrolls - Maximum number of times to scroll down (default: 20)
   * @remarks Either `title` or `slug` must be provided. If `slug` is provided, only checks SLUG field. If `title` is provided, only checks TITLE field. When an array is provided, scrolling stops at the first matching row.
   * 
   * @example
   * // Find single row by slug
   * await testHelpers.scrollDownToFindRow({ slug: 'comedy' });
   * 
   * @example
   * // Find first matching row from multiple slugs
   * await testHelpers.scrollDownToFindRow({ slug: ['comedy', 'action', 'drama'] });
   * 
   * @example
   * // Find row by title with custom max scrolls
   * await testHelpers.scrollDownToFindRow({ title: 'On Now', maxScrolls: 40 });
   */
  async scrollDownToFindRow(options: { title?: string | string[]; slug?: string | string[]; rowListElementId?: ElementOrElementId; maxScrolls?: number }): Promise<void> {
    const { title, slug, rowListElementId = 'videoTitlesRowList', maxScrolls = 20 } = options;

    if (!title && !slug) {
      throw new Error('Either "title" or "slug" must be provided');
    }

    // Convert single values to arrays for consistent handling
    const searchValues = slug ? (Array.isArray(slug) ? slug : [slug]) : (Array.isArray(title) ? title : [title!]);
    const isSlugSearch = !!slug;

    const element = testUtils.getElementKeyPath(rowListElementId);
    let baseKeyPath = `content`;
    if (element.keyPath) {
      baseKeyPath = element.keyPath + '.' + baseKeyPath;
    }

    let found = false;
    let scrollCount = 0;
    let foundValue: string | undefined;

    while (!found && scrollCount < maxScrolls) {
      try {
        // Get the currently focused row index
        const focusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex(rowListElementId);
        const rowIndex = focusedIndex[0];

        if (isSlugSearch) {
          // Only check slug field when slug parameter is provided
          const { found: slugFound, value: currentRowSlug } = await odc.getValue({
            base: element.base,
            keyPath: `${baseKeyPath}.${rowIndex}.slug`
          });

          if (slugFound && searchValues.includes(currentRowSlug)) {
            found = true;
            foundValue = currentRowSlug;
          } else {
            // Row slug doesn't match any in the list, scroll down and try again
            await ecp.sendKeypress(ecp.Key.Down);
            await utils.sleep(500); // Wait for content to load
            scrollCount++;
          }
        } else {
          // Only check title field when title parameter is provided
          const { found: titleFound, value: currentRowTitle } = await odc.getValue({
            base: element.base,
            keyPath: `${baseKeyPath}.${rowIndex}.TITLE`
          });

          if (titleFound && searchValues.includes(currentRowTitle)) {
            found = true;
            foundValue = currentRowTitle;
          } else {
            // Row title doesn't match any in the list, scroll down and try again
            await ecp.sendKeypress(ecp.Key.Down);
            await utils.sleep(500); // Wait for content to load
            scrollCount++;
          }
        }
      } catch (e) {
        // Error getting focused row or title/slug, scroll down and try again
        await ecp.sendKeypress(ecp.Key.Down);
        scrollCount++;
      }
    }

    if (!found) {
      const fieldType = isSlugSearch ? 'slug' : 'title';
      const searchList = searchValues.join('", "');
      throw new Error(`Could not find row with ${fieldType} "${searchList}" after scrolling down ${maxScrolls} times`);
    }
  }
}


// Create and export singleton instance
const testHelpers = new TestHelpers();

// Backward compatibility: export as 'shared' as well
// TODO: Gradually migrate all tests to use 'testHelpers' instead of 'shared'
const shared = testHelpers;

export { testHelpers, shared };

