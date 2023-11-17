import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { PLAYER_NODES, AUTOPLAY_NODES } from '../utils/constants';
import TitleDetailsPage from './titleDetailsPage';
const PlayBack = ({ content }) => {
	// eslint-disable-next-line no-nested-ternary

	const elements = {
		player: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.VIDEO_PLAYER_ACTUAL),
		fastForwardButton: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.FAST_FORWARD_BUTTON),
		playerRemaining: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.PLAYER_REMAINING),
		playerPlaingTime: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.CURRENT_TIME_PLAYED),
		playPauseButton: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.PLAY_PAUSE_BUTTON),
		countDownAutoplay: async () =>
			await testUtils.getNodeForElement(AUTOPLAY_NODES.COUNT_DOWN_MOVIE), //TODO check if it's same for TVShows
	};

	const ui = {
		content,
	};

	async function pageDidLoad() {
		const player = await elements.player();
		expect(player.visible).to.equal(true);
		await testUtils.expectPlayerStateToEventuallyEqual('play');
	}

	async function pausePlayback() {
		await ecp.sendKeypress(ecp.Key.Play);
		const playPauseButton = await elements.playPauseButton();
		expect(playPauseButton.visible).to.equal(true);
	}

	async function allowPlaybackToPlayForSeconds(time) {
		await utils.sleep(time);
	}

	async function getCurrentPlaybackTimeInMinutes() {
		let runTime;
		await testUtils.retryWithTimeOut(async () => {
			runTime = await elements.playerPlaingTime();
			expect(runTime.visible).to.equal(true);
		});
		const elTime = getTimeInMinutes(runTime.text);
		return Math.floor(elTime);
	}

	const getTimeInMinutes = (time) => {
		const [h, m, s] = time.split(':');
		return parseInt(h) * 60 + parseInt(m) + parseInt(s) / 60;
	};

	const getTimeInSeconds = (time) => {
		const [h, m, s] = time.split(':');
		return parseInt(h) * 3600 + parseInt(m) * 60 + parseInt(s);
	};

	async function fastForward({ howFast = 1, howLong = 300 } = {}) {
		await pausePlayback();
		await fastForwardNoWaitTime({ howFast: howFast });
		await utils.sleep(howLong);
		await ecp.sendKeypress(ecp.Key.Play);
	}

	async function clickOnNextTitleInPlaybackControlls() {
		await ecp.sendKeypress(ecp.Key.Down);
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await utils.sleep(300);
		await ecp.sendKeypress(ecp.Key.Right, { count: 3 });
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function highlightProgressBar() {
		await ecp.sendKeypress(ecp.Key.Up);
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await utils.sleep(300);
		await ecp.sendKeypress(ecp.Key.Up);
	}

	async function seekByProgressBarForward(howManyTimes) {
		await highlightProgressBar();
		await ecp.sendKeypress(ecp.Key.Right, { count: howManyTimes });
		await ecp.sendKeypress(ecp.Key.Play);
	}

	async function seekByProgressBarBack(howManyTimes) {
		await highlightProgressBar();
		await ecp.sendKeypress(ecp.Key.Left, { count: howManyTimes });
		await ecp.sendKeypress(ecp.Key.Play);
	}

	async function clickOnBackToBeginning() {
		await ecp.sendKeypress(ecp.Key.Play);
		await utils.sleep(300);
		await ecp.sendKeypress(ecp.Key.Left, { count: 3 });
		await utils.sleep(300);
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function thirtySkipBackOnPlaybackControlls() {
		await ecp.sendKeypress(ecp.Key.Down);
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await utils.sleep(300);
		await ecp.sendKeypress(ecp.Key.Left);
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function fastForwardNoWaitTime({ howFast = 1 } = {}) {
		await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Right, { count: 2 });
		// FF button highlighted
		const fastForwardButton = await elements.fastForwardButton();
		expect(fastForwardButton.visible).to.equal(true);
		// Press FF button howFast times
		await ecp.sendKeypress(ecp.Key.Ok, { count: howFast });
	}

	async function rewindPlayback({ howFast = 1, howLong = 300 } = {}) {
		await ecp.sendKeypress(ecp.Key.Down);
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Left);
		await ecp.sendKeypress(ecp.Key.Left);
		await ecp.sendKeypress(ecp.Key.Ok, { count: howFast });
		await allowPlaybackToPlayForSeconds(howLong);
		await ecp.sendKeypress(ecp.Key.Play);
		await testUtils.expectPlayerStateToEventuallyEqual('play');
		await allowPlaybackToPlayForSeconds(1000);
	}

	async function getProgressPercent() {
		const playerPlaingTime = await elements.playerPlaingTime();
		const elTime = getTimeInSeconds(playerPlaingTime.text);
		return elTime / ui.content.duration;
	}

	async function seekToAutoplay() {
		await fastForwardNoWaitTime({ howFast: 3 });
		await testUtils.untilTrue(
			async () => {
				const progress = await getProgressPercent();
				if (progress > 0.99) {
					await ecp.sendKeypress(ecp.Key.Play);
					await waitForAutoplayVisible();
					return true;
				}
			},
			'Something wrong with scrolling to autoplay',
			200000
		);
	}

	async function waitForAutoplayVisible() {
		await testUtils.retryWithTimeOut(async () => {
			//TODO change this to autoplay general
			const countDownMovieAutoPlay = await testUtils.getNodeForElement(
				'countDownMovieAutoPlay'
			);
			expect(countDownMovieAutoPlay.visible).to.equal(true);
		});
	}

	async function waitForAutoplayToDisappearByTimer() {
		await testUtils.untilTrue(
			async () => {
				let countDownAutoplay;
				await testUtils.retryWithTimeOut(async () => {
					countDownAutoplay = await elements.countDownAutoplay();
					expect(countDownAutoplay.visible).to.equal(true);
				});
				const [start, inn, space, seconds] = countDownAutoplay.text.split(' ');
				if (parseInt(seconds) === 0) {
					return true;
				}
			},
			'Autoplay didnt disappear after 40 sec',
			40000
		);
	}

	async function navigateBackToDetailsScreen() {
		await ecp.sendKeypress(ecp.Key.Back);
		const titleDetailsPage = TitleDetailsPage(content);
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	return {
		pageDidLoad,
		allowPlaybackToPlayForSeconds,
		pausePlayback,
		fastForward,
		getCurrentPlaybackTimeInMinutes,
		seekToAutoplay,
		waitForAutoplayToDisappearByTimer,
		rewindPlayback,
		seekByProgressBarForward,
		seekByProgressBarBack,
		clickOnBackToBeginning,
		clickOnNextTitleInPlaybackControlls,
		navigateBackToDetailsScreen,
		thirtySkipBackOnPlaybackControlls,
	};
};

export default PlayBack;
