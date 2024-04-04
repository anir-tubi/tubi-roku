import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import SideNav, { tabs } from '../components/sideNav';
import { Events } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC22571,
	verifyC130118,
	verifyC130120andC130121andC130125andC130127andC130126,
	verifyKidsRating,
	verifyChannelsDisabledText,
	verifyC130122andC130124andC130123,
} from '../verification/kids';
import { expect } from 'chai';

describe('Kids Events', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('entering Kids Mode C22571 and C22572 Exiting Kids Mode - Analytics Event and entering Kids Mode C22573 and C130118 App mode contains kids when home page load event occurs @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		await kidsHome.exitKidsMode();
		await utils.sleep(1000);
		await verifyC22571();
		await verifyC130118();
	});

	it('app mode contains kids after selecting kids mode C130120 and C130121 and C130125 and C130127 and C130126 and UI:C21175,C21176,C21180 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const details = await kidsHome.selectFocusedTitleKidsMode();
		const ratingText = await details.getRatingText();
		const playback = await details.selectPlay();
		await playback.allowPlaybackToPlayForSeconds(10000);
		await playback.pausePlayback();
		await verifyC130120andC130121andC130125andC130127andC130126();
		await verifyKidsRating(ratingText);
	});

	it('UI Categories Page - Kids Mode ON - When user goes to Categories page then page is displayed:C6478 and C6479 and C44199 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		await kidsHome.selectSideNavTab(tabs.categories, 4);
		await utils.sleep(1000);
		await kidsHome.selectSideNavTabNoPageReturn(tabs.movies, 5);
		const message = await kidsHome.getPopupMessage();
		await verifyChannelsDisabledText(message);
	});

	it('UI Kids Mode ON - When user opens Search Page then Search page should be displayed: C6509 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const searchScreen = await kidsHome.selectSideNavTab(tabs.search, 4);
		await searchScreen.checkIfKidsLogoPresent();
	});

	it('UI Settings Page - Kids Mode ON - When user tries to access Settings page then settings page should be displayed: C43797 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const settingsScreen = await kidsHome.selectSideNavTab(tabs.settings, 4);
		await settingsScreen.checkIfKidsLogoPresent();
	});

	it('UI Playback - When user presses Forward 30 seconds then playback advances 30 seconds forward: C4164 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.thirtySkipForward();
		await video.allowPlaybackToPlayForSeconds(1500);
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).greaterThanOrEqual(
			30,
			`Playback should be more then 30 sec after clickung on forward 30 sec`
		);
	});

	it('UI Playback - When user presses Rewind 30 seconds then playback rewinds 30 seconds back: C4165 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.thirtySkipBack();
		await ecp.sendKeypress(ecp.Key.Up);
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).lessThanOrEqual(
			10,
			`Playback should be more then 30 sec after clickung on forward 30 sec`
		);
	});

	it('UI Playback - When user presses forward 1x then the video advances at 1x speed: C4166 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.fastForwardNoWaitTime();
		await video.allowPlaybackToPlayForSeconds(10000);
		await video.pausePlayback();
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).greaterThanOrEqual(
			30,
			`Playback should be more then 30 sec `
		);
	});

	it('UI Playback - When user presses forward 2x then the video advances at 2x speed: C4167 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.fastForwardNoWaitTime({ howFast: 2 });
		await video.allowPlaybackToPlayForSeconds(10000);
		await video.pausePlayback();
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).greaterThanOrEqual(
			30,
			`Playback should be more then 30 sec `
		);
	});
	it('UI Playback - When user presses forward 3x then the video advances at 3x speed: C4168 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.fastForward({ howFast: 3, howLong: 1500 });
		await video.allowPlaybackToPlayForSeconds(15000);
		await video.pausePlayback();
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).greaterThanOrEqual(
			50,
			`Playback should be more then 60 sec `
		);
	});

	it('UI Test Title Playback Controls - Rewind Button 1x: C25125 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.rewindPlayback();
		await video.allowPlaybackToPlayForSeconds(1000);
		await video.pausePlayback();
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).lessThanOrEqual(
			6,
			`Playback should be more then 0 sec `
		);
	});

	it('UI Test Title Playback Controls - Rewind Button 2x: C25126 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.rewindPlayback({ howFast: 2, howLong: 500 });
		await video.allowPlaybackToPlayForSeconds(12000);
		await video.pausePlayback();
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).lessThanOrEqual(
			17,
			`Playback should be more then 0 sec `
		);
	});

	it('UI Test Title Playback Controls - Rewind Button 3x: C25127 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const video = await kidsHome.playKidsTitle();
		await video.rewindPlayback({ howFast: 3, howLong: 500 });
		await video.allowPlaybackToPlayForSeconds(2000);
		await video.pausePlayback();
		const time = await video.getCurrentPlaybackTimeInSeconds();
		expect(parseInt(time)).lessThanOrEqual(
			14,
			`Playback should be more then 0 sec `
		);
	});

	it('UI Categories - When User chooses a title from Categories Page then playback should be initiated: C44198 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const catgories = await kidsHome.selectSideNavTab(tabs.categories, 4);
		const container = await catgories.selectFocusedCategory();
		const detailsPage = await container.selectFocusedTitle();
		await detailsPage.selectPlay();
	});
	it('app mode contains kids for search C130122 and C130124 and C130123 @analytics,@analyticsKids', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		const search = await kidsHome.selectSideNavTab(tabs.search);
		await search.enterSearch('annie');
		await search.goToTitleInPosition({ row: 1, col: 1 });
		await search.selectFocusedTitle();
		await verifyC130122andC130124andC130123();
	});
});
