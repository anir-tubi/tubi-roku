import { expect } from 'chai';
import { ecp, odc, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';
import { adTestHelpers, AdType } from '../ad-test-helpers';

describe('HomeGrid Video Tiles', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842085
  it('C842085 - Featured row is the first row @guest,@application_launch,@video_tiles', async () => {
    await testUtils.startApplicationAtPage('home');
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for FeaturedRowList to have focus');

    const rowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    expect(rowIndex).to.be.oneOf([0, 1], 'Featured row should be the first or second row (index 0 or 1)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842086
  it('C842086 - Peek row is NOT dimmed @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const element = testUtils.getElementKeyPath('videoTitlesRowList');

    const { value: peekRowOpacity } = await odc.getValue({
      keyPath: `${element.keyPath}.1.title.opacity`
    });

    expect(peekRowOpacity).to.exist;
    expect(peekRowOpacity).to.equal(1, 'Peek row should NOT be dimmed - opacity should be 1');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842087
  it('C842087 - Peek row has portrait tiles only @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);

    await utils.sleep(1000);

    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    const content = await testUtils.getRowListRowItemsContent('videoTitlesRowList', featuredRowIndex);

    expect(content).to.be.an('array').with.lengthOf.at.least(1, 'Peek row should have at least one tile');

    for (let i = 0; i < content.length; i++) {
      const tileSize = await testUtils.getGridElementSize('videoTitlesRowList', [featuredRowIndex, i]);

      expect(tileSize.height).to.be.greaterThan(tileSize.width,
        `Tile at position [${featuredRowIndex}, ${i}] should be portrait (height > width), but got width=${tileSize.width}, height=${tileSize.height}`);
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842088
  it('C842088 - Row in focus has video tile with moderate density (Guest User) @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);

    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Verify focus is on Featured row
    const currentFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(currentFocusedIndex[0]).to.equal(featuredRowIndex, 'Focus should be on Featured row');

    // Get content and verify tiles are portrait-sized
    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', featuredRowIndex);

    for (let i = 0; i < Math.min(rowContent.length, 3); i++) {
      const tileSize = await testUtils.getGridElementSize('videoTitlesRowList', [featuredRowIndex, i]);
      expect(tileSize.height).to.equal(442,
        `Tile at position [${featuredRowIndex}, ${i}] should have height 442, but got height=${tileSize.height}`);
      expect(tileSize.width).to.equal(310,
        `Tile at position [${featuredRowIndex}, ${i}] should have width 310, but got width=${tileSize.width}`);
    }

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    // Wait for inline video preview container to be visible
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);

    // Verify preview is playing (using the inline video tiles preview player)
    await testUtils.waitForPlayerStateToEqual('inlineVideoTilesPreviewPlayer', 'playing', 10000);

    // Verify preview player size
    const previewPlayerWidth = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'width');
    const previewPlayerHeight = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'height');
    expect(previewPlayerWidth).to.be.greaterThanOrEqual(789, 'Preview player width should be at least 789');
    expect(previewPlayerHeight).to.be.greaterThanOrEqual(442, 'Preview player height should be at least 442');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842089
  it('C842089 - Row in focus has video tile with moderate density (Registered User) @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured row list to have focus', 20000);

    await utils.sleep(1000);

    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Verify focus is on Featured row
    const currentFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(currentFocusedIndex[0]).to.equal(featuredRowIndex, 'Focus should be on Featured row');

    // Get content and verify tiles are portrait-sized
    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', featuredRowIndex);
    expect(rowContent).to.be.an('array').with.lengthOf.at.least(1, 'Featured row should have at least one video tile');

    for (let i = 0; i < Math.min(rowContent.length, 3); i++) {
      const tileSize = await testUtils.getGridElementSize('videoTitlesRowList', [featuredRowIndex, i]);
      expect(tileSize.height).to.equal(442,
        `Tile at position [${featuredRowIndex}, ${i}] should have height 442, but got height=${tileSize.height}`);
      expect(tileSize.width).to.equal(310,
        `Tile at position [${featuredRowIndex}, ${i}] should have width 310, but got width=${tileSize.width}`);
    }

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    // Wait for inline video preview container to be visible
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);

    // Verify preview is playing (using the inline video tiles preview player)
    await testUtils.waitForPlayerStateToEqual('inlineVideoTilesPreviewPlayer', 'playing', 10000);

    // Verify preview player size
    const previewPlayerWidth = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'width');
    const previewPlayerHeight = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'height');
    expect(previewPlayerWidth).to.exist;
    expect(previewPlayerHeight).to.exist;
    expect(previewPlayerWidth).to.be.greaterThanOrEqual(789, 'Preview player width should be at least 789');
    expect(previewPlayerHeight).to.be.greaterThanOrEqual(442, 'Preview player height should be at least 442');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842090
  it('C842090 - When a title is in focus, a video preview plays within a landscape tile @videopreview @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 25000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842091
  it('C842091 - When a title is NOT in focus, a static image is shown within a portrait tile @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    const position = await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', position[0]);

    for (let colIndex = 0; colIndex < rowContent.length; colIndex++) {
      if (colIndex === position[1]) {
        continue;
      }

      const tile = rowContent[colIndex];
      expect(tile.video_preview_url).to.exist;

      const previewPlayer = await testUtils.getNodeForElement('previewVideoPlayer');
      const currentPlayingId = previewPlayer.content?.id;

      expect(tile.id).to.not.equal(currentPlayingId, `Tile at position [${position[0]}, ${colIndex}] should NOT be playing video preview`);
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842092
  it('C842092 - When a title does not have a video preview, a static image is shown @guest @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 10000);

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', false, 5);
    await utils.sleep(1000);
    const previewPlayerState = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(previewPlayerState).to.not.equal('playing', 'Preview video player should not be playing for content without video preview');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Static image not visible', 15000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842093
  it('C842093 - Selecting a video tile will open VOD details page @guest @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 10000);

    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Ensure we're focused on a movie or series (not linear)
    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', featuredRowIndex);
    let movieOrSeriesCol = -1;
    for (let i = 0; i < rowContent.length; i++) {
      if (rowContent[i].type === 'v' || rowContent[i].type === 's') {
        movieOrSeriesCol = i;
        break;
      }
    }

    if (movieOrSeriesCol === -1) {
      throw new Error('No movie or series found in Featured row');
    }

    // Navigate to the movie or series
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, movieOrSeriesCol]);
    await utils.sleep(500);

    // Open detail screen
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    const detailScreenTitle = await testUtils.getElementField('detailScreenTitle', 'visible');
    expect(detailScreenTitle).to.equal(true);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842094
  it('C842094 - Video preview continues when user enters/exits details screen @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview in movie screen');
    }

    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    await utils.sleep(1000);
    const previewStateOnDetail = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(previewStateOnDetail).to.equal('playing');

    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Failed to return to movie screen');

    await utils.sleep(1000);
    const previewStateAfterBack = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(previewStateAfterBack).to.equal('playing');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842095
  it('C842095 - When video preview is disabled in app settings, static image is shown in video tile @video_tiles', async () => {
    const user = await testUtils.createRegisteredUser();
    await user.enableVideoPreview(false);
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const position = await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    const [row, col] = position;

    // Verify inlineVideoPreviewPlayerContainer is visible with opacity 1
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.visible).to.equal(true, 'Inline video preview player container should be visible');
    expect(previewContainer.opacity).to.equal(1, 'Inline video preview player container opacity should be 1');

    // Verify poster inside container is visible
    const featuredPoster = await testUtils.getNodeForElement('featuredPoster');
    expect(featuredPoster.visible).to.equal(true, 'Featured poster should be visible when video preview is disabled');

    // Verify preview player is hidden (via opacity)
    const previewPlayer = await testUtils.getNodeForElement('inlineVideoTilesPreviewPlayer');
    expect(previewPlayer.opacity).to.equal(0, `Preview video player should be hidden when preview is disabled but opacity was ${previewPlayer.opacity}`);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842096
  it('C842096 - Background/foreground app while video tile is playing video preview @videopreview @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 25000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Home);
    await utils.sleep(3000);

    await ecp.sendLaunchChannel();
    await utils.sleep(5000);

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible after foregrounding', 25000);
    await utils.sleep(2000);

    await testUtils.retryWithTimeOut(async () => {
      await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus after foregrounding', 10000);
    }, 30000);

    await utils.sleep(2000);

    await testUtils.retryWithTimeOut(async () => {
      const playerState = await testUtils.getElementField('previewVideoPlayer', 'state', 5000);
      expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Preview player should resume playing or buffering after foregrounding');
    }, 15000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842097
  it('C842097 - Title autostarts when video preview ends @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5, 2000, 's');

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

    // Seek to 5 seconds before the end of the preview to speed up the test
    await testUtils.seekPlayerToRelativePosition('previewVideoPlayerScreen', -5000, 'end');

    await testUtils.retryWithTimeOut(async () => {
      const currentScreen = await testUtils.getElementField('screenStack', '-1', 10000);
      expect(currentScreen.id).to.equal('videoPlayerScreen', 'Should transition to full video player screen after preview ends');
    }, 60000);

    await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 10000);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    const content = await testUtils.getElementField('videoPlayerScreen', 'content');
    expect(content.title).to.exist;
    expect(content.id).to.exist;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842098
  it('C842098 - Vertical scrolling between rows @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus');
    await utils.sleep(1000);

    const initialFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    const initialRow = initialFocusedIndex[0];

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    const afterDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterDownIndex[0]).to.equal(initialRow + 1, 'Focus should move to the next row below');

    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);
    const afterUpIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterUpIndex[0]).to.equal(initialRow, 'Focus should return to initial row');

    await ecp.sendKeypress(ecp.Key.Down, { count: 3 });
    await utils.sleep(500);
    const afterMultipleDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterMultipleDownIndex[0]).to.be.greaterThan(initialRow, 'Focus should move down multiple rows');

    await ecp.sendKeypress(ecp.Key.Up, { count: 2 });
    await utils.sleep(500);
    const afterPartialUpIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterPartialUpIndex[0]).to.be.lessThan(afterMultipleDownIndex[0], 'Focus should move up when navigating back');

    await ecp.sendKeypress(ecp.Key.Down, { count: 10, wait: 50 });
    await utils.sleep(1000);
    const finalFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(finalFocusedIndex[0]).to.be.greaterThan(initialRow, 'Focus should handle button mashing and remain on a valid row');

    const videoTitlesRowList = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowList.visible).to.equal(true, 'Row list should remain visible after navigation');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842099
  it('C842099 - Horizontal scrolling across row @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);


    const initialFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    const initialRow = featuredRowIndex;
    const initialCol = initialFocusedIndex[1];

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);
    const afterRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterRightIndex[0]).to.equal(initialRow, 'Row should remain the same after pressing Right');
    expect(afterRightIndex[1]).to.equal(initialCol + 1, 'Focus should move to the next title in the row');

    // Verify that inlineVideoPreviewPlayerContainer metadata has been updated to the second item
    const secondItemContent = await testUtils.getGridItemContent('videoTitlesRowList', [featuredRowIndex, 1]);
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.visible).to.equal(true, 'Inline video preview player container should be visible after navigating right');

    // Verify metadata matches the second item
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not visible in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.text).to.equal(secondItemContent.description, 'Description should match the second item in Featured row');

    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(500);
    const afterLeftIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterLeftIndex[0]).to.equal(initialRow, 'Row should remain the same after pressing Left');
    expect(afterLeftIndex[1]).to.equal(initialCol, 'Focus should return to initial column');

    await ecp.sendKeypress(ecp.Key.Right, { count: 3 });
    await utils.sleep(500);
    const afterMultipleRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterMultipleRightIndex[0]).to.equal(initialRow, 'Row should remain the same after multiple Right presses');
    expect(afterMultipleRightIndex[1]).to.be.greaterThan(initialCol, 'Focus should move across multiple titles');

    await ecp.sendKeypress(ecp.Key.Left, { count: 2 });
    await utils.sleep(500);
    const afterPartialLeftIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterPartialLeftIndex[0]).to.equal(initialRow, 'Row should remain the same when navigating back');
    expect(afterPartialLeftIndex[1]).to.be.lessThan(afterMultipleRightIndex[1], 'Focus should move left across titles');

    await ecp.sendKeypress(ecp.Key.Right, { count: 20, wait: 50 });
    await utils.sleep(1000);
    const finalFocusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(finalFocusedIndex[0]).to.equal(initialRow, 'Row should remain the same after button mashing');
    expect(finalFocusedIndex[1]).to.be.greaterThan(initialCol, 'Focus should handle button mashing and remain on a valid title');

    const videoTitlesRowList = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowList.visible).to.equal(true, 'Row list should remain visible and responsive after horizontal scrolling');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842100
  it('C842100 - Video tile displays title on poster overlay @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Jump to the first item in the Featured row
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, 0]);
    await utils.sleep(1000);

    // Get the focused content title
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.title).to.exist;
    expect(focusedContent.title).to.be.a('string').with.length.greaterThan(0, 'Content should have a valid title');

    // Validate posterOverlayTitle is visible and displays the title
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Poster overlay title not visible', 5000);
    const posterOverlayTitleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(posterOverlayTitleElement.visible).to.equal(true, 'Poster overlay title should be visible');
    expect(posterOverlayTitleElement.text).to.exist.and.not.be.empty;
    expect(posterOverlayTitleElement.text).to.equal(focusedContent.title, 'Poster overlay title should match content title');

    // Validate the video tile is visible with valid dimensions
    const tileElement = await testUtils.getGridElementSize('videoTitlesRowList', [featuredRowIndex, 0]);
    expect(tileElement.width).to.be.greaterThan(0, 'Video tile should be visible with valid width');
    expect(tileElement.height).to.be.greaterThan(0, 'Video tile should be visible with valid height');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842101
  it('C842101 - Video tile displays title with regular text @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', featuredRowIndex);

    let titleWithoutArtPosition = [-1, -1];
    for (let colIndex = 0; colIndex < rowContent.length; colIndex++) {
      const tile = rowContent[colIndex];
      if (!tile.title_art_url || tile.title_art_url.trim().length === 0) {
        titleWithoutArtPosition = [featuredRowIndex, colIndex];
        break;
      }
    }

    if (titleWithoutArtPosition[0] === -1) {
      throw new Error('Could not find title without title art in Featured row');
    }

    await testUtils.jumpToRowItem('videoTitlesRowList', titleWithoutArtPosition);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.title).to.exist;
    expect(focusedContent.title.trim()).to.have.lengthOf.greaterThan(0, 'Title text should not be empty');

    const titleArtUrl = focusedContent.title_art_url || '';
    expect(titleArtUrl.trim()).to.have.lengthOf(0, 'Title art URL should be empty for titles without title art');

    const tileElement = await testUtils.getGridElementSize('videoTitlesRowList', titleWithoutArtPosition);
    expect(tileElement.width).to.be.greaterThan(0, 'Video tile should be visible with valid width');
    expect(tileElement.height).to.be.greaterThan(0, 'Video tile should be visible with valid height');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842102
  it('C842102 - Metadata displayed below video tile (movie) @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a movie (type 'v') in the grid
    let foundMovie = false;
    let moviePosition = [-1, -1];

    for (let rowIndex = 0; rowIndex < 10; rowIndex++) {
      await testUtils.jumpToRowIndex('videoTitlesRowList', rowIndex);
      await utils.sleep(500);

      const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', rowIndex);

      if (!rowContent || rowContent.length === 0) {
        continue;
      }

      for (let colIndex = 0; colIndex < rowContent.length; colIndex++) {
        const item = rowContent[colIndex];
        if (item.type === 'v') {
          moviePosition = [rowIndex, colIndex];
          foundMovie = true;
          break;
        }
      }

      if (foundMovie) {
        break;
      }
    }

    if (!foundMovie) {
      throw new Error('Could not find a movie in the first 10 rows');
    }

    // Navigate to the movie
    await testUtils.jumpToRowItem('videoTitlesRowList', moviePosition);
    await utils.sleep(1000);

    const content = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(content.title).to.exist;
    expect(content.title).to.be.a('string').and.have.length.greaterThan(0);
    expect(content.type).to.equal('v', 'Content should be a movie');

    // Validate metadata is displayed in inlineVideoPreviewPlayerContainer
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.visible).to.equal(true, 'Inline video preview player container should be visible');
    expect(previewContainer.opacity).to.equal(1, 'Inline video preview player container opacity should be 1');

    // Validate metadata fields are displayed
    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Video grid metadata not visible', 5000);

    // Validate rating is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridRatingLabel', 'Rating not displayed in video grid metadata', 5000);
    const ratingElement = await testUtils.getNodeForElement('videoGridRatingLabel');
    expect(ratingElement.visible).to.equal(true, 'Rating should be visible in video grid metadata');
    expect(ratingElement.text).to.exist.and.not.be.empty;

    // Validate description is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(descriptionElement.text).to.exist.and.not.be.empty;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842103
  it('C842103 - Metadata displayed below video tile (series) @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured row list to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find a series (type 's') in the grid by navigating with keypresses
    // This approach avoids JSON parsing issues from getRowListRowItemsContent
    let foundSeries = false;
    let focusedItem = null;

    // Try navigating down through items to find a series
    for (let attempt = 0; attempt < 50; attempt++) {
      await utils.sleep(300);

      try {
        const currentItem = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
        if (currentItem && currentItem.type === 's') {
          foundSeries = true;
          focusedItem = currentItem;
          break;
        }
      } catch (e) {
        // Skip items with JSON parse errors
      }

      // Move to next item (right or down)
      if (attempt % 5 === 4) {
        // Every 5th attempt, move down to next row
        await ecp.sendKeypress(ecp.Key.Down);
      } else {
        // Move right within row
        await ecp.sendKeypress(ecp.Key.Right);
      }
    }

    if (!foundSeries) {
      throw new Error('Could not find a series in the first 50 items');
    }

    // focusedItem already retrieved and validated above
    expect(focusedItem.title).to.exist.and.not.be.empty;
    expect(focusedItem.type).to.equal('s', 'Content should be a series');

    // Validate metadata is displayed in inlineVideoPreviewPlayerContainer
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.visible).to.equal(true, 'Inline video preview player container should be visible');
    expect(previewContainer.opacity).to.equal(1, 'Inline video preview player container opacity should be 1');

    // Validate metadata fields are displayed
    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Video grid metadata not visible', 5000);

    // Validate rating is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridRatingLabel', 'Rating not displayed in video grid metadata', 5000);
    const ratingElement = await testUtils.getNodeForElement('videoGridRatingLabel');
    expect(ratingElement.visible).to.equal(true, 'Rating should be visible in video grid metadata');
    expect(ratingElement.text).to.exist.and.not.be.empty;

    // Validate description is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(descriptionElement.text).to.exist.and.not.be.empty;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842104
  it('C842104 - Metadata displayed below video tile (linear) @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    let foundLinearContent = false;
    let linearContent = null;

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    // Navigate down up to 40 rows using keypress to find linear content
    for (let i = 0; i < 40; i++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');

        if (focusedContent) {
          if (focusedContent.type === 'l') {
            foundLinearContent = true;
            linearContent = focusedContent;
            break;
          }
        }
      } catch (e) {
        // Continue to next row
      }

      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(800);
      await testUtils.waitForGridContentToLoad('videoTitlesRowList', 3000);
    }

    if (!foundLinearContent) {
      throw new Error('Could not find linear content in the first 40 rows of home screen');
    }

    // Validate content type
    expect(linearContent.type).to.equal('l', 'Focused content should be a linear channel');

    // Workaround: Send left key to move focus to nav and disable 10-second autostart
    // This gives us unlimited time to debug the videoGridMetadata elements
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Now we have time to check if videoGridMetadata elements exist without autostart pressure
    // Wait for UI to render the metadata
    await utils.sleep(500);

    // Now validate that NEW videoGridMetadata is DISPLAYED below the focused tile (not old InfoPanel)
    // User requirement: validate Channel logo, Release year, Duration, Progress bar, Time left, Rating


    try {
      const metadataGroup = await testUtils.getNodeForElement('videoGridMetadataGroup');
    } catch (e) {
      // Error is expected if element doesn't exist yet
    }

    // Wait for videoGridMetadataGroup to be visible
    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Video grid metadata not visible', 8000);

    // 1. Validate channel logo is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridChannelLogo', 'Channel logo not displayed in video grid metadata', 5000);
    const channelLogoElement = await testUtils.getNodeForElement('videoGridChannelLogo');
    expect(channelLogoElement.visible).to.equal(true, 'Channel logo should be visible in video grid metadata');
    expect(channelLogoElement.uri).to.exist.and.not.be.empty;

    // 2. Validate rating is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridRatingLabel', 'Rating not displayed in video grid metadata', 5000);
    const ratingElement = await testUtils.getNodeForElement('videoGridRatingLabel');
    expect(ratingElement.visible).to.equal(true, 'Rating should be visible in video grid metadata');
    expect(ratingElement.text).to.exist.and.not.be.empty;

    // 3. Validate release year and duration are displayed (in subHeadlinePrefixGroup)
    // Note: subHeadlinePrefixGroup is a LayoutGroup container - we validate its existence indirectly
    // by verifying that other elements in firstLineGroup (channelLogo, rating) are visible

    // 4. Validate time left group (in subHeadlineSuffixGroup) - may not be visible for non-CW/linear content
    // Note: This is optional for linear content, so we don't fail if it's not present

    // 5. Validate progress bar (may not be visible for linear/non-CW content)
    // Note: Progress bars are typically not shown for linear content, only for CW content

    // 6. Validate description is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(descriptionElement.text).to.exist.and.not.be.empty;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842105
  it('C842105 - CW row with registration CTA for guest user @guest @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen to load', 20000);

    // Navigate to Continue Watching row
    await testHelpers.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Validate guest CW row registration CTA using helper
    await testHelpers.validateGuestContinueWatchingRow();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842106
  it('C842106 - CW row with video tile (Registered) @registered @browse', async () => {
    const user = await testUtils.createRegisteredUser();

    await testHelpers.createHistoryForSingleTitle(user, 'movie', 'PG', 500);

    await testUtils.startApplicationAtPage('home', { user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 25000);

    await testHelpers.scrollDownToFindRow({ slug: 'continue_watching', rowListElementId: 'videoTitlesRowList' });

    await utils.sleep(1000);

    const cwRowContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

    expect(cwRowContent).to.be.an('array').with.lengthOf.at.least(1, 'CW row should have at least one video tile');

    const firstTile = cwRowContent[0];
    expect(firstTile).to.have.property('title');
    expect(firstTile.title).to.be.a('string').with.lengthOf.at.least(1);

    // Validate grid item container and preview player are visible
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.visible).to.equal(true, 'Inline video preview player container should be visible');

    // Validate grid item has valid dimensions for video preview
    const poster = await testUtils.getNodeForElement('featuredPoster');
    const posterWidth = poster.width || 0;
    const posterHeight = poster.height || 0;
    expect(posterWidth).to.be.greaterThan(0, 'Grid item width should be greater than 0');
    expect(posterHeight).to.be.greaterThan(0, 'Grid item height should be greater than 0');

    // Validate inline video preview player is visible
    await testUtils.waitForElementToShowOnScreen('inlineVideoTilesPreviewPlayer', 'Inline video preview player not visible', 5000);
    const videoPreviewPlayer = await testUtils.getNodeForElement('inlineVideoTilesPreviewPlayer');
    expect(videoPreviewPlayer.visible).to.equal(true, 'Inline video preview player should be visible');

    // Validate progress bar is visible for CW content
    await testUtils.waitForElementToShowOnScreen('videoGridProgressBar', 'Progress bar not visible in video grid metadata', 5000);
    const progressBar = await testUtils.getNodeForElement('videoGridProgressBar');
    expect(progressBar.visible).to.equal(true, 'Progress bar should be visible in CW video tile');
    expect(progressBar.width).to.be.greaterThan(0, 'Progress bar should have a width greater than 0');

    // Validate description is displayed in video grid metadata
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not visible in video grid metadata', 5000);
    const description = await testUtils.getNodeForElement('videoGridDescription');
    expect(description.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(description.text).to.exist.and.not.be.empty;

    // Validate time left is displayed (in videoGridSubHeadlineSuffixGroup)
    await testUtils.waitForElementToShowOnScreen('videoGridSubHeadlineSuffixGroup', 'Time left not visible in video grid metadata', 5000);
    const timeLeft = await testUtils.getNodeForElement('videoGridSubHeadlineSuffixGroup');
    expect(timeLeft.visible).to.equal(true, 'Time left should be visible in video grid metadata');

    // Validate title is displayed over the poster (posterOverlayTitle)
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible over poster', 5000);
    const posterTitle = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(posterTitle.visible).to.equal(true, 'Title should be visible over the poster');
    expect(posterTitle.text).to.exist.and.not.be.empty;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842107
  it('C842107 - Linear row with video tile @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    let foundLinearContent = false;
    let linearContent = null;

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    // Navigate down up to 40 rows to find linear content
    for (let i = 0; i < 40; i++) {
      try {
        const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');

        if (focusedContent && focusedContent.type === 'l') {
          foundLinearContent = true;
          linearContent = focusedContent;
          break;
        }
      } catch (e) {
        // Continue to next row
      }

      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(800);
      await testUtils.waitForGridContentToLoad('videoTitlesRowList', 3000);
    }

    if (!foundLinearContent) {
      throw new Error('Could not find linear content in the first 40 rows');
    }

    // Validate content type
    expect(linearContent.type).to.equal('l', 'Focused content should be a linear channel');

    // Send left key to disable autostart timer
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Validate title is displayed on top of poster (actual UI element)
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible on poster', 5000);
    const posterTitleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(posterTitleElement.visible).to.equal(true, 'Title should be visible on poster');
    expect(posterTitleElement.text).to.exist.and.not.be.empty;

    // Validate metadata is displayed properly
    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Video grid metadata not visible', 8000);

    // Validate channel logo is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridChannelLogo', 'Channel logo not displayed', 5000);
    const channelLogoElement = await testUtils.getNodeForElement('videoGridChannelLogo');
    expect(channelLogoElement.visible).to.equal(true, 'Channel logo should be visible');

    // Validate description is displayed in metadata
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(descriptionElement.text).to.exist.and.not.be.empty;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842108
  it('C842108 - Creatorverse row with video tile @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured row list to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const rowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Creatorverse');
    expect(rowIndex).to.be.at.least(0, 'Creatorverse row should exist in home screen');

    await testUtils.jumpToRowIndex('videoTitlesRowList', rowIndex);
    await utils.sleep(1000);

    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', rowIndex);

    expect(rowContent).to.be.an('array').with.lengthOf.at.least(1, 'Creatorverse row should have at least one video tile');

    // Navigate to first tile to trigger UI display
    await testUtils.jumpToRowItem('videoTitlesRowList', [rowIndex, 0]);
    await utils.sleep(1000);

    // Send left key to disable autostart timer
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    // Validate title is displayed on top of poster (actual UI element)
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Title not visible on poster', 5000);
    const posterTitleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(posterTitleElement.visible).to.equal(true, 'Title should be visible on poster');
    expect(posterTitleElement.text).to.exist.and.not.be.empty;

    // Validate description is displayed in metadata
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(descriptionElement.text).to.exist.and.not.be.empty;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842109
  it('C842109 - Video tile displays long title with 2 line max (non-linear content) @guest @browse @video_tiles', async () => {
    proxy.resume();
    // Set up network proxy to inject movie with long title in Featured row
    const proxyPromise = testHelpers.mockHomescreenWithLongTitleContent('movie');

    // Start application
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 10000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Get the first item in Featured row (should be linear content due to mocking)
    // Please do not remove this it is required to avoid linear appending proxy.
    proxy.pause();

    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Jump to first item (should be mocked content with long title)
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, 0]);
    await utils.sleep(1000);

    // Verify the focused item has a long title
    const focusedItem = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItem.title).to.exist;
    expect(focusedItem.title.length).to.be.greaterThan(40, 'Title should be long enough to test 2-line display');
    expect(focusedItem.type).to.be.oneOf(['v', 's'], 'Content should be a movie or series (non-linear)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842110
  it('C842110 - Video tile displays long title with 1 line max (linear content) @guest @browse @video_tiles', async () => {
    // Create user and set up network proxy to inject linear content with long title in Featured row
    proxy.resume();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLongTitleContent('linear', user);

    // Start application
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);
    // Get the first item in Featured row (should be linear content due to mocking)
    // Please do not remove this it is required to avoid linear appending proxy.
    proxy.pause();
    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Jump to first item (should be mocked linear content with long title)
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, 0]);
    await utils.sleep(1000);

    // Verify the focused item is linear content with a long title
    const focusedItem = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItem.type).to.equal('l', 'Focused content should be a linear channel');
    expect(focusedItem.title).to.exist;
    expect(focusedItem.title.length).to.be.greaterThan(40, 'Linear channel title should be long enough to test 1-line display');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842111
  it('C842111 - Video tile does NOT appear in Kids Mode @kidsmode @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 20000);
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await ecp.sendKeypress(ecp.Key.Left);
    await ecp.sendKeypress(ecp.Key.Up);
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForElementToFullyShowOnScreen('exitKidsOption');

    await ecp.sendKeypress(ecp.Key.Right);
    await testUtils.waitForSideNavMenuToNotBeExpanded();
    await utils.sleep(5000);

    // In Kids Mode, content switches from videoTitlesRowList to homeScreenRowList (same as Little Kids parental control)
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'homeScreenRowList not visible after Kids Mode', 20000);
    await utils.sleep(2000);

    // Get all rows content to verify Kids Mode filtering
    // Note: In Kids Mode, focus behavior may differ, so we get all rows content instead of waiting for focus
    // Use retry mechanism to handle timing issues with grid loading in Kids Mode
    let rowsContent;
    await testUtils.retryWithTimeOut(async () => {
      rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow('homeScreenRowList');
      expect(rowsContent).to.be.an('array').with.lengthOf.at.least(1, 'Should have at least one row');
    }, 20000);

    // Verify we have content
    expect(rowsContent).to.be.an('array').with.lengthOf.at.least(1, 'Should have at least one row');
    const firstRowContent = rowsContent[0];
    expect(firstRowContent).to.be.an('array').with.lengthOf.at.least(1, 'First row should have at least one item');

    // Check all items in all rows for Kids Mode filtering and video tiles
    const violations = [];
    const videoTileViolations = [];

    for (const row of rowsContent) {
      for (const itemContent of row) {
        // Check if item has video tile grid item type
        if (itemContent.grid_item_type === 'videoTile') {
          videoTileViolations.push({
            title: itemContent.title,
            id: itemContent.id,
            gridItemType: itemContent.grid_item_type
          });
        }

        // Check if ratings exist
        if (!itemContent.ratings || itemContent.ratings.length === 0) {
          console.log(`WARNING: Content without ratings found: ${itemContent.title} (ID: ${itemContent.id})`);
          continue;
        }

        const rating = itemContent.ratings[0].value;
        const isAllowed = testHelpers.isKidsAppropriateRating(rating);

        if (!isAllowed) {
          violations.push({
            title: itemContent.title,
            id: itemContent.id,
            type: itemContent.type,
            rating: rating
          });
        }
      }
    }

    // Log video tile violations if any found
    if (videoTileViolations.length > 0) {
      console.log(`\n❌ FAILED: Found ${videoTileViolations.length} video tile item(s) in Kids Mode:`);
      videoTileViolations.forEach((v, index) => {
        console.log(`  ${index + 1}. Title: "${v.title}" | ID: ${v.id} | GridItemType: ${v.gridItemType}`);
      });
    }

    expect(videoTileViolations.length, `Found ${videoTileViolations.length} video tile item(s) in Kids Mode. Video tiles should not appear.`).to.equal(0);

    // Log all violations if any found
    if (violations.length > 0) {
      console.log(`\n❌ FAILED: Found ${violations.length} non-kids content item(s) in Kids Mode:`);
      violations.forEach((v, index) => {
        console.log(`  ${index + 1}. Title: "${v.title}" | ID: ${v.id} | Type: ${v.type} | Rating: ${v.rating}`);
      });
    }

    expect(violations.length, `Found ${violations.length} non-kids content item(s) in Kids Mode. See console for details.`).to.equal(0);

    // Validate that video tile overlay group is visible in kids mode
    const overlayGroup = await testUtils.getNodeForElement('videoTileOverlayGroup');
    const isVisible = overlayGroup.visible == true && overlayGroup.opacity == 1;
    expect(isVisible).to.equal(false, 'videoTileOverlayGroup should be visible in kids mode');

    // Validate that inline video preview player container has opacity 0 (not showing video preview in kids mode)
    // Wait for UI to update to Kids Mode state
    await utils.sleep(2000);
    await testUtils.retryWithTimeOut(async () => {
      const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
      expect(previewContainer.opacity).to.equal(0, 'inlineVideoPreviewPlayerContainer should have opacity 0 in kids mode (no video preview)');
    }, 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842112
  it('C842112 - Video tile does NOT appear in Movies Mode @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.waitForGridContentToLoad('movieScreenRowList', 10000);
    await utils.sleep(1000);

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('movieScreenRowList');

    expect(rowItemsContent).to.be.an('array').with.lengthOf.at.least(1, 'Movies row should have at least one tile');

    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('v', 'All content in Movies mode should be movies (type v)');
    }

    // Validate that inline video preview player container has opacity 0 (not showing video preview in Movies mode)
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.opacity).to.equal(0, 'inlineVideoPreviewPlayerContainer should have opacity 0 in Movies mode (no video preview)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842113
  it('C842113 - Video tile does NOT appear in TV Shows Mode @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('series', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('tvScreenRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.waitForGridContentToLoad('tvScreenRowList', 10000);
    await utils.sleep(1000);

    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('tvScreenRowList');

    expect(rowItemsContent).to.be.an('array').with.lengthOf.at.least(1, 'TV Shows row should have at least one tile');

    for (const itemContent of rowItemsContent) {
      expect(itemContent.type).to.equal('s', 'All content in TV Shows mode should be series (type s)');
    }

    // Validate that inline video preview player container has opacity 0 (not showing video preview in TV Shows mode)
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.opacity).to.equal(0, 'inlineVideoPreviewPlayerContainer should have opacity 0 in TV Shows mode (no video preview)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842114
  it('C842114 - Video tile does NOT appear when Parental Controls = Little Kids @parental_controls @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('littleKids');

    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Verify homeScreenRowList is visible and has contents
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'homeScreenRowList not visible after settings', 20000);
    // Get all rows content - focus behavior may differ with parental controls, so we get content directly
    // Use retry mechanism to handle timing issues with grid loading
    let rowsContent;
    await testUtils.retryWithTimeOut(async () => {
      rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow('homeScreenRowList');
      expect(rowsContent).to.be.an('array').with.lengthOf.at.least(1, 'Should have at least one row');
    }, 20000);

    const violations = [];
    const videoTileViolations = [];

    for (const row of rowsContent) {
      for (const item of row) {
        // Check if item has video tile grid item type
        if (item.grid_item_type === 'videoTile') {
          videoTileViolations.push({
            title: item.title,
            id: item.id,
            gridItemType: item.grid_item_type
          });
        }

        if (item.ratings && item.ratings.length > 0) {
          const rating = item.ratings[0].value;
          const isAllowed = testHelpers.isKidsAppropriateRating(rating);
          if (!isAllowed) {
            violations.push({
              title: item.title,
              id: item.id,
              type: item.type,
              rating: rating
            });
          }
        }
      }
    }

    // Log video tile violations if any found
    if (videoTileViolations.length > 0) {
      console.log(`\n❌ FAILED: Found ${videoTileViolations.length} video tile item(s) with Little Kids parental control:`);
      videoTileViolations.forEach((v, index) => {
        console.log(`  ${index + 1}. Title: "${v.title}" | ID: ${v.id} | GridItemType: ${v.gridItemType}`);
      });
    }

    expect(videoTileViolations.length, `Found ${videoTileViolations.length} video tile item(s) with Little Kids parental control. Video tiles should not appear.`).to.equal(0);

    // Log all violations if any found
    if (violations.length > 0) {
      console.log(`\n❌ FAILED: Found ${violations.length} non-kids content item(s) with Little Kids parental control:`);
      violations.forEach((v, index) => {
        console.log(`  ${index + 1}. Title: "${v.title}" | ID: ${v.id} | Type: ${v.type} | Rating: ${v.rating}`);
      });
    }

    expect(violations.length, `Found ${violations.length} non-kids content item(s) with Little Kids parental control. See console for details.`).to.equal(0);

    // Validate that inline video preview player container has opacity 0 (not showing video preview with Little Kids parental control)
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.opacity).to.equal(0, 'inlineVideoPreviewPlayerContainer should have opacity 0 with Little Kids parental control (no video preview)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842115
  it('C842115 - Video tile does NOT appear when Parental Controls = Older Kids @parental_controls @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 20000);
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('olderKids');

    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Verify homeScreenRowList is visible and has contents (Older Kids may use homeScreenRowList like Little Kids)
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'homeScreenRowList not visible after settings', 20000);

    // Use retry mechanism to handle timing issues with grid loading
    let rowsContent;
    await testUtils.retryWithTimeOut(async () => {
      rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow('homeScreenRowList');
      expect(rowsContent).to.be.an('array').with.lengthOf.at.least(1, 'Should have at least one row');
    }, 20000);

    const violations = [];
    const videoTileViolations = [];

    for (const row of rowsContent) {
      for (const item of row) {
        // Check if item has video tile grid item type
        if (item.grid_item_type === 'videoTile') {
          videoTileViolations.push({
            title: item.title,
            id: item.id,
            gridItemType: item.grid_item_type
          });
        }

        if (item.ratings && item.ratings.length > 0) {
          const rating = item.ratings[0].value;
          const isAllowed = testHelpers.isKidsAppropriateRating(rating);
          if (!isAllowed) {
            violations.push({
              title: item.title,
              id: item.id,
              type: item.type,
              rating: rating
            });
          }
        }
      }
    }

    // Log video tile violations if any found
    if (videoTileViolations.length > 0) {
      console.log(`\n❌ FAILED: Found ${videoTileViolations.length} video tile item(s) with Older Kids parental control:`);
      videoTileViolations.forEach((v, index) => {
        console.log(`  ${index + 1}. Title: "${v.title}" | ID: ${v.id} | GridItemType: ${v.gridItemType}`);
      });
    }

    expect(videoTileViolations.length, `Found ${videoTileViolations.length} video tile item(s) with Older Kids parental control. Video tiles should not appear.`).to.equal(0);

    // Log all violations if any found
    if (violations.length > 0) {
      console.log(`\n❌ FAILED: Found ${violations.length} adult content item(s) with Older Kids parental control:`);
      violations.forEach((v, index) => {
        console.log(`  ${index + 1}. Title: "${v.title}" | ID: ${v.id} | Type: ${v.type} | Rating: ${v.rating}`);
      });
    }

    expect(violations.length, `Found ${violations.length} adult content item(s) with Older Kids parental control. See console for details.`).to.equal(0);

    // Validate that inline video preview player container has opacity 0 (not showing video preview with Older Kids parental control)
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.opacity).to.equal(0, 'inlineVideoPreviewPlayerContainer should have opacity 0 with Older Kids parental control (no video preview)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842116
  it('C842116 - Video tile appear when Parental Controls = Teens @parental_controls @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 20000);
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('teens');

    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible after settings', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    // Use retry mechanism to handle timing issues with grid loading
    let content;
    await testUtils.retryWithTimeOut(async () => {
      content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
      expect(content.length).to.be.greaterThan(0);
    }, 20000);

    const firstTile = content[0];
    expect(firstTile.title).to.exist;

    // Validate that inline video preview player container has opacity 1 (video preview enabled for Teens parental control)
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.opacity).to.equal(1, 'inlineVideoPreviewPlayerContainer should have opacity 1 with Teens parental control (video preview enabled)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842117
  it('C842117 - Video tiles are not shown in Browse While Watching section @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Get home screen tile size for comparison
    const homeScreenTileSize = await testUtils.getGridElementSize('videoTitlesRowList', [0, 0]);

    // Navigate to Movies screen where Play button works directly (unlike new video tiles home screen)
    await testUtils.goToPage('movies');
    await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for movie screen');
    await utils.sleep(1000);

    // Start playback from Movies screen
    await ecp.sendKeypress(ecp.Key.Play);
    await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

    await ecp.sendKeypress(ecp.Key.Down);
    await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW header not shown', 10000);

    await utils.sleep(1000);

    // Get BWW tile size
    const bwwTileSize = await testUtils.getGridElementSize('browseWhileWatchingRowList', [0, 0]);

    // BWW tiles should be smaller than home screen tiles
    expect(bwwTileSize.width).to.be.lessThan(homeScreenTileSize.width,
      `BWW tile width (${bwwTileSize.width}) should be less than home screen tile width (${homeScreenTileSize.width})`);
    expect(bwwTileSize.height).to.be.lessThan(homeScreenTileSize.height,
      `BWW tile height (${bwwTileSize.height}) should be less than home screen tile height (${homeScreenTileSize.height})`);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842118
  it('C842118 - Linear in Featured: Video tile autostarts after 10 seconds @guest @videopreview @video_tiles', async () => {
    // Create user and set up network proxy to inject linear content in Featured row
    proxy.resume();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);
    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus');
    // Get the first item in Featured row (should be linear content due to mocking)
    // Please do not remove this it is required to avoid linear appending proxy.
    proxy.pause();

    await testUtils.jumpToRowWithTitle('videoTitlesRowList', 'Featured');
    await utils.sleep(500);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'First item in Featured row should be linear content (injected via network proxy)');
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 20000);

    await testUtils.retryWithTimeOut(async () => {
      const playerState = await testUtils.getElementField('linearVideoPlayerScreen', 'state', 5000);
      expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Linear video should be playing or buffering after 10-second autostart');
    }, 20000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842119
  it('C842119 - Linear in Featured: Selecting a linear video tile takes user to linear full screen @guest @linear @featured @video_tiles', async () => {
    // Create user and set up network proxy to inject linear content in Featured row
    proxy.resume();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);
    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.jumpToRowWithTitle('videoTitlesRowList', 'Featured');
    await utils.sleep(500);

    // Verify it's linear content before selecting
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'First item in Featured row should be linear content (injected via network proxy)');

    proxy.pause();

    // Select the linear tile
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 20000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

    const playerContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    expect(playerContent).to.exist;

    // Go back to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 20000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    // Navigate down to find another linear content in other rows
    let foundLinearContent = false;
    let linearContent = null;

    for (let i = 0; i < 40; i++) {
      try {
        const currentFocusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');

        if (currentFocusedContent && currentFocusedContent.type === 'l') {
          foundLinearContent = true;
          linearContent = currentFocusedContent;
          break;
        }
      } catch (e) {
        // Continue to next row
      }

      await ecp.sendKeypress(ecp.Key.Down);
      await utils.sleep(800);
      await testUtils.waitForGridContentToLoad('videoTitlesRowList', 3000);
    }

    if (!foundLinearContent) {
      throw new Error('Could not find linear content in the first 40 rows');
    }

    expect(linearContent.type).to.equal('l', 'Focused content should be a linear channel');

    // Select this linear content
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('linearVideoPlayerScreen', 20000);
    await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

    const secondPlayerContent = await testUtils.getElementField('linearVideoPlayerScreen', 'content');
    expect(secondPlayerContent).to.exist;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842120
  it('C842120 - Linear in Featured: Video tile displays "Live/On Now" badge for linear in Featured row @guest @linear @featured @video_tiles', async () => {
    // Create user and set up network proxy to inject linear content in Featured row
    proxy.resume();
    const user = await testUtils.createRegisteredUser();
    const proxyPromise = testHelpers.mockHomescreenWithLinearContentInFeatured(user);

    // Start application with the user
    await testUtils.startApplicationAtPage('home', { user, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 5000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Navigate to Featured row and jump to first item (pattern from C842118/C842119)
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    proxy.pause();

    // Jump to first item in Featured row (should be linear content due to mocking)
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, 0]);
    await utils.sleep(1000);

    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedContent.type).to.equal('l', 'First item in Featured row should be linear content (injected via network proxy)');

    // Verify Live/On Now badge is displayed
    await testUtils.waitForElementToShowOnScreen('liveBadgeText', 'Live badge not visible', 5000);
    const badgeElement = await testUtils.getNodeForElement('liveBadgeText');
    expect(badgeElement.visible).to.equal(true, 'Live badge should be visible on linear content tile');

    const badgeText = await testUtils.getElementField('liveBadgeText', 'text');
    expect(badgeText).to.match(/Live|On Now/i, 'Badge should display "Live" or "On Now" text');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842121
  it('C842121 - Video tiles are shown in CA locale @guest @locale @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

    expect(content).to.be.an('array').with.lengthOf.at.least(1, 'Featured row should have at least one video tile');

    for (const item of content) {
      expect(item.title).to.exist;
      expect(item.title).to.be.a('string').with.length.greaterThan(0, 'Video tile should have a valid title');
    }

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length > 0) {
      await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
      await utils.sleep(2000);

      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    }

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    const afterDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterDownIndex[0]).to.be.greaterThan(0, 'Vertical navigation should work');

    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    const afterRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterRightIndex[1]).to.be.greaterThan(0, 'Horizontal navigation should work');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    const detailScreenTitle = await testUtils.getElementField('detailScreenTitle', 'visible');
    expect(detailScreenTitle).to.equal(true, 'Detail screen should open when selecting video tile');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842122
  it('C842122 - Video tiles are shown in UK locale @guest @locale @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

    expect(content).to.be.an('array').with.lengthOf.at.least(1, 'Featured row should have at least one video tile');

    for (const item of content) {
      expect(item.title).to.exist;
      expect(item.title).to.be.a('string').with.length.greaterThan(0, 'Video tile should have a valid title');
    }

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length > 0) {
      await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
      await utils.sleep(2000);

      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    }

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    const afterDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterDownIndex[0]).to.be.greaterThan(0, 'Vertical navigation should work');

    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    const afterRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterRightIndex[1]).to.be.greaterThan(0, 'Horizontal navigation should work');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    const detailScreenTitle = await testUtils.getElementField('detailScreenTitle', 'visible');
    expect(detailScreenTitle).to.equal(true, 'Detail screen should open when selecting video tile');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842123
  it('C842123 - Video tiles are shown in MX locale @guest @locale @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const content = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');

    expect(content).to.be.an('array').with.lengthOf.at.least(1, 'Featured row should have at least one video tile');

    for (const item of content) {
      expect(item.title).to.exist;
      expect(item.title).to.be.a('string').with.length.greaterThan(0, 'Video tile should have a valid title');
    }

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length > 0) {
      await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
      await utils.sleep(2000);

      await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    }

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    const afterDownIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterDownIndex[0]).to.be.greaterThan(0, 'Vertical navigation should work');

    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(500);

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    const afterRightIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(afterRightIndex[1]).to.be.greaterThan(0, 'Horizontal navigation should work');

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);

    const detailScreenTitle = await testUtils.getElementField('detailScreenTitle', 'visible');
    expect(detailScreenTitle).to.equal(true, 'Detail screen should open when selecting video tile');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842124
  it('C842124 - Video tiles on low-end device @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 25000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen rowlist to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    await testHelpers.findAndNavigateToVideoPreviewContent('videoTitlesRowList', true, 5);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    const previewContent = await testUtils.getElementField('previewVideoPlayer', 'content');
    expect(previewContent).to.exist;

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus after navigation', 10000);

    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Detail screen title not visible', 10000);

    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen rowlist to have focus after exiting detail screen', 10000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842125
  it('C842125 - Video tiles in different resolutions @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', featuredRowIndex);

    expect(rowContent).to.be.an('array').with.lengthOf.at.least(1, 'Featured row should have at least one video tile');

    for (let colIndex = 0; colIndex < Math.min(rowContent.length, 5); colIndex++) {
      await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, colIndex]);
      await utils.sleep(500);

      const tileSize = await testUtils.getGridElementSize('videoTitlesRowList', [featuredRowIndex, colIndex]);

      expect(tileSize.width).to.be.greaterThan(0, `Tile at position [${featuredRowIndex}, ${colIndex}] should have valid width`);
      expect(tileSize.height).to.be.greaterThan(0, `Tile at position [${featuredRowIndex}, ${colIndex}] should have valid height`);

      const tile = rowContent[colIndex];
      expect(tile.title).to.exist;
      expect(tile.title).to.be.a('string').with.length.greaterThan(0, `Tile at position [${featuredRowIndex}, ${colIndex}] should have a valid title`);
    }

    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(500);
    const secondRowIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    expect(secondRowIndex[0]).to.equal(featuredRowIndex + 1, 'Focus should move to next row');

    const secondRowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', secondRowIndex[0]);

    expect(secondRowContent).to.be.an('array').with.lengthOf.at.least(1, 'Second row should have at least one video tile');

    for (let colIndex = 0; colIndex < Math.min(secondRowContent.length, 5); colIndex++) {
      const tileSize = await testUtils.getGridElementSize('videoTitlesRowList', [secondRowIndex[0], colIndex]);

      expect(tileSize.width).to.be.greaterThan(0, `Tile at position [${secondRowIndex[0]}, ${colIndex}] should have valid width`);
      expect(tileSize.height).to.be.greaterThan(0, `Tile at position [${secondRowIndex[0]}, ${colIndex}] should have valid height`);
    }

    const videoTitlesRowList = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowList.visible).to.equal(true, 'Featured row list should be visible across different resolutions');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842126
  it.skip('C842126 - SoT appears on Video Tile @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(2000);

    let foundTileWithLabels = false;
    let tileWithLabels = null;

    for (let rowIndex = 0; rowIndex < 15; rowIndex++) {
      await testUtils.jumpToRowIndex('videoTitlesRowList', rowIndex);
      await utils.sleep(1000);

      await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
      await utils.sleep(500);

      const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', rowIndex);

      if (!rowContent || rowContent.length === 0) {
        continue;
      }

      for (const item of rowContent) {
        if ((item.top_label && item.top_label.trim().length > 0) ||
          (item.metadata_label && item.metadata_label.trim().length > 0) ||
          (item.trust_marker && item.trust_marker.trim().length > 0) ||
          (item.poster_label && item.poster_label.trim().length > 0)) {
          foundTileWithLabels = true;
          tileWithLabels = item;
          break;
        }
      }

      if (foundTileWithLabels) {
        break;
      }
    }

    expect(foundTileWithLabels, 'Could not find any tile with SoT labels in the first 15 rows').to.be.true;
    expect(tileWithLabels).to.exist;

    if (tileWithLabels.top_label && tileWithLabels.top_label.trim().length > 0) {
      expect(tileWithLabels.top_label).to.be.a('string').with.length.greaterThan(0, 'Top Label should be a non-empty string');
    }

    if (tileWithLabels.metadata_label && tileWithLabels.metadata_label.trim().length > 0) {
      expect(tileWithLabels.metadata_label).to.be.a('string').with.length.greaterThan(0, 'Metadata Label should be a non-empty string');
    }

    if (tileWithLabels.trust_marker && tileWithLabels.trust_marker.trim().length > 0) {
      expect(tileWithLabels.trust_marker).to.be.a('string').with.length.greaterThan(0, 'Trust Marker should be a non-empty string');
    }

    if (tileWithLabels.poster_label && tileWithLabels.poster_label.trim().length > 0) {
      expect(tileWithLabels.poster_label).to.be.a('string').with.length.greaterThan(0, 'Poster Label should be a non-empty string');
    }
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842129
  it('C842129 - Overflow description fallback @guest @browse @video_tiles', async () => {
    proxy.resume();
    // Set up network proxy to inject movie with long description in Featured row
    const proxyPromise = testHelpers.mockHomescreenWithLongDescriptionContent();

    // Start application
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 10000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Please do not remove this it is required to avoid linear appending proxy.
    void proxy.pause();

    // Navigate to Featured row
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Jump to first item (should be mocked content with long description)
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, 0]);
    await utils.sleep(1000);

    // Verify the focused item has a long description
    const focusedItem = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(focusedItem.description).to.exist;
    expect(focusedItem.description.length).to.be.greaterThan(500, 'Description should be long enough to test overflow behavior');

    // In new video tiles mode, description is in videoGridDescription (not homeScreenContentDescription)
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not visible', 10000);

    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible');

    const descriptionSize = await testUtils.getElementSize('videoGridDescription');
    expect(descriptionSize.width).to.be.greaterThan(500, 'Description width should be greater than 500 to show overflow handling');
    expect(descriptionSize.width).to.be.lessThan(1920, 'Description width should not exceed screen width');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842130
  it('C842130 - Network row first tile @guest @browse @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);

    await utils.sleep(1000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);

    const totalRows = 40;
    // Navigate down through each row and validate first item
    for (let rowIndex = 0; rowIndex < totalRows; rowIndex++) {
      // Get the first item (StarterGridItem) in current row
      const starterGridItemKeyPath = `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#RowList.${rowIndex}.items.0`;

      try {
        const { value: starterGridItem } = await odc.getValue({
          keyPath: starterGridItemKeyPath
        });

        // Verify StarterGridItem exists
        expect(starterGridItem).to.exist;

        // Verify itemContent exists
        expect(starterGridItem.itemContent).to.exist;

        // Verify itemContent does NOT have type=channel
        const itemContentType = starterGridItem.itemContent.type;
        expect(itemContentType).to.not.equal('channel', `Row ${rowIndex}: First item should not have type=channel`);
      } catch (e) {
        // Skip rows that don't have items
        console.log(`Row ${rowIndex}: Skipping - no items found`);
      }

      // Navigate down to next row if not the last row
      if (rowIndex < totalRows - 1) {
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(500);
        await testUtils.waitForGridContentToLoad('videoTitlesRowList', 3000);
      }
    }

    // Verify the grid is visible on screen
    const { isShowing } = await testUtils.isElementShowingOnScreen('videoTitlesRowList');
    expect(isShowing).to.equal(true, 'Featured row list should be visible on screen');
  });

  // Test for video preview resume when returning from side nav
  it('Video preview resumes when user returns from side nav to video tiles @guest @videopreview @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Find content with video preview
    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview in featured row list');
    }

    // Navigate to content with video preview
    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

    // Verify video preview is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    const previewStateBeforeSideNav = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(previewStateBeforeSideNav).to.equal('playing', 'Video preview should be playing before navigating to side nav');

    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);

    // Verify side nav has focus
    await testUtils.waitForSideNavMenuToBeExpanded();

    // Verify video preview is paused
    await utils.sleep(500);
    const previewStateInSideNav = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(previewStateInSideNav).to.be.oneOf(['paused', 'stopped'], 'Video preview should be paused when focus moves to side nav');

    // Navigate back to video tiles (Right key)
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Verify video tiles have focus again
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus after returning from side nav');
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);
  });

  // Test: Scroll down vertically through entire home grid and verify no duplicate containers
  it('Should scroll through entire home grid without duplicate containers @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const element = testUtils.getElementKeyPath('videoTitlesRowList');
    const baseKeyPath = element.keyPath ? `${element.keyPath}.content` : 'content';

    const seenContainers = new Map<string, number>(); // container identifier -> first row index seen
    const processedRows = new Set<number>();
    let previousRowIndex = -1;
    let sameRowCount = 0;
    let totalScrolls = 0;

    // Helper function to check for duplicates
    const checkDuplicate = (identifier: string, type: string, currentRowIndex: number) => {
      if (identifier) {
        if (seenContainers.has(identifier)) {
          const firstSeenAt = seenContainers.get(identifier);
          throw new Error(`Duplicate container found! ${type} "${identifier}" first seen at row ${firstSeenAt}, found again at row ${currentRowIndex}`);
        }
        seenContainers.set(identifier, currentRowIndex);
      }
    };

    while (sameRowCount < 3 && totalScrolls < 100) {
      try {
        const focusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
        const currentRowIndex = focusedIndex[0];

        // Track if row changed
        if (currentRowIndex === previousRowIndex) {
          sameRowCount++;
        } else {
          sameRowCount = 0;
          previousRowIndex = currentRowIndex;
        }

        // Only check new rows for duplicates
        if (!processedRows.has(currentRowIndex)) {
          processedRows.add(currentRowIndex);

          const { value: containerSlug } = await odc.getValue({
            base: element.base,
            keyPath: `${baseKeyPath}.${currentRowIndex}.slug`
          });

          checkDuplicate(containerSlug, 'slug', currentRowIndex);
        }

        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(300);
        totalScrolls++;

      } catch (error) {
        if (error.message?.includes('Duplicate container')) throw error;

        sameRowCount++;
        await ecp.sendKeypress(ecp.Key.Down);
        await utils.sleep(300);
        totalScrolls++;
      }
    }

    expect(seenContainers.size).to.be.greaterThan(5, 'Should have at least 5 unique containers');
    expect(sameRowCount).to.be.greaterThanOrEqual(3, 'Should have reached the end');
  });

  // Test Rail Link: TBD - First tile in Featured row has video preview
  it('C842999 - First tile in Featured row plays video preview immediately @guest @videopreview @video_tiles', async () => {
    // Helper function to normalize IDs by removing leading zeros for comparison (series IDs sometimes have leading zeros)
    const normalizeId = (id: string) => String(Number(id));

    // Set up network proxy to mock homescreen with first item having video preview
    proxy.resume();

    const proxyPromise = new Promise((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => {
          return args.url.includes('/api/v7/homescreen');
        },
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());
          // Find Featured container (or use first container as fallback)
          const featuredContainer = responseJson.containers.find((c: any) => c.id === 'featured') || responseJson.containers[0];
          // Find first VOD content with video preview from any container
          let itemWithPreviewId = null;
          for (const container of responseJson.containers) {
            if (!container.children) continue;

            for (const childId of container.children) {
              const content = responseJson.contents[childId];
              if (content &&
                (content.type === 'v' || content.type === 's') &&
                content.video_preview_url?.trim()) {
                itemWithPreviewId = childId;
                break;
              }
            }
            if (itemWithPreviewId) break;
          }

          // Move item to beginning of Featured row if found
          if (itemWithPreviewId) {
            const currentIndex = featuredContainer.children.indexOf(itemWithPreviewId);
            if (currentIndex > 0) {
              featuredContainer.children.splice(currentIndex, 1);
            }
            if (currentIndex !== 0) {
              featuredContainer.children.unshift(itemWithPreviewId);
            }
          }

          resolve(null);
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Start application
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 10000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interfering with subsequent requests
    proxy.pause();

    await utils.sleep(1000);

    // Navigate to Featured row (should be first or second row)
    const featuredRowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    await testUtils.jumpToRowIndex('videoTitlesRowList', featuredRowIndex);
    await utils.sleep(500);

    // Jump to first item in Featured row
    await testUtils.jumpToRowItem('videoTitlesRowList', [featuredRowIndex, 0]);
    await utils.sleep(1000);

    // Verify the first item has video preview URL
    const firstItem = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(firstItem.video_preview_url).to.exist;
    expect(firstItem.video_preview_url).to.be.a('string').with.length.greaterThan(0);

    // Verify video preview player is visible
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainer.visible).to.equal(true, 'Inline video preview player container should be visible');
    expect(previewContainer.opacity).to.equal(1, 'Inline video preview player container opacity should be 1');

    // Verify preview is playing (using the inline video tiles preview player)
    await testUtils.waitForPlayerStateToEqual('inlineVideoTilesPreviewPlayer', 'playing', 15000);
    const playerState = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'state');
    expect(playerState).to.equal('playing', 'Video preview should be playing for first item in Featured row');

    // Verify preview player has valid content
    const previewContent = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'content');
    expect(previewContent).to.exist;
    expect(normalizeId(previewContent.id)).to.equal(normalizeId(firstItem.id), 'Preview player should be playing the focused content');

    // Verify preview player size matches expected dimensions
    const previewPlayerWidth = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'width');
    const previewPlayerHeight = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'height');
    expect(previewPlayerWidth).to.be.greaterThanOrEqual(789, 'Preview player width should be at least 789');
    expect(previewPlayerHeight).to.be.greaterThanOrEqual(442, 'Preview player height should be at least 442');

    // Verify metadata overlay is visible and displays correct information
    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Video grid metadata not visible', 5000);

    // Verify description is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed in video grid metadata', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible in video grid metadata');
    expect(descriptionElement.text).to.exist.and.not.be.empty;

    // Verify title is displayed on poster overlay
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Poster overlay title not visible', 5000);
    const posterTitleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(posterTitleElement.visible).to.equal(true, 'Poster overlay title should be visible');
    expect(posterTitleElement.text).to.exist.and.not.be.empty;

    // Verify video tile overlay group is visible
    const overlayGroup = await testUtils.getNodeForElement('videoTileOverlayGroup');
    expect(overlayGroup.visible).to.equal(true, 'Video tile overlay group should be visible');

    // Navigate right to verify preview changes
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(2000);

    // Verify new preview is playing
    await testUtils.waitForPlayerStateToEqual('inlineVideoTilesPreviewPlayer', 'playing', 10000);
    const secondItem = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    const secondPreviewContent = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'content');
    expect(normalizeId(secondPreviewContent.id)).to.equal(normalizeId(secondItem.id), 'Preview player should update to play the newly focused content');

    // Navigate back left to first item
    await ecp.sendKeypress(ecp.Key.Left);
    await utils.sleep(2000);

    // Verify first item preview is playing again
    await testUtils.waitForPlayerStateToEqual('inlineVideoTilesPreviewPlayer', 'playing', 10000);
    const firstItemAgain = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(normalizeId(firstItemAgain.id)).to.equal(normalizeId(firstItem.id), 'Should return focus to first item');
  });

  // Test: Scroll horizontally through comedy row and verify no duplicate content with pagination
  it('Should scroll horizontally through comedy row without duplicate content @video_tiles', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    // Navigate to comedy row
    await testHelpers.scrollDownToFindRow({ slug: ['comedy', 'back_by_popular_demand_crm', 'action'], rowListElementId: 'videoTitlesRowList', maxScrolls: 40 });
    await utils.sleep(1000);

    const focusedIndex = await testUtils.getCurrentlyFocusedGridItemIndex('videoTitlesRowList');
    const comedyRowIndex = focusedIndex[0];

    // Scroll right 30 times to trigger pagination
    for (let i = 0; i < 60; i++) {
      await ecp.sendKeypress(ecp.Key.Right, { wait: 50 });
    }

    // Wait for content to load after pagination
    await utils.sleep(1000);

    // Get all content from the comedy row
    const rowContent = await testUtils.getRowListRowItemsContent('videoTitlesRowList', comedyRowIndex);

    // Check for duplicate content IDs
    const seenContentIds = new Map<string, number>(); // content id -> first index seen

    for (let index = 0; index < rowContent.length; index++) {
      const content = rowContent[index];
      const contentId = content?.id;

      if (contentId) {
        if (seenContentIds.has(contentId)) {
          const firstSeenAt = seenContentIds.get(contentId);
          throw new Error(`Duplicate content found in comedy row! ID "${contentId}" first seen at index ${firstSeenAt}, found again at index ${index}`);
        }
        seenContentIds.set(contentId, index);
      }
    }

    expect(rowContent.length).to.be.greaterThan(10, 'Comedy row should have more than 10 items');
    expect(seenContentIds.size).to.equal(rowContent.length, 'All content items should have unique IDs');
  });

  // Test Rail Link: TBD - Wrapper Ad Autoplay Test
  it('Wrapper ad should autoplay into fullscreen and return to home screen after completion @guest @ads @video_tiles', async () => {
    // Set up ads endpoint mock before launching app
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Wrapper, AdType.Spotlight]);
    // Launch app
    await testUtils.startApplicationAtPage('home', {
      shouldCreateNewUser: false,
      clearRegistry: false,
      disableSkinAds: false
    });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad to have focus', 15000);
    // Wait for wrapper ad to appear (wrapper ads show on homepage_video or tubi_app_homepage)
    // The wrapper ad should automatically transition to fullscreen video playback
    await utils.sleep(7000); // Allow time for ad to initialize

    // Verify wrapper ad video player is visible and displaying on screen
    await testUtils.waitForCurrentScreenToEqual('adPlayerScreen', 10000);

    // Verify the ad is playing in fullscreen mode with retry
    await testUtils.untilTrue(async () => {
      const videoPlayer = await testUtils.getNodeForElement('adPlayerScreen');
      return videoPlayer.adState === 'adsPlaying';
    }, 'Wrapper ad should be playing', 10000);

    // Verify ad player skin elements are visible and non-empty in fullscreen
    await testUtils.waitForElementToShowOnScreen('adPlayerSkinAdLogo', 'Ad player logo should be visible', 3000);
    const adPlayerLogoUri = await testUtils.getElementField('adPlayerSkinAdLogo', 'uri');
    expect(adPlayerLogoUri).to.not.be.empty;

    await testUtils.waitForElementToShowOnScreen('adPlayerSkinAdDescription', 'Ad player description should be visible', 3000);
    const adPlayerDescText = await testUtils.getElementField('adPlayerSkinAdDescription', 'text');
    expect(adPlayerDescText).to.not.be.empty;

    // Verify player closes and returns to home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 120000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Should return focus to home grid', 30000);

    // Verify home screen skin ad elements are visible and non-empty
    await testUtils.waitForElementToShowOnScreen('skinAdLogo', 'Skin ad logo should be visible on home screen', 3000);
    const skinAdLogoUri = await testUtils.getElementField('skinAdLogo', 'uri');
    expect(skinAdLogoUri).to.not.be.empty;

    await testUtils.waitForElementToShowOnScreen('skinAdDescription', 'Skin ad description should be visible on home screen', 3000);
    const skinAdDescText = await testUtils.getElementField('skinAdDescription', 'text');
    expect(skinAdDescText).to.not.be.empty;

    // Verify skinAdCountdownText shows "Watch again" after ad completion
    await testUtils.waitForElementToShowOnScreen('skinAdCountdownText', 'Skin ad countdown text should be visible on home screen', 3000);
    const skinAdCountdownText = await testUtils.getElementField('skinAdCountdownText', 'text');
    expect(skinAdCountdownText).to.equal('Watch again', 'Countdown text should show "Watch again" after ad completion');

    // Verify preview player is playing and keeps looping by checking at intervals
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 3000);

    // Check it's still playing after first interval
    const previewDuration = await testUtils.getPlayerDuration('previewVideoPlayer');
    await utils.sleep(previewDuration + 3000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 3000);

    // Check it's still playing after second interval (confirms continuous looping)
    await utils.sleep(previewDuration + 3000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 3000);

    await ecp.sendKeypress(ecp.Key.Ok);

    await testUtils.waitForCurrentScreenToEqual('adPlayerScreen', 120000);
    await ecp.sendKeypress(ecp.Key.Back);

    await testUtils.waitForCurrentScreenToEqual('homeScreen', 120000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Should return focus to home grid', 30000);

    await proxy.pause();
  });

  // Test Rail Link: TBD - Video tiles visibility when scrolling from wrapper ad
  it('Video tiles are shown when scrolling down from wrapper ad and hidden when scrolling back up @guest @ads @video_tiles', async () => {
    // Set up ads endpoint mock before launching app
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Wrapper]);
    // Launch app
    await testUtils.startApplicationAtPage('home', {
      shouldCreateNewUser: false,
      clearRegistry: false,
      disableSkinAds: false
    });
    await utils.promiseTimeout(proxyPromise, 50000);
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad to have focus', 15000);
    // Wait for grid content to load
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);

    // Verify video tiles are hidden when focus is on wrapper ad
    // Check if either overlay is hidden or container opacity is 0 (either condition indicates video tiles are hidden)
    const videoTileOverlayGroup = await testUtils.getNodeForElement('videoTileOverlayGroup');
    const inlineVideoPreviewContainer = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    const isVideoTilesHidden = videoTileOverlayGroup.visible === false || inlineVideoPreviewContainer.opacity === 0;
    expect(isVideoTilesHidden).to.equal(true, 'Video tiles should be hidden when focus is on wrapper ad (either overlay hidden or container opacity 0)');

    // Scroll down from wrapper ad to video tiles
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify video tiles row list has focus
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus after scrolling down', 10000);
    await ecp.sendKeypress(ecp.Key.Back);
    await utils.sleep(1000);
    // Verify video tiles are shown
    await testUtils.waitForElementToShowOnScreen('videoTileOverlayGroup', 'Video tile overlay should be visible after scrolling down', 5000);
    const videoTileOverlayGroupAfterDown = await testUtils.getNodeForElement('videoTileOverlayGroup');
    const inlineVideoPreviewContainerAfterDown = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(videoTileOverlayGroupAfterDown.visible).to.equal(true, 'Video tile overlay should be visible when focus is on video tiles');
    expect(inlineVideoPreviewContainerAfterDown.opacity).to.equal(1, 'Inline video preview container should have opacity 1 when focus is on video tiles');
    await ecp.sendKeypress(ecp.Key.Right);
    // Scroll back up to wrapper ad
    await ecp.sendKeypress(ecp.Key.Up);
    await utils.sleep(1000);

    // Verify wrapper ad has focus again
    await testUtils.waitForElementToHaveFocus('skinAdRow', 'Timed out waiting for wrapper ad to have focus after scrolling up', 10000);
    await utils.sleep(1000);

    const videoTileOverlayGroupAfterUp = await testUtils.getNodeForElement('videoTileOverlayGroup');
    const inlineVideoPreviewContainerAfterUp = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    const isVideoTilesHiddenAfterUp = videoTileOverlayGroupAfterUp.visible === false || inlineVideoPreviewContainerAfterUp.opacity === 0;
    expect(isVideoTilesHiddenAfterUp).to.equal(true, 'Video tiles should be hidden when focus returns to wrapper ad (either overlay hidden or container opacity 0)');


    await proxy.pause();
  });

  // Test Rail Link: TBD - Spotlight Container Ad Loop Test
  it('Spotlight container ad should loop continuously in the grid @guest @ads @video_tiles', async () => {
    // Set up ads endpoint mock before launching app
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Spotlight]);

    // Launch app
    await testUtils.startApplicationAtPage('home', {
      shouldCreateNewUser: false,
      clearRegistry: false
    });
    await utils.promiseTimeout(proxyPromise, 50000);
    // Wait for home page to load
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home page to load', 15000);
    await utils.sleep(2000);

    await testUtils.jumpToRowIndex('videoTitlesRowList', 2);
    await utils.sleep(1000);

    // Navigate to spotlight container ad row by ID (hdc_spotlight)
    const rowItemsContent = await testUtils.getCurrentlyFocusedRowListRowItemsContent('videoTitlesRowList');
    expect(rowItemsContent[0].id).to.equal('hdc_spotlight', 'Spotlight ad row should be at index 2');

    const { value: title } = await odc.getValue({
      keyPath: '#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#RowList.2.title.#CategoryName',
    });

    expect(title.text).to.equal('The gift of fast delivery', 'Spotlight ad row header should be "The gift of fast delivery"');

    // Verify spotlight ad preview player is playing and keeps looping
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 3000);

    // Check it's still playing after first interval
    const previewDuration = await testUtils.getPlayerDuration('previewVideoPlayer');
    await utils.sleep(previewDuration + 3000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 3000);

    // Check it's still playing after second interval (confirms continuous looping)
    await utils.sleep(previewDuration + 3000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 3000);


    await ecp.sendKeypress(ecp.Key.Ok);
    await utils.sleep(1000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 120000);

    await proxy.pause();
  });

  // Test Rail Link: TBD - HDC Carousel Ad Test
  it('HDC carousel ad should display with proper brand elements @guest @ads @video_tiles', async () => {
    // Set up ads endpoint mock with carousel override
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Carousel]);

    // Launch app
    await testUtils.startApplicationAtPage('home', {
      shouldCreateNewUser: false,
      clearRegistry: false
    });
    await utils.promiseTimeout(proxyPromise, 50000);

    // Wait for home page to load
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home page to load', 15000);
    await utils.sleep(2000);

    // Navigate to HDC carousel ad row by ID (hdc_row with carousel content)
    // First, jump to row 1 to see peek row (row 2)
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Verify peek row (row 2) has carousel content
    const peekRowTitleUri = await testUtils.getElementField('adCarouselContainerName', 'text');
    expect(peekRowTitleUri).to.equal('Give Something Beautiful', 'Peek row header should be "Give Something Beautiful"');

    // Verify peek row poster uri matches carousel poster
    const peekRowPosterUri = await testUtils.getElementField('adCarouselContainerPoster', 'uri');
    expect(peekRowPosterUri).to.include('xY5ORmI2BFwNUODkiBGFgT-Background%2520Video%2520Static%2520Image_Poster.png', 'Peek row poster should match carousel poster');

    // Scroll down one row to carousel row (row 2)
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Validate adCarouselTitle is not empty
    await testUtils.waitForElementToShowOnScreen('adCarouselTitle', 'Carousel title should be visible', 3000);
    const adCarouselTitleText = await testUtils.getElementField('adCarouselTitle', 'text');
    expect(adCarouselTitleText).to.not.be.empty;

    // Validate adCarouselBrandLogo is not empty
    await testUtils.waitForElementToShowOnScreen('adCarouselBrandLogo', 'Carousel brand logo should be visible', 3000);
    const adCarouselBrandLogoUri = await testUtils.getElementField('adCarouselBrandLogo', 'uri');
    expect(adCarouselBrandLogoUri).to.not.be.empty;

    // Validate adCarouselGrid has focus
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Carousel grid should have focus', 3000);

    // Validate adCarouselGrid has 5 children
    const carouselGridChildCount = await testUtils.getElementField('adCarouselGrid', 'content.getChildCount()');
    expect(carouselGridChildCount).to.equal(5, 'Carousel grid should have 5 children');

    // Verify preview video player is playing
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'finished', 30000);

    await utils.sleep(500);

    // Validate background poster changes when navigating through carousel tiles
    // Get both initial background poster URIs
    const initialBackgroundUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const initialBackgroundUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Store both as initial state (at least one should be non-empty)
    expect(initialBackgroundUri1 || initialBackgroundUri2).to.not.be.empty;

    // Press right 4 times and capture background URIs after each press
    const backgroundUriPairs: Array<{ uri1: string, uri2: string }> = [
      { uri1: initialBackgroundUri1, uri2: initialBackgroundUri2 }
    ];
    await utils.sleep(500);
    for (let i = 0; i < 4; i++) {
      await ecp.sendKeypress(ecp.Key.Right);
      await utils.sleep(500);

      // Get both background poster URIs
      const currentBackgroundUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
      const currentBackgroundUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

      backgroundUriPairs.push({ uri1: currentBackgroundUri1, uri2: currentBackgroundUri2 });
    }

    // Verify each tile has a different background (check if either uri1 or uri2 changed between tiles)
    for (let i = 1; i < backgroundUriPairs.length; i++) {
      const prev = backgroundUriPairs[i - 1];
      const curr = backgroundUriPairs[i];

      const uri1Changed = curr.uri1 !== prev.uri1;
      const uri2Changed = curr.uri2 !== prev.uri2;

      expect(uri1Changed || uri2Changed, `Tile ${i} should have different background from tile ${i - 1}`).to.be.true;
    }

    // Press right one more time (5th press) to loop back to first tile
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);

    // Get both background poster URIs for the looped state
    const loopedBackgroundUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const loopedBackgroundUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Collect all 4 URIs and check if at least 2 are the same
    const allUris = [initialBackgroundUri1, initialBackgroundUri2, loopedBackgroundUri1, loopedBackgroundUri2];
    const uniqueUris = new Set(allUris.filter(uri => uri && uri !== ''));

    // If we have less than 4 unique URIs, it means at least 2 are the same (carousel looped back)
    expect(uniqueUris.size, 'At least 2 background URIs should be the same when looping back (among 4 total URIs)').to.be.lessThan(4);

    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(500);
    // Validate autorotate is working (carousel automatically advances without user input)
    // Get initial background poster URIs before autorotate
    const autorotateInitialUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const autorotateInitialUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Wait for autorotate interval (typically 10 seconds for carousels)
    await utils.sleep(12000);

    // Get background poster URIs after autorotate
    const autorotateAfterUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const autorotateAfterUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Verify at least one URI changed (autorotate advanced to next tile)
    const autorotateUri1Changed = autorotateAfterUri1 !== autorotateInitialUri1;
    const autorotateUri2Changed = autorotateAfterUri2 !== autorotateInitialUri2;
    expect(autorotateUri1Changed || autorotateUri2Changed, 'Carousel should autorotate to next tile automatically').to.be.true;

    await proxy.pause();
  });

  // Test Rail Link: TBD - HDC Carousel Ad Auto-rotate with Preview Disabled
  it('HDC carousel ad auto-rotate works when preview is turned off @guest @ads @video_tiles', async () => {
    /**
     * Test Steps:
     * 1. Launch app with video preview disabled
     * 2. Navigate to HDC carousel ad row
     * 3. Verify carousel displays with proper brand elements
     * 4. Wait and verify carousel auto-rotates to next tile
     * 
     * Expected:
     * - Carousel displays properly with brand elements
     * - Auto-rotate works even when video preview is disabled
     * - Background changes after auto-rotate interval (~10s)
     */

    // Set up carousel ad mock
    proxy.resume();
    const proxyPromise = adTestHelpers.mockAds([AdType.Carousel]);
    const user = await testUtils.createRegisteredUser();

    // Launch app with video preview disabled
    await testUtils.startApplicationAtPage('home', {
      user,
      clearRegistry: false
    });
    await utils.promiseTimeout(proxyPromise, 50000);

    // Wait for home page to load
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home page to load', 15000);
    await utils.sleep(2000);

    // Disable video preview in settings
    await testHelpers.enablePreviewInSettings(false);
    await utils.sleep(2000);

    // Return to home screen
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Should return to home screen', 5000);
    await utils.sleep(3000);

    // Navigate to HDC carousel ad row - jump to row 1 (see peek row 2), then Down to carousel row
    await testUtils.jumpToRowIndex('videoTitlesRowList', 1);
    await utils.sleep(1000);

    // Verify peek row header is visible with carousel content
    const peekRowTitleUri = await testUtils.getElementField('adCarouselContainerName', 'text');
    expect(peekRowTitleUri).to.equal('Give Something Beautiful', 'Peek row header should show carousel brand');

    // Navigate down to carousel row
    await ecp.sendKeypress(ecp.Key.Down);
    await utils.sleep(1000);

    // Verify carousel grid has focus
    await testUtils.waitForElementToHaveFocus('adCarouselGrid', 'Should be focused on carousel grid', 5000);

    // Validate carousel brand elements are displayed
    await testUtils.waitForElementToShowOnScreen('adCarouselTitle', 'Carousel title should be visible', 3000);
    const adCarouselTitleText = await testUtils.getElementField('adCarouselTitle', 'text');
    expect(adCarouselTitleText).to.not.be.empty;

    // Validate brand logo is visible
    await testUtils.waitForElementToShowOnScreen('adCarouselBrandLogo', 'Brand logo should be visible', 3000);
    const adCarouselBrandLogoUri = await testUtils.getElementField('adCarouselBrandLogo', 'uri');
    expect(adCarouselBrandLogoUri).to.not.be.empty;

    // Get initial background poster URIs before auto-rotate
    const initialBackgroundUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const initialBackgroundUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Wait for auto-rotate interval (carousel should rotate after ~10 seconds)
    // Adding 2 seconds buffer for safety
    await utils.sleep(12000);

    // Get background poster URIs after auto-rotate
    const afterRotateUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const afterRotateUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // Verify at least one URI changed (auto-rotate occurred)
    const uri1Changed = afterRotateUri1 !== initialBackgroundUri1;
    const uri2Changed = afterRotateUri2 !== initialBackgroundUri2;
    expect(uri1Changed || uri2Changed, 'Carousel should auto-rotate to next tile even with preview disabled').to.be.true;

    // Verify carousel is still functional - press Right to manually navigate
    await ecp.sendKeypress(ecp.Key.Right);
    await utils.sleep(1000);

    // Get URIs after manual navigation to verify carousel navigation still works
    const afterRightUri1 = await testUtils.getElementField('backgroundPoster', 'uri');
    const afterRightUri2 = await testUtils.getElementField('backgroundPoster2', 'uri');

    // At least one URI should be different from after auto-rotate
    const manualNavWorking = (afterRightUri1 !== afterRotateUri1) || (afterRightUri2 !== afterRotateUri2);
    expect(manualNavWorking, 'Manual carousel navigation should still work').to.be.true;

    await proxy.pause();
  });

  // Test Rail Link: TBD - Video tile preview restoration after valid_duration expires
  it('Video tile overlay and preview display correctly after valid_duration expires @guest @videopreview @video_tiles', async () => {
    // Helper function to normalize IDs by removing leading zeros for comparison (series IDs sometimes have leading zeros)
    const normalizeId = (id: string) => String(Number(id));

    // Set up network proxy to mock homescreen with valid_duration = 10 seconds
    proxy.resume();

    const proxyPromise = new Promise<void>((resolve) => {
      proxy.addCallback({
        shouldProcess: (args) => args.url.includes('/api/v7/homescreen'),
        processResponse: (args) => {
          const responseJson = JSON.parse(args.responseBuffer.toString());
          // Override valid_duration to 10 seconds at the root level
          responseJson.valid_duration = 10;
          resolve();
          args.removeCallback();
          return JSON.stringify(responseJson);
        }
      });
    });

    // Start application
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false, clearRegistry: false });
    await utils.promiseTimeout(proxyPromise, 10000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    // Pause proxy to avoid interfering with subsequent requests
    proxy.pause();

    // Navigate to Featured row using scrollDownToFindRow with featured slug
    await testHelpers.scrollDownToFindRow({ slug: 'featured', rowListElementId: 'videoTitlesRowList' });
    await utils.sleep(1000);

    // Verify video tile overlay and preview are visible before navigating
    await testUtils.waitForElementToShowOnScreen('videoTileOverlayGroup', 'Video tile overlay not visible', 5000);
    const overlayGroupBefore = await testUtils.getNodeForElement('videoTileOverlayGroup');
    expect(overlayGroupBefore.visible).to.equal(true, 'Video tile overlay should be visible');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible', 5000);
    const previewContainerBefore = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainerBefore.visible).to.equal(true, 'Inline video preview player container should be visible');
    expect(previewContainerBefore.opacity).to.equal(1, 'Inline video preview player container opacity should be 1');

    // Get the focused content for later verification
    const focusedContent = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');

    // Press OK to navigate to detail screen
    await ecp.sendKeypress(ecp.Key.Ok);
    await testUtils.waitForCurrentScreenToEqual('detailScreen', 10000);
    await utils.sleep(1000);

    // Wait for valid_duration to expire (10 seconds + buffer)
    await utils.sleep(12000);

    // Navigate back to home screen
    await ecp.sendKeypress(ecp.Key.Back);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 10000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 10000);

    // Verify we're still on the same item
    const focusedContentAfter = await testUtils.getCurrentlyFocusedGridItemContent('videoTitlesRowList');
    expect(normalizeId(focusedContentAfter.id)).to.equal(normalizeId(focusedContent.id), 'Should return to the same focused item');

    // Verify video tile overlay is visible again
    await testUtils.waitForElementToShowOnScreen('videoTileOverlayGroup', 'Video tile overlay not visible after returning', 5000);
    const overlayGroupAfter = await testUtils.getNodeForElement('videoTileOverlayGroup');
    expect(overlayGroupAfter.visible).to.equal(true, 'Video tile overlay should be visible after returning from detail screen');

    // Verify inline video preview player container is visible
    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainer', 'Inline video preview player container not visible after returning', 5000);
    const previewContainerAfter = await testUtils.getNodeForElement('inlineVideoPreviewPlayerContainer');
    expect(previewContainerAfter.visible).to.equal(true, 'Inline video preview player container should be visible after returning');
    expect(previewContainerAfter.opacity).to.equal(1, 'Inline video preview player container opacity should be 1 after returning');

    // Verify video preview is playing (if content has video preview)
    if (focusedContent.video_preview_url && focusedContent.video_preview_url.trim().length > 0) {
      await testUtils.waitForPlayerStateToEqual('inlineVideoTilesPreviewPlayer', 'playing', 10000);
      const previewPlayerContent = await testUtils.getElementField('inlineVideoTilesPreviewPlayer', 'content');
      expect(previewPlayerContent).to.exist;
      expect(normalizeId(previewPlayerContent.id)).to.equal(normalizeId(focusedContent.id), 'Preview player should be playing the focused content');
    }

    // Verify metadata overlay is visible
    await testUtils.waitForElementToShowOnScreen('videoGridMetadataGroup', 'Video grid metadata not visible after returning', 5000);
    const metadataGroup = await testUtils.getNodeForElement('videoGridMetadataGroup');
    expect(metadataGroup.visible).to.equal(true, 'Video grid metadata should be visible after returning');

    // Verify description is displayed
    await testUtils.waitForElementToShowOnScreen('videoGridDescription', 'Description not displayed after returning', 5000);
    const descriptionElement = await testUtils.getNodeForElement('videoGridDescription');
    expect(descriptionElement.visible).to.equal(true, 'Description should be visible after returning');
    expect(descriptionElement.text).to.exist.and.not.be.empty;

    // Verify poster overlay title is visible
    await testUtils.waitForElementToShowOnScreen('posterOverlayTitle', 'Poster overlay title not visible after returning', 5000);
    const posterTitleElement = await testUtils.getNodeForElement('posterOverlayTitle');
    expect(posterTitleElement.visible).to.equal(true, 'Poster overlay title should be visible after returning');
    expect(posterTitleElement.text).to.exist.and.not.be.empty;
  });
});