import { testUtils } from '../../test-utils';
import { tabs } from '../components/sideNav';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import {
	verifyC543693,
	verifyC543693NavigateToPage,
	verifyC543694,
} from '../verification/navigateToPage';
import SignInEmailPage from '../pages/signInPage';

describe('Activate events', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('Account - Activate Account  C543693 and Account - Account Activated C543694 and C5314 and C5313  @analytics,@analyticsActivate', async () => {
		const homePage = HomePage();
		const activation = await homePage.selectSideNavTab(tabs.signIn);
		await activation.clickOnLetsCreateYourAccount();
		const signInEmailPage = SignInEmailPage();
		await signInEmailPage.pageDidLoad();
		await signInEmailPage.enterPasswordAndClickContinue('111111');
		const settings = await homePage.selectSideNavTab(tabs.settings);
		await settings.signOut();
		await verifyC543693();
		await verifyC543693NavigateToPage();
		await verifyC543694();
	});
});
