import Home from '../pages/homePage';
import Settings from '../pages/settingsPage';
import { moveToRow } from '../utils/helpers';
import { ecp } from 'roku-test-automation';
import { testUtils } from '../../test-utils';
import { expect } from 'chai';

export const tabs = {
	signIn: {
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
		row: 3,
	},
	home: {
		row: 4,
	},
	myList: {
		row: 5,
	},
	categories: {
		row: 6,
	},
	channels: {
		row: 7,
	},
	espanol: {
		row: 8,
		page: () => Home(),
	},
	settings: {
		row: 9,
		page: () => Settings(),
	},
	exit: {
		row: 10,
	},
};

const SideNav = () => {
	const elements = {};

	const ui = {
		row: 4,
	};

	async function selectTab(tab) {
		await moveToRow(ui.row - tab.row);
		await ecp.sendKeypress(ecp.Key.Ok);
		tab.row === 1 ? ui.row : (ui.row = tab.row);
		const page = tab.page();
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
		await selectTabNoPageReturn(tab);
	}

	async function selectSideNavTab(tab, currentRow = ui.row) {
		ui.row = currentRow;
		await ecp.sendKeypress(ecp.Key.Left);
		await testUtils.waitForSideNavMenuToBeExpanded();
		const nextPage = await selectTab(tab);
		return nextPage;
	}

	return {
		selectSideNavTab,
		selectSideNavTabNoPageReturn,
	};
};

export default SideNav;
