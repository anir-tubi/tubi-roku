import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import TitleDetailsPage from './titleDetailsPage';
import LiveNews from '../pages/liveNews';
import { NODES } from '../utils/constants';
import SideNav, { tabs } from '../components/sideNav';
const HomePage = ({ isMovies, isTvShows } = {}) => {
	const elements = {
		movieScreenRowList: async () =>
			await testUtils.getNodeForElement(NODES.MOVIE_SCREEN_ROW_LIST),
		tvScreenRowList: async () =>
			await testUtils.getNodeForElement(NODES.TV_SHOW_SCREEN_ROW_LIST),
		espanolRowList: async () =>
			await testUtils.getNodeForElement(NODES.ESPANOL_SCREEN_ROW_LIST),
		movieDescription: async () =>
			await testUtils.getNodeForElement(NODES.TITLE_DESCRIPTION_MOVIE),
		homeScreenPoster: async () =>
			await testUtils.getNodeForElement('homeScreenPoster'),
		homeScreenKidsLogo: async () =>
			await testUtils.getNodeForElement('kidsLogoHomeScreen'),
		channelsDisabledMessage: async () =>
			await testUtils.getNodeForElement('channelsDisabledMessage'),
	};

	// expect(tvScreenRowList.visible).to.equal(true);
	async function getMovieTitleId() {
		const movieScreenRowList = await elements.movieScreenRowList();
		expect(movieScreenRowList.visible).to.equal(true);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		return parseInt(content.id);
	}

	async function pageDidLoad() {
		const homeScreenPoster = await elements.homeScreenPoster();
		expect(homeScreenPoster.visible).to.equal(true);
	}

	async function getMovieTitleIdAndCategory() {
		const movieScreenRowList = await elements.movieScreenRowList();
		expect(movieScreenRowList.visible).to.equal(true);
		const detailScreenTitle = await elements.movieDescription();
		const [categorySlug, contentId] = detailScreenTitle.text.split(' ');
		return { contentId: contentId, categorySlug: categorySlug };
	}

	async function getTVShowTitleId() {
		const tvShowScreenRowList = await elements.tvScreenRowList();
		expect(tvShowScreenRowList.visible).to.equal(true);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.TV_SHOW_SCREEN_ROW_LIST
		);
		return parseInt(content.id);
	}

	async function selectFocusedTitleMovie() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.MOVIE_SCREEN_ROW_LIST
		);
		return await selectFocusedTitle(content);
	}

	async function selectFocusedTitleKidsMode() {
		await testUtils.retryWithTimeOut(async () => {
			const kidsLogo = await elements.homeScreenKidsLogo();
			expect(kidsLogo.visible).to.equal(true);
		});
		await utils.sleep(2000);
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.HOME_SCREEN_ROW_LIST
		);
		return await selectFocusedTitle(content);
	}

	async function getPopupMessage() {
		let channelsDisabledMessage;
		await testUtils.retryWithTimeOut(async () => {
			channelsDisabledMessage = await elements.channelsDisabledMessage();
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

	async function fetchEspanolContent() {
		const content = await testUtils.getCurrentlyFocusedGridItemContent(
			NODES.ESPANOL_SCREEN_ROW_LIST
		);
		return content;
	}

	async function playTitle(espanol = false) {
		await ecp.sendKeypress(ecp.Key.Play);
		let content;
		if (espanol) {
			content = await fetchEspanolContent();
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

	async function playEspanolTitle() {
		const espanolRowList = await elements.espanolRowList();
		expect(espanolRowList.visible).to.equal(true);
		return await playTitle(true);
	}

	async function playTVShowTitle() {
		const tvShowScreenRowList = await elements.tvScreenRowList();
		expect(tvShowScreenRowList.visible).to.equal(true);
		return await playTitle();
	}

	async function navigateDown(times) {
		await ecp.sendKeypress(ecp.Key.Down, { count: times });
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
		...SideNav(),
	};
};

export default HomePage;
