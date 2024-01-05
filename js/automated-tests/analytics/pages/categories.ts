import { testUtils } from '../../test-utils';
import { expect } from 'chai';

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

	return {
		pageDidLoad,
	};
};

export default Categories;
