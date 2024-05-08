import { testUtils } from '../../test-utils';
import { tabs } from '../components/sideNav';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC543693,
	verifyC148727NavigateToPage,
	verifyC543694,
} from '../verification/navigateToPage';
import { verifyC148718 } from '../verification/dialog';
import SignInEmailPage from '../pages/signInPage';

describe('Activate events', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('Account - Activate Account  C543693 and Account - Account Activated C543694 and C5314 and C5313 and C148718  @analytics,@analyticsActivate', async () => {
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

	it('Home Page - Guest Roku user with Tubi account selects Register/Sign In from CW row -Create account page C148861  @analytics,@analyticsActivate', async () => {
		const homePage = HomePage();
		const activation = await homePage.navigateToContinueWatchingAndSelectIt();
		await activation.clickOnLetsCreateYourAccount();
		const signInEmailPage = SignInEmailPage();
		await signInEmailPage.pageDidLoad();
		await verifyC148718();
	});
});
