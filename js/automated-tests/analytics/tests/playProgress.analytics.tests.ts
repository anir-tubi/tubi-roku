import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { ecp } from 'roku-test-automation';
import {
	verifyC66349andC543679andC543680,
	verifyC543681,
	verifyC543682andC543683,
	verifyC543684,
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

	it('Play Progress - Fires every 10 seconds C21349 and Play Progress - ""videoId"" is correct for movie title C543679 \
      and C543680 Play Progress - ""position"" and ""view_time"" is accurate on playback start @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(100000);
		await playback.pausePlayback();
		await verifyC66349andC543679andC543680(titleId);
	});

	it('C543681 Play Progress - ""videoId"" is correct for episode title @analytics,@analyticsPlayProgress', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(100000);
		await playback.pausePlayback();
		await verifyC543681(episodeId);
	});

	it('Play Progress - ""position"" and ""view_time"" is accurate on seek C543682 and C543683 Seek - ""videoId"" is correct for movie title and UI: C536531 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.fastForward({ howFast: 3, howLong: 10000 });
		const timeFromPlayback = await playback.getCurrentPlaybackTimeInMinutes();
		await playback.pausePlayback();
		await verifyC543682andC543683(timeFromPlayback, titleId);
	});

	it('Play Progress - ""fromAutoplayAutomatic"" true when autoplay title auto played C543684 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.seekToAutoplay();
		await playback.waitForAutoplayToDisappearByTimer();
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC543684();
	});

	it('Play Progress view_time value when user seeks forward C66349 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.fastForward({ howFast: 1, howLong: 1500 });
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
	});

	it('Play Progess view_time value when user seeks backward C66355 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.rewindPlayback({ howFast: 1, howLong: 1500 });
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
	});

	it('Play Progress view_time value when user jumps ahead 10s C66356 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.seekByProgressBarForward(1);
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
		await verifyC66356();
	});

	it('Play Progress view_time value when user jumps back 10s C66357 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.seekByProgressBarBack(1);
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
	});

	it('Play Progress view_time value when user chooses to go back to beginning from player controls C66358 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.clickOnBackToBeginning();
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
		await verifyC66356();
	});

	it('Play Progress view_time value when user choose to go to next from player controls C66359 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.clickOnNextTitleInPlaybackControlls();
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC66349();
		await verifyC66359();
	});

	it('Play Progress when user exits the player C66351 and UI: Movie Details - When Movie Details page is opened then genre is displayed C5832 \
      and Movie Details - When Movie Details page is opened then runtime is displayed C76705 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		let details = await homePage.selectFocusedTitleMovie();
		const playback = await details.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(10000);
		details = await playback.navigateBackToDetailsScreen();
		await details.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await verifyC66349();
	});

	it('Play Progress when seek back 30s when < 30s has played in video, view time should be 10000 to 11000 C66352 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.clickOnNextTitleInPlaybackControlls();
		await playback.thirtySkipBackOnPlaybackControlls();
		await verifyC66349();
	});

	it('Play Progress event is not fired when pressing "Home" during seek C424695 @analytics,@analyticsPlayProgress', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.fastForward({ howFast: 3, howLong: 300 });
		await ecp.sendKeypress(ecp.Key.Home);
		await verifyC424695();
	});
});
