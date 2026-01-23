import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import ActivatePage from './activatePage';
import TitleDetailsPage from './titleDetailsPage';
import LiveNews from '../pages/liveNews';
import { NODES, PLAYER_NODES } from '../utils/constants';
import SideNav, { tabs } from '../components/sideNav';
const HomePage = ({ isMovies, isTvShows } = {}) => {
	const elements = {
		movieScreenRowList: async () =>
			await testUtils.getNodeForElement(NODES.MOVIE_SCREEN_ROW_LIST),
		tvScreenRowList: async () =>
			await testUtils.getNodeForElement(NODES.TV_SHOW_SCREEN_ROW_LIST),
		espanolRowList: async () =>
			await testUtils.getNodeForElement(NODES.ESPANOL_SCREEN_ROW_LIST),
		homeRowList: async () =>
			await testUtils.getNodeForElement(NODES.HOME_SCREEN_ROW_LIST),
		movieDescription: async () =>
			await testUtils.getNodeForElement(NODES.TITLE_DESCRIPTION_MOVIE),
		description: async () =>
			await testUtils.getNodeForElement(NODES.TITLE_DESCRIPTION_HOME),
		homeScreenPoster: async () =>
			await testUtils.getNodeForElement('homeScreenPoster'),
		homeScreenPosterVideoPreview: async () =>
			await testUtils.getNodeForElement(NODES.HOME_SCREEN_POSTER_VIDEO_PREVIEW),
		homeScreenKidsLogo: async () =>
			await testUtils.getNodeForElement('tubiKidsLogo'),
		exitToUseFeatureMessage: async () =>
			await testUtils.getNodeForElement('exitToUseThisFeatureMesage'),
		exitToUseFeatureMessageKids: async () =>
			await testUtils.getNodeForElement('exitToUseThisFeatureMesageKids'),
		tvShowsSeriesLabel: async () =>
			await testUtils.getNodeForElement('tvShowsSeriesLabel'),
		moviesLabel: async () => await testUtils.getNodeForElement('moviesLabel'),
	};

	const ui = {
		currentPosition: 0,
	};

	// expect(tvScreenRowList.visible).to.equal(true);
	async function getMovieTitleId() {
		await testUtils.retryWithTimeOut(async () => {
			const movieScreenRowList = await elements.movieScreenRowList();
			expect(movieScreenRowList.visible).to.equal(true);
			const moviesLabel = await elements.moviesLabel();
			expect(moviesLabel.visible).to.equal(true);
		});
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		return parseInt(content.id);
	}

	async function getTitleIdHomeScreenHorizontal({ row, amount }) {
		const ids = [];
		await testUtils.retryWithTimeOut(async () => {
			const homeScreenPoster = await elements.homeScreenPoster();
			expect(homeScreenPoster.visible).to.equal(true);
		});
		const content = await testUtils.getAllRowListItemsContentGroupedByRow(
			NODES.HOME_SCREEN_ROW_LIST
		);
		content[row].slice(0, amount).map((item) => ids.push(parseInt(item.id)));
		return ids;
	}

	async function getTitleIdEspanolScreenHorizontal({ row, amount }) {
		const ids = [];
		await testUtils.retryWithTimeOut(async () => {
			const homeScreenPoster = await elements.homeScreenPoster();
			expect(homeScreenPoster.visible).to.equal(true);
		});
		const content = await testUtils.getAllRowListItemsContentGroupedByRow(
			NODES.ESPANOL_SCREEN_ROW_LIST
		);
		content[row].slice(0, amount).map((item) => ids.push(parseInt(item.id)));
		return ids;
	}

	async function getTitleIdHomeScreenVertical({ amount }) {
		const ids = [];
		await testUtils.retryWithTimeOut(async () => {
			const homeScreenPoster = await elements.homeScreenPoster();
			expect(homeScreenPoster.visible).to.equal(true);
		});
		const content = await testUtils.getAllRowListItemsContentGroupedByRow(
			NODES.HOME_SCREEN_ROW_LIST
		);
		for (let i = 0; i < amount; i++) {
			content[i].slice(0, 1).map((item) => ids.push(parseInt(item.id)));
		}
		return ids;
	}

	async function getTitleIdMoviesScreen({ row, amount }) {
		const ids = [];
		await testUtils.retryWithTimeOut(async () => {
			const homeScreenPoster = await elements.homeScreenPoster();
			expect(homeScreenPoster.visible).to.equal(true);
		});
		const content = await testUtils.getAllRowListItemsContentGroupedByRow(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		content[row].slice(0, amount).map((item) => ids.push(parseInt(item.id)));
		return ids;
	}

	async function getTitleIdTVShowsScreen({ row, amount }) {
		const ids = [];
		await testUtils.retryWithTimeOut(async () => {
			const homeScreenPoster = await elements.homeScreenPoster();
			expect(homeScreenPoster.visible).to.equal(true);
		});
		const content = await testUtils.getAllRowListItemsContentGroupedByRow(
			NODES.TV_SHOW_SCREEN_ROW_LIST
		);
		content[row].slice(0, amount).map((item) => ids.push(parseInt(item.id)));
		return ids;
	}

	async function navigateToFirstColumn() {
		while (ui.currentPosition >= 0) {
			await ecp.sendKeypress(ecp.Key.Left, { count: 1, wait: 1000 });
			ui.currentPosition--;
		}
	}

	async function navigateRightAndGetTitleIdsOnSameRow(numberOfTitles: number): Promise<number[]> {
		const titleIds: number[] = [];
		for (let i = 0; i < numberOfTitles; i++) {
			const titleId = await getTitleId();
			if (titleId) {
				titleIds.push(titleId);
			}
			await ecp.sendKeypress(ecp.Key.Right);
			await utils.sleep(1000);
			ui.currentPosition = i;
		}
		return titleIds;
	}

	async function highlightTitleWithVideoPreview() {
		await testUtils.retryWithTimeOut(async () => {
			const movieScreenRowList = await elements.movieScreenRowList();
			expect(movieScreenRowList.visible).to.equal(true);
			const moviesLabel = await elements.moviesLabel();
			expect(moviesLabel.visible).to.equal(true);
		});
		let content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);

		let i = 40;
		while (
			content.video_preview_url &&
			content.video_preview_url.length === 0 &&
			i > 0
		) {
			await ecp.sendKeypress(ecp.Key.Right);
			content = await testUtils.getCurrentlyFocusedGridItemContent(
				NODES.MOVIE_SCREEN_ROW_LIST
			);
			i--;
		}
		return parseInt(content.id);
	}

	async function waitForPlayBackToStartForMovie() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		await testUtils.retryWithTimeOut(async () => {
			const player = await testUtils.getNodeForElement(
				PLAYER_NODES.VIDEO_PLAYER_ACTUAL
			);
			expect(player.visible).to.equal(true);
		}, 120000);
		const playback = PlayBack({ content: content });
		await playback.pageDidLoad();
		return playback;
	}

	async function pageDidLoad() {
		const homeScreenPoster = await elements.homeScreenPoster();
		expect(homeScreenPoster.visible).to.equal(true);
	}

	async function getMovieTitleIdAndCategory() {
		const movieScreenRowList = await elements.movieScreenRowList();
		expect(movieScreenRowList.visible).to.equal(true);
		await testUtils.retryWithTimeOut(async () => {
			const movieDescirption = await elements.movieDescription();
			expect(movieDescirption.visible).to.equal(true);
		});
		const detailScreenTitle = await elements.movieDescription();
		const [categorySlug, contentId] = detailScreenTitle.text.split(' ');
		return { contentId: contentId, categorySlug: categorySlug };
	}

	async function getHomeCategoryName() {
		const homeScreenRowList = await elements.homeRowList();
		expect(homeScreenRowList.visible).to.equal(true);
		const detailScreenTitle = await elements.description();
		const [categorySlug] = detailScreenTitle.text.split(' ');
		return { categorySlug: categorySlug };
	}

	async function getTVShowTitleId() {
		let content;
		await testUtils.retryWithTimeOut(async () => {
			const tvShowScreenRowList = await elements.tvScreenRowList();
			expect(tvShowScreenRowList.visible).to.equal(true);
			const tvShowsSeriesLabel = await elements.tvShowsSeriesLabel();
			expect(tvShowsSeriesLabel.visible).to.equal(true);
		});
		await testUtils.retryWithTimeOut(async () => {
			content = await testUtils.getCurrentlyFocusedGridItemContent(
				NODES.TV_SHOW_SCREEN_ROW_LIST
			);
		});
		return parseInt(content.id);
	}

	async function getSerialTag() {
		const tvShowsSeriesLabel = await elements.tvShowsSeriesLabel();
		return tvShowsSeriesLabel.text;
	}

	async function selectFocusedTitleMovie() {
		// need to contnent in focus to get the correct title
		await utils.sleep(800);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		return await selectFocusedTitle(content);
	}

	async function selectFocusedTitleMovieWithSubtitles() {
		let content;
		let i;
		await testUtils.untilTrue(
			async () => {
				await utils.sleep(800);
				content = await testUtils.getCurrentlyFocusedGridItemContent(
					NODES.MOVIE_SCREEN_ROW_LIST
				);
				if (content.has_subtitle) {
					return true;
				}
				if (i == 7) {
					await ecp.sendKeypress(ecp.Key.Down); // need this to change row
					i = 0;
				}
				await ecp.sendKeypress(ecp.Key.Right);
				i++;
			},
			'Cant find title with subtitles',
			200000
		);
		return await selectFocusedTitle(content);
	}

	async function selectFocusedTitleKidsMode() {
		await testUtils.retryWithTimeOut(async () => {
			const kidsLogo = await elements.homeScreenKidsLogo();
			expect(kidsLogo.visible).to.equal(true);
		});
		await utils.sleep(4000);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.HOME_SCREEN_ROW_LIST
		);
		return await selectFocusedTitle(content);
	}

	async function getPopupMessage() {
		let channelsDisabledMessage;
		await testUtils.retryWithTimeOut(async () => {
			channelsDisabledMessage = await elements.exitToUseFeatureMessage();
			expect(channelsDisabledMessage.text).to.not.be.empty;
		});
		return channelsDisabledMessage.text;
	}

	async function getPopupMessageKids() {
		let channelsDisabledMessage;
		await testUtils.retryWithTimeOut(async () => {
			channelsDisabledMessage = await elements.exitToUseFeatureMessageKids();
			expect(channelsDisabledMessage.text).to.not.be.empty;
		});
		return channelsDisabledMessage.text;
	}

	async function selectFocusedTitleEspanol() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.ESPANOL_SCREEN_ROW_LIST
		);
		return await selectFocusedTitle(content);
	}

	async function selectFocusedTvShowTitleEspanol() {
		let content;
		await testUtils.untilTrue(
			async () => {
				content = await testUtils.getCurrentlyFocusedGridItemContent(
					NODES.ESPANOL_SCREEN_ROW_LIST
				);
				if (content.type === 's') {
					return true;
				}
				await ecp.sendKeypress(ecp.Key.Right, { wait: 2000 });
			},
			'Cant find TV Show on Espanol Page',
			200000
		);
		return await selectFocusedTitle(content);
	}

	async function selectMovieTitleWithNoTrailer() {
		let content;
		let i = 0;
		await testUtils.untilTrue(
			async () => {
				await utils.sleep(800);
				content = await testUtils.getCurrentlyFocusedGridItemContent(
					NODES.MOVIE_SCREEN_ROW_LIST
				);
				if (content.trailers == undefined) {
					return true;
				}
				if (i == 7) {
					await ecp.sendKeypress(ecp.Key.Down); // need this to change row
					i = 0;
				}
				await ecp.sendKeypress(ecp.Key.Right);
				i++;
			},
			'Cant find title with no trailer',
			200000
		);
		return await selectFocusedTitle(content);
	}

	async function navigateToLiveNews(getNavigateToPage = false) {
		await testUtils.jumpToRowWithTitle(
			'homeScreenRowList',
			'recommended_linear_channels'
		);
		if (getNavigateToPage) {
			await utils.sleep(500);
			await ecp.sendKeypress(ecp.Key.Up);
			await utils.sleep(500);
			await ecp.sendKeypress(ecp.Key.Down);
		}
	}

	async function navigateToContinueWatchingAndSelectIt() {
		await testUtils.jumpToRowWithTitle(
			'homeScreenRowList',
			'Continue Watching'
		);
		await ecp.sendKeypress(ecp.Key.Ok);
		const activatePage = ActivatePage();
		await activatePage.pageDidLoad();
		return activatePage;
	}

	async function navigateToLiveNewsAndSelect(getNavigateToPage = false) {
		await navigateToLiveNews(getNavigateToPage);
		await ecp.sendKeypress(ecp.Key.Ok);
		const liveNews = LiveNews();
		await liveNews.pageDidLoad();
		return liveNews;
	}

	async function selectMovieTitleWithTrailer() {
		let content;
		let i = 0;
		await testUtils.untilTrue(
			async () => {
				await utils.sleep(800);
				content = await testUtils.getCurrentlyFocusedGridItemContent(
					NODES.MOVIE_SCREEN_ROW_LIST
				);
				if (content.trailers !== undefined) {
					return true;
				}
				if (i == 7) {
					await ecp.sendKeypress(ecp.Key.Down); // need this to change row
					i = 0;
				}
				await ecp.sendKeypress(ecp.Key.Right);
				i++;
			},
			'Cant find title with tailer',
			200000
		);
		return await selectFocusedTitle(content);
	}

	async function exitKidsMode() {
		await SideNav().selectSideNavTabNoPageReturn(tabs.exitKids);
	}

	async function selectFocusedTitleTVShow() {
		//await ecp.sendKeypress(ecp.Key.Down);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.TV_SHOW_SCREEN_ROW_LIST
		);
		return await selectFocusedTitle(content);
	}

	async function selectFocusedTitle(content) {
		await ecp.sendKeypress(ecp.Key.Ok);
		const titleDetailsPage = TitleDetailsPage(content);
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	async function fetchContent() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		return content;
	}

	async function fetchKidsContent() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.HOME_SCREEN_ROW_LIST
		);
		return content;
	}

	async function fetchTVShowContent() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.TV_SHOW_SCREEN_ROW_LIST
		);
		return content;
	}

	async function fetchEspanolContent() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.ESPANOL_SCREEN_ROW_LIST
		);
		return content;
	}

	async function playTitle(espanol = false, kids = false, tvShow = false) {
		await pageDidLoad();
		await testUtils.retryWithTimeOut(async () => {
			const homeScreenPosterVideoPreview = await elements.homeScreenPosterVideoPreview();
			expect(homeScreenPosterVideoPreview.visible).to.equal(true);
		});
		// need to sleep to get the correct title
		await utils.sleep(1000);
		await ecp.sendKeypress(ecp.Key.Play);
		let content;
		if (espanol) {
			content = await fetchEspanolContent();
		} else if (kids) {
			content = await fetchKidsContent();
		} else if (tvShow) {
			content = await fetchTVShowContent();
		} else {
			content = await fetchContent();
		}
		const playback = PlayBack({ content: content });
		await playback.pageDidLoad();
		return playback;
	}

	async function playMovieTitle() {
		const movieScreenRowList = await elements.movieScreenRowList();
		expect(movieScreenRowList.visible).to.equal(true);
		return await playTitle();
	}

	async function playKidsTitle() {
		await testUtils.retryWithTimeOut(async () => {
			const kidsLogo = await elements.homeScreenKidsLogo();
			expect(kidsLogo.visible).to.equal(true);
		});
		await utils.sleep(3500);
		return await playTitle(false, true);
	}

	async function playEspanolTitle() {
		const espanolRowList = await elements.espanolRowList();
		expect(espanolRowList.visible).to.equal(true);
		return await playTitle(true);
	}

	async function playTVShowTitle() {
		const tvShowScreenRowList = await elements.tvScreenRowList();
		expect(tvShowScreenRowList.visible).to.equal(true);
		return await playTitle(false, false, true);
	}

	async function navigateDown(times, wait = 200) {
		await ecp.sendKeypress(ecp.Key.Down, { count: times, wait: wait });
	}

	async function navigateRight(times) {
		await ecp.sendKeypress(ecp.Key.Right, { count: times });
	}

	return {
		getMovieTitleId,
		getTVShowTitleId,
		playMovieTitle,
		playTVShowTitle,
		selectFocusedTitleTVShow,
		selectFocusedTitleMovie,
		navigateDown,
		navigateRight,
		getMovieTitleIdAndCategory,
		selectMovieTitleWithNoTrailer,
		selectMovieTitleWithTrailer,
		navigateToLiveNewsAndSelect,
		navigateToLiveNews,
		playEspanolTitle,
		selectFocusedTitleEspanol,
		selectFocusedTvShowTitleEspanol,
		exitKidsMode,
		pageDidLoad,
		selectFocusedTitleKidsMode,
		getPopupMessage,
		playKidsTitle,
		getSerialTag,
		highlightTitleWithVideoPreview,
		waitForPlayBackToStartForMovie,
		selectFocusedTitleMovieWithSubtitles,
		navigateToContinueWatchingAndSelectIt,
		getPopupMessageKids,
		navigateRightAndGetTitleIdsOnSameRow,
		navigateToFirstColumn,
		getTitleIdHomeScreenHorizontal,
		getTitleIdMoviesScreen,
		getTitleIdTVShowsScreen,
		getTitleIdHomeScreenVertical,
		getHomeCategoryName,
		getTitleIdEspanolScreenHorizontal,
		...SideNav(),
	};
};

export default HomePage;
