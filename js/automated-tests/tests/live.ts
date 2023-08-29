import { expect } from 'chai';
import { odc, ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';
import { shared } from '../shared';
import { count, timeEnd } from 'console';

describe('Live', function () {
    before(async () => {
        await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
        await testUtils.waitForAppLaunchBeaconToFire();
        await testUtils.waitForElementToHaveFocus('homeScreenRowList', 'Timed out waiting for Rowlist to have focus');
    });

    // https://tubi.testrail.io/index.php?/cases/view/114677
    it('C114677 - Live News - Open Side Navigation while on Live New Row @live', async () => {

        // Navigate to the Live News Row
        const node = await testUtils.getNodeForElement('topNavRecommendedWhiteLabel');
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Recommended Channels');


        // Press left navigation to open the side navigation
        await ecp.sendKeyPress(ecp.Key.Left);

        // Is the left Nav open?
        const leftNavHomeButton = await testUtils.getNodeForElement('leftNavHomeButton');
        await testUtils.elementHasFocus('leftNavHomeButton');


        // Verify playback and timer stops

        // Verify that video preview is not playing
        const player = await ecp.getMediaPlayer();
        expect(player.state).to.not.equal('play');
        expect(player.state).to.equal('pause');

    });

    // https://tubi.testrail.io/index.php?/cases/view/207737
    it('C207737 - Live Screen: When in full view, pressing back will return the user to preview mode @live', async () => {

        // Navigate to the Live News Row
        const node = await testUtils.getNodeForElement('topNavRecommendedWhiteLabel');
        await testUtils.jumpToRowWithTitle('homeScreenRowList', 'Recommended Channels');


        // Start a live feed
        await ecp.sendKeyPress(ecp.Key.Ok);
        await utils.sleep(1000);

        // Verify that video is playing
        await testUtils.expectPlayerStateToEventuallyEqual('play');

        // Go back to preview?
        await ecp.sendKeyPress(ecp.Key.Back);

        // Verify that video preview is not playing
        const player = await ecp.getMediaPlayer();
        expect(player.state).to.equal('play');
        expect(player.state).to.not.equal('pause');

    });

});
