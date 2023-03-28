import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';


describe('Video Preview', function () {
  it('C257895 - Verify that High TVT Evergreen titles will have Video Preview clips @videopreview', async () => {
    await testUtils.startApplicationAtPage('home', true);

    // Navigate to search screen
    await testUtils.goToPage('search');

    await ecp.sendText('zapped');

    // Navigate right until the grid is in focus
    await testUtils.untilTrue(async () => {
      await ecp.sendKeyPress(ecp.Key.Right);
      const {value: id} = await odc.getValue({
        base: 'focusedNode',
        keyPath: 'id'
      });
      return id === 'ResultGrid';
    }, 'ResultGrid never obtained focus');

    // Wait until our content is loaded
    await odc.onFieldChangeOnce({
      base: 'focusedNode',
      keyPath: 'content',
      match: {
        base: 'focusedNode',
        keyPath: 'content.0.title',
        value: 'Zapped'
      }
    });

    // Go to the detail page
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Add the item to the user's queue
    await testUtils.selectMenuItem('detailScreenMenu', 'Add to My List');

    // Wait until menu item switches so we know it was added to their my list
    await testUtils.untilTrue(async () => {
      const index = await testUtils.findRowIndexWithTitle('detailScreenMenu', 'Remove from My List');
      return index >= 0;
    }, 'Failed adding item to my list');

    // Navigate back to the home screen
    await ecp.sendKeyPress(ecp.Key.Back);
    await ecp.sendKeyPress(ecp.Key.Back);
    await ecp.sendKeyPress(ecp.Key.Back);
    await ecp.sendKeyPress(ecp.Key.Down);
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Now find where the My List Row is and jump to it
    const myListIndex = await testUtils.jumpToRowWithTitle('homeScreenRowList', 'My List');

    // Get the video preview url for this content
    const args = testUtils.getElementKeyPath('homeScreenRowList', {
      responseMaxChildDepth: 1
    });

    args.keyPath += `.content.${myListIndex}`;
    const {value: row} = await odc.getValue(args);
    const json = JSON.parse(row.json);
    const videoPreviewUrl = json[row.children[0].id].video_preview_url;

    await testUtils.retryWithTimeOut(async () => {
      const args = testUtils.getElementKeyPath('previewVideoPlayer');
      args.keyPath += `.content`;
      const {value: content} = await odc.getValue(args);
      expect(content.URL).to.equal(videoPreviewUrl);
    });

    // Verify that video is playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');

    // Go to the detail screen
    await ecp.sendKeyPress(ecp.Key.Ok);

    // Verify that video is still playing
    await testUtils.expectPlayerStateToEventuallyEqual('play');
  });
});
