import { testUtils } from '../../test-utils';
import { tabs } from '../components/sideNav';
import HomePage from '../pages/homePage';
import { createNewTestInProxy } from '../utils/network/qaProxy';
import { verifyC112684 } from '../verification/navigateToPage';

describe('User action', function () {
	beforeEach(async () => {
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('home', {
			shouldCreateNewUser: false,
		});
	});

	it('User Action - Click on settings C112684 @analyticsASet3,@analyticsUserActions', async () => {
		const homePage = HomePage();
		await homePage.selectSideNavTabNoPageReturn(tabs.settings);
		await verifyC112684();
	});
});
