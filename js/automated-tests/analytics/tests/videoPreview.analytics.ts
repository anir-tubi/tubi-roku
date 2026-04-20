import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC285595,
	verifyC285596,
	verifyC285597,
	verifyC285598,
} from '../verification/autoplay';

describe('Video preview', function () {
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('C285595 and C285596 When a video starts automatically after the video preview has concluded, update the StartVideoEvent @analyticsASet3,@analyticsVideoPreview', async () => {
		const homePage = HomePage();
		const titleId = await homePage.highlightTitleWithVideoPreview();
		const video = await homePage.waitForPlayBackToStartForMovie();
		await video.allowPlaybackToPlayForSeconds(30000);
		await verifyC285595(titleId);
		await verifyC285596(titleId);
	});
	it('C285597,C285598 When a user starts video playback from any UI that is not the autoplay UI or automatically from video previews (from pressing play on the details screen for instance), update the StartVideoEvent @analyticsASet3,@analyticsVideoPreview', async () => {
		const homePage = HomePage();
		const titleId = await homePage.highlightTitleWithVideoPreview();
		await utils.sleep(10000);
		const details = await homePage.selectFocusedTitleMovie();
		const video = await details.selectPlay();
		await video.allowPlaybackToPlayForSeconds(35000);
		await verifyC285597(titleId);
		await verifyC285598(titleId);
	});
});
