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
		continueWatchingRowText: async () =>
			await testUtils.getNodeForElement('continueWatchingRow'),
		goHomeMyStuffButton: async () =>
			await testUtils.getNodeForElement('goHomeMyStuffButton'),
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
		await utils.sleep(1500);
		await testUtils.retryWithTimeOut(async () => {
			const unlockNowForMyStuff = await elements.unlockNowForMyStuff();
			expect(unlockNowForMyStuff.text).to.equal('Unlock Now');
		});
		await ecp.sendKeypress(ecp.Key.Ok);
		const activatePage = ActivatePage();
		await activatePage.pageDidLoad();
		return activatePage;
	}

	async function selectGoHome() {
		const goToHome = await elements.goHomeMyStuffButton(); //if user signed in text should be Go to Home
		expect(goToHome.text).equal('Go Home');
		await ecp.sendKeypress(ecp.Key.Ok);
		const homePage = HomePage();
		await homePage.pageDidLoad();
		return homePage;
	}

	async function selectContinueWatchingIfOnlyone() {
		await testUtils.retryWithTimeOut(async () => {
			const unlockNowForMyStuff = await elements.continueWatchingRowText();
			expect(unlockNowForMyStuff.visible).to.equal(true);
		});
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			'myStuffGrid'
		);
		await ecp.sendKeypress(ecp.Key.Ok);
		const titleDetailsPage = TitleDetailsPage(content);
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	async function selectQueueIfOnlyone() {
		await testUtils.retryWithTimeOut(async () => {
			const unlockNowForMyStuff = await elements.continueWatchingRowText();
			expect(unlockNowForMyStuff.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Down);
		await utils.sleep(1000);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			'queueRowList'
		);
		await ecp.sendKeypress(ecp.Key.Ok);
		const titleDetailsPage = TitleDetailsPage(content);
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	return {
		selectContinueWatchingIfOnlyone,
		pageDidLoad,
		selectUnlockNow,
		selectQueueIfOnlyone,
		selectGoHome,
	};
};

export default MyStuff;
