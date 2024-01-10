import { testUtils } from '../../test-utils';
import { expect } from 'chai';
import { ecp, utils, odc } from 'roku-test-automation';
import { moveToCol, moveToGrid } from '../utils/helpers';
import TitleDetailsPage from './titleDetailsPage';

const SearchPage = () => {
	const ui = {
		keyGrid: {
			row: 1,
			col: 1,
			key: null,
			isFocused: true,
		},
		titleGrid: {
			row: 1,
			col: 1,
			content: null,
			query: null,
			isFocused: false,
		},
	};
	const elements = {
		searchGrid: async () => await testUtils.getNodeForElement('searchGrid'),
		kidsLogo: async () =>
			await testUtils.getNodeForElement('kidsLogoHomeScreen'),
		foundSearch: async () =>
			await testUtils.getNodeForElement('foundTitlesSearch'),
		searchResultsText: async () =>
			await testUtils.getNodeForElement('searchResultsText'),
	};

	async function pageDidLoad() {
		await testUtils.retryWithTimeOut(async () => {
			const grid = await elements.searchGrid();
			expect(grid.visible).to.equal(true);
		});
	}

	async function enterSearch(text) {
		await ecp.sendText(text);
		await testUtils.retryWithTimeOut(async () => {
			const foundSearch = await elements.foundSearch();
			expect(foundSearch.visible).to.equal(true);
		});
		await utils.sleep(5000);
		await testUtils.retryWithTimeOut(async () => {
			const searchResultsText = await elements.foundSearch();
			const foundText = searchResultsText.text.split('"')[1];
			expect(foundText).to.equal(text);
		});
	}

	const updateGridState = (grid, row, col) => {
		grid.row = row;
		grid.col = col;
	};

	async function moveToTitleGrid() {
		const { keyGrid, titleGrid } = ui;
		if (keyGrid.isFocused) {
			const isSymbolRow = keyGrid.row === 7;
			const destCol = isSymbolRow ? 4 : 7;
			await moveToCol(keyGrid.col - destCol);
			updateGridState(keyGrid, keyGrid.row, isSymbolRow ? 3 : 6);
			keyGrid.isFocused = false;
			titleGrid.isFocused = true;
		}
	}

	async function goToTitleInPosition(opts) {
		const { row, col } = opts;
		await moveToTitleGrid();
		await moveToGrid({ grid: ui.titleGrid, destCol: row, destRow: col });
		ui.titleGrid.row = row;
		ui.titleGrid.col = col;
	}

	async function checkIfKidsLogoPresent() {
		await testUtils.retryWithTimeOut(async () => {
			const kidsLogo = await elements.kidsLogo();
			expect(kidsLogo.visible).to.equal(true);
		});
	}
	async function selectFocusedTitle() {
		await testUtils.retryWithTimeOut(async () => {
			const searchResultsDesc = await elements.searchResultsText();
			expect(searchResultsDesc.visible).to.equal(true);
		});
		const searchResultsText = await elements.searchResultsText();
		const text = searchResultsText.text;
		await ecp.sendKeypress(ecp.Key.Ok);
		const details = TitleDetailsPage(text);
		await details.pageDidLoad();
		return details;
	}

	return {
		pageDidLoad,
		checkIfKidsLogoPresent,
		enterSearch,
		moveToTitleGrid,
		goToTitleInPosition,
		selectFocusedTitle,
	};
};

export default SearchPage;
