import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import ChannelsPage from '../pages/channelsPage';
import SideNav, { tabs } from '../components/sideNav';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC543668andC543669,
	verifyC543671,
	verifyC543672,
	verifyC425239,
	verifyC425249,
	verifyC425250,
	verifyC425240,
	verifyC425241,
	verifyC425244,
	verifyC425251,
	verifyC425235,
	verifyC425236,
	verifyC425233,
	verifyC268959,
	verifyC268957WithinPage,
	verifyC524595,
	verifyC690744,
	verifyC690748,
} from '../verification/navigateWithinPageVerification';
import {
	verifyC268956ComponentInteraction,
	verifyC268957,
} from '../verification/componentInteraction';
import { ecp, utils } from 'roku-test-automation';
import Categories from '../pages/categories';

describe('Navigate Within Page', function () {
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('When HomePage vertical navigation C543668 and NavigateWithinPage - CategoryPage navigation C543669\
	    and User Action - Scroll within sublists, such as categories or channel C3843 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		await homePage.navigateDown(1);
		await verifyC543668andC543669(titleId);
	});
	it('NavigateWithinPage - HomePage CategoryComponent horizontal navigation - every 3 seconds C543671 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const details = await homePage.getMovieTitleIdAndCategory();
		await homePage.navigateDown(1);
		await utils.sleep(500); //need this as quick navigation messing with events
		await homePage.navigateRight(2);
		await utils.sleep(500);
		await homePage.navigateRight(1);
		await verifyC543671(details);
	});
	it('NavigateWithinPage - autoplay navigation C543672 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const playback = await homePage.playMovieTitle();
		await playback.seekToAutoplay();
		await playback.selectNextTitleInAutoplay(1);
		await playback.allowPlaybackToPlayForSeconds(4000);
		await playback.pausePlayback();
		await verifyC543672(titleId);
	});
	it('When user navigates between menu options - EPISODES_LIST C425239 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const titleId = await homePage.getTVShowTitleId();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		await detailsPage.highlightEpisodeList();
		await ecp.sendKeypress(ecp.Key.Down);
		await verifyC425239(titleId);
	});

	it('When user makes a selection from details page menu - EPISODES_LIST C425249 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const titleId = await homePage.getTVShowTitleId();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		await detailsPage.selectEpisodeList();
		await ecp.sendKeypress(ecp.Key.Back);
		await utils.sleep(400);
		await ecp.sendKeypress(ecp.Key.Up, { wait: 500 });
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC425249(titleId);
		//await verifyC425250(titleId); // check how to get sign up to save progress
	});

	it('When user navigates between menu options - SIGNUP_TO_SAVE_PROGRESS C425240 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const titleId = await homePage.getTVShowTitleId();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		await detailsPage.highlightEpisodeList();
		await ecp.sendKeypress(ecp.Key.Down);
		await verifyC425240(titleId);
	});

	it('When user navigates between menu options - ADD_TO_MY_LIST C425241 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const movieDetailsPage = await homePage.selectMovieTitleWithNoTrailer();
		const videoId = movieDetailsPage.getTitleId();
		await movieDetailsPage.highlightLikeOrDislike();
		await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
		await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
		await verifyC425241(videoId);
	});
	it('When user navigates between menu options - GO_TO_NETWORK C42524 \
	    and C425251 When user makes a selection from details page menu - GO_TO_NETWORK @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
		await testUtils.waitForAppLaunchBeaconToFire();
		await testUtils.goToPage('network');
		const categories = Categories();
		await categories.pageDidLoad();
		const container = await categories.selectChannelByName('cj_enm');
		const titleDetailsPage = await container.selectFocusedTitle();
		const videoId = titleDetailsPage.getTitleId();
		await titleDetailsPage.highlightAddToMyList();
		await ecp.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Down);
		await ecp.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC425244();
		await verifyC425251(videoId);
	});
	it('When user navigates between menu options - LIKE C425235 \
	    and C425236 When user navigates between menu options - DISLIKE @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const movieDetailsPage = await homePage.selectMovieTitleWithNoTrailer();
		const videoId = movieDetailsPage.getTitleId();
		await movieDetailsPage.selectLikeOrDislike();
		await utils.sleep(1500);
		await ecp.sendKeypress(ecp.Key.Down);
		await utils.sleep(1500);
		await ecp.sendKeypress(ecp.Key.Up);
		await verifyC425235(videoId);
		await verifyC425236(videoId);
	});
	it('When user navigates between menu options - WATCH_TRAILER C425233 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		let movieDetailsPage = await homePage.selectMovieTitleWithTrailer();
		const videoId = movieDetailsPage.getTitleId();
		const video = await movieDetailsPage.selectPlay();
		await video.allowPlaybackToPlayForSeconds(10000);
		movieDetailsPage = await video.navigateBackToDetailsScreen();
		await movieDetailsPage.highlightWatchTrailer(300);
		await ecp.sendKeypress(ecp.Key.Down, { wait: 2000 });
		await verifyC425233(videoId);
	});

	it('When the user selects Espanol from Left Side Nav when they were on For You - Home Page: C268956 and C268957 and C268958 and C268959 @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		await homePage.selectSideNavTab(tabs.espanol);
		await ecp.sendKeypress(ecp.Key.Left);
		await verifyC268956ComponentInteraction();
		await verifyC268957();
		await verifyC268959();
		await verifyC268957WithinPage();
	});

	it('C524595 User lands on the “You May Also Like” container on the player page. @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		let movieDetailsPage = await homePage.selectFocusedTitleMovie();
		const video = await movieDetailsPage.selectPlay();
		await video.allowPlaybackToPlayForSeconds(10000);
		await video.selectFirstTitleFromBrowseWhileWatching();
		await video.allowPlaybackToPlayForSeconds(10000);
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC524595();
	});

	it('C690744	User scrolls vertically and navigates within the left side navigation page  @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const channelsPage = await homePage.highlightedSideNavTab(tabs.categories, 7);
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Up);
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
		await utils.sleep(3000);
		await verifyC690744();
	});

	it('C690746	User scrolls vertically and navigates within the categories listed on the category list page  @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories, 7);
		await utils.sleep(2000);
		await ecp.sendKeypress(ecp.Key.Up);
		await utils.sleep(2000);
		await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
		await verifyC690744();
	});

	it('C690748	User browses the titles in a given category on the category page  @analyticsASet2,@analyticsNavigateWithinPage', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories, 7);
		const container = await categories.selectCategoryByName('action');
		const slugCategory = await container.getCategoryName();
		await ecp.sendKeypress(ecp.Key.Right, { count: 4, wait: 2000 });
		await verifyC690748(slugCategory);
	});

});
