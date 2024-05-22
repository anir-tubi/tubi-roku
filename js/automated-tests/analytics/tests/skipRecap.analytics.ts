import { testUtils } from '../../test-utils';
import { tabs } from '../components/sideNav';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { verifyC215937 } from '../verification/skipRecap';

describe('Skip Recap', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('Skip Recap: When user selects Skip Recap button when playback starts for TV episodes with cue points C215937 @analyticsASet3,@analyticsSkipRecap', async () => {
		const homePage = HomePage();
		const searchPage = await homePage.selectSideNavTab(tabs.search);
		await searchPage.enterSearch('the freak brothers');
		await searchPage.goToTitleInPosition(1);
		const detailsPage = await searchPage.selectFocusedTitle();
		const episodeId = await detailsPage.getEpisodeId();
		const video = await detailsPage.selectPlay();
		await video.clickOnSkipIntro();
		await verifyC215937(episodeId);
	});
});
