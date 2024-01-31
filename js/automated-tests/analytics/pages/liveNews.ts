import { testUtils } from '../../test-utils';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import TitleDetailsPage from './titleDetailsPage';
import { LINEAR_NODES } from '../utils/constants';
import HomePage from './homePage';
import { expect } from 'chai';

const LiveNews = () => {
	const elements = {
		liveNewsGrid: async () =>
			await testUtils.getNodeForElement(LINEAR_NODES.LINEAR_NAVIGATION_PANEL),
		subtitlesIcon: async () =>
			await testUtils.getNodeForElement(LINEAR_NODES.LIVENEWS_SUBTITLES),
		subtitlesNavigation: async () =>
			await testUtils.getNodeForElement(LINEAR_NODES.LIVENEWS_SUBTITLES_PANEL),
		liveIcon: async () =>
			await testUtils.getNodeForElement(LINEAR_NODES.LIVE_ICON),
		countDownText: async () =>
			await testUtils.getNodeForElement(LINEAR_NODES.COUNT_DOWN),
	};

	async function checkIfVideoPlaying() {
		await testUtils.retryWithTimeOut(async () => {
			await testUtils.expectPlayerStateToEventuallyEqual('play');
		});
	}

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			await ecp.sendKeypress(ecp.Key.Down);
			const liveNewsGrid = await elements.liveNewsGrid();
			expect(liveNewsGrid.visible).to.equal(true);
		});
		await checkIfVideoPlaying();
	}

	async function navigateThroughChannelsAndGoToNextCategory() {
		await ecp.sendKeypress(ecp.Key.Right, { count: 2 });
		await ecp.sendKeypress(ecp.Key.Down);
	}

	async function checkIfLiveNewsShown() {
		await testUtils.retryWithTimeOut(async () => {
			const emblem = await elements.liveIcon();
			expect(emblem.visible).to.equal(true);
		});
	}

	async function waitUntilCountDownAppears() {
		await testUtils.retryWithTimeOut(async () => {
			const element = await elements.countDownText();
			expect(element.visible).to.equal(true);
		});
	}

	async function waitWhenGoFullScreen() {
		await waitUntilCountDownAppears();
		await testUtils.untilTrue(
			async () => {
				await utils.sleep(800);
				const element = await elements.countDownText();
				let { text } = element;
				if (text.includes('Fullscreen in 0 sec')) {
					return true;
				}
			},
			'Full screen is not visible after 15 sec',
			15000
		);
	}

	async function selectSubtitles(togle) {
		await ecp.sendKeypress(ecp.Key.Down);

		await ecp.sendKeypress(ecp.Key.Up);
		await ecp.sendKeypress(ecp.Key.Left);
		await testUtils.retryWithTimeOut(async () => {
			const subtitlesIcon = await elements.subtitlesIcon();
			expect(subtitlesIcon.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Up);
		await ecp.sendKeypress(ecp.Key.Ok);
		await testUtils.retryWithTimeOut(async () => {
			const subtitlesNavigation = await elements.subtitlesNavigation();
			expect(subtitlesNavigation.visible).to.equal(true);
		});
		if (togle) {
			await ecp.sendKeypress(ecp.Key.Right);
			await ecp.sendKeypress(ecp.Key.Ok);
		} else {
			await ecp.sendKeypress(ecp.Key.Left);
			await ecp.sendKeypress(ecp.Key.Ok);
		}
	}

	async function selectNewChannelFromMenu(channelNumber) {
		await ecp.sendKeypress(ecp.Key.Down, { wait: 200 });
		await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
		await elements.liveNewsGrid();
		await ecp.sendKeypress(ecp.Key.Down, {
			count: channelNumber,
			wait: 200,
		});
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function navigateToChannelMenu() {
		await ecp.sendKeypress(ecp.Key.Down, { wait: 200 });
		await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
		await elements.liveNewsGrid();
	}

	async function exitLiveNewsPlayer() {
		await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });
		await ecp.sendKeypress(ecp.Key.Back, { wait: 200 });
		return HomePage();
	}

	return {
		pageDidLoad,
		checkIfVideoPlaying,
		navigateThroughChannelsAndGoToNextCategory,
		selectSubtitles,
		checkIfLiveNewsShown,
		waitUntilCountDownAppears,
		waitWhenGoFullScreen,
		selectNewChannelFromMenu,
		navigateToChannelMenu,
		exitLiveNewsPlayer,
	};
};

export default LiveNews;
