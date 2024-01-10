import { Events } from '../utils/constants';
import {
	getMatchedFullEventsFromLastEvent,
	getMatchedEventsFromLastEvent,
	fullAnalyticEventOnSteps,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC130118() {
	let fullEventOne;
	let i = 1;
	while (fullEventOne === undefined && i < 10) {
		const pulletEvents = await getMatchedFullEventsFromLastEvent(
			Events.navigate_within_page,
			14 + i
		);
		fullEventOne = pulletEvents.find(
			(event) => event.app.app_mode === 'KIDS_MODE'
		);

		i++;
	}
	expect(fullEventOne.app.app_mode).equal(
		'KIDS_MODE', // Change this to KidsMode
		`fullEventOne.app.app_mode==='KIDS_MODE', Event: \n
${JSON.stringify(fullEventOne)} \n`
	);
}

export async function verifyC130120andC130121andC130125andC130127andC130126() {
	const fullEvents = await fullAnalyticEventOnSteps([
		12, 13, 14, 15, 16, 17, 18, 19,
	]);
	fullEvents.forEach((event) => {
		expect(event.app.app_mode).equal(
			'KIDS_MODE',
			`fullEventOne.app.app_mode==='KIDS_MODE', Event: \n
    ${JSON.stringify(event)} \n`
		);
	});
}

export async function verifyKidsRating(ratingText) {
	expect(ratingText).to.not.equal(['NC-17', 'R', 'PG-13', 'TV-14', 'TV-MA']);
}

export async function verifyChannelsDisabledText(text) {
	expect(text).equal('Channels Disabled');
}

export async function verifyC22571() {
	let dialogEvent;
	let i = 1;
	while (dialogEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			30 + i
		);
		dialogEvent = pulletEvents.find(
			(event) =>
				event.dialog.dialog_action &&
				event.dialog.dialog_action === 'ACCEPT_DELIBERATE'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'ACCEPT_DELIBERATE',
		`dialog.dialog_action===ACCEPT_DELIBERATE, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'enter-kids-mode',
		`eventOne.dialog.dialog_sub_type===enter-kids-mode, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'ENTER_KIDS_MODE',
		`eventOne.dialog.dialog_type===ENTER_KIDS_MODE, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyC130122andC130124andC130123() {
	const fullEvents = await fullAnalyticEventOnSteps([12, 13, 14, 15, 16]);
	fullEvents.forEach((event) => {
		expect(event.app.app_mode).equal(
			'KIDS_MODE',
			`fullEventOne.app.app_mode==='KIDS_MODE', Event: \n
			${JSON.stringify(event)} \n`
		);
	});
}
