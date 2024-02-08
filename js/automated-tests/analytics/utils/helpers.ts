import { ecp, utils } from 'roku-test-automation';

export async function moveToRow(row) {
	let moves = row;
	if (moves > 0) {
		while (moves > 0) {
			await utils.sleep(400);
			await ecp.sendKeypress(ecp.Key.Up);
			moves--;
		}
	} else if (moves < 0) {
		while (moves < 0) {
			await utils.sleep(400);
			await ecp.sendKeypress(ecp.Key.Down);
			moves++;
		}
	}
}

export async function moveToCol(col) {
	let moves = col;
	if (moves > 0) {
		while (moves > 0) {
			await ecp.sendKeypress(ecp.Key.Left);
			moves--;
		}
	} else if (moves < 0) {
		while (moves < 0) {
			await ecp.sendKeypress(ecp.Key.Right);
			moves++;
		}
	}
}

export async function moveToGrid({ grid, destRow, destCol }) {
	const rowMoves = grid.row - destRow;
	const colMoves = grid.col - destCol;
	rowMoves && (await moveToRow(rowMoves));
	colMoves && (await moveToCol(colMoves));
}
