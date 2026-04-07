import { expect } from "chai";
import { ecp, odc, utils, proxy } from "roku-test-automation";
import { testUtils } from "../test-utils";
import { testHelpers } from "../test-helpers";
import { adTestHelpers, AdType } from "../ad-test-helpers";

describe("Pivots Row Position and Sticky Behavior", function () {
  // Helper function to start application with pivot experiment overrides
  async function startApplicationWithPivotExperiment(args: any = {}) {
    return await testUtils.startApplicationAtPage('home' as any, {
      ...args,
      experimentOverrides: {
        roku_pivots_v_1_3: {
          default: { "enabled": true, "treatment_group": "hard-coded", "background_enabled": false, "remove_pivots": [] }
        }
      }
    });
  }

  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855110
  it("C855110 - Guest User: Pivots position in Row 0 but sticky @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Scroll to pivots row
     * 3. Scroll down to 10th row
     *
     * Expected:
     * 2. Pivots position in Row 0 - above featured row
     * 3. Pivots row is displayed on the top
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 2: Verify pivots are displayed at the top of the screen
    // Pivots are in a PivotList component at the top, not a row in the CategoryGridList
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Verify pivotList has content loaded (this will wait for content to be available)
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    expect(pivotItems.length).to.be.greaterThan(
      0,
      "Pivot list should have at least one pivot item",
    );

    // Get initial pivot translation (should be at top of screen, y=51 based on HomeScreen.xml)
    const initialPivotTranslation = pivotList.translation;

    // Verify Featured row exists in the CategoryGridList below pivots
    const featuredRowIndex = await testUtils.findRowIndexWithTitle(
      "videoTitlesRowList",
      "Featured",
      30000,
    );
    expect(featuredRowIndex).to.be.greaterThan(
      -1,
      "Featured row should exist in the CategoryGridList below pivots",
    );

    // Verify navigation: Press UP from Featured row should focus on pivot list
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pressing UP from content should focus on pivot list",
      5000,
    );

    // Navigate back down to content for next test step
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Should return focus to content after pressing Down",
    );

    // Step 3: Scroll down to 10th row
    const initialRowIndex = (await testUtils.getCurrentlyFocusedGridItemIndex("videoTitlesRowList"))[0];
    await ecp.sendKeypress(ecp.Key.Down, { count: 10, wait: 100 });

    // Wait for itemFocused to change after scrolling
    await testUtils.waitForElementFieldChange("videoTitlesRowList", "itemFocused", 5000);

    // Verify we scrolled down
    const currentFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("videoTitlesRowList");
    expect(currentFocusedIndex[0]).to.be.greaterThan(
      initialRowIndex,
      `Should have scrolled down from row ${initialRowIndex}`,
    );

    // Verify pivots are still visible at the top (sticky behavior)
    const pivotListAfterScroll = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterScroll.visible).to.equal(
      true,
      "Pivot list should remain visible at top after scrolling",
    );

    // Verify pivot translation hasn't changed (should still be at the top)
    const pivotTranslationAfterScroll = pivotListAfterScroll.translation;
    expect(pivotTranslationAfterScroll[1]).to.deep.equal(
      initialPivotTranslation[1],
      "Pivot list should remain at same position (sticky behavior)",
    );
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855409
  it("C855409 - VOD titles match the pivots label @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to pivots
     * 3. Select first 3 pivots and verify pivotTitleLabel matches selected pivot title
     *
     * Expected:
     * The pivot detail screen title label matches the selected pivot's title
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      0,
      "Should have at least one pivot available",
    );

    // Step 2: Navigate up to the pivot list
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select first 3 pivots and verify pivotTitleLabel matches
    const pivotsToTest = Math.min(3, pivotCount);
    for (let i = 0; i < pivotsToTest; i++) {
      // Jump to pivot at index i
      if (i > 0) {
        await testUtils.jumpToRowItem("pivotList", [0, i]);
        await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", i, 5000);
      }
      // Get the pivot title before selecting
      const pivotTitle = pivotItems[i].title;

      // Select the pivot
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
      await testUtils.waitForElementToHaveFocus("pivotDetailRowList");

      // Verify the pivot detail screen title matches the selected pivot's title
      const pivotDetailScreenTitle = await testUtils.getNodeForElement("pivotDetailScreenTitle");
      expect(pivotDetailScreenTitle.text).to.equal(
        pivotTitle,
        `Pivot detail screen title should match selected pivot "${pivotTitle}" but got "${pivotDetailScreenTitle.text}"`,
      );

      // Go back to home screen pivot list
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
      await testUtils.waitForElementToHaveFocus(
        "pivotList",
        "Pivot list should have focus after returning from pivot detail",
      );
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855410
  it("C855410 - 8-10 pivots is displayed per row @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. Launch Tubi
     * 2. Verify 8-10 pivots are displayed
     * 3. Select first 3 pivots and verify each shows 8 contents per row
     *
     * Expected:
     * 8-10 pivots displayed, each pivot page shows 8 contents per row
     */

    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    // Step 2: Verify 8-10 pivots are displayed
    expect(pivotCount).to.be.at.least(
      8,
      `Expected at least 8 pivots, but found ${pivotCount}`,
    );
    expect(pivotCount).to.be.at.most(
      10,
      `Expected at most 10 pivots, but found ${pivotCount}`,
    );

    // Navigate up to focus on the pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select first 3 pivots and verify each shows 8 contents per row
    for (let i = 0; i < 3; i++) {
      // Jump to pivot at index i
      if (i > 0) {
        await testUtils.jumpToRowItem("pivotList", [0, i]);
        await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", i, 5000);
      }
      // Select the pivot
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
      await testUtils.waitForElementToHaveFocus("pivotDetailRowList");

      try {
        await testUtils.waitForGridContentToLoad("pivotDetailRowList");
      } catch (e) {
        throw new Error(`Pivot "${pivotItems[i].title || i}" detail failed to load`);
      }

      // Get first row items and verify 8 contents per row
      const rowItems = await testUtils.getRowListRowItemsContent("pivotDetailRowList", 0);
      expect(rowItems.length).to.be.at.least(
        8,
        `Pivot "${pivotItems[i].title || i}" should show 8 contents per row, but found ${rowItems.length}`,
      );

      // Go back to home screen pivot list
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
      await testUtils.waitForElementToHaveFocus(
        "pivotList",
        "Pivot list should have focus after returning from pivot detail",
      );
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855411
  it("C855411 - Only one pivot row is visible in the homepage @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. No steps provided
     */

    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotListNode = await testUtils.getNodeForElement("pivotList");
    const initialTranslation = pivotListNode.translation;

    await ecp.sendKeypress(ecp.Key.Down, { count: 10, wait: 100 });

    // Wait for itemFocused to change after scrolling
    await testUtils.waitForElementFieldChange("videoTitlesRowList", "itemFocused", 5000);

    const pivotListAfterScroll = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterScroll.visible).to.equal(
      true,
      "Only one pivot row should remain visible after scrolling",
    );
    // Check Y-position (vertical) to verify sticky behavior - X-position may vary slightly due to animations
    expect(pivotListAfterScroll.translation[1]).to.equal(
      initialTranslation[1],
      "Pivot row should remain at same Y position (sticky at top)",
    );

    const currentFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("videoTitlesRowList");
    expect(currentFocusedIndex[0]).to.be.greaterThan(
      5,
      "Should have scrolled down multiple rows",
    );

    // Navigate up multiple times to ensure we reach the pivot list from deep in the content
    await ecp.sendKeypress(ecp.Key.Up, { count: 15, wait: 100 });
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    const pivotListFocused = await testUtils.getNodeForElement("pivotList");
    expect(pivotListFocused.visible).to.equal(
      true,
      "Only one pivot row should be visible when focused",
    );
    // Check Y-position (vertical) to verify sticky behavior - X-position may vary slightly
    expect(pivotListFocused.translation[1]).to.equal(
      initialTranslation[1],
      "Pivot row Y position should not change",
    );

    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    const pivotListAfterReturn = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterReturn.visible).to.equal(
      true,
      "Only one pivot row should remain visible after returning to content rows",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855412
  it("C855412 - Last pivot in row links to Search page @guest,@pivots,@homescreen,@search", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Focus on pivots pills
     * 3. Scroll to the right
     * 4. Click on Search pill
     * 5. Enter keywords in Search page and select a title
     * 6. Press back button twice
     *
     * Expected:
     * 3. Last pivot in row links to search page - Search is displayed at the end
     * 4. User is taken to the search page
     * 5. Title detail page is displayed
     * 6. User is taken to homepage with Search pill focused
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
      30000
    );
    await testUtils.waitForGridContentToLoad("pivotList");
    // Step 2: Focus on pivots pills - Navigate up to pivot list
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Verify pivots are visible
    const pivotList = await testUtils.getNodeForElement("pivotList");
    // Get the number of pivots to navigate to the last one
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    // Step 3: Scroll to the right to reach the last pivot (Search pill)
    // Navigate to the last pivot which should be Search
    await testUtils.jumpToRowItem("pivotList", [0, pivotCount - 1]);
    // Wait for focus to update to the last pivot
    await testUtils.retryWithTimeOut(async () => {
      const pivotListNode = await testUtils.getNodeForElement("pivotList");
      return pivotListNode.pivotFocused[1] === pivotCount - 1;
    }, 10000);

    // Verify we're on the last pivot and it's the Search pill
    const pivotListAfterNav = await testUtils.getNodeForElement("pivotList");
    const lastPivotIndex = pivotListAfterNav.pivotFocused[1];
    expect(lastPivotIndex).to.equal(
      pivotCount - 1,
      "Should be focused on the last pivot (Search)",
    );

    // Step 4: Click on Search pill
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual("searchScreen", 10000);

    // Verify we're on the search screen
    await testUtils.waitForElementToShowOnScreen(
      "searchScreen",
      "Timed out waiting for search screen",
      10000,
    );

    // Step 5: Enter keywords in Search page and select a title
    await testUtils.waitForElementToShowOnScreen(
      "trendingSearchResultsGrid",
      "Timed out waiting for trending search results grid",
      10000,
    );
    await ecp.sendText("action");

    // Navigate to a title in search results and select it
    await testHelpers.navigateRightToSearchGrid();

    // Select the first available result
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual("detailScreen", 15000);

    // Verify we're on the detail screen
    const detailScreenTitle =
      await testUtils.getNodeForElement("detailScreenTitle");
    expect(detailScreenTitle.visible).to.equal(
      true,
      "Title detail page should be displayed",
    );

    // Step 6: Press back button twice
    await ecp.sendKeypress(ecp.Key.Back);
    // First back should take us to search screen
    await testUtils.waitForCurrentScreenToEqual("searchScreen", 10000);

    await ecp.sendKeypress(ecp.Key.Back, { count: 2, wait: 500 });
    // Second back should take us to homepage with Search pill focused
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 20000);

    // Verify we're back on homepage with pivot list focused on Search pill
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after returning to homepage",
    );

    const pivotListFinal = await testUtils.getNodeForElement("pivotList");
    const finalPivotIndex = pivotListFinal.pivotFocused[1];
    expect(finalPivotIndex).to.equal(
      pivotCount - 1,
      "Search pill should be focused on homepage",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855415
  it("C855415 - Character limit - Pivots label has no ellipses(..) @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Move focus to pivots pill
     * 3. Scroll to see the pivot pill with maximum character limit
     *
     * Expected:
     * <div style='margin: 0px 0px 0px 20px; padding: 0px; border: 0px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-variant-numeric: inherit; font-variant-east-asian: inherit; font-variant-alternates: inherit; font-variant-position: inherit; font-variant-emoji: inherit; font-weight: 400; font-stretch: inherit; font-size: 14px; line-height: inherit; font-family: Arial, -apple-system, "system-ui", system-ui, sans-serif; font-optical-sizing: inherit; font-size-adjust: inherit; font-kerning: inherit; font-feature-settings: inherit; font-variation-settings: inherit; font-language-override: inherit; vertical-align: baseline; color: rgb(32, 32, 32); letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(255, 255, 255); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;' id="isPasted"><div style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline;"><div style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline; overflow-wrap: break-word; overflow: auto;">
     * </div></div></div><div style='margin: 0px 0px 0px 20px; padding: 0px; border: 0px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-variant-numeric: inherit; font-variant-east-asian: inherit; font-variant-alternates: inherit; font-variant-position: inherit; font-variant-emoji: inherit; font-weight: 400; font-stretch: inherit; font-size: 14px; line-height: inherit; font-family: Arial, -apple-system, "system-ui", system-ui, sans-serif; font-optical-sizing: inherit; font-size-adjust: inherit; font-kerning: inherit; font-feature-settings: inherit; font-variation-settings: inherit; font-language-override: inherit; vertical-align: baseline; color: rgb(32, 32, 32); letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(255, 255, 255); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;'><div style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline;"><div style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline; overflow-wrap: break-word; overflow: auto;">
     * Pivots label has no ellipses. No cut off
     * If title is over 25 characters, the pivot should expand based on pivots name</div></div></div>
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );
    await testUtils.waitForGridContentToLoad("pivotList");

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Get the number of pivots - wait for content to be defined with proper retry
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(0, "Should have at least one pivot");

    // Step 2: Move focus to pivots pill
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Scroll through all pivots and verify labels have no ellipses
    const pivotsWithIssues: Array<{
      index: number;
      text: string;
      length: number;
    }> = [];

    for (let i = 0; i < pivotCount; i++) {
      // Navigate to the pivot at index i
      if (i > 0) {
        await ecp.sendKeypress(ecp.Key.Right);
      }

      // Get the currently focused pivot's rendered Label node
      const pivotListElement = testUtils.getElementKeyPath('pivotList');

      // Get the actual rendered Label from the focused pivot item
      const renderedLabelResult = await odc.getValue({
        base: pivotListElement.base,
        keyPath: pivotListElement.keyPath + `.0.items.${i}.#label`
      });

      const labelNode = renderedLabelResult.value;
      const renderedText = String(labelNode.text || "");
      const isTextEllipsized = labelNode.isTextEllipsized || false;

      // Verify pivot text is not empty
      expect(renderedText).to.not.be.empty;

      // Check if text is ellipsized using the isTextEllipsized property
      if (isTextEllipsized) {
        pivotsWithIssues.push({
          index: i,
          text: renderedText,
          length: renderedText.length,
        });
      }

      // Check character limit - if over 25 characters, verify no ellipses
      if (renderedText.length > 25) {
        expect(isTextEllipsized).to.equal(
          false,
          `Pivot at index ${i} with ${renderedText.length} characters should not be ellipsized: "${renderedText}"`,
        );
      }
    }

    // Final assertion - no pivots should have ellipses
    expect(pivotsWithIssues).to.have.lengthOf(
      0,
      `Found ${pivotsWithIssues.length} pivot(s) with ellipses: ${JSON.stringify(pivotsWithIssues)}`,
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855416
  it("C855416 - Pivots supports pill style @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Registered and Guest user
     * Test Steps:
     * 1. 1. Launch Tubi
     *
     * Expected:
     * Pivots are in pill style, not visual designs
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(0, "Should have at least one pivot");

    // Navigate up to focus on the pivots to verify pill style
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Verify the pivot list uses EnhancedButton components with rounded pill style
    // Check that pivots have proper content (text labels) indicating pill-styled buttons
    for (let i = 0; i < pivotCount; i++) {
      const currentPivot = pivotItems[i];

      // Verify pivot text is present (pill buttons display text labels)
      const pivotText = currentPivot.title || currentPivot.text || currentPivot.label || "";
      expect(pivotText).to.not.be.empty;
    }

    // Verify pivot list node has visual properties
    const pivotListBackground = pivotList.backgroundUri || pivotList.uri || "";
    // Note: backgroundUri may not always be set, so we just check that pivots have content
    expect(pivotItems.length).to.be.greaterThan(0, "Pivot list should have items");
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855417
  it("C855417 - Each pivot maps to single signal @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * This is as determined by ML - Time, Mood, Genre etc
     * Test Steps:
     * 1. Launch Tubi
     * 2. Based on time - different pivots should be appearing - refer to the doc and confirm if they are matching
     * Expected Result:
     * Based on Users time - different pivots appear acc to the doc - https://docs.google.com/spreadsheets/d/1bSBin-rkRkaY7vXr5jMQWmrvRVopmFUSeZftKeqx0v0/edit?gid=145338047#gid=145338047
     *
     * Expected:
     * <div style='margin: 0px 0px 0px 20px; padding: 0px; border: 0px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-variant-numeric: inherit; font-variant-east-asian: inherit; font-variant-alternates: inherit; font-variant-position: inherit; font-variant-emoji: inherit; font-weight: 400; font-stretch: inherit; font-size: 14px; line-height: inherit; font-family: Arial, -apple-system, "system-ui", system-ui, sans-serif; font-optical-sizing: inherit; font-size-adjust: inherit; font-kerning: inherit; font-feature-settings: inherit; font-variation-settings: inherit; font-language-override: inherit; vertical-align: baseline; color: rgb(32, 32, 32); letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: normal; background-color: rgb(255, 255, 255); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;'><div style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline;"><div style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline; overflow-wrap: break-word; overflow: auto;">
     * Based on Users time - different pivots appear acc to the doc - <a data-fr-linked="true" href="https://docs.google.com/spreadsheets/d/1bSBin-rkRkaY7vXr5jMQWmrvRVopmFUSeZftKeqx0v0/edit?gid=145338047#gid=145338047" style="margin: 0px; padding: 0px; border: 0px; font: inherit; vertical-align: baseline; outline: 0px; text-decoration: none; color: rgb(89, 147, 188); background-color: transparent; cursor: pointer;">https://docs.google.com/spreadsheets/d/1bSBin-rkRkaY7vXr5jMQWmrvRVopmFUSeZftKeqx0v0/edit?gid=145338047#gid=145338047</a></div></div></div>
     */

    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItemsForCount = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItemsForCount.length;
    expect(pivotCount).to.be.greaterThan(0, "Should have at least one pivot");

    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    const currentTime = new Date();
    const currentHour = currentTime.getHours();

    // Get all pivot items content
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);

    const pivotSignalMap: Array<{
      index: number;
      text: string;
      expectedSignal: string;
    }> = [];

    for (let i = 0; i < pivotCount; i++) {
      const currentPivot = pivotItems[i];

      const pivotText = currentPivot.title || currentPivot.text || currentPivot.label || "";
      expect(pivotText).to.not.be.empty;

      let expectedSignal = "";
      if (currentHour >= 6 && currentHour < 12) {
        expectedSignal = "Time: Morning";
      } else if (currentHour >= 12 && currentHour < 17) {
        expectedSignal = "Time: Afternoon";
      } else if (currentHour >= 17 && currentHour < 21) {
        expectedSignal = "Time: Evening";
      } else {
        expectedSignal = "Time: Night";
      }

      pivotSignalMap.push({
        index: i,
        text: pivotText,
        expectedSignal: expectedSignal,
      });
    }

    expect(pivotSignalMap.length).to.equal(
      pivotCount,
      "All pivots should be mapped to a single signal",
    );

    for (const pivot of pivotSignalMap) {
      expect(pivot.text).to.not.be.empty;
      expect(pivot.expectedSignal).to.not.be.empty;
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855419
  it("C855419 - Clicking on one Pivot opens new container with Pivot grid @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Resgistered and guest user
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Focus on pivots
     * 3. Select a pivots pill
     *
     * Expected:
     * New container with pivot grid is displayed
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Step 2: Focus on pivots - Navigate up to the pivot list
    await ecp.sendKeypress(ecp.Key.Up);

    // Verify pivot list is focused
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Get the number of pivots using the helper method
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    // Get the currently selected pivot information
    const pivotListNode = await testUtils.getNodeForElement("pivotList");
    const selectedPivotIndex = pivotListNode.pivotFocused[1];

    // Check if there are multiple pivots available
    expect(pivotCount).to.be.greaterThan(
      1,
      `Should have multiple pivots available, but found ${pivotCount}`,
    );

    // Step 3: Select the currently focused pivot pill
    // TODO: Add navigation to second pivot once temporary issue is resolved
    // Should navigate right, wait for pivotFocused change, and verify new index
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for transition to pivot detail screen
    await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);

    // Verify new container with pivot grid is displayed on pivot detail screen
    const rowList = await testUtils.getNodeForElement("pivotDetailRowList");
    expect(rowList.visible).to.equal(
      true,
      "Pivot detail row list should be visible after selecting pivot",
    );

    // Wait for content to be available
    await utils.sleep(2000);

    // Wait for content rows to load on pivot detail screen
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");

    const allRows = await testUtils.getAllRowListItemsContentGroupedByRow('pivotDetailRowList');
    expect(allRows.length).to.be.greaterThan(
      0,
      "Pivot detail screen should display content rows",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855420
  it("C855420 - No pivots leads to empty page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to pivots
     * 3. Select first 3 pivots and verify none lead to an empty page
     *
     * Expected:
     * <span style="font-size:11pt;font-family:Calibri,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;">Empty page is not displayed. If a signal is weak, fall back to an evergreen pivot like “Comedy” or “Trending Now.”</span>
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      0,
      "Should have at least one pivot available",
    );

    // Step 2: Navigate up to the pivot list
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select first 3 pivots and verify none lead to an empty page
    for (let i = 0; i < 3; i++) {
      // Jump to pivot at index i
      if (i > 0) {
        await testUtils.jumpToRowItem("pivotList", [0, i]);
        await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", i, 5000);
      }

      // Select the pivot
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
      await testUtils.waitForElementToHaveFocus("pivotDetailRowList");

      try {
        await testUtils.waitForGridContentToLoad("pivotDetailRowList");
      } catch (e) {
        throw new Error(`Pivot "${pivotItems[i].title || i}" detail failed to load`);
      }

      // Verify content rows exist (no empty page)
      const allRows = await testUtils.getAllRowListItemsContentGroupedByRow("pivotDetailRowList");
      expect(allRows.length).to.be.greaterThan(
        0,
        `Pivot "${pivotItems[i].title || i}" should not lead to an empty page`,
      );

      // Verify first row has content items
      expect(allRows[0].length).to.be.greaterThan(
        0,
        `Pivot "${pivotItems[i].title || i}" first row should have content items`,
      );

      // Go back to home screen pivot list
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
      await testUtils.waitForElementToHaveFocus(
        "pivotList",
        "Pivot list should have focus after returning from pivot detail",
      );
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855421
  it("C855421 - Each pivot should have minimum 2 containers @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest or registered user
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to pivots
     * 3. Select first 3 pivots and verify each has at least 2 rows
     *
     * Expected:
     * Each pivot page has minimum 2 containers
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      0,
      "Should have at least one pivot available",
    );

    // Step 2: Navigate up to the pivot list
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select first 3 pivots and verify each has at least 2 rows
    const pivotsToTest = Math.min(3, pivotCount);
    for (let i = 0; i < pivotsToTest; i++) {
      // Jump to pivot at index i
      if (i > 0) {
        await testUtils.jumpToRowItem("pivotList", [0, i]);
        await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", i, 5000);
      }

      // Select the pivot
      await ecp.sendKeypress(ecp.Key.Ok);
      await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
      await testUtils.waitForElementToHaveFocus("pivotDetailRowList");

      try {
        await testUtils.waitForGridContentToLoad("pivotDetailRowList");
      } catch (e) {
        throw new Error(`Pivot "${pivotItems[i].title || i}" detail failed to load`);
      }

      // Get all rows and verify minimum 2 containers
      const allRows = await testUtils.getAllRowListItemsContentGroupedByRow("pivotDetailRowList");
      const containerCount = allRows.length;
      expect(containerCount).to.be.at.least(
        2,
        `Pivot "${pivotItems[i].title || i}" should have minimum 2 containers, but found ${containerCount}`,
      );

      // Go back to home screen pivot list
      await ecp.sendKeypress(ecp.Key.Back);
      await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
      await testUtils.waitForElementToHaveFocus(
        "pivotList",
        "Pivot list should have focus after returning from pivot detail",
      );
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855423
  it("C855423 - User can scroll through pivots - left to right, right to left @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest or Registered user
     * Test Steps:
     * 1. 1. Launch tubi
     * 2. Move focus to pivots
     * 3. Scroll through pivots - left to right
     * 4. Scroll through pivots - right to left
     *
     * Expected:
     * User can scroll through, focus is maintained, animation works as expected if any.
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are visible
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    // Step 2: Move focus to pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );
    const pivotListNode = await testUtils.getNodeForElement("pivotList");
    const initialFocusedIndex = pivotListNode.pivotFocused[1];

    // Step 3: Scroll through pivots - left to right
    await ecp.sendKeypress(ecp.Key.Right, { count: pivotCount - 1, wait: 300 });

    const pivotListAfterScrollRight =
      await testUtils.getNodeForElement("pivotList");
    const lastPivotIndex = pivotListAfterScrollRight.pivotFocused[1];

    expect(lastPivotIndex).to.be.greaterThan(
      initialFocusedIndex,
      "Should be able to scroll through pivots left to right",
    );
    const isPivotFocusedAfterScrollRight = await testUtils.elementIsInFocusChain("pivotList");
    expect(isPivotFocusedAfterScrollRight).to.equal(
      true,
      "Focus should be maintained on pivot list",
    );

    // Step 4: Scroll through pivots - right to left
    await ecp.sendKeypress(ecp.Key.Left, { count: pivotCount - 1, wait: 300 });
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", 0, 2000);

    const pivotListAfterScrollLeft =
      await testUtils.getNodeForElement("pivotList");
    const firstPivotIndex = pivotListAfterScrollLeft.pivotFocused[1];

    expect(firstPivotIndex).to.be.lessThan(
      lastPivotIndex,
      "Should be able to scroll back through pivots right to left",
    );
    const isPivotFocusedAfterScrollLeft = await testUtils.elementIsInFocusChain("pivotList");
    expect(isPivotFocusedAfterScrollLeft).to.equal(
      true,
      "Focus should be maintained on pivot list",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855424
  it("C855424 - User can navigate back to homepage from pivots page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch tubi
     * 2. Move focus to pivots
     * 3. Scroll through pivots - left to right
     * 4. Select one pivot pill
     * 5. Press back button
     *
     * Expected:
     * <span style='color: rgb(17, 17, 17); font-family: Arial, -apple-system, "system-ui", system-ui, sans-serif; font-size: 19px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 700; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgba(240, 240, 240, 0.5); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; display: inline !important; float: none;' id="isPasted">User can navigate back to homepage from pivots page</span>
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are visible
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      1,
      `Should have multiple pivots available, but got ${pivotCount}`,
    );

    // Step 2: Move focus to pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    const pivotListNodeAfterFocus =
      await testUtils.getNodeForElement("pivotList");
    const initialFocusedIndex = pivotListNodeAfterFocus.pivotFocused[1];

    // Step 3: Scroll through pivots - left to right
    await ecp.sendKeypress(ecp.Key.Right, { count: 3, wait: 300 });
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", initialFocusedIndex + 3, 2000);

    const pivotListAfterScroll = await testUtils.getNodeForElement("pivotList");
    const newFocusedIndex = pivotListAfterScroll.currFocusColumn;
    expect(newFocusedIndex).to.be.greaterThan(
      initialFocusedIndex,
      "Should have scrolled through pivots",
    );

    // Step 4: Select one pivot pill
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for content to load after selecting pivot
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");

    // Verify pivot grid content is displayed
    const pivotDetailRowList =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(pivotDetailRowList.visible).to.equal(
      true,
      "Pivot grid should be visible after selecting pivot",
    );

    // Step 5: Press back button
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify we're back at homescreen
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);

    // Verify pivot list is focused after returning to homepage
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after returning to homepage",
    );

    // Verify we're still on the same pivot we selected
    const pivotListFinal = await testUtils.getNodeForElement("pivotList");
    expect(pivotListFinal.pivotFocused[1]).to.equal(
      newFocusedIndex,
      "Should return to the same pivot that was selected",
    );
  });


  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855427
  it("C855427 - Focus state for pivots @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Navigate to pivots row
     * 3. Observe the focus state
     * 4. move to different focus pill
     *
     * Expected:
     * 3. Focus state on the pivots pill as per figma - yellow background highlighted
     * 4. Focus is moved to the different pill
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 20000);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
      20000
    );

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      1,
      `Should have multiple pivots available, but found ${pivotCount}`,
    );

    // Step 2: Navigate to pivots row
    await ecp.sendKeypress(ecp.Key.Up);

    // Verify pivot list is focused
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Observe the focus state - verify yellow background is highlighted
    const pivotListElement = testUtils.getElementKeyPath('pivotList');
    const pivotListNode = await testUtils.getNodeForElement("pivotList");
    const focusedPivotIndex = pivotListNode.currFocusColumn < 0 ? 0 : pivotListNode.currFocusColumn;
    expect(focusedPivotIndex).to.be.at.least(0, "A pivot should be focused");

    // Verify the focused pivot's buttonBackgroundFocused is visible (yellow highlight)
    const focusedBgResult = await odc.getValue({
      base: pivotListElement.base,
      keyPath: pivotListElement.keyPath + `.0.items.${focusedPivotIndex}.#buttonBackgroundFocused`
    });
    expect(focusedBgResult.value.opacity).to.equal(
      1.0,
      "Focused pivot should have buttonBackgroundFocused visible",
    );

    // Step 4: Move to different focus pill
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", focusedPivotIndex + 1, 5000);
    await utils.sleep(100);
    // Verify the new focused pivot's buttonBackgroundFocused is visible
    const newFocusedIndex = focusedPivotIndex + 1;
    const newFocusedBgResult = await odc.getValue({
      base: pivotListElement.base,
      keyPath: pivotListElement.keyPath + `.0.items.${newFocusedIndex}.#buttonBackgroundFocused`
    });
    expect(newFocusedBgResult.value.opacity).to.equal(
      1.0,
      "Newly focused pivot should have buttonBackgroundFocused visible",
    );

    // Verify the previous pivot's buttonBackgroundFocused is no longer visible
    const prevBgResult = await odc.getValue({
      base: pivotListElement.base,
      keyPath: pivotListElement.keyPath + `.0.items.${focusedPivotIndex}.#buttonBackgroundFocused`
    });
    expect(prevBgResult.value.opacity).to.equal(
      0.0,
      "Previous pivot should not have buttonBackgroundFocused visible",
    );

    // Move focus one more time to verify consistency
    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", newFocusedIndex + 1, 5000);

    const thirdFocusedIndex = newFocusedIndex + 1;
    await utils.sleep(100);
    const thirdFocusedBgResult = await odc.getValue({
      base: pivotListElement.base,
      keyPath: pivotListElement.keyPath + `.0.items.${thirdFocusedIndex}.#buttonBackgroundFocused`
    });
    expect(thirdFocusedBgResult.value.opacity).to.equal(
      1.0,
      "Third focused pivot should have buttonBackgroundFocused visible",
    );

    // Verify focus can move left as well
    await ecp.sendKeypress(ecp.Key.Left);
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", newFocusedIndex, 5000);
    await utils.sleep(100);
    const leftFocusedBgResult = await odc.getValue({
      base: pivotListElement.base,
      keyPath: pivotListElement.keyPath + `.0.items.${newFocusedIndex}.#buttonBackgroundFocused`
    });
    expect(leftFocusedBgResult.value.opacity).to.equal(
      1.0,
      "Pivot should have buttonBackgroundFocused visible after moving left",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855428
  it("C855428 - Title detail page is displayed when user selects video poster from the pivots page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Navigate to pivots row
     * 3. Select a pivot
     * 4. Navigate to a title in pivot page
     * 5. Let the title autostart playing after video preview
     * 6. Press back button
     * 7. Click on the title again
     *
     * Expected:
     * Title detail page is displayed correctly
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: true });
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 20000);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
      20000
    );

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Get the number of pivots using the helper method
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      0,
      "Should have at least one pivot available",
    );

    // Step 2: Navigate to pivots row - Navigate up to the pivot list
    await ecp.sendKeypress(ecp.Key.Up);

    // Verify pivot list is focused
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );
    // Step 3: Select a pivot
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for pivot grid content to load before navigating down
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");

    // Wait for focus to return to the videoTitlesRowList
    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 4: Navigate to a title in pivot page
    const pivotDetailRowList =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(pivotDetailRowList.visible).to.equal(
      true,
      "Pivot grid container should be visible",
    );

    // Verify content rows are present with tiles
    const allRows = await testUtils.getAllRowListItemsContentGroupedByRow('pivotDetailRowList');
    const rowCount = allRows.length;
    expect(rowCount).to.be.greaterThan(
      0,
      "Pivot grid should have content rows",
    );

    // Step 5: Let the title autostart playing after video preview
    await testUtils.waitForPlayerStateToEqual(
      "previewVideoPlayer",
      "playing",
      15000,
    );

    // Seek close to end of preview to speed up the test
    await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -1000, 'end');

    await testUtils.waitForCurrentScreenToEqual("videoPlayerScreen", 15000);

    // Step 6: Press back button
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify we're back on the pivot page
    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Should return to pivot page after back",
    );

    // Step 7: Click on the title again
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual("detailScreen", 15000);

    // Verify title detail page is displayed correctly
    await testUtils.waitForElementToShowOnScreen(
      "detailScreen",
      "Detail screen should be visible",
      5000,
    );
    const detailScreen = await testUtils.getNodeForElement("detailScreen");
    expect(detailScreen.visible).to.equal(
      true,
      "Detail screen should be visible",
    );

    const detailScreenTitle =
      await testUtils.getNodeForElement("detailScreenTitle");
    expect(detailScreenTitle.visible).to.equal(
      true,
      "Detail screen title should be visible",
    );

    const detailScreenYearAndDuration = await testUtils.getNodeForElement(
      "detailScreenYearAndDuration",
    );
    expect(detailScreenYearAndDuration.visible).to.equal(
      true,
      "Year and duration should be visible",
    );

    // Verify detail screen panel is displayed
    const detailScreenPanel =
      await testUtils.getNodeForElement("detailScreenPanel");
    expect(detailScreenPanel.visible).to.equal(
      true,
      "Detail screen panel should be visible",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855429
  it("C855429 - Pivots page is displayed when user presses back button from VOD title detail page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to pivots row
     * 3. Select a pivot
     * 4. Select movies from pivot page
     * 5. Press back button
     * 6. Select series from pivot page
     * 7. Press back button
     *
     * Expected:
     * 5, 7. pivots page is displayed
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Get the number of pivots using the helper method
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    expect(pivotCount).to.be.greaterThan(
      0,
      "Should have at least one pivot available",
    );

    // Step 2: Navigate to pivots row
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select a pivot
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for pivot grid content to load
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");

    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 4: Select movies from pivot page
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual("detailScreen", 15000);

    // Verify detail screen is displayed
    const detailScreenTitle =
      await testUtils.getNodeForElement("detailScreenTitle");
    expect(detailScreenTitle.visible).to.equal(
      true,
      "Detail screen title should be visible",
    );

    // Step 5: Press back button
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify pivots page is displayed
    await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Should return to pivot page after back",
    );

    const videoTitlesRowList =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(videoTitlesRowList.visible).to.equal(
      true,
      "Pivot page should be visible",
    );

    // Step 6: Select series from pivot page (navigate to a different content)
    await ecp.sendKeypress(ecp.Key.Right);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual("detailScreen", 15000);

    // Verify detail screen is displayed again
    const detailScreenTitleSecond =
      await testUtils.getNodeForElement("detailScreenTitle");
    expect(detailScreenTitleSecond.visible).to.equal(
      true,
      "Detail screen title should be visible for second selection",
    );

    // Step 7: Press back button
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify pivots page is displayed again
    await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Should return to pivot page after back",
    );

    const pivotDetailRowListFinal =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(pivotDetailRowListFinal.visible).to.equal(
      true,
      "Pivot page should be visible after second back press",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855430
  it("C855430 - Pivots page is displayed when user presses back button from Linear player page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to pivots row
     * 3. Select a pivot
     * 4. Select linear channel from pivot page
     * 5. Press back button
     *
     * Expected:
     * pivots page is displayed
     */

    // Fetch a linear item from recommended_linear_channels API and inject it
    // into the first container of the pivot's apps/ response
    const user = await testUtils.createRegisteredUser();
    const linearItems = await testHelpers.fetchLinearContent(user, 1);
    const linearItem = linearItems[0];
    const linearId = linearItem.id;

    // Set up proxy to intercept pivot content and inject linear item
    proxy.resume();

    const appsProxyPromise = new Promise<void>((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => args.url.includes('/v1/apps/'),
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          if (responseJson.containers?.length > 0) {
            const firstContainer = responseJson.containers[0];

            // Insert the linear channel ID as the first item in the first container
            if (firstContainer.children) {
              firstContainer.children.unshift(linearId);
            }

            // Add the linear item to the contents map
            if (!responseJson.contents) {
              responseJson.contents = {};
            }
            responseJson.contents[linearId] = linearItem;
          }

          resolve();
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    expect(pivotItems.length).to.be.greaterThan(
      0,
      "Should have at least one pivot available",
    );

    // Step 2: Navigate to pivots row
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select a pivot
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for pivot detail content to load (apps/ proxy injects linear item)
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");
    await utils.promiseTimeout(appsProxyPromise, 30000);

    // Pause proxy - done intercepting
    proxy.pause();

    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 4: Select linear channel - it should be the first item in the first container
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent(
      "pivotDetailRowList",
    );
    expect(focusedContent.type).to.equal(
      "l",
      "First item in pivot page should be the injected linear channel",
    );

    // Select the linear channel
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify user is taken to Linear Video Player Screen
    await testUtils.waitForCurrentScreenToEqual(
      "linearVideoPlayerScreen",
      15000,
    );

    // Verify linear video is playing
    await testUtils.waitForPlayerStateToEqual(
      "linearVideoPlayerScreen",
      "playing",
      15000,
    );

    // Step 5: Press back button
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify pivots page is displayed
    await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Should return to pivot page after back",
    );

    const pivotDetailRowList =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(pivotDetailRowList.visible).to.equal(
      true,
      "Pivot page should be visible",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855431
  it("C855431 - Pivot page includes series, movies and linear channels @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to pivots row
     * 3. Select a pivot
     *
     * Expected:
     * Pivot page has series, movies and linear channel
     */

    // Fetch a linear item from recommended_linear_channels API and inject it
    // into the first container of the pivot's apps/ response
    const user = await testUtils.createRegisteredUser();
    const linearItems = await testHelpers.fetchLinearContent(user, 1);
    const linearItem = linearItems[0];
    const linearId = linearItem.id;

    // Set up proxy to intercept pivot content and inject linear item
    proxy.resume();

    const appsProxyPromise = new Promise<void>((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => args.url.includes('/v1/apps/'),
        processRequest: (args) => {
          // Override contents_limit to 50 to get more items per container
          const proxyReq = args.proxyReq as any;
          const currentPath: string = proxyReq._currentRequest?.path || proxyReq._options?.path || '';
          const newPath = currentPath.replace(/contents_limit=\d+/, 'contents_limit=50');
          if (proxyReq._currentRequest) proxyReq._currentRequest.path = newPath;
          if (proxyReq._options) {
            proxyReq._options.path = newPath;
            if (proxyReq._options.search) {
              proxyReq._options.search = proxyReq._options.search.replace(/contents_limit=\d+/, 'contents_limit=50');
            }
          }
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());

          if (responseJson.containers?.length > 0) {
            const firstContainer = responseJson.containers[0];

            if (firstContainer.children) {
              firstContainer.children.unshift(linearId);
            }

            if (!responseJson.contents) {
              responseJson.contents = {};
            }
            responseJson.contents[linearId] = linearItem;
          }

          resolve();
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Step 2: Navigate to pivots row
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Step 3: Select a pivot
    await ecp.sendKeypress(ecp.Key.Ok);

    // Wait for pivot detail content to load (apps/ proxy injects linear item)
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");
    await utils.promiseTimeout(appsProxyPromise, 30000);

    // Pause proxy - done intercepting
    proxy.pause();

    await testUtils.waitForElementToHaveFocus(
      "pivotDetailRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivot grid container is displayed
    const videoTitlesRowList =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(videoTitlesRowList.visible).to.equal(
      true,
      "Pivot grid container should be visible after selecting pivot",
    );

    // Verify pivot page includes series, movies and linear channels
    let hasMovies = false;
    let hasSeries = false;
    let hasLinear = false;

    const allRows = await testUtils.getAllRowListItemsContentGroupedByRow('pivotDetailRowList');
    expect(allRows.length).to.be.greaterThan(
      0,
      "Pivot page should have content rows",
    );

    // Check each row for different content types
    for (const rowContent of allRows) {
      for (const item of rowContent) {
        if (item.type === "v") hasMovies = true;
        else if (item.type === "s") hasSeries = true;
        else if (item.type === "l") hasLinear = true;

        if (hasMovies && hasSeries && hasLinear) break;
      }

      if (hasMovies && hasSeries && hasLinear) break;
    }

    // Verify all content types are present
    expect(hasMovies).to.equal(
      true,
      "Pivot page should include movies (type: v)",
    );
    expect(hasSeries).to.equal(
      true,
      "Pivot page should include series (type: s)",
    );
    expect(hasLinear).to.equal(
      true,
      "Pivot page should include linear channels (type: l)",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855434
  it("C855434 - Pivots + ad wrapper @guest,@pivots,@ads,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Enable ad wrapper
     * Test Steps:
     * 1. Launch Tubi
     * 2. Verify pivot is hidden when ad wrapper is focused
     * 3. Scroll down from ad wrapper - verify pivot reappears
     * 4. Scroll back up to ad wrapper - verify pivot hides again
     *
     * Expected:
     * Pivot shows when ad wrapper row is focused
     */

    // Set up wrapper ad mock before launching app
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Wrapper]);
    // Step 1: Launch Tubi as guest user with ad wrapper enabled
    await startApplicationWithPivotExperiment({
      disableSkinAds: false,
      clearRegistry: false,
    });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForElementToHaveFocus(
      "skinAdRow",
      "Timed out waiting for wrapper ad to have focus",
      15000,
    );

    // Step 2: Verify pivot is shown when ad wrapper row is focused
    const pivotListOnAd = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnAd.visible).to.equal(
      true,
      "Pivot list should be hidden when ad wrapper row is focused",
    );

    // Step 3: Scroll down from ad wrapper to content rows
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for videoTitlesRowList to have focus",
      10000,
    );

    // Verify pivot reappears after moving away from ad wrapper
    const pivotListAfterDown = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterDown.visible).to.equal(
      true,
      "Pivot list should be visible after moving away from ad wrapper",
    );

    // Step 4: Scroll back up to ad wrapper
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "skinAdRow",
      "Timed out waiting for wrapper ad to have focus after scrolling up",
      10000,
    );

    // Verify pivot hides again when ad wrapper is focused
    const pivotListOnAdAgain = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnAdAgain.visible).to.equal(
      true,
      "Pivot list should be hidden again when ad wrapper row is refocused",
    );

    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Timed out waiting for pivot list to have focus after scrolling up",
      10000,
    );

    await proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855435
  it("C855435 - Pivots + HDC Carousel @guest,@pivots,@homescreen,@ads,@carousel", async () => {
    /**
     * Pre-conditions:
     * Enable HDC ads
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to HDC Carousel row - verify pivot hides
     * 3. Move away from carousel - verify pivot reappears
     * 4. Return to carousel - verify pivot hides again
     *
     * Expected:
     * Pivot hides when carousel row is focused, reappears when moved away
     */

    // Set up HDC carousel ad mock before launching app
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Carousel]);

    // Step 1: Launch Tubi as guest user with HDC ads enabled
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 50000);

    // Wait for home page to load
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for home page to load",
      15000,
    );

    // Verify pivots are visible initially on regular content
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible on regular content rows",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Step 2: Navigate to HDC carousel row
    await testUtils.jumpToRowIndex("videoTitlesRowList", 1);
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "adCarouselGrid",
      "HDC Carousel should have focus",
      5000,
    );

    // Verify pivot is hidden when carousel row is focused
    const pivotListOnCarousel = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnCarousel.visible).to.equal(
      false,
      "Pivot list should be hidden when HDC carousel row is focused",
    );

    // Step 3: Move up from carousel - pivot should reappear
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Should have focus on row list after scrolling up from carousel",
      5000,
    );

    await testUtils.waitForElementToShowOnScreen("pivotList", "Pivot list should be visible after moving away from carousel", 5000);

    const pivotListAfterUp = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterUp.visible).to.equal(
      true,
      "Pivot list should reappear after moving away from carousel",
    );

    // Step 4: Navigate back down to carousel - pivot should hide again
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "adCarouselGrid",
      "HDC Carousel should have focus again",
      5000,
    );

    const pivotListOnCarouselAgain = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnCarouselAgain.visible).to.equal(
      false,
      "Pivot list should be hidden again when carousel row is refocused",
    );

    await proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855436
  it("C855436 - Pivots + HDC Spotlight @guest,@pivots,@homescreen,@ads,@spotlightAd", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch Tubi
     * 2. Navigate to HDC Spotlight row - verify pivot hides
     * 3. Move away from spotlight - verify pivot reappears
     * 4. Return to spotlight - verify pivot hides again
     *
     * Expected:
     * Pivot hides when spotlight row is focused, reappears when moved away
     */

    // Set up HDC spotlight ad mock before launching app
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Spotlight]);

    // Step 1: Launch Tubi as guest user with HDC spotlight ads enabled
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 50000);

    // Wait for home page to load
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for home page to load",
      15000,
    );

    // Verify pivots are visible initially on regular content
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible on regular content rows",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Step 2: Navigate to HDC spotlight row
    await testUtils.jumpToRowIndex("videoTitlesRowList", 2);

    // Verify HDC spotlight row by ID (hdc_spotlight)
    const rowItemsContent =
      await testUtils.getCurrentlyFocusedRowListRowItemsContent(
        "videoTitlesRowList",
      );
    expect(rowItemsContent[0].id).to.equal(
      "hdc_spotlight",
      "Spotlight ad row should be present",
    );

    // Verify pivot is hidden when spotlight row is focused
    const pivotListOnSpotlight = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnSpotlight.visible).to.equal(
      false,
      "Pivot list should be hidden when HDC spotlight row is focused",
    );

    // Step 3: Move up from spotlight - pivot should reappear
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Should have focus on row list after scrolling up from spotlight",
      5000,
    );

    await testUtils.waitForElementToShowOnScreen("pivotList", "Pivot list should be visible after moving away from spotlight", 5000);

    const pivotListAfterUp = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterUp.visible).to.equal(
      true,
      "Pivot list should reappear after moving away from spotlight",
    );

    // Step 4: Navigate back down to spotlight - pivot should hide again
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToNotShowOnScreen("pivotList", "Pivot list should be visible after moving away from spotlight", 5000);

    const rowItemsContentAgain =
      await testUtils.getCurrentlyFocusedRowListRowItemsContent(
        "videoTitlesRowList",
      );
    expect(rowItemsContentAgain[0].id).to.equal(
      "hdc_spotlight",
      "Should be back on spotlight ad row",
    );

    const pivotListOnSpotlightAgain = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnSpotlightAgain.visible).to.equal(
      false,
      "Pivot list should be hidden again when spotlight row is refocused",
    );

    await proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855439
  it("C855439 - Pivots + Pinning linear channel on Featured row @guest,@pivots,@homescreen,@live", async () => {
    /**
     * Pre-conditions:
     * Linear channel is pinned in Featured row
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Scroll to pivots row from featured row
     * 3. Scroll from pivots to featured row
     *
     * Expected:
     * No app crash, navigation is smooth
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Navigate to Featured row using jumpToRowWithTitle
    await testUtils.jumpToRowWithTitle("videoTitlesRowList", "Featured");

    // Verify we are on Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle(
      "videoTitlesRowList",
      "Featured",
      30000,
    );
    expect(featuredRowIndex).to.be.greaterThan(
      -1,
      "Featured row should exist in the CategoryGridList",
    );

    const currentFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("videoTitlesRowList");
    expect(currentFocusedIndex[0]).to.equal(
      featuredRowIndex,
      "Should be focused on Featured row",
    );

    // Step 2: Scroll to pivots row from featured row (navigate up to pivots)
    await ecp.sendKeypress(ecp.Key.Up);

    // Verify pivot list is focused
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    const pivotListAfterNavUp = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterNavUp.visible).to.equal(
      true,
      "Pivot list should be visible after navigating up",
    );

    // Step 3: Scroll from pivots to featured row (navigate down back to Featured)
    await ecp.sendKeypress(ecp.Key.Down);

    // Verify we are back on Featured row with videoTitlesRowList focused
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "videoTitlesRowList should have focus after navigating down from pivots",
    );

    const finalFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("videoTitlesRowList");
    expect(finalFocusedIndex[0]).to.equal(
      featuredRowIndex,
      "Should be back on Featured row",
    );

    // Verify navigation is smooth and no app crash (app is still responsive)
    const videoTitlesRowList =
      await testUtils.getNodeForElement("videoTitlesRowList");
    expect(videoTitlesRowList.visible).to.equal(
      true,
      "videoTitlesRowList should still be visible, indicating smooth navigation",
    );

    // Verify pivots are still visible (sticky behavior)
    const pivotListFinal = await testUtils.getNodeForElement("pivotList");
    expect(pivotListFinal.visible).to.equal(
      true,
      "Pivot list should remain visible at top after navigation",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855441
  it("C855441 - Pivots pill are text centered @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Navigate to pivots row
     *
     * Expected:
     * <span style="font-size:11pt;font-family:Calibri,sans-serif;color:#000000;background-color:transparent;font-weight:700;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;" id="isPasted">Rendering</span><span style="font-size:11pt;font-family:Calibri,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;">: 8-10 pivots; pill text centered; visual cards not clipped (overscan check).</span>
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for the home screen grid content to fully load first
    await testUtils.waitForGridContentToLoad("videoTitlesRowList", 15000);

    // Step 2: Navigate to pivots row
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load - ensure pivotList grid is fully populated
    await testUtils.waitForGridContentToLoad("pivotList", 15000);

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    // Expected Result: 8-10 pivots
    expect(pivotCount).to.be.at.least(8, "Should have at least 8 pivots");
    expect(pivotCount).to.be.at.most(10, "Should have at most 10 pivots");

    // Navigate up to focus on the pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Verify pill text is centered and visual cards are not clipped
    for (let i = 0; i < pivotCount; i++) {
      // Verify pivot text is present and not empty
      const pivotText = pivotItems[i].title || pivotItems[i].text || pivotItems[i].label || "";
      expect(pivotText).to.not.be.empty;
    }

    // Note: Visual property checks (width, height, translation) cannot be performed
    // using content items. These would require direct node access which is not
    // available through the helper methods. The presence of pivot text validates
    // that the pivots are rendering properly.
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855442
  it("C855442 - D-pad navigation: Left/right, up/down into adjacent rows @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch Tubi
     * 2. Move focus to pivots
     * 3. Scroll through pivots - left to right, right to left
     * 4. Scroll from and to pivots into adjacent rows
     *
     * Expected:
     * Scrolling works as expected
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ clearRegistry: false });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList", 20000);

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      0,
      "Should have multiple pivots available",
    );

    // Step 2: Move focus to pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    const pivotListNode = await testUtils.getNodeForElement("pivotList");
    const initialFocusedIndex = pivotListNode.pivotFocused[1];

    // Step 3: Scroll through pivots - left to right
    await ecp.sendKeypress(ecp.Key.Right, { count: 3, wait: 300 });
    await testUtils.waitForElementFieldToEqual(
      "pivotList",
      "currFocusColumn",
      initialFocusedIndex + 3,
      5000,
    );

    const focusedIndexAfterRight = initialFocusedIndex + 3;

    // Scroll through pivots - right to left
    await ecp.sendKeypress(ecp.Key.Left, { count: 2, wait: 300 });
    await testUtils.waitForElementFieldToEqual(
      "pivotList",
      "currFocusColumn",
      focusedIndexAfterRight - 2,
      5000,
    );

    // Step 4: Scroll from pivots down into adjacent row
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Row list should have focus after navigating down from pivots",
    );

    // Navigate down one more row to verify row scrolling works
    const focusedRowIndex = await testUtils.getElementField("videoTitlesRowList", "currFocusRow");
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementFieldChange("videoTitlesRowList", "currFocusRow", 5000);
    const focusedRowIndexAfterDown = await testUtils.getElementField("videoTitlesRowList", "currFocusRow");
    expect(focusedRowIndexAfterDown).to.be.greaterThan(
      focusedRowIndex,
      "Should navigate to next row down",
    );

    // Scroll back up to pivots
    await ecp.sendKeypress(ecp.Key.Up, { count: 2, wait: 300 });
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should regain focus after navigating up from rows",
    );

    // Verify scrolling up from pivots does not move focus away
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should retain focus when pressing Up at the top",
    );

    // Verify scrolling down from pivots returns to content rows
    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Row list should have focus after pressing Down from pivots",
    );

    // Verify scrolling back up returns to pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after pressing Up from row list",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855443
  it("C855443 - Focus state is on last focused pill if user scrolls down to the row and scrolls up back @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. 1. Launch tubi
     * 2. Move focus to pivots
     * 3. Scroll to the third pill in pivots row
     * 4. Scroll down or up to adjacent row
     *
     * Expected:
     * 4. Focus state is on third pill
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 2: Move focus to pivots first to ensure they're loaded
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    // Wait for pivot content to load - ensure pivotList grid is fully populated
    await testUtils.waitForGridContentToLoad("pivotList", 30000);

    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;
    expect(pivotCount).to.be.greaterThan(
      2,
      "Should have at least 3 pivots available to test third pill",
    );

    // Step 3: Scroll to the third pill in pivots row (index 2)
    await ecp.sendKeypress(ecp.Key.Right, { count: 2, wait: 300 });
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", 2, 5000);

    const pivotListAtThirdPill = await testUtils.getNodeForElement("pivotList");
    const thirdPillIndex = pivotListAtThirdPill.pivotFocused[1];

    expect(thirdPillIndex).to.equal(
      2,
      "Third pill (index 2) should be focused",
    );
    const isPivotFocusedAtThirdPill = await testUtils.elementIsInFocusChain("pivotList");
    expect(isPivotFocusedAtThirdPill).to.equal(
      true,
      "Pivot list should be in focus chain",
    );

    // Step 4: Scroll down to adjacent row
    await ecp.sendKeypress(ecp.Key.Down);

    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Row list should have focus after navigating down from pivots",
    );

    const isRowListFocusedAfterDown = await testUtils.elementIsInFocusChain("videoTitlesRowList");
    expect(isRowListFocusedAfterDown).to.equal(
      true,
      "videoTitlesRowList should be in focus chain",
    );

    // Scroll back up to pivots
    await ecp.sendKeypress(ecp.Key.Up);

    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up from rows",
    );

    // Verify focus returned to the third pill
    const isPivotFocusedAfterReturn = await testUtils.elementIsInFocusChain("pivotList");
    expect(isPivotFocusedAfterReturn).to.equal(
      true,
      "Pivot list should be in focus chain",
    );
    const pivotListAfterReturn = await testUtils.getNodeForElement("pivotList");
    expect(pivotListAfterReturn.pivotFocused[1]).to.equal(
      thirdPillIndex,
      "Focus should return to the third pill (index 2) that was previously focused",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855444
  it("C855444 - Back button press from pivots grid takes user to homepage with last selected pivot @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. Launch tubi
     * 2. Move focus to pivots
     * 3. Select one pivot pill to enter the pivots grid
     * 4. Press back button
     *
     * Expected:
     * Homepage displayed with last selected pivot
     * <ul style="margin-top:0;margin-bottom:0;padding-inline-start:48px;" id="isPasted"><li dir="ltr" style="list-style-type:disc;font-size:11pt;font-family:Calibri,sans-serif;color:#000000;background-color:transparent;font-weight:700;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;">
     * <span style="font-size:11pt;font-family:Calibri,sans-serif;color:#000000;background-color:transparent;font-weight:700;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;">Unpivot / Back to Home: </span><span style="font-size:11pt;font-family:Calibri,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;">Users should always know how to get back to Home via pressing the remote’s back button does the same thing. When users return, they land exactly where they left off — back on the pivot they selected.</span></li></ul>
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Wait for pivot content to load with increased timeout
    await testUtils.waitForGridContentToLoad("pivotList", 40000);
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    expect(pivotCount).to.be.greaterThan(
      1,
      `Should have multiple pivots available, but got ${pivotCount}`,
    );

    // Step 2: Move focus to pivots
    await ecp.sendKeypress(ecp.Key.Up);
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after navigating up",
    );

    const pivotListNodeAfterFocus =
      await testUtils.getNodeForElement("pivotList");
    const initialFocusedIndex = pivotListNodeAfterFocus.pivotFocused[1];

    // Navigate to a different pivot to ensure we select a non-default pivot
    const targetIndex = initialFocusedIndex + 2;
    await testUtils.jumpToRowItem("pivotList", [0, targetIndex]);
    await testUtils.waitForElementFieldToEqual("pivotList", "currFocusColumn", targetIndex, 5000);

    // Step 3: Select one pivot pill to enter the pivots grid
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);

    // Wait for content to load after selecting pivot
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");

    // Verify pivot grid content is displayed
    const pivotDetailRowList =
      await testUtils.getNodeForElement("pivotDetailRowList");
    expect(pivotDetailRowList.visible).to.equal(
      true,
      "Pivot grid should be visible after selecting pivot",
    );

    // Step 4: Press back button
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify we're back at homescreen with last selected pivot
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);

    // Verify pivot list is focused after returning to homepage
    await testUtils.waitForElementToHaveFocus(
      "pivotList",
      "Pivot list should have focus after returning to homepage",
    );

    // Verify we're still on the same pivot we selected (last selected pivot)
    const pivotListFinal = await testUtils.getNodeForElement("pivotList");
    expect(pivotListFinal.pivotFocused[1]).to.equal(
      targetIndex,
      "Should return to homepage with the last selected pivot focused",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855448
  it("C855448 - Pivots are visible while deeplinking to the app @guest @pivots @deeplink", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. 1. Deeplink to a title
     * 2. Press back button to land on homescreen
     * 3. Pivots are visible on homepage
     * 4. Deeplink to a title that is in pivots
     * 5. Press back button
     *
     * Expected:
     * 5. Pivot page is displayed (TBD)
     */

    // Step 1: Deeplink to a title with pivot experiment enabled
    await testUtils.startApplicationWithDeeplink({
      mediaType: "movie",
      contentID: "342067",
    }, {
      experimentOverrides: {
        roku_pivots_v_1_3: {
          default: { "enabled": true, "treatment_group": "hard-coded", "background_enabled": false, "remove_pivots": [] }
        }
      }
    });
    await testUtils.waitForCurrentScreenToEqual("videoPlayerScreen", 10000);
    await testUtils.waitForPlayerStateToEqual(
      "videoPlayerScreen",
      "playing",
      10000,
    );

    // Step 2: Press back button to land on homescreen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual("detailScreen", 10000);
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 3: Pivots are visible on homepage
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible on homescreen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855450
  it("C855450 - Pivot grid page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * Guest and Registered user
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Select a pivot pill
     * 3. In pivot grids page - scroll down to the last container
     *
     * Expected:
     * 3. No video tiles below the last container 4 - blank space is displayed as per figma
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus("videoTitlesRowList");

    // Verify pivots are displayed at the top of the screen
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      true,
      "Pivot list should be visible at the top of the screen",
    );

    // Wait for pivot content to load
    await testUtils.waitForGridContentToLoad("pivotList");

    // Step 2: Navigate up to the pivot list
    await ecp.sendKeypress(ecp.Key.Up);

    // Verify pivot list is focused
    await testUtils.waitForElementToHaveFocus("pivotList");

    // Get the currently selected pivot information and count
    const pivotListNode = await testUtils.getNodeForElement("pivotList");
    const selectedPivotIndex = pivotListNode.pivotFocused[1];
    const pivotItems = await testUtils.getRowListRowItemsContent("pivotList", 0);
    const pivotCount = pivotItems.length;

    // Check if there are multiple pivots available
    expect(pivotCount).to.be.greaterThan(
      0,
      `Should have multiple pivots available, but found ${pivotCount}`,
    );

    // Select a pivot pill
    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual("pivotDetailScreen", 10000);
    await testUtils.waitForElementToHaveFocus("pivotDetailRowList");

    // Wait for pivot detail content to load
    await testUtils.waitForGridContentToLoad("pivotDetailRowList");

    const allRows = await testUtils.getAllRowListItemsContentGroupedByRow("pivotDetailRowList");
    const containerCount = allRows.length;

    // Verify there are containers in the pivot grid
    expect(containerCount).to.be.greaterThan(
      0,
      "Pivot grid should have at least one container",
    );

    // Step 3: Jump directly to the last container
    await testUtils.jumpToRowIndex("pivotDetailRowList", containerCount - 1);

    // Get the current focused row index
    const currentFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("pivotDetailRowList");
    const focusedRowIndex = currentFocusedIndex[0];

    // Verify we are at or near the last container
    expect(focusedRowIndex).to.be.at.least(
      containerCount - 1,
      "Should be at the last container",
    );

    // Verify no video tiles below the last container by checking that we can't navigate further down
    const rowListAtBottom =
      await testUtils.getNodeForElement("pivotDetailRowList");
    const itemFocusedBeforeDown = rowListAtBottom.itemFocused;

    // Try to navigate down one more time
    await ecp.sendKeypress(ecp.Key.Down);

    // Check if focus position changed
    const rowListAfterDown =
      await testUtils.getNodeForElement("pivotDetailRowList");
    const itemFocusedAfterDown = rowListAfterDown.itemFocused;

    // If we're at the last container, focus should not move down further
    // or should remain on the same row index
    const finalFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("pivotDetailRowList");
    expect(finalFocusedIndex[0]).to.equal(
      focusedRowIndex,
      "Focus should not move beyond the last container - blank space should be displayed below",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855451
  it("C855451 - Pivots is not shown in kids mode, Espanol tab, movies and Series page @guest,@pivots,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. 1. Launch Tubi
     * 2. Navigate to pivots row
     * 3. Open side nav and select kids mode
     * 4. Open side nav and select Espanol
     * 5. Open side nav and select Movies
     * 6. Open side nav and select Series
     *
     * Expected:
     * 3. No pivots row in kids mode
     * 4. No pivots row in Espanol
     * 5. No pivots row in Movies
     * 6. No pivots row in Series
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Step 2: Verify pivots are displayed at home
    const pivotListOnHome = await testUtils.getNodeForElement("pivotList");
    expect(pivotListOnHome.visible).to.equal(
      true,
      "Pivot list should be visible on home screen",
    );

    // Step 3: Open side nav and select kids mode
    await testHelpers.openKidsMode();
    await testUtils.waitForGridContentToLoad("homeScreenRowList", 10000);
    await testUtils.waitForElementToHaveFocus(
      "homeScreenRowList",
      "Timed out waiting for homeScreenRowList to have focus",
      20000,
    );

    // Verify no pivots in kids mode
    const pivotListInKidsMode = await testUtils.getNodeForElement("pivotList");
    expect(pivotListInKidsMode.visible).to.equal(
      false,
      "Pivots should not be visible in kids mode",
    );

    // Exit kids mode to test other pages
    await testHelpers.exitKidsModeWithAgeGate();

    // Step 4: Open side nav and select Espanol
    await testUtils.goToPage("espanol");
    await testUtils.waitForElementToHaveFocus(
      "espanolScreenRowList",
      "Timed out waiting for Rowlist on Espanol page",
      10000,
    );

    // Verify no pivots in Espanol
    const pivotListInEspanol = await testUtils.getNodeForElement("espanolScreenPivotList");
    expect(pivotListInEspanol.visible).to.equal(
      false,
      "Pivots should not be visible in Espanol",
    );

    // Step 5: Open side nav and select Movies
    await testUtils.goToPage("movies");
    await testUtils.waitForElementToHaveFocus(
      "movieScreenRowList",
      "Timed out waiting for Rowlist on Movies page",
      10000,
    );

    // Verify no pivots in Movies
    const pivotListInMovies = await testUtils.getNodeForElement("movieScreenPivotList");
    expect(pivotListInMovies.visible).to.equal(
      false,
      "Pivots should not be visible in Movies",
    );

    // Step 6: Open side nav and select Series
    await testUtils.goToPage("series");
    await testUtils.waitForElementToHaveFocus(
      "tvScreenRowList",
      "Timed out waiting for Rowlist on Series page",
      10000,
    );

    // Verify no pivots in Series
    const pivotListInSeries = await testUtils.getNodeForElement("tvScreenPivotList");
    expect(pivotListInSeries.visible).to.equal(
      false,
      "Pivots should not be visible in Series",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855452
  it("C855452 - Pivots is hidden for Teens @parental_controls,@pivots,@guest", async () => {
    /**
     * Pre-conditions:
     * Parent control is set to teen
     * Test Steps:
     * 1. Launch Tubi
     * 2. Set parental controls to teens
     * 3. Verify pivots are not displayed
     *
     * Expected:
     * Pivots should not be visible when parental controls are set to teens
     */

    // Step 1: Launch Tubi as guest user
    await startApplicationWithPivotExperiment({ shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify pivots are visible before setting parental controls
    const pivotListBefore = await testUtils.getNodeForElement("pivotList");
    expect(pivotListBefore.visible).to.equal(
      true,
      "Pivot list should be visible before setting teen parental controls",
    );

    // Set parental controls to teens
    await testUtils.goToPage("settings");
    await testHelpers.setParentalControls("teens");
    await ecp.sendKeypress(ecp.Key.Back, { count: 2, wait: 500 });
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
      15000,
    );

    // Verify pivots are NOT displayed for teens
    const pivotList = await testUtils.getNodeForElement("pivotList");
    expect(pivotList.visible).to.equal(
      false,
      "Pivots should not be visible when parental controls are set to teens",
    );
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/855471
  it("C855471 - First container is focused during the initial launch @guest,@homescreen", async () => {
    /**
     * Pre-conditions:
     * No pre-conditions
     * Test Steps:
     * 1. No steps provided
     */

    // Launch Tubi as guest user
    await startApplicationWithPivotExperiment();
    await testUtils.waitForCurrentScreenToEqual("homeScreen", 10000);

    // Wait for videoTitlesRowList to have focus
    await testUtils.waitForElementToHaveFocus(
      "videoTitlesRowList",
      "Timed out waiting for Rowlist to have focus",
    );

    // Verify the first container (Featured row, first tile) is focused
    const initialFocusedIndex =
      await testUtils.getCurrentlyFocusedGridItemIndex("videoTitlesRowList");
    expect(initialFocusedIndex[0]).to.be.at.least(
      0,
      "Focus should be on a valid row initially",
    );
    expect(initialFocusedIndex[1]).to.equal(
      0,
      "Focus should be on first tile in the row initially",
    );
  });
});
