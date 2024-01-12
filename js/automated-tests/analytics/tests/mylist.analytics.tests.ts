import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import {
	verifyC163671,
	verifyC150664,
	verifyC116493,
	verifyC150666andC150672andC150665,
	verifyC439643,
	verifyC439643PageLoad,
	verifyC439644,
	verifyC439645,
	verifyC439646,
	verifyC348168,
	verifyC3840,
	verifyC348168NavigateToPage,
	verifyC348168PageLoad,
} from '../verification/mylist';

describe('My List events', function () {
	beforeEach(async () => {
		this.timeout(300000);
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('Add To My List(Movie) - when show the login required from Details Page C163671 and C116493 and UI:C32373 @analytics,@analyticsMyList', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectTitleAddToMyList();
		await verifyC116493();
		await verifyC163671(titleId);
		const message = await movieDetailsPage.getPopUpMessage();
		expect(message).equal('Account needed', `text should be Account needed`);
	});

	it('Add To My List(Series) - when show the login required from Details Page C150664 @analytics,@analyticsMyList', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getTitleId();
		await detailsPage.selectTitleAddToMyList();
		await verifyC150664(episodeId);
	});

	it('when toggle left side nav on My List page C150666 and C150672 and C150665 and C439643 and C439644 and C439645 @analytics,@analyticsMyList', async () => {
		//await testUtils.startApplicationAtPage('home');
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const activate = await myStuff.selectUnlockNow();
		await activate.clickOnLetsCreateYourAccount();
		await verifyC150666andC150672andC150665();
		await verifyC439643();
		await verifyC439643PageLoad();
		await verifyC439644();
		await verifyC439645();
	});

	it('Analytics: Guest User - How many users click “Cancel” on “Let’s create your Tubi account” modal? C439646 @analytics,@analyticsMyList', async () => {
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const activate = await myStuff.selectUnlockNow();
		await activate.clickCancelForCreateAccount();
		await verifyC439646();
	});

	it('Analytics: Guest User - Dialog event when selecting the my stuff menu item and registering C348169 and C348170 and C150665 and C3840 C151880 @analytics,@analyticsMyList', async () => {
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const activate = await myStuff.selectUnlockNow();
		await verifyC348168();
		await verifyC3840();
		await verifyC348168NavigateToPage();
		await verifyC348168PageLoad();
	});
});
