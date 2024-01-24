import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import {
	addMoviesToQueue,
	addTheFreakBrothersTVShowToHistory,
	addZappedTitleToHistory,
	addZappedTitleToMyList,
	addTheFreakBrothersTVShowToMyList
} from '../utils/userManipulations';
import { ecp, utils } from 'roku-test-automation';
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
	verifyC543642,
	verifyC543642AddToQueue,
	verifyC5220,
	verifyC70582,
	verifyC5226,
	verifyC439649,
	verifyC439651,
	verifyC439651Movie
} from '../verification/mylist';

import { verifyC439649NavigateToPage,verifyC439651NavigateToPage,verifyC439651NavigateToPageMovie } from '../verification/navigateToPage';

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

	it('When removing movie from the queue then "videoId" matches selected movie title C543642 and C5225 @analytics,@analyticsMyList', async () => {
		const user = await testUtils.createRegisteredUser();
		await testUtils.startApplicationAtPage('movies', { user: user });
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.selectTitleAddToMyList();
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC543642(titleId);
		await verifyC543642AddToQueue(titleId);
	});

	it('When series is added to the queue then "seriesId" matches selected series title C5220 and C70582 @analytics,@analyticsMyList', async () => {
		const user = await testUtils.createRegisteredUser();
		await testUtils.startApplicationAtPage('tv', { user: user });
		const homePage = HomePage();
		const titleId = await homePage.getTVShowTitleId();
		const tvShowDetailsPage = await homePage.selectFocusedTitleTVShow();
		await tvShowDetailsPage.selectTitleAddToMyList();
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC5220(titleId);
		await verifyC70582(titleId);
	});

	it('When removing series from history then seriesId is correct C5226 @analytics,@analyticsMyList', async () => {
		const user = await testUtils.createRegisteredUser();
		await addTheFreakBrothersTVShowToHistory(user);
		await testUtils.startApplicationAtPage('home', { user: user });
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const detailsPage = await myStuff.selectContinueWatchingIfOnlyone();
		await detailsPage.selectRemoveFromHistory();
		await verifyC5226(300007896);
	});

	it('Analytics: Registered User - How many users select one Movie title within Continue Watching and land on details page of the title? C439649 @analytics,@analyticsMyList', async () => {
		const user = await testUtils.createRegisteredUser();
		await addZappedTitleToHistory(user);
		await testUtils.startApplicationAtPage('home', { user: user });
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const detailsPage = await myStuff.selectContinueWatchingIfOnlyone();
		await detailsPage.selectRemoveFromHistory();
		await verifyC439649NavigateToPage(342067);
		await verifyC439649(342067);
	});
	
	it('Analytics: Registered User - How many users select one TV Show title within My List and land on the titleâ€™s details page? C439651 @analytics,@analyticsMyList', async () => {
		const user = await testUtils.createRegisteredUser();
		await addTheFreakBrothersTVShowToMyList(user);
		await testUtils.startApplicationAtPage('home', { user: user });
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const detailsPage = await myStuff.selectQueueIfOnlyone();
		await detailsPage.selectRemoveFromMyList();
		await verifyC439651NavigateToPage(300007896);
		await verifyC439651(300007896);
	});
	
	it('Analytics: Registered User - How many users select one Movie title within My List and land on the titleâ€™s details page? C439651 @analytics,@analyticsMyList', async () => {
		const user = await testUtils.createRegisteredUser();
		await addZappedTitleToMyList(user);
		await testUtils.startApplicationAtPage('home', { user: user });
		const homePage = HomePage();
		const myStuff = await homePage.selectSideNavTab(tabs.myStuff);
		const detailsPage = await myStuff.selectQueueIfOnlyone();
		await detailsPage.selectRemoveFromMyList();
		await verifyC439651NavigateToPageMovie(342067);
		await verifyC439651Movie(342067);
});
});
