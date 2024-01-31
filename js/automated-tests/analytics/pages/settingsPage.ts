import SideNav, { tabs } from '../components/sideNav';
import { SETTINGS_NODES } from '../utils/constants';
import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { moveToRow } from '../utils/helpers';
const elements = {
	settingsScreen: async () =>
		await testUtils.getNodeForElement(SETTINGS_NODES.SETTINGS_SCREEN),
	kidsLogo: async () => await testUtils.getNodeForElement('kidsLogoHomeScreen'),
};
export const settingsTabs = {
	parentalControls: {
		row: 1,
	},
	about: {
		row: 3,
	},
	privatePolicy: {
		row: 4,
	},
	signOut: {
		row: 5,
	},
};

const Settings = () => {
	async function pageDidLoad() {
		const settingsScreen = await elements.settingsScreen();
		expect(settingsScreen.visible).to.equal(true);
	}

	async function checkIfKidsLogoPresent() {
		await testUtils.retryWithTimeOut(async () => {
			const kidsLogo = await elements.kidsLogo();
			expect(kidsLogo.visible).to.equal(true);
		});
	}

	async function signOut() {
		await moveToRow(ui.row - settingsTabs.signOut.row);
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	const ui = {
		row: 1,
	};

	return {
		pageDidLoad,
		checkIfKidsLogoPresent,
		signOut,
		...SideNav(),
	};
};
export default Settings;
