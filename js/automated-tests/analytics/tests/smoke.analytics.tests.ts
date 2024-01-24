import { testUtils } from '../../test-utils';
import { utils } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { verifyC21392, verifyC21398andC130133 } from '../verification/autoplay';
import { verifyC130131 } from '../verification/pageLoad';
import { verifyC130135 } from '../verification/playProgressVerification';
import { verifyC21386andC21388andC21379 } from '../verification/subtitles';

describe('SmokeTests', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
	});

	it('Autoplay - Action show "videoId" is correct for movie title C21392 and C21398 and C130131 and C130133 and C130135 and UI: C5768 @analytics,@analyticsSmoke', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		await utils.sleep(3000);
		const playback = await homePage.playMovieTitle();
		await playback.seekToAutoplay();
		await playback.selectNextTitleInAutoplay(1);
		await playback.allowPlaybackToPlayForSeconds(30000);
		await playback.pausePlayback();
		const idFromAutoplay = await playback.getIdOfCurrentTitle();
		await verifyC21392(titleId);
		await verifyC130131(idFromAutoplay);
		await verifyC130135(idFromAutoplay);
		await verifyC21398andC130133(idFromAutoplay);
	});

	it('videoId is correct for episode title C21386 and C21388 and C21379 @analytics,@analyticsSmoke', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const tvShowsHome = HomePage();
		const details = await tvShowsHome.selectFocusedTitleTVShow();
		const episodeId = details.getEpisodeId();
		await details.selectEpisodeList();
		const video = await details.selectPlay();
		await video.allowPlaybackToPlayForSeconds(20000);
		await video.selectSubtitlesOn();
		await video.allowPlaybackToPlayForSeconds(2000);
		await verifyC21386andC21388andC21379(episodeId);
	});
});
