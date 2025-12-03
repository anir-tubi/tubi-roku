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
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from './test-utils';
import { moveToGrid } from './analytics/utils/helpers';


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
  public positionToRowCol(position: number, columns: number = 5): [number, number] {
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
  public async findContentPositionInGridThatContainsVideoPreview(gridId: any, hasVideoPreview: boolean = true, columnsPerRow: number = 5) {
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
  public async createHistory(seekTimeMs: number = 120000) {
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
    await testUtils.seekPlayerToRelativePosition('videoPlayerScreen', seekTimeMs, 'current');
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 15000);
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
  public async verifyPlayFromBeginning(maxPositionMs: number = 1000) {
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
  public async verifyResumeWithinRange(expectedPositionMs: number = 120000, toleranceMs: number = 5000) {
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
  public async verifySeekWithinRange(startPosition: number, expectedDelta: number = 30000, tolerance: number = 5000) {
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
  public async selectCategoriesFromSideNav(timeout: number = 15000): Promise<void> {
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
  public async navigateToCategories(timeout: number = 15000): Promise<void> {
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
  public async startAtHomeScreen(shouldCreateNewUser: boolean = true, user?: any) {
    const options = user ? { user } : { shouldCreateNewUser };
    await testUtils.startApplicationAtPage('home', options);
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
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
  public async openPageAndWaitForElement(page: any, element: any, timeout: number = 15000) {
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
  public async openSeriesScreenAndWaitUntilListIsFocused(shouldCreateNewUser: boolean = true) {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    await this.openSeries();
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');
  }

  /**
   * BACKWARD COMPATIBILITY: Opens Movies screen and waits until list is focused
   * 
   * @param shouldCreateNewUser - Whether to create new user (default: true)
   */
  public async openMoviesScreenAndWaitUntilListIsFocused(shouldCreateNewUser: boolean = true) {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser });
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
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
   *   - Must already be on home screen with homeScreenRowList focused
   * 
   * @example
   * // Navigate to movie on home screen
   * await testHelpers.navigateToMovieInHome();
   * // Now you're focused on a movie
   * await ecp.sendKeypress(ecp.Key.Ok); // Open detail screen
   */
  public async navigateToMovieInContainer() {
    const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    let colIndex = -1;
    for (const [index, item] of content.entries()) {
      if (item.type === 'v') {
        colIndex = index;
        break;
      }
    }
    if (colIndex === -1) {
      throw new Error('No movie found in current row of homeScreenRowList');
    }
    await ecp.sendKeypress(ecp.Key.Right, { count: colIndex });
  }

  /**
   * Navigates to a series/TV show on home screen
   * 
   * USE WHEN:
   *   - Need to navigate to series detail page
   *   - Testing series-specific features
   *   - Need to find a series (not a movie) on home screen
   * 
   * PREREQUISITES:
   *   - Must already be on home screen with homeScreenRowList focused
   * 
   * @example
   * // Navigate to series on home screen
   * await testHelpers.navigateToSeriesInHome();
   * // Now you're focused on a series
   * await ecp.sendKeypress(ecp.Key.Ok); // Open detail screen
   */
  public async navigateToSeriesInContainer() {
    const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('homeScreenRowList');
    let colIndex = -1;
    for (const [index, item] of content.entries()) {
      if (item.type === 's') {
        colIndex = index;
        break;
      }
    }
    if (colIndex === -1) {
      throw new Error('No series found in current row of homeScreenRowList');
    }
    await ecp.sendKeypress(ecp.Key.Right, { count: colIndex });
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
   * HELPER: Highlights My Stuff menu item in side nav (without selecting)
   * 
   * PATTERN: Used 28+ times in my-stuff.ts
   * 
   * @example
   * await testHelpers.highlightMyStuffMenuItem();
   * // My Stuff is highlighted but not selected yet
   */
  public async highlightMyStuffMenuItem() {
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementToFullyShowOnScreen('sideNavMenu' as any);
    await testUtils.jumpToRowWithTitle('sideNavMenu' as any, 'My Stuff');
    await testUtils.waitForElementToFullyShowOnScreen('myStuffLeftNavButton' as any);
  }

  /**
   * HELPER: Opens My Stuff page
   * 
   * @example
   * await testHelpers.openMyStuffPage();
   */
  public async openMyStuffPage() {
    await this.highlightMyStuffMenuItem();
    await ecp.sendKeypress(ecp.Key.Ok);
  }

  /**
   * HELPER: Jumps to Continue Watching row on home screen
   * 
   * PATTERN: Used 12+ times across multiple files
   * 
   * @param listElement - List element ID (default: 'homeScreenRowList')
   * 
   * @example
   * await testHelpers.jumpToContinueWatchingRow();
   * await testHelpers.jumpToContinueWatchingRow('customListElement');
   */
  public async jumpToContinueWatchingRow(listElement: any = 'homeScreenRowList') {
    await testUtils.jumpToRowWithTitle(listElement, 'Continue Watching');
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
  public async setParentalControls(level: 'littleKids' | 'olderKids' | 'teens' | 'adults', password: string = '111111', shouldDismiss: boolean = true) {
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
  public async enterPassword(password: string = '111111', handleKeyboard: boolean = true) {
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
   * const user = await shared.createUser();
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
  public async createHistoryForEvergreenMovie(user: any, contentId: number = 342067, watchTimeSeconds: number = 500) {
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
  public async createHistoryForEvergreenSeries(user: any, contentId: number = 300005163, watchTimeSeconds: number = 500) {
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
   * HELPER: Turns ON/OFF autoplay (uses generic toggleSetting)
   */
  public async setAutoplay(enabled: boolean) {
    await this.toggleSetting('autoplayNextVideoMenu', enabled ? 0 : 1, 'AutoplayPreviewMenu');
  }

  /**
   * HELPER: Turns ON/OFF video preview (uses generic toggleSetting)
   */
  public async setPreview(enabled: boolean) {
    await this.toggleSetting('autoplayPreviewMenu', enabled ? 0 : 1);
  }

  /**
   * BACKWARD COMPATIBILITY: Keep old method names
   */
  public async turnOnAutoplay() { await this.setAutoplay(true); }
  public async turnOffAutoplay() { await this.setAutoplay(false); }
  public async turnOnPreview() { await this.setPreview(true); }
  public async turnOffPreview() { await this.setPreview(false); }

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
  public async navigate(direction: 'Up' | 'Down' | 'Left' | 'Right', count: number = 1, waitForElement?: any, waitTime: number = 200) {
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
  public async pressKeyAndWait(key: string, count: number = 1, waitForElement?: any, waitForScreen?: any) {
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
  public async jumpToRowAndSelect(listElement: any, rowTitle: string, shouldSelect: boolean = false, confirmElement?: any) {
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
  public async waitForElementVisibleAndFocused(elementId: any, timeout: number = 15000) {
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
  public async navigateToGridPosition(gridElement: string, targetRow: number, targetCol: number, startRow: number = 0, startCol: number = 0) {
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
  public generateTestEmail(prefix: string = 'build_roku', domain: string = 'tubi.tv'): string {
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
   * HELPER: Starts playback and waits for playing state
   * 
   * @param playerElement - Player element ID (default: 'videoPlayerScreen')
   * @param timeout - Timeout in ms (default: 15000)
   * 
   * @example
   * await testHelpers.startPlaybackAndWait();
   * await testHelpers.startPlaybackAndWait('previewVideoPlayer', 10000);
   */
  public async startPlaybackAndWait(playerElement: any = 'videoPlayerScreen', timeout: number = 15000) {
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
  public async exitPlayback(expectedScreen: any = 'detailScreen', backCount: number = 1) {
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
  public async jumpToButtonById(buttonListElementId: any, buttonId: string, waitForFocus: boolean = true): Promise<number> {
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
   * @param rowListElementId - Element ID of the RowList (e.g., 'movieScreenRowList', 'homeScreenRowList')
   * @param targetRow - Target row index (0-based)
   * @param targetCol - Target column index (0-based)
   * 
   * @example
   * // Navigate to row 2, column 3 in home screen
   * await testHelpers.jumpToRowListPosition('homeScreenRowList', 2, 3);
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
   * @param rowListElementId - Element ID of the RowList (e.g., 'movieScreenRowList', 'homeScreenRowList')
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
   * const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('homeScreenRowList', true);
   * if (position.length === 0) {
   *   throw new Error('Could not find content with video preview');
   * }
   */
  public async findContentPositionInRowListThatContainsVideoPreview(
    rowListElementId: any,
    hasVideoPreview: boolean = true,
    maxRowsToSearch: number = 5
  ): Promise<[number, number] | []> {
    // Get all content grouped by row
    const rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow(rowListElementId);

    // Search through rows up to maxRowsToSearch
    for (let rowIndex = 0; rowIndex < Math.min(rowsContent.length, maxRowsToSearch); rowIndex++) {
      const rowContent = rowsContent[rowIndex];

      // Search through items in this row
      for (let colIndex = 0; colIndex < rowContent.length; colIndex++) {
        const item = rowContent[colIndex];
        const videoPreviewUrl = item.video_preview_url?.trim();

        // Check if item matches the video preview criteria
        if (hasVideoPreview && videoPreviewUrl.length > 0) {
          return [rowIndex, colIndex];
        } else if (!hasVideoPreview && videoPreviewUrl.length === 0) {
          return [rowIndex, colIndex];
        }
      }
    }

    // Return empty array if not found
    return [];
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
  public async verifyElementVisible(elementId: any, expectedValue: boolean = true) {
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
  public async verifyElementText(elementId: any, expectedText: string, shouldContain: boolean = false) {
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
    const kidsRatings = ['G', 'TV-Y', 'TV-Y7', 'TV-G', 'PG'];
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
  public async verifyAutoplayUIShowing(countdownElement: any = 'countDownAutoPlay', secondsElement: any = 'countDownSecondsAutoPlay', verifyPlayerSize: boolean = false) {
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
  public async verifyAutoplayUINotShowing(countdownElement: any = 'autoplayCountdownTimerSection', verifyPlayerSize: boolean = false) {
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
  public async triggerMovieAutoplay(shouldCreateNewUser: boolean = true, verifyPlayerSize: boolean = false) {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser });
    await this.setAutoplay(true);
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
  public async validateAutoplayNotTriggered(verifyPlayerSize: boolean = false) {
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
  public async completeAgeGate(age: string = '20', acceptButton: any = 'continueWatchingConsentPageAcceptButton') {
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
  public async createHistoryForSingleTitle(user: any, contentType: string, rating: string = 'PG', watchTime: number = 500, hasVideoPreview: boolean = false) {
    let query = user.getContent().ofContentType(contentType).withRating(rating);

    if (contentType === 'series' && hasVideoPreview) {
      query = query.hasVideoPreview();
    }

    const content = await query.retrieve({ limit: 1 });
    await user.addContentToViewHistory(content, watchTime);
  }
}


// Create and export singleton instance
const testHelpers = new TestHelpers();

// Backward compatibility: export as 'shared' as well
// TODO: Gradually migrate all tests to use 'testHelpers' instead of 'shared'
const shared = testHelpers;

export { testHelpers, shared };

