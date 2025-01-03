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
			await testUtils.getNodeForElement(AUTOPLAY_NODES.COUNT_DOWN_MOVIE),
		countDownAutoplaySeries: async () =>
			await testUtils.getNodeForElement(AUTOPLAY_NODES.COUNT_DOWN_SERIES),
		subtitles: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.SUBTITLES),
		titleName: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.TITLE_NAME_IN_PLAYBACK),
		videoPlayer: async () =>
			await testUtils.getNodeForElement(PLAYER_NODES.VIDEO_PLAYER),
		skipIntro: async () => await testUtils.getNodeForElement('skipIntro'),
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

	async function clickOnSkipIntroIfPresent() {
		let skipIntro;
		await testUtils.retryWithTimeOut(async () => {
			skipIntro = await elements.skipIntro();
		});
		if (skipIntro.visible) {
			await clickOnSkipIntro();
		}
	}

	async function checkIfSkipIntroIfPresent() {
		let skipIntro;
		await testUtils.retryWithTimeOut(async () => {
			skipIntro = await elements.skipIntro();
		});
		return skipIntro.visible;
	}


	async function clickOnSkipIntro() {
		await testUtils.retryWithTimeOut(async () => {
			const skipIntro = await elements.skipIntro();
			expect(skipIntro.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Up), { wait: 300 };
		await ecp.sendKeypress(ecp.Key.Ok, { wait: 500, count: 2 });
	}

	async function getIdOfCurrentTitle() {
		const videoPlayer = await elements.videoPlayer();
		const searchedTitleId = videoPlayer.content.id;
		return { id: searchedTitleId };
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

	async function getCurrentPlaybackTimeInSeconds() {
		let runTime;
		await testUtils.retryWithTimeOut(async () => {
			runTime = await elements.playerPlaingTime();
			expect(runTime.visible).to.equal(true);
		});
		const elTime = getTimeInSeconds(runTime.text);
		return elTime;
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

	async function thirtySkipForward() {
		if(await checkIfSkipIntroIfPresent()){
			await utils.sleep(1000);	
			await ecp.sendKeypress(ecp.Key.Down);
			await utils.sleep(1000);
		}
		await ecp.sendKeypress(ecp.Key.Down);
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await utils.sleep(300);
		await ecp.sendKeypress(ecp.Key.Right);
		await ecp.sendKeypress(ecp.Key.Ok);
		await utils.sleep(300);
	}

	async function thirtySkipBack() {
		await ecp.sendKeypress(ecp.Key.Down, { count: 4 });
		await allowPlaybackToPlayForSeconds(300);
		await ecp.sendKeypress(ecp.Key.Left);
		await allowPlaybackToPlayForSeconds(300);
		await ecp.sendKeypress(ecp.Key.Ok);
		await allowPlaybackToPlayForSeconds(3500);
	}
	async function fastForwardNoWaitTime({ howFast = 1 } = {}) {
		if (await checkIfSkipIntroIfPresent()){
			await ecp.sendKeypress(ecp.Key.Down, { count: 1 });
			await allowPlaybackToPlayForSeconds(1000); 
		}
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
		if(await checkIfSkipIntroIfPresent()){
			await ecp.sendKeypress(ecp.Key.Down, { count: 2,wait: 700 });
		}
		await ecp.sendKeypress(ecp.Key.Down);
		await testUtils.retryWithTimeOut(async () => {
			const playPauseButton = await elements.playPauseButton();
			expect(playPauseButton.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Left, { count: 2 });
		await ecp.sendKeypress(ecp.Key.Ok, { count: howFast });
		await allowPlaybackToPlayForSeconds(howLong);
		await ecp.sendKeypress(ecp.Key.Play);
		await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing');
		await allowPlaybackToPlayForSeconds(1000);
	}

	async function getProgressPercent() {
		const playerPlaingTime = await elements.playerPlaingTime();
		const elTime = getTimeInSeconds(playerPlaingTime.text);
		let duration;
		if (content.selectedContentType === 'series') {
			duration = ui.content.length;
		} else {
			duration = ui.content.duration;
		}
		return elTime / duration;
	}

	function areLastFortyValuesSame(arr: number[]): boolean {
		if (arr.length < 40) {
			return false;
		}
		const lastFive = arr.slice(-40);
		return lastFive.every((value, index, array) => value === array[0]);
	}

	function allNaN(arr: number[]): boolean {
		if (arr.length < 7000) {
			return false;
		}
		return arr.every((num) => isNaN(num));
	}

	async function seekToAutoplay() {
		await clickOnSkipIntroIfPresent();
		await fastForwardNoWaitTime({ howFast: 3 });
		const arr = new Array<number>();
		let latestPorgress;
		await testUtils.untilTrue(
			async () => {
				const progress = await getProgressPercent();
				if (progress > 0.99 || areLastFortyValuesSame(arr) || allNaN(arr)) {
					await ecp.sendKeypress(ecp.Key.Play);
					await waitForAutoplayVisible();
					return true;
				}
				if (latestPorgress === progress || Number.isNaN(latestPorgress)) {
					arr.push(latestPorgress);
				}
				latestPorgress = progress;
			},
			'Something wrong with scrolling to autoplay',
			200000
		);
	}

	async function waitForAutoplayVisible() {
		await testUtils.retryWithTimeOut(async () => {
			let countDownAutoPlay;
			if (content.mode === 'series') {
				countDownAutoPlay = await elements.countDownAutoplaySeries();
			} else {
				countDownAutoPlay = await elements.countDownAutoplay();
			}
			expect(countDownAutoPlay.visible).to.equal(true);
		});
	}

	async function seekToTheEndAndDismissAutoplay() {
		await seekToAutoplay();
		await waitForCountDown();
		await ecp.sendKeypress(ecp.Key.Back);
		await fastForwardNoWaitTime();
		await testUtils.untilTrue(
			async () => {
				const progress = await getProgressPercent();
				console.log(`progress ${progress}`);
				if (progress > 0.97) {
					await ecp.sendKeypress(ecp.Key.Play);
					await getCurrentPlaybackTimeInMinutes();
					return true;
				}
			},
			'Something wrong with scrolling to autoplay',
			200000
		);
	}

	async function waitForCountDown() {
		await testUtils.untilTrue(
			async () => {
				let countDownAutoplay;
				if (content.mode === 'series' || content.type === 's') {
					countDownAutoplay = await elements.countDownAutoplaySeries();
				} else {
					countDownAutoplay = await elements.countDownAutoplay();
				}
				const text = countDownAutoplay.text;
				const [start, inn, space, seconds] = countDownAutoplay.text.split(' ');
				if (content.mode === 'series' || content.type === 's') {
					if (
						parseInt(seconds) === 14 ||
						parseInt(seconds) === 13 ||
						parseInt(seconds) === 12
					) {
						return true;
					}
				} else {
					if (
						parseInt(seconds) === 29 ||
						parseInt(seconds) === 28 ||
						parseInt(seconds) === 27 ||
						parseInt(seconds) === 26
					) {
						return true;
					}
				}
			},
			'Missed start of autoplay',
			95000
		);
	}

	async function selectNextTitleInAutoplay(times) {
		await waitForCountDown();
		await allowPlaybackToPlayForSeconds(2000);
		if (times != 0) {
			await ecp.sendKeypress(ecp.Key.Right, { count: times });
		}
		await allowPlaybackToPlayForSeconds(2000);
		await ecp.sendKeypress(ecp.Key.Ok);
		await pageDidLoad();
	}
	async function selectSubtitles() {
		await ecp.sendKeypress(ecp.Key.Down);
		await testUtils.retryWithTimeOut(async () => {
			const subtitles = await elements.subtitles();
			expect(subtitles.visible).to.equal(true);
		});
		await ecp.sendKeypress(ecp.Key.Right, { count: 4 });
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function selectSubtitlesOff() {
		await selectSubtitles();
		await ecp.sendKeypress(ecp.Key.Down, { count: 1,wait: 400 });
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function selectSubtitlesOn() {
		await selectSubtitles();
		await utils.sleep(500);
		await ecp.sendKeypress(ecp.Key.Down, { count:2,wait: 400 });
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function waitForAutoplayToDisappearByTimer() {
		let passedHalf = false;
		await testUtils.untilTrue(
			async () => {
				let countDownAutoplay;
				await testUtils.retryWithTimeOut(async () => {
					countDownAutoplay = await elements.countDownAutoplay();
					expect(countDownAutoplay.visible).to.equal(true);
				}, 110000);
				const [start, inn, space, seconds] = countDownAutoplay.text.split(' ');
				if (seconds < 15) {
					passedHalf = true;
				}
				if (
					parseInt(seconds) === 0 ||
					(passedHalf && parseInt(seconds) === 30) ||
					(passedHalf && parseInt(seconds) === 1)
				) {
					return true;
				}
			},
			'Autoplay didnt disappear after 1.35 min',
			95000
		);
	}

	async function navigateBackToDetailsScreen() {
		await ecp.sendKeypress(ecp.Key.Back);
		const titleDetailsPage = TitleDetailsPage(content);
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	async function selectFirstTitleFromBrowseWhileWatching() {
		await ecp.sendKeypress(ecp.Key.Down, { count: 3, wait: 700 });
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			'browseWhileWatchingRowList'
		);
		await ecp.sendKeypress(ecp.Key.Right, { wait: 200 });
		await allowPlaybackToPlayForSeconds(10000);
		await ecp.sendKeypress(ecp.Key.Ok);
		const playback = PlayBack({ content: content });
		await playback.pageDidLoad();
		return playback;
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
		selectNextTitleInAutoplay,
		selectSubtitlesOff,
		selectSubtitlesOn,
		getIdOfCurrentTitle,
		seekToTheEndAndDismissAutoplay,
		thirtySkipForward,
		thirtySkipBack,
		getCurrentPlaybackTimeInSeconds,
		fastForwardNoWaitTime,
		clickOnSkipIntro,
		selectFirstTitleFromBrowseWhileWatching,
	};
};

export default PlayBack;
