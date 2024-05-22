import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import {
	verifyC21365,
	verifyC21366,
	verifyC21368andC21368,
	verifyC21370,
} from '../verification/seek';

describe('Seek Events', function () {
	beforeEach(async () => {
		this.timeout(300000);
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('videoId is correct for episode title C21365 and UI:C6522  @analyticsASet3,@analyticsPlayback', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPageTVShow = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPageTVShow.getEpisodeId();
		const playback = await detailsPageTVShow.clickOnPlay();
		await playback.fastForward({ howFast: 1, howLong: 10000 });
		await playback.allowPlaybackToPlayForSeconds(3500);
		await verifyC21365(episodeId);
	});

	it('fromPosition and toPosition reflect start and end position C21366 and C21367 @analyticsASet3,@analyticsPlayback', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		const timeFromPlaybackBeforeSeek =
			await playback.getCurrentPlaybackTimeInMinutes();
		await playback.fastForward({ howFast: 3, howLong: 10000 });
		await playback.allowPlaybackToPlayForSeconds(3500);
		await playback.pausePlayback();
		const timeFromPlaybackAfterSeek =
			await playback.getCurrentPlaybackTimeInMinutes();
		await verifyC21366(timeFromPlaybackBeforeSeek, timeFromPlaybackAfterSeek);
	});

	it('event fires on 30 skip forward C21368 and C21369 @analyticsASet3,@analyticsPlayback', async () => {
		const homePage = HomePage();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(5000);
		await playback.thirtySkipForward();
		await playback.allowPlaybackToPlayForSeconds(5000);
		await playback.thirtySkipBack();
		await playback.allowPlaybackToPlayForSeconds(3000);
		await playback.pausePlayback();
		await verifyC21368andC21368();
	});

	it('event fires on fast forward and rewind C21370 @analyticsASet3,@analyticsPlayback', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.allowPlaybackToPlayForSeconds(5000);
		await playback.fastForward({ howFast: 2, howLong: 9000 });
		await playback.allowPlaybackToPlayForSeconds(5000);
		await playback.pausePlayback();
		await playback.rewindPlayback({ howFast: 2, howLong: 9000 });
		await playback.allowPlaybackToPlayForSeconds(5000);
		await playback.pausePlayback();
		await verifyC21370(titleId);
	});
});
