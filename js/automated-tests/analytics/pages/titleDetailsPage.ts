import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import {
	TITLE_DETAILS_PAGE_NODES,
	TV_SHOW_DETAILS_PAGE_BUTONS,
} from '../utils/constants';
const TitleDetailsPage = (titleDetails) => {
	const elements = {
		detailsScreenTitle: async () =>
			await testUtils.getNodeForElement(
				TITLE_DETAILS_PAGE_NODES.DETAILS_SCREEN_TITLE
			),
		backGroundPoster: async () =>
			await testUtils.getNodeForElement(
				TITLE_DETAILS_PAGE_NODES.BACKGROUND_POSTER
			),
		detailsScreen: async () =>
			await testUtils.getNodeForElement(
				TITLE_DETAILS_PAGE_NODES.DETAILS_SCREEN
			),
		caption: async () =>
			await testUtils.getNodeForElement(TITLE_DETAILS_PAGE_NODES.CAPTIONS),
		titleDetailsRatingsLabel: async () =>
			await testUtils.getNodeForElement(
				TITLE_DETAILS_PAGE_NODES.TITLE_DETIALS_RATINGS_LABEL
			),
		youMightAlsoLikeFistPoster: async () =>
			await testUtils.getNodeForElement(
				TITLE_DETAILS_PAGE_NODES.YOU_MIGHT_ALSO_LIKE_FIRST_POSTER
			),
		detailsPageMenu: async () =>
			await testUtils.getNodeForElement(
				TITLE_DETAILS_PAGE_NODES.DETAILS_PAGE_MENU
			),
		raitingLabel: async () =>
			await testUtils.getNodeForElement('raitingLabelInDetailsScreen'),
	};

	async function pageDidLoad() {
		let detailScreenTitle;
		await testUtils.retryWithTimeOut(async () => {
			detailScreenTitle = await elements.detailsScreenTitle();
			expect(detailScreenTitle.text).to.not.be.empty;
		});
		await testUtils.retryWithTimeOut(async () => {
			const titleSeriesBackgroundPoster = await elements.backGroundPoster();
			expect(titleSeriesBackgroundPoster).to.exist;
		});
		await testUtils.retryWithTimeOut(async () => {
			const detailsPageMenu = await elements.detailsPageMenu();
			expect(detailsPageMenu).to.exist;
		});
		expect(detailScreenTitle.text).to.equal(titleDetails.title);
		detailScreenTitle = await elements.detailsScreen();
		if (detailScreenTitle != undefined) {
			titleDetails = detailScreenTitle;
		}
	}

	function getEpisodeId() {
		if (titleDetails.isSeries != undefined && titleDetails.isSeries == true) {
			const [episodeId, description] = titleDetails.description.split(' ');
			return parseInt(episodeId);
		}
	}

	async function getRatingText() {
		let ratingTogle;
		await testUtils.retryWithTimeOut(async () => {
			ratingTogle = await elements.raitingLabel();
			expect(ratingTogle.text).to.not.be.empty;
		});
		return ratingTogle.text;
	}

	function getTitleId() {
		return parseInt(titleDetails.content.id);
	}

	async function verifySubtitlesToglePresent() {
		const caption = await elements.caption();
		expect(caption.visible).to.equal(true);
	}

	async function verifyRatingToglePresent() {
		const titleDetailsRatingsLabel = await elements.titleDetailsRatingsLabel();
		expect(titleDetailsRatingsLabel.visible).to.equal(true);
	}

	async function moveToRow(elementText, timeout = 10000) {
		await testUtils.jumpToRowWithTitle('detailsPageMenu', elementText, timeout);
	}

	async function highlightEpisodeList() {
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.EPISODE_LIST);
	}

	async function highlightAddToMyList(timeOut = 0) {
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.ADD_TO_MY_LIST, timeOut);
	}

	async function highlightWatchTrailer(timeOut = 0) {
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.WATCH_TRAILER, timeOut);
	}

	async function highlightPlay() {
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.PLAY, 20000);
	}

	async function selectTitleFromYouMayAlsoLike(position) {
		await testUtils.retryWithTimeOut(async () => {
			const youMightAlsoLikeFistPoster =
				await elements.youMightAlsoLikeFistPoster();
			expect(youMightAlsoLikeFistPoster.visible).to.equal(true);
		});
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.ADD_TO_MY_LIST);
		await ecp.sendKeypress(ecp.Key.Down, { wait: 200 });
		await ecp.sendKeypress(ecp.Key.Down, { wait: 200 });
		await ecp.sendKeypress(ecp.Key.Right, { count: position, wait: 200 });
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function selectPlay() {
		await highlightPlay();
		await ecp.sendKeypress(ecp.Key.Ok);
		const playback = PlayBack({ content: titleDetails });
		await playback.pageDidLoad();
		return playback;
	}

	async function selectEpisodeList() {
		await highlightEpisodeList();
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function highlightGoBackToChannel() {
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.Go_TO, 700);
	}

	async function highlightLikeOrDislike() {
		await moveToRow(TV_SHOW_DETAILS_PAGE_BUTONS.LIKE_OR_DISLIKE, 700);
	}

	async function selectLikeOrDislike() {
		await highlightLikeOrDislike();
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function selectGoToBackToChannel() {
		await highlightGoBackToChannel();
		await ecp.sendKeypress(ecp.Key.Ok);
	}

	async function clickOnPlay() {
		await ecp.sendKeypress(ecp.Key.Play);
		//TODO check how to fetch content from TiteDetailsPage
		const playback = PlayBack({ content: titleDetails });
		await playback.pageDidLoad();
		return playback;
	}

	return {
		pageDidLoad,
		clickOnPlay,
		getEpisodeId,
		highlightEpisodeList,
		selectEpisodeList,
		highlightAddToMyList,
		getTitleId,
		selectGoToBackToChannel,
		selectLikeOrDislike,
		selectPlay,
		verifySubtitlesToglePresent,
		verifyRatingToglePresent,
		selectTitleFromYouMayAlsoLike,
		highlightLikeOrDislike,
		highlightWatchTrailer,
		getRatingText,
	};
};

export default TitleDetailsPage;
