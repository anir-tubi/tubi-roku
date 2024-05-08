import { Events, EventsValues } from '../utils/constants';
import {
	getMatchedFullEventsFromLastEvent,
	getMatchedEventsFromLastEvent,
	fullAnalyticEventOnSteps,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC148718() {
	let dialogEvent;
	let i = 1;
	while (dialogEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			40 + i
		);
		dialogEvent = pulletEvents.find(
			(event) =>
				event.dialog.dialog_action &&
				event.dialog.dialog_action === 'SHOW' &&
				event.dialog.dialog_sub_type &&
				event.dialog.dialog_sub_type === 'email-prefill'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'SHOW',
		`dialog.dialog_action===SHOW, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'email-prefill',
		`eventOne.dialog.dialog_sub_type===email-prefill, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'REGISTRATION',
		`eventOne.dialog.dialog_type===REGISTRATION, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`dialogEvent.dialog.home_page.content_mode===EventsValues.conentModeUnknown, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}
