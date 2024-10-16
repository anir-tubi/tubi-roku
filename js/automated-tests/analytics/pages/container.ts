import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { CONTAINER_PAGE_NODES } from '../utils/constants';
import TitleDetailsPage from './titleDetailsPage';
const Container = () => {
	const elements = {
		grid: async () =>
			await testUtils.getNodeForElement(CONTAINER_PAGE_NODES.GRID),
		channelsVideoGrid: async () =>
			await testUtils.getNodeForElement('channelsVideoGrid'),
		titleDescription: async () =>
			await testUtils.getNodeForElement(CONTAINER_PAGE_NODES.TITLE_DESCRIPTION),
		titleName: async () =>
			await testUtils.getNodeForElement(
				CONTAINER_PAGE_NODES.TITLE_NAME_IN_CONTAINER
			),
		categoryNameInCategoryDetailsPage: async () =>
			await testUtils.getNodeForElement('categoryNameInCategoryDetailsPage'),
		firstChannelName: async () =>
			await testUtils.getNodeForElement('firstChannelNameInChannelPage'),
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const grid = await elements.channelsVideoGrid();
			expect(grid.visible).to.equal(true);
		});
	}

	async function selectFocusedTitle() {
		let titleName;
		await ecp.sendKeypress(ecp.Key.Ok);
		await utils.sleep(2500);
		await ecp.sendKeypress(ecp.Key.Ok);
		await testUtils.retryWithTimeOut(async () => {
			titleName = await elements.titleName();
			expect(titleName.visible).to.equal(true);
		});
		const titleDetailsPage = TitleDetailsPage({ title: titleName.text });
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	async function getCategoryName() {
		const categoryNameInCategoryDetailsPage =
			await elements.categoryNameInCategoryDetailsPage();
		return categoryNameInCategoryDetailsPage.text;
	}

	async function getNameOfFirstChannel() {
		let text = '';
		await testUtils.retryWithTimeOut(async () => {
			const channelPoster = await elements.firstChannelName();
			expect(channelPoster.visible).to.equal(true);
			text = channelPoster.text;
		});
		return text;
	}

	return {
		pageDidLoad,
		selectFocusedTitle,
		getCategoryName,
		getNameOfFirstChannel
	};
};

export default Container;
