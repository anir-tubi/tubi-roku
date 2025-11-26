import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../test-helpers';
import { count, timeEnd } from 'console';

describe('Live', function () {
    beforeEach(async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForApplicationStartup();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });
    // Let's investigate the preview player when the left nav is open here
    // https://tubi.testrail.io/index.php?/cases/view/114677
    it('C114677 - Live News - Open Side Navigation while on Live New Row @live', async () => {

        // Navigate to the Live News Row
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

        // Verify that video preview is playing
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'On Now');
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing');
        // Press left navigation to open the side navigation
        await ecp.sendKeypress(ecp.Key.Left);
        await testUtils.waitForElementToHaveFocus('leftNav');
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'stopped');
    });

    // https://tubi.testrail.io/index.php?/cases/view/207737
    it('C207737 - Live Screen: When in full view, pressing back will return the user to preview mode @live', async () => {

        // Navigate to the Live News Row
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

        // Start a live feed
        await startLiveFeed();

        // Verify that full linear video is playing
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

        // Go back to preview
        await utils.sleep(6000); // Waiting for full screen - improve
        await ecp.sendKeypress(ecp.Key.Back, { count: 1 });

        // Verify that linear preview video is playing
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

    });

    // https://tubi.testrail.io/index.php?/cases/view/114053
    it('C114053 - Live News - Live TV channel guide @live', async () => {

        // Navigate to the Live News Row
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

        // Start a live feed
        await startLiveFeed();

        // Verify that full linear video is playing
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 10000);

        // Navigate right after displaying the guide
        await ecp.sendKeypress(ecp.Key.Up);
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Right);

        // Verify that linear video is still playing
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 10000);
    });

    // https://tubi.testrail.io/index.php?/cases/view/114058
    it('C114058 - Live News - When a user changes channels during playback, playback for the updated channel should be near instantaneous @live', async () => {

        // Navigate to the Live News Row
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
        await utils.sleep(2000);
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

        // Verify that linear preview video is playing
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

        // Navigate right
        await ecp.sendKeypress(ecp.Key.Right);

        // Verify that linear video is still playing 
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

        // Navigate left
        await ecp.sendKeypress(ecp.Key.Left);

        // Verify that linear video is still playing 
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing');


    });


    // https://tubi.testrail.io/index.php?/cases/view/115290
    it('C115290 -  Home Screen Automatic Small video transition to full screen view @live', async () => {

        // Navigate to the Live News Row
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'On Now');

        // Verify that full video plays after preview video is playing

        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);

        // Verify that full linear video is playing
        await testUtils.waitForPlayerStateToEqual('linearVideoPlayerScreen', 'playing', 20000);
    });

    async function startLiveFeed() {
        await utils.sleep(1000);
        await ecp.sendKeypress(ecp.Key.Ok);

    }

});
