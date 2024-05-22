import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC66349,
	verifyC434294,
	verifyC543688,
} from '../verification/subtitles';

describe('Subtitles events', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('videoId is correct for movie title C543685 and C21387 and Subtitle Toggle - ""videoId"" is correct for movie title C543687 \
      and Subtitle Toggle - ""toggleState"" is OFF when subtitles are disabled C543667 \
      and Users clicked the "Subtitles/Audio" icon on the player and landed on "Subtitles/Audio" selection dialog C434294 \
      and UI: C535839 @analyticsASet3,@analyticsSubtitles', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const detailsPage = await homePage.selectFocusedTitleMovie();
		await detailsPage.verifySubtitlesToglePresent();
		const playback = await detailsPage.selectPlay();
		await playback.selectSubtitlesOff();
		await verifyC66349(titleId);
		await verifyC434294();
	});
	it('Subtitle Toggle - "language" is set on both enable and disable subtitle C543688 and UI: Movie Details - When Movie Details page is opened then ratings icon is seen C536526 @analyticsASet3,@analyticsSubtitles', async () => {
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleMovieWithSubtitles();
		const titleId = await homePage.getMovieTitleId();
		await detailsPage.verifyRatingToglePresent();
		const playback = await detailsPage.selectPlay();
		await playback.selectSubtitlesOn();
		await ecp.sendKeypress(ecp.Key.Back);
		await utils.sleep(7000);
		await playback.selectSubtitlesOff();
		await verifyC543688(titleId);
	});
});
