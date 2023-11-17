import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { ecp } from 'roku-test-automation';
import {
	verifyC66349andC21350andC21350,
	verifyC21351,
	verifyC21354andC21364,
	verifyC21360,
	verifyC66349,
	verifyC66356,
	verifyC66359,
	verifyC424695,
} from '../verification/playProgressVerification';

describe('Play progress', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('C21349 and C21350 and C21352 @analytics', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(100000);
		await playback.pausePlayback();
		await verifyC66349andC21350andC21350(titleId);
	});

	it('C21351 @analytics', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(100000);
		await playback.pausePlayback();
		await verifyC21351(episodeId);
	});

	it('C21354 and C21364 and UI: C5770 @analytics', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.fastForward({ howFast: 3, howLong: 10000 });
		const timeFromPlayback = await playback.getCurrentPlaybackTimeInMinutes();
		await playback.pausePlayback();
		await verifyC21354andC21364(timeFromPlayback, titleId);
	});

	it('C21360 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.seekToAutoplay();
		await playback.waitForAutoplayToDisappearByTimer();
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC21360();
	});

	it('C66349 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.fastForward({ howFast: 1, howLong: 1500 });
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
	});

	it('C66355 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.rewindPlayback({ howFast: 1, howLong: 1500 });
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
	});

	it('C66356 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.seekByProgressBarForward(1);
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
		await verifyC66356();
	});

	it('C66357 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.seekByProgressBarBack(1);
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
	});

	it('C66358 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.clickOnBackToBeginning();
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
		await verifyC66356();
	});

	it('C66359 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.clickOnNextTitleInPlaybackControlls();
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
		await verifyC66359();
	});

	it('C66351 and UI: C5832 and C76705 @analytics', async () => {
		const homePage = HomePage();
		let details = await homePage.selectFocusedTitleMovie();
		const playback = await details.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(10000);
		details = await playback.navigateBackToDetailsScreen();
		await details.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await verifyC66349();
	});

	it('C66352 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.clickOnNextTitleInPlaybackControlls();
		await playback.thirtySkipBackOnPlaybackControlls();
		await verifyC66349();
	});

	it('C424695 @analytics', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.fastForward({ howFast: 3, howLong: 300 });
		await ecp.sendKeypress(ecp.Key.Home);
		await verifyC424695();
	});
});
