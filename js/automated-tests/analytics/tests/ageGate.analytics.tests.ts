import { testUtils } from '../../test-utils';
import { tabs } from '../components/sideNav';
import HomePage from '../pages/homePage';
import AgeGatePage from '../pages/ageGatePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { ecp, utils } from 'roku-test-automation';
import {
	verifyC543693,
	verifyC543693NavigateToPage,
	verifyC543694,
} from '../verification/navigateToPage';
import {
	verifyAgeGatePageLoad,
	verifyRequestForInfo,
	verifyDialogEvent,
} from '../verification/pageLoad';
import SignInEmailPage from '../pages/signInPage';

describe('Age gate', function () {
	this.timeout(300000);
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('RequesttForInfoEvent when DOB is submitted C152086, C166029, C165481, C165480 @analyticsASet1,@analyticsAgeGate', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		await kidsHome.exitKidsMode();
		const ageGate = AgeGatePage();
		await ageGate.pageDidLoad();
		await utils.sleep(2000);
		await ecp.sendText('1995');
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyAgeGatePageLoad();
		await verifyRequestForInfo();
	});

	it('Wrong data @analyticsASet1,@analyticsAgeGate', async () => {
		const homePage = HomePage();
		const kidsHome = await homePage.selectSideNavTab(tabs.kids);
		await ecp.sendKeypress(ecp.Key.Right);
		await kidsHome.exitKidsMode();
		const ageGate = AgeGatePage();
		await ageGate.pageDidLoad();
		await utils.sleep(2000);
		await ecp.sendText('2012');
		await ecp.sendKeypress(ecp.Key.Ok);
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await verifyDialogEvent();
	});
});
