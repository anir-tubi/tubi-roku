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
} from '../verification/kids';

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
		await kidsHome.selectSideNavTabNoPageReturn(tabs.channels, 6);
		const message = await kidsHome.getPopupMessage();
		await verifyChannelsDisabledText(message);
	});
});
