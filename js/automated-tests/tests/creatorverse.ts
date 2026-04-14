import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';


/**
 * Disco AI › Creatorverse › Creator Search Test Suite
 * Generated from TestRail Suite
 *
 * Pre-conditions (all tests):
 * - Guest or Registered User
 * - Creator Search experiment (roku_search_creator_tile_v1) is enabled
 *
 * Shared setup: launches the app once, searches for 'Watcher', and navigates
 * to the results grid. Individual tests assert on that shared state and
 * continue from where the previous test left off (C878864 clicks the tile
 * after C878861/C878862 have verified its presence and ranking).
 */
describe('Disco AI › Creatorverse › Creator Search', function () {
  let creatorName: string = 'Watcher';
  let searchResults: any[];

  before(async () => {
    // Launch app with Creator Search experiment enabled
    await testUtils.startApplicationAtPage('home', {
      deviceIdOverride: "roku_test_automation_creator_in_search",
      experimentOverrides: {
        roku_search_creator_tile: {
          roku_search_creator_tile_v1: {
            default: { "enabled": true }
          }
        }
      }
    });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to Search page
    await testUtils.goToPage('search');
    await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for trending search results grid', 10000);

    // Enter 'Watcher' in search and wait for results
    await ecp.sendText(creatorName);
    await utils.sleep(3000);

    // Navigate from keyboard to results grid and wait for content to load
    await testHelpers.navigateRightToSearchGrid();
    await testUtils.waitForGridContentToLoad('searchResultGrid', 15000);

    searchResults = await testUtils.getAllGridItemsContent('searchResultGrid');
  });

  /**
   * C878861 - Verify searching for creator name search result returns a Creator Page tile
   *
   * Test Steps:
   * 1. Launch Tubi app
   * 2. Navigate to Search page
   * 3. Enter 'Watcher' in search
   * 4. Verify at least one Creator Page tile (type = 'creator') appears in results
   */
  it('C878861 - Verify searching for creator name search result returns a Creator Page tile @search @creator', async () => {
    expect(searchResults.length).to.be.greaterThan(0, 'Search results should not be empty');

    const hasCreatorTile = searchResults.some((item: any) => item.type === 'creator');
    expect(hasCreatorTile).to.equal(true, 'Search results should contain a Creator Page tile');
  });

  /**
   * C878862 - Verify Creator Page tile ranked number 1
   *
   * Test Steps:
   * 1. Launch Tubi app
   * 2. Navigate to Search page
   * 3. Enter 'Watcher' in search
   * 4. Submit search query
   */
  it('C878862 - Verify Creator Page tile ranked number 1 @search @creator', async () => {
    // Verify the first search result is a Creator Page tile
    const firstSearchResult = await testUtils.getCurrentlyFocusedGridItemContent('searchResultGrid');
    expect(firstSearchResult.type).to.equal('creator', 'First search result should be a Creator Page tile');

    // Verify creator content titles follow after the creator tile
    const hasCreatorTitlesAfterCreatorTile = searchResults.slice(1).some((item: any) => item.type === 'video' || item.type === 'series');
    expect(hasCreatorTitlesAfterCreatorTile).to.equal(true, 'Creator titles should be ranked after the Creator Page tile');
  });

  /**
   * C878863 - Verify Creator tile UI layout
   *
   * Test Steps:
   * 1. Launch Tubi app
   * 2. Navigate to Search page
   * 3. Enter 'Watcher' in search
   * 4. Verify the AppItem grid tile is rendering a logo and title
   * 5. Verify the info panel shows a logo to the left of the creator name
   */
  it('C878863 - Verify Creator tile UI layout @search @creator', async () => {
    // Verify the AppItem grid tile is rendering a logo and title
    const appItemLogo = await testUtils.getNodeForElement('searchResultGridAppItemLogo');
    expect(appItemLogo.uri).to.be.a('string').and.not.be.empty;

    const appItemTitle = await testUtils.getNodeForElement('searchResultGridAppItemTitle');
    expect(appItemTitle.text).to.equal(creatorName, 'AppItem title should display the creator name');

    // Verify the info panel shows a logo to the left of the creator name
    const infoPanelTitleLogo = await testUtils.getNodeForElement('searchScreenInfoPanelTitleLogo');
    expect(infoPanelTitleLogo.uri).to.be.a('string').and.not.be.empty;

    const infoPanelTitle = await testUtils.getNodeForElement('searchScreenInfoPanelTitle');
    expect(infoPanelTitle.text).to.equal(creatorName, 'Info panel title should display the creator name');
  });

  /**
   * C878864 - Verify that clicking the Creator Page tile takes the user to the Creator Page
   *
   * Test Steps:
   * 1. Launch Tubi app
   * 2. Navigate to Search page
   * 3. Enter 'Watcher' in search
   * 4. Wait for search results to show the 'Watcher' Creator Page tile
   * 5. Select/click on the 'Watcher' Creator Page tile
   * 6. Verify the Creator Page (Collection Screen) opens with the creator name visible
   */
  it('C878864 - Verify that clicking the Creator Page tile takes the user to the Creator Page @search @creator', async () => {
    // Click on the Creator Page tile
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify the Creator Page (Collection Screen) opens
    await testUtils.waitForCurrentScreenToEqual('collectionScreen', 10000);

    // Verify creator name is displayed in the info panel
    await testUtils.waitForElementToShowOnScreen('collectionScreenCreatorName', 'Creator name label not visible', 10000);
    const creatorNameLabel = await testUtils.getNodeForElement('collectionScreenCreatorName');
    expect(creatorNameLabel.visible).to.equal(true, 'Creator name label should be visible');
    expect(creatorNameLabel.text).to.equal(creatorName, 'Creator name label should match the creator name');
  });

  /**
   * C2277742 - Verify when experiment is turned off, searching for creator name search does not return a Creator Page tile
   * 
   * Pre-conditions:
   * - Guest or Registered User
   * - Experiment is set to Control (roku_search_creator_tile_v1 disabled)
   *
   * Test Steps:
   * 1. Launch Tubi app
   * 2. Navigate to Search page
   * 3. Enter 'Watcher' in search
   * 4. Submit search query
   */
  it('C2277742 - Verify when experiment is turned off, searching for creator name search does not return a Creator Page tile @search @creator', async () => {
    await testUtils.startApplicationAtPage('home', {
      deviceIdOverride: "roku_test_automation_creator_in_search",
      experimentOverrides: {
        roku_search_creator_tile: {
          roku_search_creator_tile_v1: {
            default: { "enabled": false }
          }
        }
      }
    });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.goToPage('search');
    await testUtils.waitForElementToShowOnScreen('trendingSearchResultsGrid', 'Timed out waiting for trending search results grid', 10000);

    await ecp.sendText('Watcher');
    await utils.sleep(3000);

    await testHelpers.navigateRightToSearchGrid();
    await testUtils.waitForGridContentToLoad('searchResultGrid', 15000);

    const searchResults = await testUtils.getAllGridItemsContent('searchResultGrid');
    expect(searchResults.length).to.be.greaterThan(0, 'Search results should not be empty');

    const hasCreatorTile = searchResults.some((item: any) => item.type === 'creator');
    expect(hasCreatorTile).to.equal(false, 'Search results should NOT contain a Creator Page tile when experiment is disabled');
  });
});
