import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import Container from './container';

const AgeGatePage = () => {
	const elements = {
		confirmYourAgeText: async () =>
			await testUtils.getNodeForElement('confirmYourAgeText'),
	};
	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const confirmYourAgeText = await elements.confirmYourAgeText();
			expect(confirmYourAgeText.visible).to.equal(true);
			expect(confirmYourAgeText.text).to.equal('Confirm your age*');
		});
	}
	// async function selectKey(k) {
	// 	const key = k === ' ' ? 'space' : k;
	// 	const { row, col } = keyboard[key];
	// 	// await adjustColumnFor7thRow(ui.keyGrid, { row, col });
	// 	await moveToGrid({ grid: ui.keyGrid, destCol: col, destRow: row });
	// 	ui.keyGrid.row = row;
	// 	ui.keyGrid.col = col;
	// 	await remote.pressOK();
	// 	ui.keyGrid.key = key;
	// }

	return {
		pageDidLoad,
	};
};

export default AgeGatePage;
