import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import Container from './container';

const ActivatePage = () => {
	async function pageDidLoad() {}

	async function clickOnLetsCreateYourAccount() {
		await utils.sleep(4000);
		await ecp.sendKeypress(ecp.Key.Ok);
	}
	async function clickCancelForCreateAccount() {
		await utils.sleep(4000);
		await ecp.sendKeypress(ecp.Key.Down);
		await utils.sleep(500);
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	return {
		pageDidLoad,
		clickOnLetsCreateYourAccount,
		clickCancelForCreateAccount,
	};
};

export default ActivatePage;
