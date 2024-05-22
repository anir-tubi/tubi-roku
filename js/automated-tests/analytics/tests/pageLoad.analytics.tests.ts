import { createNewTestInProxy } from '../utils/network/qaProxy';
import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import HomePage from '../pages/homePage';
import { expect } from 'chai';
import SideNav, { tabs } from '../components/sideNav';
import {
	verifyC21253,
	verifyC21254,
	verifyC21254PlayerLoad,
	verifyC543704,
	verifyC543703,
	verifyC76715,
	verifyC76715PageLoad,
} from '../verification/pageLoad';
import {
	verifyC112682,
	verifyC76713,
	verifyC112683,
} from '../verification/navigateToPage';

import {
	verifyC543705,
	verifyC76717,
	verifyC76715NavigateWithinPage,
} from '../verification/navigateWithinPageVerification';

describe('Page Load Analytics', function () {
	beforeEach(async () => {
		this.timeout(300000);
		await createNewTestInProxy();
		await testUtils.startApplicationAtPage('movies', {
			shouldCreateNewUser: false,
		});
	});

	it('When navigation within the application then navigate to page event is fired C21253 and C21254 and UI: C5836 and C5837 @analyticsASet3,@analyticsPageLoad', async () => {
		const homePage = HomePage();
		const titleId = await homePage.getMovieTitleId();
		const movieDetailsPage = await homePage.selectFocusedTitleMovie();
		await movieDetailsPage.clickOnPlay();
		await verifyC21253();
		await verifyC21254(titleId);
		await verifyC21254PlayerLoad(titleId);
	});

	it('When browse is loaded then first key is ""categoryListPage"" in the logs C543703 and Page Load - When category container is loaded then first key is ""categoryPage"" with categorySlug C543704 and HomePage to CategoryPage by CategoryComponent C543705 and C21260 and C76712 and C76713 and C76714 and C3857 and C3858 and C3860 @analyticsASet3,@analyticsPageLoad,@debug', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories,7);
		const container = await categories.selectCategoryByName('action');
		const slugCategory = await container.getCategoryName();
		await container.selectFocusedTitle();
		await verifyC112682();
		await verifyC543704(slugCategory);
		await verifyC543703();
		await verifyC543705(slugCategory);
		await verifyC76713(slugCategory);
	});
	it('When channels page displayed C76715 and C76716 and C76717 and C3859 and UI: C44199 @analyticsASet3,@analyticsPageLoad', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories);
		const channels = await categories.selectCategoryByName('Networks');
		const firstSlugCategory = await channels.getNameOfFirstChannel();
		const container = await channels.selectChannelByName('cj_enm');
		const slugCategory = await container.getCategoryName();
		const details = await container.selectFocusedTitle();
		await details.selectPlay();
		await verifyC112683();
		await verifyC76717(slugCategory);
		await verifyC76715(slugCategory);
		await verifyC76715PageLoad();
		await verifyC76715NavigateWithinPage(firstSlugCategory);
	});
});
