import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import TitleDetailsPage from './titleDetailsPage';
import { LINEAR_NODES } from '../utils/constants';
import HomePage from './homePage';
import ActivatePage from './activatePage';
import { expect } from 'chai';

const SignInEmailPage = (emailPovided = true) => {
	const elements = {
		passwordField: async () =>
			await testUtils.getNodeForElement('signInScreenPasswordBox'),
		continueButtonSignInPage: async () =>
			await testUtils.getNodeForElement('continueButtonSignInPage'),
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const passwordField = await elements.passwordField();
			expect(passwordField.visible).to.equal(true);
		});
	}

	async function enterPasswordAndClickContinue(text) {
		await testUtils.retryWithTimeOut(async () => {
			const passwordField = await elements.passwordField();
			expect(passwordField.visible).to.equal(true);
		});
		await utils.sleep(3000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await ecp.sendText(text);
		await ecp.sendKeypress(ecp.Key.Down, { count: 5, wait: 500 });
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Right);
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await utils.sleep(1000);
	}

	return {
		pageDidLoad,
		enterPasswordAndClickContinue,
	};
};

export default SignInEmailPage;
