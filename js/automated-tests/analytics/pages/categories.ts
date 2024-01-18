import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp } from 'roku-test-automation';
import Container from './container';

const Categories = () => {
	const elements = {
		channelCategoryGrid: async () =>
			await testUtils.getNodeForElement('channelCategoryGrid'),
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const channelPoster = await elements.channelCategoryGrid();
			expect(channelPoster.visible).to.equal(true);
		});
	}

	async function selectFocusedCategory() {
		await ecp.sendKeypress(ecp.Key.Ok);
		const container = Container();
		await container.pageDidLoad();
		return container;
	}

	async function selectCategoryByName(categoryName) {
		await testUtils.jumpToRowWithTitle('channelCategoryGrid', categoryName);
		await ecp.sendKeypress(ecp.Key.Ok);
		const container = Container();
		await container.pageDidLoad();
		return container;
	}

	return {
		selectCategoryByName,
		selectFocusedCategory,
		pageDidLoad,
	};
};

export default Categories;
