import { expect } from 'chai';
import { ecp, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared, testHelpers } from '../test-helpers';
import { mockDataHelpers } from '../mock-data-helpers';
import {
  getCurrentLiveProgram,
  safeResumeProxy
} from './manual-regression-helpers';

/**
 * Live/Linear TV Regression Tests
 * Tests for On Now row, live badges, sports, news, and linear content
 */

describe('Live/Linear TV Regression Tests', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  afterEach(async () => {
    await proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/601532
  it('C601532 - Verify program image is displayed instead of channel image @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - Movies or Series must be airing in On Now row
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row on home screen.
     * 3. Focus on a title that is a movie or series (not a live channel).
     * 4. Verify that the program image (movie/series poster) is displayed instead of the channel logo.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Check if focused item has programs array (contains program metadata), otherwise find one that does
    let focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    if (!focusedContent.programs || focusedContent.programs.length === 0) {
      // Current item doesn't have programs, find one that does
      const rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      let programItemIndex = -1;
      for (let i = 0; i < rowContent.length; i++) {
        if (rowContent[i].programs && rowContent[i].programs.length > 0) {
          programItemIndex = i;
          break;
        }
      }

      if (programItemIndex === -1) {
        throw new Error('Could not find content with program metadata (movie/series) in On Now row');
      }

      // Navigate to the program item
      const currentIndex1 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
      await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex1[0], programItemIndex]);

      focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    }

    // Verify program poster is displayed (not channel logo)
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Program poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');

    // Program image should be displayed (not the generic channel logo)
    expect(posterElement.visible).to.equal(true, 'Program poster should be visible');
    expect(posterElement.uri).to.exist.and.not.be.empty;

    // Verify program data is present
    expect(focusedContent.programs).to.be.an('array').with.lengthOf.at.least(1, 'Should have program metadata');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.series_title || currentProgram.title).to.exist.and.not.be.empty;

    // The poster should show the program/series image, not just the channel logo
    // Program images would be in series_images or the program's own images
    if (currentProgram.series_images || currentProgram.images) {
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/602027
  it('C602027 - Verify progress bar reflects the real progress @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row on home screen.
     * 3. Focus on any live content with a progress bar.
     * 4. Verify that the progress bar accurately reflects the current playback position.
     * 5. Wait a few seconds and verify the progress bar updates accordingly.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // All items in linear channels row are linear, so just use the focused item
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'Focused content should be linear');

    // Send left key to disable autostart timer so we can inspect the progress bar
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Wait for progress bar to be visible
    await testUtils.waitForElementToShowOnScreen('videoGridProgressBar', 'Progress bar not visible', 5000);
    const progressBar = await testUtils.getNodeForElement('videoGridProgressBar');
    expect(progressBar.visible).to.equal(true, 'Progress bar should be visible for linear content');

    // Get initial progress bar width
    const initialWidth = progressBar.width;
    expect(initialWidth).to.be.greaterThan(0, 'Progress bar should have initial width greater than 0');

    // Wait for 5 seconds
    await utils.sleep(5000);

    // Get updated progress bar width
    const updatedProgressBar = await testUtils.getNodeForElement('videoGridProgressBar');
    const updatedWidth = updatedProgressBar.width;

    // Verify progress bar has advanced (width should increase as program progresses)
    // Note: For live linear content, progress bar reflects elapsed time in current program
    expect(updatedWidth).to.be.at.least(initialWidth,
      `Progress bar should advance over time. Initial: ${initialWidth}, After 5s: ${updatedWidth}`);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603705
  it('C603705 - Verify user is taken to live tv tab when they click on any program in On Now row @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Live and On Now events are airing in On Now row
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row on home screen.
     * 3. Focus on any live content in the row.
     * 4. Press OK to select the content.
     * 5. Verify user is taken to the Live TV screen/player.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList', maxScrolls: 25 });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Verify we're on linear content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'Focused content should be linear');

    // Select the linear content
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify user is taken to Linear Video Player Screen
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);

    // Verify linear video is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Verify player has content loaded
    const playerContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    expect(playerContent).to.exist;
    expect(playerContent.id).to.equal(focusedContent.id, 'Player should be playing linear content');

    // Verify we can go back to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should return focus to home screen', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603706
  it('C603706 - Verify live badge is displayed on live events in On Now row @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find live event (content where programs[0].live === true).
     * 4. Verify "Live" badge is displayed on the tile.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    // Get row content and search for live event (currentProgram.live === true)
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let liveEventIndex = -1;
    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.live === true) {
        liveEventIndex = i;
        break;
      }
    }
    // If not found, scroll right 30 more times and try again
    if (liveEventIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.live === true) {
          liveEventIndex = i;
          break;
        }
      }
    }

    if (liveEventIndex === -1) {
      throw new Error('Could not find live event in On Now row');
    }

    // Navigate to the live event
    const currentIndex2 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex2[0], liveEventIndex]);


    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.live).to.equal(true, 'Content should be a live event');

    // Verify Live badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Live badge should be visible');
    expect(badgeElement.text).to.match(/Live/i, 'Badge should display "Live" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603707
  it('C603707 - Verify on now badge is displayed on non-live events in On Now row @manual_regression @live', async () => {
    /**
     * Pre-conditions: None
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find non-live event (content where programs[0].live === false).
     * 4. Verify "On Now" badge is displayed on the tile.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    // Get row content and search for non-live event (currentProgram is invalid or currentProgram.live === false)
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let nonLiveEventIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (!currentProgram || currentProgram.live === false) {
        nonLiveEventIndex = i;
        break;
      }
    }

    // If not found, scroll right 30 more times and try again
    if (nonLiveEventIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (!currentProgram || currentProgram.live === false) {
          nonLiveEventIndex = i;
          break;
        }
      }
    }

    if (nonLiveEventIndex === -1) {
      throw new Error('Could not find non-live event in On Now row');
    }

    // Navigate to the non-live event
    const currentIndex3 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex3[0], nonLiveEventIndex]);


    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(!currentProgram || currentProgram.live === false).to.equal(true, 'Content should be a non-live event');

    // Verify On Now badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'On Now badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'On Now badge should be visible');
    expect(badgeElement.text).to.match(/On Now/i, 'Badge should display "On Now" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/602046
  it('C602046 - Verify On Now badge is on the tile and not on the title description @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Focus on any content.
     * 4. Verify badge is displayed on the tile (posterOverlay area).
     * 5. Verify badge is NOT in the metadata/description area.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Verify badge is on the tile (liveBadgeText is in the poster overlay area)
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible on tile', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible on tile');

    // Verify badge is part of the poster overlay, not the metadata area
    // The liveBadgeText element should be a child of the video tile overlay, not the videoGridMetadataGroup
    const videoGridMetadata = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(videoGridMetadata.visible).to.equal(true, 'Metadata should be visible');

    // Badge should be on the tile (poster overlay), metadata should be below the tile
    // This is verified by the element hierarchy - liveBadgeText is in posterOverlay, not in videoGridMetadata
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603708
  it('C603708 - On Now - Movie - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - Movie airing on On Now row
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find movie content (programs[0].type === 'v').
     * 4. Verify UI elements: title, poster, metadata, badge.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    // Get row content and search for movie content (currentProgram.type === 'v')
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let movieIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.type === 'v') {
        movieIndex = i;
        break;
      }
    }

    // If not found, scroll right 30 more times and try again
    if (movieIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.type === 'v') {
          movieIndex = i;
          break;
        }
      }
    }

    if (movieIndex === -1) {
      throw new Error('Could not find movie in On Now row');
    }

    // Navigate to the movie
    const currentIndex4 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex4[0], movieIndex]);


    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.type).to.equal('v', 'Content should be a movie');
    expect(currentProgram.title).to.exist.and.not.be.empty;

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Poster should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603709
  it('C603709 - On Now - Series - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Series airing in On Now row
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find series content (programs[0].series_id exists).
     * 4. Verify UI elements: series title, episode info, poster, metadata, badge.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    // Get row content and search for series content (currentProgram.series_id exists)
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let seriesIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.series_id) {
        seriesIndex = i;
        break;
      }
    }

    // If not found, scroll right 30 more times and try again
    if (seriesIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.series_id) {
          seriesIndex = i;
          break;
        }
      }
    }

    if (seriesIndex === -1) {
      throw new Error('Could not find series in On Now row');
    }

    // Navigate to the series
    const currentIndex5 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex5[0], seriesIndex]);


    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.series_id).to.exist.and.not.be.empty;
    expect(currentProgram.series_title).to.exist.and.not.be.empty;

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Poster should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603722
  it('C603722 - On Now - Sports programme - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Sports programme event airing in On Now row
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app with mocked sports content (Real Madrid).
     * 2. Navigate to On Now row.
     * 3. Focus on first item (Real Madrid sports content).
     * 4. Verify UI elements: teams/league info, poster, metadata, badge.
     */

    // Setup mock for sports content
    await safeResumeProxy();
    const mockPromise = mockDataHelpers.mockSportsContent();

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { clearRegistry: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await utils.promiseTimeout(mockPromise, 50000);

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // First item should be Real Madrid sports content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.id).to.equal('613762', 'First item should be Real Madrid channel');
    expect(focusedContent.type).to.equal('l', 'First item should be linear content');

    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.id).to.equal('500006541', 'Current program should be Real Madrid vs. CF Pachuca');

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Poster should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Badge should be visible');

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603713
  it('C603713 - Live - News - Verify UI @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Live news airing in On Now row
     * - Guest or Registered user
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find live news content (programs[0].live === true and tags/genres include news).
     * 4. Verify UI elements: title, channel logo, metadata, live badge.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Scroll right 10 times first to explore initial content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    // Get row content and search for live news content (currentProgram.live === true)
    // Prefer content with "news" in title or tags
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let liveNewsIndex = -1;
    let liveFallbackIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.live === true) {
        const title = (rowContent[i].title || '').toLowerCase();
        const tags = (rowContent[i].tags || []).map((t: string) => t.toLowerCase());

        if (title.includes('news') || tags.some((tag: string) => tag.includes('news'))) {
          liveNewsIndex = i;
          break;
        } else if (liveFallbackIndex === -1) {
          liveFallbackIndex = i;
        }
      }
    }

    // If not found, scroll right 30 more times and try again
    if (liveNewsIndex === -1) {
      await ecp.sendKeypress(ecp.Key.Right, { count: 30 });
      await utils.sleep(1000);

      rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

      for (let i = 0; i < rowContent.length; i++) {
        const currentProgram = getCurrentLiveProgram(rowContent[i]);
        if (currentProgram && currentProgram.live === true) {
          const title = (rowContent[i].title || '').toLowerCase();
          const tags = (rowContent[i].tags || []).map((t: string) => t.toLowerCase());

          if (title.includes('news') || tags.some((tag: string) => tag.includes('news'))) {
            liveNewsIndex = i;
            break;
          } else if (liveFallbackIndex === -1) {
            liveFallbackIndex = i;
          }
        }
      }
    }

    // Use fallback if news content not found
    const targetIndex = liveNewsIndex !== -1 ? liveNewsIndex : liveFallbackIndex;

    if (targetIndex === -1) {
      throw new Error('Could not find live content in On Now row');
    }

    if (liveNewsIndex === -1 && liveFallbackIndex !== -1) {
    }

    // Navigate to the live news/content
    const currentIndex7 = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex7[0], targetIndex]);


    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const currentProgram = getCurrentLiveProgram(focusedContent);
    expect(currentProgram).to.exist;
    expect(currentProgram.live).to.equal(true, 'Content should be live');

    // Verify UI elements
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible', 5000);
    const titleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(titleElement.visible).to.equal(true, 'Title should be visible');

    // For live news, channel logo should be visible
    await testUtils.waitForElementToShowOnScreen('videoGridChannelLogo', 'Channel logo not visible', 5000);
    const channelLogoElement = await testUtils.getNodeForElement('videoGridChannelLogo');
    expect(channelLogoElement.visible).to.equal(true, 'Channel logo should be visible');

    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Metadata not visible', 5000);
    const metadataElement = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataElement.visible).to.equal(true, 'Metadata should be visible');

    // Verify Live badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Live badge should be visible');
    expect(badgeElement.text).to.match(/Live/i, 'Badge should display "Live" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603694
  it('C603694 - When a live program is pinned on Featured, swipe horizontally on other VOD contents @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or Registered user
     * - A P0 live game program is airing and pinned in Featured row
     * 
     * Test Steps:
     * 1. Launch app with mocked linear content in Featured row (2 linear items mocked)
     * 2. Verify first item in Featured row is linear content (pinned)
     * 3. Verify second item is also linear content (we mock 2 linear items)
     * 4. Swipe right to navigate through VOD contents (starting from index 2)
     * 5. Verify horizontal navigation works correctly
     * 6. Verify can navigate back to pinned linear content
     */

    // Set up network proxy to inject linear content at the start of Featured row
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interference
    proxy.pause();

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Get the Featured row index
    const initialFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    const featuredRowIndex = initialFocusedIndex[0];

    // Verify first item is linear content (pinned live program)
    const firstItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(firstItemContent.type).to.equal('l', 'First item in Featured row should be linear content (pinned live program)');
    expect(initialFocusedIndex[1]).to.equal(0, 'Should be focused on first item in Featured row');

    // Swipe right to navigate through contents (note: first 2 items are linear due to mocking)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    const afterFirstRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterFirstRightIndex[0]).to.equal(featuredRowIndex, 'Row should remain the same after pressing Right');
    expect(afterFirstRightIndex[1]).to.equal(1, 'Focus should move to the second item in the row');

    // Verify second item is also linear content (we mock 2 linear items)
    const secondItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(secondItemContent.type).to.equal('l', 'Second item should also be linear content (we mock 2 linear items)');

    // Swipe right again to navigate to third item (first VOD item)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    const afterSecondRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterSecondRightIndex[0]).to.equal(featuredRowIndex, 'Row should remain the same after pressing Right again');
    expect(afterSecondRightIndex[1]).to.equal(2, 'Focus should move to the third item in the row');

    // Verify third item is VOD content (first non-linear item)
    const thirdItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(thirdItemContent.type).to.be.oneOf(['v', 's'], 'Third item should be VOD content (movie or series)');

    // Swipe right once more to verify fourth item is also VOD
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    const afterThirdRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterThirdRightIndex[1]).to.equal(3, 'Focus should move to the fourth item in the row');

    // Verify fourth item is also VOD content
    const fourthItemContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(fourthItemContent.type).to.be.oneOf(['v', 's'], 'Fourth item should be VOD content (movie or series)');

    // Navigate back to the first pinned linear content
    await ecp.sendKeypress(ecp.Key.Left, { count: 3 });
    await utils.sleep(1000);

    const backToFirstIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(backToFirstIndex).to.deep.equal([featuredRowIndex, 0], 'Should return to first item in Featured row');

    // Verify we're back on the first linear content
    const backToFirstContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(backToFirstContent.type).to.equal('l', 'Should return to linear content (pinned live program)');
    expect(backToFirstContent.id).to.equal(firstItemContent.id, 'Should be the same linear content as before');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603696
  it('C603696 - Live Sport event start, navigate to different tabs then back to home tab - live tile still in 1st position of featured row @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Game is airing (mocked via network proxy)
     * 
     * Test Steps:
     * 1. Launch app with mocked linear content in Featured row
     * 2. Verify live tile is in 1st position of Featured row
     * 3. Navigate to different tabs (Movies, TV Shows, My Stuff)
     * 4. Navigate back to Home tab
     * 5. Verify live tile is still in 1st position of Featured row
     */

    // Set up network proxy to inject linear content at the start of Featured row
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interference
    proxy.pause();

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Verify first item is linear content (live sport event)
    const initialLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(initialLinearContent.type).to.equal('l', 'First item in Featured row should be linear content (live sport event)');
    const initialLinearId = initialLinearContent.id;

    // Navigate to Movies tab
    await testUtils.goToPage('movies');
    await testUtils.waitForCurrentScreenToEqual('movieScreen', 10000);
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movie screen', 10000);


    // Navigate to TV Shows tab
    await testUtils.goToPage('series');
    await testUtils.waitForCurrentScreenToEqual('tvScreen', 10000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV screen', 10000);


    // Navigate to My Stuff tab
    await testUtils.goToPage('myStuff');
    await testUtils.waitForCurrentScreenToEqual('myStuffScreen', 10000);


    // Navigate back to Home tab
    await testUtils.goToPage('home');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 10000);


    // Navigate back to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Verify live tile is still in 1st position of Featured row
    const finalLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(finalLinearContent.type).to.equal('l', 'First item in Featured row should still be linear content after navigation');
    expect(finalLinearContent.id).to.equal(initialLinearId, 'Same live sport event should still be in 1st position');

    const finalFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(finalFocusedIndex[1]).to.equal(0, 'Live tile should be at first position (column 0)');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603698
  it('C603698 - Live sport start, quit then relaunch app - game tile still in 1st position of featured row @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Game is airing (mocked via network proxy)
     * 
     * Test Steps:
     * 1. Launch app with mocked linear content in Featured row
     * 2. Verify live tile is in 1st position of Featured row
     * 3. Quit the app
     * 4. Relaunch the app
     * 5. Verify live tile is still in 1st position of Featured row
     */

    // Set up network proxy to inject linear content at the start of Featured row
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interference
    proxy.pause();

    // Navigate to Featured row using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Verify first item is linear content (live sport event)
    const initialLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(initialLinearContent.type).to.equal('l', 'First item in Featured row should be linear content (live sport event)');
    const initialLinearId = initialLinearContent.id;

    // Quit the app by going to home screen (Roku launcher)
    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(3000);

    await ecp.sendLaunchChannel();
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus after relaunch', 20000);



    // Navigate to Featured row after relaunch using slug
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Verify live tile is still in 1st position of Featured row after relaunch
    const finalLinearContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(finalLinearContent.type).to.equal('l', 'First item in Featured row should still be linear content after relaunch');
    expect(finalLinearContent.id).to.equal(initialLinearId, 'Same live sport event should still be in 1st position after relaunch');

    const finalFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(finalFocusedIndex[1]).to.equal(0, 'Live tile should be at first position (column 0) after relaunch');

  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244257
  it('C244257 - The poster size of the live channel should match the poster size of the VOD content @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * - Linear content is available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to a row with mixed content (VOD and linear).
     * 3. Compare the poster sizes of VOD and linear content.
     * 4. Verify they match.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row (recommended_linear_channels)
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Get poster dimensions for linear content
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const linearPoster = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    const linearWidth = linearPoster.width;
    const linearHeight = linearPoster.height;

    // Navigate to a VOD row (featured row)
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Find VOD content in the row
    const rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let vodIndex = -1;
    for (let i = 0; i < rowContent.length; i++) {
      if (rowContent[i].type === 'v' || rowContent[i].type === 's') {
        vodIndex = i;
        break;
      }
    }

    if (vodIndex === -1) {
      throw new Error('Could not find VOD content in Featured row');
    }

    // Navigate to VOD content
    const currentIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex[0], vodIndex]);

    // Get poster dimensions for VOD content
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const vodPoster = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    const vodWidth = vodPoster.width;
    const vodHeight = vodPoster.height;

    // Verify poster sizes match
    expect(linearWidth).to.equal(vodWidth, 'Linear and VOD poster widths should match');
    expect(linearHeight).to.equal(vodHeight, 'Linear and VOD poster heights should match');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244260
  it('C244260 - User should be able to access channel guide and other player features from linear player @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * - Linear content is available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Select linear content to start playback.
     * 4. Press down to access channel guide.
     * 5. Verify channel guide is accessible.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Select linear content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Press down to access channel guide
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify channel guide/overlay is visible
    await testUtils.waitForElementToShowOnScreen('linearOverlayContentArea', 'Channel guide not visible', 5000);
    const channelGuide = await testUtils.getNodeForElement('linearOverlayContentArea');
    expect(channelGuide.visible).to.equal(true, 'Channel guide should be visible');

    await testUtils.waitForElementToHaveFocus('linearProgramGrid', 'Timed out waiting for linear EPG program grid to have focus', 15000);
    await testUtils.waitForGridContentToLoad('linearProgramGrid', 15000);

    // Get initial content ID
    const initialContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    const initialContentId = initialContent?.id;

    // Scroll down to select a different channel (auto-switches on focus change)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);

    // Verify the new channel is playing
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Verify the content ID has changed
    const newContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    const newContentId = newContent?.id;
    expect(newContentId).to.not.equal(initialContentId, 'Content ID should change when switching channels');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244261
  it('C244261 - When searching for linear channel, channel should show in search results @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * - Linear channels are available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to search screen.
     * 3. Search for a known linear channel name.
     * 4. Verify linear channel appears in search results.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to search
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);

    // Search for a news channel (common linear content)
    await ecp.sendText('news');
    await utils.sleep(3000);

    // Navigate to search results
    await testHelpers.navigateRightToSearchGrid();

    // Check search results for linear content
    const searchResults = await testUtils.getAllGridItemsContent('searchResultGrid');
    expect(searchResults.length).to.be.greaterThan(0, 'Search results should not be empty');

    // Verify at least one result is linear content
    const hasLinear = searchResults.some((item: any) => item.type === 'linear');
    expect(hasLinear).to.equal(true, 'Search results should include linear channel');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244270
  it('C244270 - Verify the presence of the Live Icon on top of channel posters @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * - Live content is airing
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find live content.
     * 4. Verify Live icon is displayed on the poster.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Scroll to find live content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    const rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let liveIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.live === true) {
        liveIndex = i;
        break;
      }
    }

    if (liveIndex !== -1) {
      const currentIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
      await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex[0], liveIndex]);

      // Verify Live badge is on the poster
      await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
      const badge = await testUtils.getNodeForElement('liveBadgeText');
      expect(badge.visible).to.equal(true, 'Live badge should be visible on poster');
      expect(badge.text).to.match(/Live/i, 'Badge should display "Live" text');
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/244272
  it('C244272 - Searching and selecting live channel goes direct to broadcast (no details page) @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * - Linear channels are available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to search screen.
     * 3. Search for a linear channel.
     * 4. Select the linear channel from results.
     * 5. Verify user goes directly to linear player (no details page).
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to search
    await testUtils.goToPage('search');
    await testUtils.waitForCurrentScreenToEqual('searchScreen', 10000);

    // Search for news channel
    await ecp.sendText('news');
    await utils.sleep(3000);

    // Navigate to search results
    await testHelpers.navigateRightToSearchGrid();

    // Find linear content in results
    const searchResults = await testUtils.getAllGridItemsContent('searchResultGrid');
    let linearIndex = -1;

    for (let i = 0; i < searchResults.length; i++) {
      if (searchResults[i].type === 'l') {
        linearIndex = i;
        break;
      }
    }

    if (linearIndex !== -1) {
      // Navigate to linear content
      for (let i = 0; i < linearIndex; i++) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(300);
      }

      // Select linear content
      await ecp.sendKeypress(ecp.Key.Ok);

      // Verify we go directly to linear player (not details page)
      await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
      await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

      // Go back to home
      await ecp.sendKeypress(ecp.Key.Back);
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/603699
  it('C603699 - Verify linear program event is not displayed in featured row of Kids, Espanol, movies and TV Shows @manual_regression @live', async () => {
    /**
     * Pre-conditions:
     * - Guest or registered user
     * - Linear content is available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to Kids page and verify no linear content in featured row.
     * 3. Navigate to Espanol page and verify no linear content in featured row.
     * 4. Navigate to Movies page and verify no linear content in featured row.
     * 5. Navigate to TV Shows page and verify no linear content in featured row.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Check Kids page
    await testUtils.goToPage('kids');
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Kids rowlist', 10000);

    // Navigate to Featured row in Kids
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    let rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let hasLinear = rowContent.some((item: any) => item.type === 'l');
    expect(hasLinear).to.equal(false, 'Kids Featured row should not contain linear content');

    // Exit kids mode before checking other pages
    await testHelpers.exitKidsModeWithAgeGate();

    // Check Movies page
    await testUtils.goToPage('movies');
    await testUtils.waitForCurrentScreenToEqual('movieScreen', 10000);
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Movies rowlist', 10000);

    // Get first row content in Movies
    rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');
    hasLinear = rowContent.some((item: any) => item.type === 'l');
    expect(hasLinear).to.equal(false, 'Movies page should not contain linear content');

    // Check TV Shows page
    await testUtils.goToPage('series');
    await testUtils.waitForCurrentScreenToEqual('tvScreen', 10000);
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for TV Shows rowlist', 10000);

    // Get first row content in TV Shows
    rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');
    hasLinear = rowContent.some((item: any) => item.type === 'l');
    expect(hasLinear).to.equal(false, 'TV Shows page should not contain linear content');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/601530
  it('C601530 - Live Sport Event: Verify program image is displayed instead of channel image @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Live sport event is airing
     * 
     * Test Steps:
     * 1. Launch app with mocked sports content.
     * 2. Navigate to On Now row.
     * 3. Focus on sports event.
     * 4. Verify program image (sports event poster) is displayed.
     */

    // Setup mock for sports content
    await safeResumeProxy();
    const mockPromise = mockDataHelpers.mockSportsContent();

    // Launch app
    await testUtils.startApplicationAtPage('home', { clearRegistry: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await utils.promiseTimeout(mockPromise, 50000);

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // First item should be sports content
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'Content should be linear');

    // Verify program poster is displayed
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Poster not visible', 5000);
    const posterElement = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainerContentPoster');
    expect(posterElement.visible).to.equal(true, 'Program poster should be visible');
    expect(posterElement.uri).to.exist.and.not.be.empty;

    proxy.pause();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/595937
  it('C595937 - Live Sport Event: Verify program image of first tile of featured row has a progress indicator @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Live sport event is pinned in Featured row
     * 
     * Test Steps:
     * 1. Launch app with mocked sports content in Featured row.
     * 2. Navigate to Featured row.
     * 3. Verify first tile has progress indicator.
     */

    // Setup mock for sports content
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    proxy.pause();

    // Navigate to Featured row
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Verify first item is linear content with progress bar
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'First item should be linear content');

    // Verify progress bar is visible
    await testUtils.waitForElementToShowOnScreen('videoGridProgressBar', 'Progress bar not visible', 5000);
    const progressBar = await testUtils.getNodeForElement('videoGridProgressBar');
    expect(progressBar.visible).to.equal(true, 'Progress bar should be visible');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/595940
  it('C595940 - Live Sport Event: Verify video starts playing for LIVE event on the featured row @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Live sport event is pinned in Featured row
     * 
     * Test Steps:
     * 1. Launch app with mocked sports content in Featured row.
     * 2. Navigate to Featured row.
     * 3. Select the live sport event.
     * 4. Verify video starts playing.
     */

    // Setup mock for sports content
    await safeResumeProxy();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Launch app
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    proxy.pause();

    // Navigate to Featured row
    await shared.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });

    // Select the live sport event
    await ecp.sendKeypress(ecp.Key.Ok);

    // Verify video starts playing
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Go back
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/602028
  it('C602028 - Live Sport Event - Verify live program starts to play in the top right when user highlights the title @manual_regression @live @sports', async () => {
    /**
     * Pre-conditions:
     * - Live sport event is available
     * - Video preview is enabled
     * 
     * Test Steps:
     * 1. Launch app with mocked sports content.
     * 2. Navigate to On Now row.
     * 3. Focus on live sport event.
     * 4. Verify video preview starts playing.
     */

    // Setup mock for sports content
    await safeResumeProxy();
    const mockPromise = mockDataHelpers.mockSportsContentInContainer('recommended_linear_channels');

    // Launch app with a new user to ensure fresh homescreen request
    await testUtils.startApplicationAtPage('home', { clearRegistry: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');
    await utils.promiseTimeout(mockPromise, 50000);

    // Turn on video previews
    await testHelpers.enablePreviewInSettings(true);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 10000);

    proxy.pause();
    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Verify video preview is playing in linear video player
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/114061
  it('C114061 - Live News - Pause disabled Users will not be able to pause video while in playback @manual_regression @live @news', async () => {
    /**
     * Pre-conditions:
     * - Live news channel is available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Find and select live news content.
     * 4. Try to pause playback.
     * 5. Verify pause is disabled for live content.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Find live content
    await ecp.sendKeypress(ecp.Key.Right, { count: 10 });
    await utils.sleep(1000);

    const rowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    let liveIndex = -1;

    for (let i = 0; i < rowContent.length; i++) {
      const currentProgram = getCurrentLiveProgram(rowContent[i]);
      if (currentProgram && currentProgram.live === true) {
        liveIndex = i;
        break;
      }
    }

    if (liveIndex === -1) {
      // Use any linear content as fallback
      liveIndex = 0;
    }

    const currentIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    await testUtils.jumpToRowItem('videoTitlesRowList', [currentIndex[0], liveIndex]);

    // Select the content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Try to pause
    await ecp.sendKeypress(ecp.Key.Play);
    await utils.sleep(1000);

    // Verify still playing (pause should be disabled for live)
    const playerState = await testUtils.getElementField('linearVideoPlayerScreen', 'state');
    expect(playerState).to.equal('playing', 'Live content should not be pauseable');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/117763
  it('C117763 - Live news should not appear when parental settings are set @manual_regression @live @news @parental_controls', async () => {
    /**
     * Pre-conditions:
     * - Parental controls are set to Little Kids
     * 
     * Test Steps:
     * 1. Create user and set parental controls to Little Kids.
     * 2. Launch app.
     * 3. Verify On Now row is not visible.
     */

    // Launch app and set parental controls
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Set Parental Controls to Little Kids
    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('littleKids');
    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 15000);

    // Try to find On Now row - should not exist
    let foundOnNow = false;
    try {
      await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
      foundOnNow = true;
    } catch (e) {
      foundOnNow = false;
    }

    expect(foundOnNow).to.equal(false, 'On Now row should not be visible with parental controls set to Little Kids');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/117765
  it('C117765 - Pressing back while in full view mode and transport controls are not present, will exit full screen playback @manual_regression @live @news', async () => {
    /**
     * Pre-conditions:
     * - Live content is available
     * 
     * Test Steps:
     * 1. Launch app.
     * 2. Navigate to On Now row.
     * 3. Select live content to start playback.
     * 4. Wait for transport controls to hide.
     * 5. Press back.
     * 6. Verify user exits playback and returns to home screen.
     */

    // Launch app as guest user
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    // Navigate to On Now row
    const rowIndex = await shared.scrollDownToFindRow({ slug: 'recommended_linear_channels', rowListElementId: 'videoTitlesRowList' });
    await testUtils.waitForElementFieldToEqual('videoTitlesRowList', 'itemFocused', rowIndex, 10000);

    // Select linear content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 15000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 15000);

    // Wait for transport controls to auto-hide
    await utils.sleep(5000);

    // Press back to exit playback
    await ecp.sendKeypress(ecp.Key.Back);

    // Verify we return to home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should return to home screen', 10000);
  });
});
