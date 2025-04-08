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
} from '../verification/pageLoad';
import {
	verifyC112682,
	verifyC690749,
} from '../verification/navigateToPage';

import {
	verifyC76717,
	verifyC76715NavigateWithinPage,
	verifyC690751NavigateWithinPage,
	verifyC690753NavigateWithinPage,
} from '../verification/navigateWithinPageVerification';
import {
	verifyC690745ComponentInteraction,
} from '../verification/componentInteraction';
import { verifyC690749NavigateToPage } from '../verification/navigateToPage';

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

	it('When browse is loaded then first key is ""categoryListPage"" in the logs C543703 and Page Load - When category container is loaded then first key is ""categoryPage"" with categorySlug C543704 and HomePage to CategoryPage by CategoryComponent C543705 and C690745 and C21260 and C76712 and C76713 and C76714 and C3857 and C3858 and C3860 and C690747 @analyticsASet3,@analyticsPageLoad', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories, 7);
		const container = await categories.selectCategoryByName('action');
		const slugCategory = await container.getCategoryName();
		await container.selectFocusedTitle();
		await verifyC112682();
		await verifyC543704(slugCategory);
		await verifyC543703();
		await verifyC690749(slugCategory);
		await verifyC690745ComponentInteraction(slugCategory);
	});

	it('When channels page displayed C76715 and C76716 and C76717 and C3859 and C690750 and C690752 and C690754 and UI: C44199 @analyticsASet3,@analyticsPageLoad', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories, 7);
		await categories.selectCategoryByName('Networks');
		const container = await categories.selectChannelByName('cj_enm');
		const slugCategory = await container.getCategoryName();
		const details = await container.selectFocusedChannel();
		await details.selectPlay();
		await verifyC76717(slugCategory);
		await verifyC76715(slugCategory);
		await verifyC76715NavigateWithinPage(slugCategory);
		await verifyC690749NavigateToPage();
	});

	it('C690751	User browses the Network channels on the category list page @analyticsASet3,@analyticsPageLoad', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories, 7);
		await categories.selectCategoryByName('Networks');
		await ecp.sendKeypress(ecp.Key.Right);
		await utils.sleep(2000);
		await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
		await verifyC690751NavigateWithinPage('networks');
	});

	it('C690753	User browses the titles in a given channel on the channel category page  @analyticsASet3,@analyticsPageLoad', async () => {
		const homePage = HomePage();
		const categories = await homePage.selectSideNavTab(tabs.categories, 7);
		await categories.selectCategoryByName('Networks');
		const container = await categories.selectChannelByName('cj_enm');
		const slugCategory = await container.getCategoryName();
		await ecp.sendKeypress(ecp.Key.Right);
		await utils.sleep(2000);
		await ecp.sendKeypress(ecp.Key.Down, { count: 2 });
		await verifyC690753NavigateWithinPage(slugCategory);
	});
}); 
