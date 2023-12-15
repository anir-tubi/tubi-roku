import { ecp } from 'roku-test-automation';

export async function moveToRow(row) {
	let moves = row;
	if (moves > 0) {
		while (moves > 0) {
			await ecp.sendKeypress(ecp.Key.Up);
			moves--;
		}
	} else if (moves < 0) {
		while (moves < 0) {
			await ecp.sendKeypress(ecp.Key.Down);
			moves++;
		}
	}
}
