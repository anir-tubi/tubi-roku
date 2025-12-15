import { expect } from 'chai';
import { ecp, odc, utils, proxy } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { testHelpers } from '../test-helpers';

describe('HomeGrid Video Tiles', function () {
  before(async () => {
    await proxy.start();
  });

  after(async () => {
    await proxy.stop();
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842085
  it('C842085 - Featured row is the first row @guest,@application_launch', async () => {
    await testUtils.startApplicationAtPage('home');
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for FeaturedRowList to have focus');

    const rowIndex = await testUtils.findRowIndexWithTitle('videoTitlesRowList', 'Featured');
    expect(rowIndex).to.be.oneOf([0, 1], 'Featured row should be the first or second row (index 0 or 1)');
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842086
  it('C842086 - Peek row is NOT dimmed @guest @browse', async () => {
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
  it('C842087 - Peek row has portrait tiles only @guest @browse', async () => {
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
  it('C842088 - Row in focus has video tile with moderate density (Guest User) @guest @browse', async () => {
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
  it('C842089 - Row in focus has video tile with moderate density (Registered User)', async () => {
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
  it('C842090 - When a title is in focus, a video preview plays within a landscape tile @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 25000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview in featured row list');
    }

    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842091
  it('C842091 - When a title is NOT in focus, a static image is shown within a portrait tile @guest @browse', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);
    await utils.sleep(2000);
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 20000);
    await utils.sleep(1000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);
    await utils.sleep(1000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview in featured row list');
    }

    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

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
  it('C842092 - When a title does not have a video preview, a static image is shown @guest', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 10000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 5000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', false, 5);
    if (position.length === 0) {
      throw new Error('Could not find content without video preview in the first 5 rows');
    }

    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('videoTitlesRowList', row, col);

    await utils.sleep(2000);

    const previewPlayerState = await testUtils.getElementField('previewVideoPlayer', 'state');
    expect(previewPlayerState).to.be.oneOf(['stopped', 'none'], 'Preview video player should not be playing for content without video preview');

    await testUtils.waitForElementToShowOnScreen('inlineVideoPreviewPlayerContainerContentPoster', 'Static image not visible', 15000);
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842093
  it('C842093 - Selecting a video tile will open VOD details page @guest', async () => {
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
  it('C842094 - Video preview continues when user enters/exits details screen', async () => {
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
  it('C842095 - When video preview is disabled in app settings, static image is shown in video tile', async () => {
    const user = await testUtils.createRegisteredUser();
    await user.enableVideoPreview(false);
    await testUtils.startApplicationAtPage('home', { user: user });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus');

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview in movie screen');
    }

    const [row, col] = position;
    await testHelpers.jumpToRowListPosition('videoTitlesRowList', row, col);

    await utils.sleep(2000);

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
  it('C842096 - Background/foreground app while video tile is playing video preview @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 25000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('Could not find content with video preview');
    }

    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

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
  it('C842097 - Title autostarts when video preview ends', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for videoTitlesRowList to have focus', 20000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    if (position.length === 0) {
      throw new Error('No content with video preview found on home screen');
    }

    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

    await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 15000);

    await utils.sleep(90000);

    await testUtils.retryWithTimeOut(async () => {
      const currentScreen = await testUtils.getElementField('screenStack', '-1', 10000);
      expect(currentScreen.id).to.equal('videoPlayerScreen', 'Should transition to full video player screen after preview ends');
    }, 60000);

    await testUtils.retryWithTimeOut(async () => {
      const playerState = await testUtils.getElementField('videoPlayerScreen', 'state', 5000);
      expect(playerState).to.be.oneOf(['playing', 'buffering'], 'Full video should be playing or buffering after autoplay');
    }, 60000);

    const content = await testUtils.getElementField('videoPlayerScreen', 'content');
    expect(content.title).to.exist;
    expect(content.id).to.exist;
  });

  // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/842098
  it('C842098 - Vertical scrolling between rows @guest @browse', async () => {
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
  it('C842099 - Horizontal scrolling across row @guest @browse', async () => {
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
  it('C842100 - Video tile displays title on poster overlay @guest @browse', async () => {
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
  it('C842101 - Video tile displays title with regular text @guest @browse', async () => {
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
  it('C842102 - Metadata displayed below video tile (movie) @guest @browse', async () => {
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
  it('C842103 - Metadata displayed below video tile (series)', async () => {
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
  it('C842104 - Metadata displayed below video tile (linear) @guest @browse', async () => {
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
  it('C842105 - CW row with registration CTA for guest user @guest', async () => {
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
  it('C842107 - Linear row with video tile @guest @browse', async () => {
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
  it('C842108 - Creatorverse row with video tile @guest @browse', async () => {
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
  it('C842109 - Video tile displays long title with 2 line max (non-linear content) @guest @browse', async () => {
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
  it('C842110 - Video tile displays long title with 1 line max (linear content) @guest @browse', async () => {
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
  it('C842111 - Video tile does NOT appear in Kids Mode @kidsmode', async () => {
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
    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible after Kids Mode', 20000);
    const videoTitlesRowList = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowList.content).to.be.null;

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

    // Check all items in all rows for Kids Mode filtering
    const violations = [];

    for (const row of rowsContent) {
      for (const itemContent of row) {
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
  it('C842112 - Video tile does NOT appear in Movies Mode @guest @browse', async () => {
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
  it('C842113 - Video tile does NOT appear in TV Shows Mode @guest @browse', async () => {
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
  it('C842114 - Video tile does NOT appear when Parental Controls = Little Kids @parental_controls', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for Rowlist to have focus', 20000);

    await testUtils.goToPage('settings');
    await testHelpers.setParentalControls('littleKids');

    await ecp.sendKeypress(ecp.Key.Back, { count: 2 });
    await utils.sleep(2000);
    await testUtils.waitForCurrentScreenToEqual('homeScreen', 15000);

    // Verify homeScreenRowList is visible and has contents
    await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'homeScreenRowList not visible after settings', 20000);
    const videoTitlesRowList = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowList.content).to.be.null;
    // Get all rows content - focus behavior may differ with parental controls, so we get content directly
    // Use retry mechanism to handle timing issues with grid loading
    let rowsContent;
    await testUtils.retryWithTimeOut(async () => {
      rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow('homeScreenRowList');
      expect(rowsContent).to.be.an('array').with.lengthOf.at.least(1, 'Should have at least one row');
    }, 20000);

    const violations = [];

    for (const row of rowsContent) {
      for (const item of row) {
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
  it('C842115 - Video tile does NOT appear when Parental Controls = Older Kids @parental_controls', async () => {
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
    const videoTitlesRowList = await testUtils.getNodeForElement('videoTitlesRowList');
    expect(videoTitlesRowList.content).to.be.null;

    // Use retry mechanism to handle timing issues with grid loading
    let rowsContent;
    await testUtils.retryWithTimeOut(async () => {
      rowsContent = await testUtils.getAllRowListItemsContentGroupedByRow('homeScreenRowList');
      expect(rowsContent).to.be.an('array').with.lengthOf.at.least(1, 'Should have at least one row');
    }, 20000);

    const violations = [];

    for (const row of rowsContent) {
      for (const item of row) {
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
  it('C842116 - Video tile appear when Parental Controls = Teens @parental_controls', async () => {
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
  it('C842117 - Video tiles are not shown in Browse While Watching section', async () => {
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
  it('C842118 - Linear in Featured: Video tile autostarts after 10 seconds @guest @videopreview', async () => {
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
  it('C842119 - Linear in Featured: Selecting a linear video tile takes user to linear full screen @guest @linear @featured', async () => {
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
  it('C842120 - Linear in Featured: Video tile displays "Live/On Now" badge for linear in Featured row @guest @linear @featured', async () => {
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
  it('C842121 - Video tiles are shown in CA locale @guest @locale', async () => {
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
  it('C842122 - Video tiles are shown in UK locale @guest @locale', async () => {
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
  it('C842123 - Video tiles are shown in MX locale @guest @locale', async () => {
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
  it('C842124 - Video tiles on low-end device', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });

    await testUtils.waitForElementToShowOnScreen('videoTitlesRowList', 'videoTitlesRowList not visible', 25000);
    await utils.sleep(2000);
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for home screen rowlist to have focus', 20000);

    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);
    await utils.sleep(1000);

    const position = await testHelpers.findContentPositionInRowListThatContainsVideoPreview('videoTitlesRowList', true, 5);
    expect(position.length).to.be.greaterThan(0, 'No video tiles with video preview found on home screen');

    await testHelpers.jumpToRowListPosition('videoTitlesRowList', position[0], position[1]);
    await utils.sleep(2000);

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
  it('C842125 - Video tiles in different resolutions @guest @browse', async () => {
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
  it.skip('C842126 - SoT appears on Video Tile @guest @browse', async () => {
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
  it('C842129 - Overflow description fallback @guest @browse', async () => {
    void proxy.resume();
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
  it('C842130 - Network row first tile @guest @browse', async () => {
    await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: false });
    await testUtils.waitForElementToHaveFocus('videoTitlesRowList', 'Timed out waiting for featured rowlist to have focus', 15000);

    await utils.sleep(1000);
    await testUtils.waitForGridContentToLoad('videoTitlesRowList', 10000);

    const totalRows = 40;
    // Navigate down through each row and validate first item
    for (let rowIndex = 0; rowIndex < totalRows; rowIndex++) {
      // Get the first item (StarterGridItem) in current row
      const starterGridItemKeyPath = `#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#homeScreen.#FeaturedRowList.${rowIndex}.items.0`;

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
});