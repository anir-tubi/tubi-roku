import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import TitleDetailsPage from './titleDetailsPage';
import { LINEAR_NODES } from '../utils/constants';
import HomePage from './homePage';
import ActivatePage from './activatePage';
import { expect } from 'chai';

const MyStuff = ({ isAuth = false } = {}) => {
	const elements = {
		unlockNowForMyStuff: async () =>
			await testUtils.getNodeForElement('unlockNowForMyStuff'),
	};

	async function pageDidLoad() {
		if (isAuth) {
			await testUtils.retryWithTimeOut(async () => {
				const unlockNowForMyStuff = await elements.unlockNowForMyStuff();
				expect(unlockNowForMyStuff.visible).to.equal(true);
			});
		}
	}

	async function selectUnlockNow() {
		await testUtils.retryWithTimeOut(async () => {
			const unlockNowForMyStuff = await elements.unlockNowForMyStuff();
			expect(unlockNowForMyStuff.text).to.equal('Unlock Now');
		});
		await ecp.sendKeypress(ecp.Key.Ok);
		const activatePage = ActivatePage();
		await activatePage.pageDidLoad();
		return activatePage;
	}

	return {
		pageDidLoad,
		selectUnlockNow,
	};
};

export default MyStuff;
