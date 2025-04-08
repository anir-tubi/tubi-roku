import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp,utils } from 'roku-test-automation';
import Container from './container';


const Categories = () => {
	const elements = {
		channelCategoryGrid: async () =>
			await testUtils.getNodeForElement('channelCategoryGrid'),
		channelSideNavigation: async () =>
			await testUtils.getNodeForElement('channelSideNav'),
		titleName: async () =>
			await testUtils.getNodeForElement('titleNameInCategories'),
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
		await testUtils.jumpToRowWithTitle('channelSideNav', categoryName);
		await utils.sleep(1500);
		await ecp.sendKeypress(ecp.Key.Ok);
		const container = Container();
		await container.pageDidLoad();
		return container;
	}

	async function selectChannelByName(channelName) {
		await ecp.sendKeypress(ecp.Key.Right);
		await utils.sleep(1500);
		await testUtils.jumpToRowWithTitle('channelsListScreenGrid', channelName);
		await ecp.sendKeypress(ecp.Key.Ok);
		const container = Container();
		await container.pageDidLoad();
		return container;
	}

	async function getNameOfHighlighteditle() {
		let text = '';
		await testUtils.retryWithTimeOut(async () => {
			const channelPoster = await elements.titleName();
			expect(channelPoster.visible).to.equal(true);
			text = channelPoster.text;
		});
		return text;
	}

	return {
		selectCategoryByName,
		selectFocusedCategory,
		pageDidLoad,
		getNameOfHighlighteditle,
		selectChannelByName,
	};
};

export default Categories;
