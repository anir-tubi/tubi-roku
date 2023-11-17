import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import PlayBack from './playback';
import { TITLE_DETAILS_PAGE_NODES } from '../utils/constants';
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
	};
};

export default TitleDetailsPage;
