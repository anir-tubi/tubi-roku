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
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const grid = await elements.channelsVideoGrid();
			expect(grid.visible).to.equal(true);
		});
	}

	async function selectFocusedTitle() {
		const titleName = await elements.titleName();
		await ecp.sendKeypress(ecp.Key.Ok);
		const titleDetailsPage = TitleDetailsPage({ title: titleName.text });
		await titleDetailsPage.pageDidLoad();
		return titleDetailsPage;
	}

	async function getCategoryName() {
		const categoryNameInCategoryDetailsPage =
			await elements.categoryNameInCategoryDetailsPage();
		return categoryNameInCategoryDetailsPage.text;
	}

	return {
		pageDidLoad,
		selectFocusedTitle,
		getCategoryName,
	};
};

export default Container;
