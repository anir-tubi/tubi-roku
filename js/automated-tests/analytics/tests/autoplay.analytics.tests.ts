import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import { Events } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC130134,
	verifyC130136,
	verifyC21265,
	verifyC285594,
	verifyC285592,
	verifyC21393,
	verifyC130132,
	verifyC130132NavigateToPage,
	verifyC21397,
	verifyC21396,
	verifyC25123,
} from '../verification/autoplay';

describe('Autoplay Analytics', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('Start video - From autoplay field when autoplay is automatic C130134 \
      and Play progress - From autoplay field when autoplay is automatic C130136 @analyticsASet1,@analyticsAutoplay', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.seekToAutoplay();
		await playback.waitForAutoplayToDisappearByTimer();
		await playback.allowPlaybackToPlayForSeconds(30000);
		const eventPlayProgress = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			3
		);
		await playback.pausePlayback();
		const idOfTitleFromAutoplay = await playback.getIdOfCurrentTitle();
		await verifyC130134(idOfTitleFromAutoplay);
		await verifyC130136(idOfTitleFromAutoplay);
		await verifyC21265(idOfTitleFromAutoplay, titleId);
		await verifyC285594(eventPlayProgress[0], idOfTitleFromAutoplay);
	});
	it('Autoplay - Action show "videoId" is correct for tv show C515573 and Page load - When next episode playback starts C130132 \
      and  Autoplay - Series - When episode reaches the end of playback then Autoplay \
      and Player remain in view C4184 \
      and Autoplay - Series - Next episode plays after multiple consecutive autoplays C6030 @analyticsASet1,@analyticsAutoplay', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.seekToAutoplay();
		await playback.selectNextTitleInAutoplay(0);
		await playback.allowPlaybackToPlayForSeconds(15000);
		const idOfNextEpisode = await playback.getIdOfCurrentTitle();
		await playback.pausePlayback();
		await verifyC285592(idOfNextEpisode);
		await verifyC21393(episodeId);
		await verifyC130132(idOfNextEpisode);
		await verifyC130132NavigateToPage(idOfNextEpisode, episodeId);
	});
	it('UI: C21201 Autoplay - When user presses the Back button then series autoplay UI is dismissed @analyticsASet1,@analyticsAutoplay', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const playback = await detailsPage.clickOnPlay();
		await playback.seekToAutoplay();
		await ecp.sendKeypress(ecp.Key.Back);
		await playback.pausePlayback();
	});
	it('UI: C21205 - When autoplay timer expires then next episode autoplays @analyticsASet1,@analyticsAutoplay', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const playback = await detailsPage.clickOnPlay();
		await playback.seekToAutoplay();
		await playback.allowPlaybackToPlayForSeconds(30000);
		await playback.pausePlayback();
	});
	it('Autoplay - Action show is fired when autoplay dismissed and viewed again C515574 and \
      Autoplay - Action dismiss when autoplay is dismissed C515575 @analyticsASet1,@analyticsAutoplay', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.seekToTheEndAndDismissAutoplay();
		await verifyC21397(episodeId);
		await verifyC21396(episodeId);
	});
	it('UI: C25123,C105693 - Autoplay - When user chooses last title on the list then movie plays @analyticsASet1,@analyticsAutoplay', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.seekToAutoplay();
		await playback.selectNextTitleInAutoplay(9);
		await playback.allowPlaybackToPlayForSeconds(17000);
		await playback.pausePlayback();
		await verifyC25123(titleId);
	});
});
