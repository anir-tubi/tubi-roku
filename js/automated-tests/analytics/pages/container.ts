import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { CONTAINER_PAGE_NODES } from '../utils/constants';
import TitleDetailsPage from './titleDetailsPage';
import { title } from 'process';
const Container = () => {
	const elements = {
		grid: async () =>
			await testUtils.getNodeForElement(CONTAINER_PAGE_NODES.GRID),
	categoriesScreenContentGrid: async () =>
		await testUtils.getNodeForElement('categoriesScreenContentGrid'),
		titleDescription: async () =>
			await testUtils.getNodeForElement(CONTAINER_PAGE_NODES.TITLE_DESCRIPTION),
		titleName: async () =>
			await testUtils.getNodeForElement(
				CONTAINER_PAGE_NODES.TITLE_NAME_IN_CONTAINER
			),
		channelDescriptionCategoryDetailsPage: async () =>
			await testUtils.getNodeForElement('channelDescription'),
		titleDetailsDescriptionContainer: async () =>
			await testUtils.getNodeForElement('titleDetailsDescriptionContainer'),
		categoryNameInCategoryDetailsPage: async () =>
			await testUtils.getNodeForElement('categoryNameInCategoryDetailsPage'),
		firstChannelName: async () =>
			await testUtils.getNodeForElement('firstChannelNameInChannelPage'),
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const grid = await elements.categoriesScreenContentGrid();
			expect(grid.visible).to.equal(true);
		});
	}

	async function selectFocusedChannel() {
		await testUtils.retryWithTimeOut(async () => {
			const titleDescription = await elements.channelDescriptionCategoryDetailsPage();
			expect(titleDescription.visible).to.equal(true);
		});
		const titleName = await elements.titleName();
		await ecp.sendKeypress(ecp.Key.Ok);
		const titleDetailsPage = TitleDetailsPage({ title: titleName.text });
		await titleDetailsPage.pageDidLoad(false);
		return titleDetailsPage;
	}

	async function selectFocusedTitle() {
		await testUtils.retryWithTimeOut(async () => {
			const titleDescription = await elements.titleDetailsDescriptionContainer();
			expect(titleDescription.visible).to.equal(true);
		});
		const titleName = await elements.titleName();
		await ecp.sendKeypress(ecp.Key.Ok);
		const titleDetailsPage = TitleDetailsPage({ title: titleName.text });
		await titleDetailsPage.pageDidLoad(false);
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
		selectFocusedChannel,
		getCategoryName,
		getNameOfFirstChannel,
		selectFocusedTitle,
	};
};

export default Container;
