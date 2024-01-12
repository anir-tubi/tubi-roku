import Home from '../pages/homePage';
import { ecp } from 'roku-test-automation';
import { moveToCol } from '../utils/helpers';
import { testUtils } from '../../test-utils';
import { expect } from 'chai';

export const sections = {
	recomended: {
		columns: 1,
		page: () => Home(),
	},
	movies: {
		columns: 2,
		page: () => Home(),
	},
	tvShows: {
		columns: 3,
		page: () => Home(),
	},
	// liveNews: {
	// 	columns: 4,
	// 	page: () => LiveNews(),
	// },
};

const topNav = () => {
	const elements = {
		topNavigation: async () =>
			await testUtils.getNodeForElement('selectedTopNavForYouItem'),
	};

	const ui = {
		colums: 1,
	};

	async function selectTab(tab) {
		await moveToCol(ui.colums - tab.columns);
		await ecp.sendKeypress(ecp.Key.Ok);
		tab.columns === 1 ? ui.colums : (ui.colums = tab.colums);
		const page = tab.page();
		await page.pageDidLoad();
		return page;
	}

	async function selectTopNavTab(tab, currentColumn = ui.colums) {
		ui.colums = currentColumn;
		await ecp.sendKeypress(ecp.Key.Back);
		await testUtils.retryWithTimeOut(async () => {
			const kidsLogo = await elements.topNavigation();
			expect(kidsLogo.visible).to.equal(true);
		});
		const nextPage = await selectTab(tab);
		return nextPage;
	}

	return {
		selectTopNavTab,
	};
};

export default topNav;
