import SideNav, { tabs } from '../components/sideNav';
import { SETTINGS_NODES } from '../utils/constants';
import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { moveToRow } from '../utils/helpers';
const elements = {
	settingsScreen: async () =>
		await testUtils.getNodeForElement(SETTINGS_NODES.SETTINGS_SCREEN),
	kidsLogo: async () => await testUtils.getNodeForElement('tubiKidsLogo'),
};
export const settingsTabs = {
	parentalControls: {
		row: 1,
	},
	autplayControls: {
		row: 2,
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
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 3000 });
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function turnOfPreview(){
		await moveToRow(ui.row - settingsTabs.autplayControls.row);
		// wait for the row to be highlighted
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 1000 });
		await ecp.sendKeypress(ecp.Key.Down, { wait: 1000 });
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 3000 });
	}

	const ui = {
		row: 1,
	};

	return {
		pageDidLoad,
		checkIfKidsLogoPresent,
		signOut,
		turnOfPreview,
		...SideNav(),
	};
};
export default Settings;
