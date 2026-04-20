import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import { Events } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC115421PageLoad,
	verifyC115421Autoplay,
	verifyC115421,
	verifyC116492,
	verifyC116525,
} from '../verification/espanol';

describe('Espanol Events', function () {
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('espanol', {
			shouldCreateNewUser: false,
		});
	});

	it('“app_mode”:“LATINO_MODE” in analytics calls C115421 and C116491 and C115414 @analyticsASet1', async () => {
		const homePage = HomePage();
		const playback = await homePage.playEspanolTitle();
		await playback.seekToAutoplay();
		await playback.selectNextTitleInAutoplay(1);
		await playback.allowPlaybackToPlayForSeconds(30000);
		await verifyC115421PageLoad();
		await verifyC115421Autoplay();
		await verifyC115421();
	});

	it('“YMAL Movie title playback: send “app_mode”:“LATINO_MODE” to Rainmaker when a user begins playback from Tubi en Español through YMAL C116492 and UI:C115400 @analyticsASet1', async () => {
		const homePage = HomePage();
		const detials = await homePage.selectFocusedTitleEspanol();
		await detials.selectTitleFromYouMayAlsoLike(1);
		const playback = await detials.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(30000);
		await verifyC116492();
	});

	it('YMAL Series title playback: send app mode = latino to Rainmaker when a user begins playback from Tubi en Español through YMAL C116525 @analyticsASet1', async () => {
		const espanolHome = HomePage();
		const detailsPage = await espanolHome.selectFocusedTvShowTitleEspanol();
		await detailsPage.selectTitleFromYouMayAlsoLike(0);
		await utils.sleep(2000);
		const playback = await detailsPage.selectPlay();
		await playback.allowPlaybackToPlayForSeconds(30000);
		await verifyC116525();
	});
});
