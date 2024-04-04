import Home from '../pages/homePage';
import Settings from '../pages/settingsPage';
import Categories from '../pages/categories';
import ChannelsPage from '../pages/channelsPage';
import MyStuff from '../pages/myStuff';
import SearchPage from '../pages/searchPage';
import ActivatePage from '../pages/activatePage';
import { moveToRow } from '../utils/helpers';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../../test-utils';
import { expect } from 'chai';

export const tabs = {
	signIn: {
		page: () => ActivatePage(),
		row: 1,
	},
	exitKids: {
		row: 2,
	},
	kids: {
		page: () => Home(),
		row: 2,
	},
	search: {
		page: () => SearchPage(),
		row: 3,
	},
	home: {
		row: 4,
	},
	categories: {
		row: 5,
		page: () => Categories(),
	},
	myStuff: {
		row: 6,
		page: ({ isAuth }) => MyStuff({ isAuth }),
	},
	movies: {
		row: 7,
		page: () => Home(),
	},
	tvShows: {
		row: 8,
		page: () => Home(),
	},
	espanol: {
		row: 10,
		page: () => Home(),
	},
	settings: {
		row: 11,
		page: () => Settings(),
	},
};

const SideNav = () => {
	const elements = {};

	const ui = {
		row: 4,
	};

	async function selectTab(tab, { isAuth }) {
		await moveToRow(ui.row - tab.row);
		await utils.sleep(800);
		await ecp.sendKeypress(ecp.Key.Ok);
		tab.row === 1 ? ui.row : (ui.row = tab.row);
		const page = tab.page({ isAuth });
		await page.pageDidLoad();
		return page;
	}

	async function selectTabNoPageReturn(tab) {
		await moveToRow(ui.row - tab.row);
		await ecp.sendKeypress(ecp.Key.Ok);
		tab.row === 1 ? ui.row : (ui.row = tab.row);
	}

	async function selectSideNavTabNoPageReturn(tab, currentRow = ui.row) {
		ui.row = currentRow;
		await ecp.sendKeypress(ecp.Key.Left);
		await testUtils.waitForSideNavMenuToBeExpanded();
		await utils.sleep(1000);
		await selectTabNoPageReturn(tab);
	}

	async function selectSideNavTab(tab, currentRow = ui.row, isAuth = false) {
		ui.row = currentRow;
		await ecp.sendKeypress(ecp.Key.Left);
		await testUtils.waitForSideNavMenuToBeExpanded();
		const nextPage = await selectTab(tab, { isAuth });
		return nextPage;
	}

	return {
		selectSideNavTab,
		selectSideNavTabNoPageReturn,
	};
};

export default SideNav;
