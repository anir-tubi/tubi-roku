import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import TitleDetailsPage from './titleDetailsPage';
import { NODES } from '../utils/constants';
const HomePage = ({ isMovies, isTvShows } = {}) => {
	const elements = {
		movieScreenRowList: async () =>
			await testUtils.getNodeForElement(NODES.MOVIE_SCREEN_ROW_LIST),
		tvScreenRowList: async () =>
			await testUtils.getNodeForElement(NODES.TV_SHOW_SCREEN_ROW_LIST),
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

	async function playTitle() {
		await ecp.sendKeypress(ecp.Key.Play);
		const content = await fetchContent();
		const playback = PlayBack({ content: content });
		await playback.pageDidLoad();
		return playback;
	}

	async function playMovieTitle() {
		const movieScreenRowList = await elements.movieScreenRowList();
		expect(movieScreenRowList.visible).to.equal(true);
		return await playTitle();
	}

	async function playTVShowTitle() {
		const tvShowScreenRowList = await elements.tvScreenRowList();
		expect(tvShowScreenRowList.visible).to.equal(true);
		return await playTitle();
	}

	return {
		getMovieTitleId,
		getTVShowTitleId,
		playMovieTitle,
		playTVShowTitle,
		selectFocusedTitleTVShow,
		selectFocusedTitleMovie,
	};
};

export default HomePage;
