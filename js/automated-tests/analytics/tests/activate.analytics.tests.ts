import { testUtils } from '../../test-utils';
import { tabs } from '../components/sideNav';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import ActivatePage from '../pages/activatePage';
import { ecp, utils } from 'roku-test-automation';
import {
	verifyC543693,
	verifyC148727NavigateToPage,
	verifyC543694,
	verifyC450499,
	verifyC450500NavigateToPage,
	C450501NavigateToPage,
	C450501NavigateToPageLoginPage,
	C450501NavigateToPageDestLoginPage
} from '../verification/navigateToPage';
import {
	verifyC148718,
	verifyC148861,
	verifyC450497,
	verifyC450500,
	verifyC450502
} from '../verification/dialog';
import SignInEmailPage from '../pages/signInPage';

describe('Activate events', function () {
	this.timeout(480000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('Account - Activate Account  C543693 and Account - Account Activated C543694 and C5314 and C5313 and C148718  @analyticsASet1,@analyticsActivate', async () => {
		const homePage = HomePage();
		const activation = await homePage.selectSideNavTab(tabs.signIn);
		await activation.clickOnLetsCreateYourAccount();
		const signInEmailPage = SignInEmailPage();
		await signInEmailPage.pageDidLoad();
		await signInEmailPage.enterPasswordAndClickContinue('111111');
		const settings = await homePage.selectSideNavTab(tabs.settings);
		await settings.signOut();
		await verifyC543693();
		await verifyC148727NavigateToPage();
		await verifyC543694();
		await verifyC148718();
	});

	it('Home Page - Guest Roku user with Tubi account selects Register/Sign In from CW row -Create account page C148861  @analyticsASet1,@analyticsActivate', async () => {
		const homePage = HomePage();
		const activation = await homePage.navigateToContinueWatchingAndSelectIt();
		await activation.clickOnLetsCreateYourAccount();
		const signInEmailPage = SignInEmailPage();
		await signInEmailPage.pageDidLoad();
		await verifyC148718();
	});

	it('Exit prompt - Users click the BACK button on the remote and see the "Wait, dont lose your progress" prompt C148861 and C450497  @analyticsASet1,@analyticsActivate', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(350000);
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC148861(episodeId);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC450497(episodeId);
		await utils.sleep(2000);
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC450499(episodeId);
	});

	it('Exit prompt - Users click the "Sign Up Later" option on the "Wait, dont lose your progress" prompt C450500  @analyticsASet1,@analyticsActivate', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(350000);
		await ecp.sendKeypress(ecp.Key.Back);
		await ecp.sendKeypress(ecp.Key.Down, { wait: 1000 });
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyC450500(episodeId);
		await verifyC450500NavigateToPage(episodeId);
	});

	it('Exit prompt - Users completed registration flow and landed back to the details page C450501 @analyticsASet1,@analyticsActivate', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(350000);
		await ecp.sendKeypress(ecp.Key.Back,{ wait: 3000 });
		const activation =  ActivatePage();
		await activation.clickOnLetsCreateYourAccount();
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Ok);
		const signInEmailPage = SignInEmailPage();
		await signInEmailPage.pageDidLoad();
		await signInEmailPage.enterPasswordAndClickContinue('111111');
		await C450501NavigateToPage(episodeId)
		await C450501NavigateToPageLoginPage(episodeId)
		await C450501NavigateToPageDestLoginPage(episodeId)
		await ecp.sendKeypress(ecp.Key.Back);
		const settings = await homePage.selectSideNavTab(tabs.settings);
		await settings.signOut();
	});

	it('Exit prompt - Users click the back button to exit the "Wait, dont lose your progress" prompt C450502  @analyticsASet1,@analyticsActivate', async () => {
		await testUtils.startApplicationAtPage('tv', {
			shouldCreateNewUser: false,
		});
		const homePage = HomePage();
		const detailsPage = await homePage.selectFocusedTitleTVShow();
		const episodeId = detailsPage.getEpisodeId();
		const playback = await detailsPage.clickOnPlay();
		await playback.allowPlaybackToPlayForSeconds(350000);
		await ecp.sendKeypress(ecp.Key.Back);
		await utils.sleep(2000);
		await ecp.sendKeypress(ecp.Key.Back);
		await verifyC450502(episodeId);
	});
});
