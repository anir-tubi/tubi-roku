import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import {
	verifyC21261,
	verifyC76112andC76048,
	verifyC21262,
	verifyC112681,
	verifyC63513,
	verifyC21263,
	verifyC112680,
	verifyC21267,
	verifyC116493,
	verifyC3854,
	verifyC145000,
} from '../verification/navigateToPage';
import { ecp } from 'roku-test-automation';

import { verifyC3856 } from '../verification/pageLoad';

describe('Navigate To Page', function () {
	beforeEach(async () => {
		this.timeout(300000);
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('HomePage to VideoPage by CategoryComponent C21261 and C76112 and C76048 @analytics,@analyticsNavigateToPage', async () => {
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const titleDetailsPage = await homePage.selectFocusedTitleMovie();
		const video = await titleDetailsPage.clickOnPlay();
		await video.pausePlayback();
		await verifyC21261(titleId);
		await verifyC76112andC76048(titleId);
	});
	it('NavigateToPage - HomePage to SeriesDetailPage by CategoryComponent C21262 and UI:C63513 @analytics,@analyticsNavigateToPage', async () => {
		const homePage = HomePage();
		await homePage.selectSideNavTab(tabs.tvShows);
		const titleId = await homePage.getTVShowTitleId();
		const serialTag = await homePage.getSerialTag();
		await homePage.selectFocusedTitleTVShow();
		await verifyC21262(titleId);
		await verifyC63513(serialTag);
		await verifyC112681();
	});
	it('HomePage to VideoPage by CategoryComponent C21263 and C112680 @analytics,@analyticsNavigateToPage', async () => {
		const homePage = HomePage();
		await homePage.selectSideNavTab(tabs.movies);
		const titleId = await homePage.getMovieTitleId();
		const titleDetailsPage = await homePage.selectFocusedTitleMovie();
		const video = await titleDetailsPage.clickOnPlay();
		await video.pausePlayback();
		await verifyC21263(titleId);
		await verifyC112680();
	});
	it('NavigateToPage - SearchPage to VideoPage by Search Result Component C21267 and C116493 and C3854 and C3856 @analytics,@analyticsNavigateToPage', async () => {
		const homePage = HomePage();
		const search = await homePage.selectSideNavTab(tabs.search);
		await search.enterSearch('hey mr postman');
		await search.goToTitleInPosition(1);
		const details = await search.selectFocusedTitle();
		const id = await details.getTitleId();
		const video = await details.selectPlay();
		await video.pausePlayback();
		await verifyC21267(id);
		await verifyC116493();
		await verifyC3854();
		await verifyC3856();
	});
	it('Guest User selects My List from left Nav and is prompted to Sign In or Register, selects Ok C145000 @analytics,@analyticsNavigateToPage', async () => {
		const homePage = HomePage();
		await homePage.selectSideNavTab(tabs.myStuff);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC145000();
	});
});
