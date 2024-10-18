import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import LiveNews from '../pages/liveNews';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { verifyC118157 } from '../verification/navigateWithinPageVerification';
import { verifyC118158, verifyC118164 } from '../verification/navigateToPage';
import {
	verifyC118162,
	verifyC118175,
	verifyCC125523,
	verifyC120934,
} from '../verification/liveNews';
import { verifyC125524 } from '../verification/componentInteraction';
import { ecp } from 'roku-test-automation';

describe('Live News Events', function () {
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('When the user changes focus of a new channel in the channel guide, it should send a "navigate_within_page" beacon C118157 @analyticsASet1,@analyticsliveNews', async () => {
		await testUtils.startApplicationAtPage('livefeed', {
			shouldCreateNewUser: false,
		});
		const liveNews = LiveNews();
		await liveNews.pageDidLoad();
		await liveNews.navigateThroughChannelsAndGoToNextCategory();
		await verifyC118157();
	});
	it('When the user selects a channel from the channel guide, then it should send a "navigate_to_page" beacon C118158 and C118164 @analyticsASet1,@analyticsliveNews', async () => {
		const homePage = HomePage();
		await homePage.pageDidLoad();
		await homePage.navigateToLiveNewsAndSelect(true);
		const liveNews = LiveNews();
		await liveNews.selectSubtitles(false);
		await liveNews.selectSubtitles(true);
		await verifyC118158();
		await verifyC118164();
	});
	it('A "start_live_video_event" beacon should be sent at the start of the video playback. C118162 \
      and UI: C114051 and UI: C114052 @analyticsASet1,@analyticsliveNews', async () => {
		const homePage = HomePage();
		await homePage.pageDidLoad();
		await homePage.navigateToLiveNews(true);
		const liveNews = LiveNews();
		await liveNews.checkIfLiveNewsShown();
		await liveNews.waitWhenGoFullScreen();
		await verifyC118162();
	});
	it('A "fullscreen_toggle" beacon should be sent when the video exits fullscreen C118175 \
      and C125523 and C125524 and UI:C114055 and C114061 @analyticsASet1,@analyticsliveNews', async () => {
		const homePage = HomePage();
		await homePage.navigateToLiveNews(true);
		const liveNews = LiveNews();
		await liveNews.checkIfLiveNewsShown();
		await liveNews.waitWhenGoFullScreen();
		await ecp.sendKeypress(ecp.Key.Play);
		await liveNews.checkIfVideoPlaying();
		await liveNews.selectNewChannelFromMenu(2);
		await liveNews.navigateToChannelMenu();
		await ecp.sendKeypress(ecp.Key.Back);
		await liveNews.exitLiveNewsPlayer();
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC118175();
		await verifyCC125523();
		await verifyC125524();
	});

	it('Subbtitles toggle when captions are turned off C120934 @analyticsASet1,@analyticsliveNews', async () => {
		const homePage = HomePage();
		await homePage.navigateToLiveNews(true);
		const liveNews = LiveNews();
		await liveNews.checkIfLiveNewsShown();
		await liveNews.waitWhenGoFullScreen();
		await liveNews.selectSubtitles(true);
		await liveNews.selectSubtitles(false);
		await liveNews.exitLiveNewsPlayer();
		await verifyC120934();
	});
});
