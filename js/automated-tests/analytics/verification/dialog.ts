import { Events, EventsValues, DialogAction } from '../utils/constants';
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
				event.dialog.dialog_sub_type === 'email-prefill-return'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'SHOW',
		`dialog.dialog_action===SHOW, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'email-prefill-return',
		`eventOne.dialog.dialog_sub_type===email-prefill-return, Event: \n
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

export async function verifyC450500(episodeId) {
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
				event.dialog.dialog_action === DialogAction.dismissDeliberate &&
				event.dialog.dialog_sub_type &&
				event.dialog.dialog_sub_type === 'sign_up_to_save'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		DialogAction.dismissDeliberate,
		`dialog.dialog_action===${DialogAction.dismissDeliberate}, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'sign_up_to_save',
		`eventOne.dialog.dialog_sub_type===sign_up_to_save, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'INFORMATION',
		`eventOne.dialog.dialog_type===INFORMATION, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.video_player_page.video_id).equal(
		episodeId,
		`dialogEvent.dialog.video_player_page.video_id===episodeId, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyC450497(episodeId) {
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
				event.dialog.dialog_action === 'ACCEPT_DELIBERATE' &&
				event.dialog.dialog_sub_type &&
				event.dialog.dialog_sub_type === 'sign_up_to_save'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'ACCEPT_DELIBERATE',
		`dialog.dialog_action===ACCEPT_DELIBERATE, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'sign_up_to_save',
		`eventOne.dialog.dialog_sub_type===sign_up_to_save, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'INFORMATION',
		`eventOne.dialog.dialog_type===INFORMATION, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.video_player_page.video_id).equal(
		episodeId,
		`dialogEvent.dialog.video_player_page.video_id===episodeId, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyC450502(episodeId) {
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
				event.dialog.dialog_action === DialogAction.dismissDeliberate &&
				event.dialog.dialog_sub_type &&
				event.dialog.dialog_sub_type === 'sign_up_to_save'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		DialogAction.dismissDeliberate,
		`dialog.dialog_action===DialogAction.dismissDeliberate, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'sign_up_to_save',
		`eventOne.dialog.dialog_sub_type===sign_up_to_save, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'INFORMATION',
		`eventOne.dialog.dialog_type===INFORMATION, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.video_player_page.video_id).equal(
		episodeId,
		`dialogEvent.dialog.video_player_page.video_id===episodeId, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyC148861(episodeId) {
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
				event.dialog.dialog_sub_type === 'sign_up_to_save'
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'SHOW',
		`dialog.dialog_action===SHOW, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'sign_up_to_save',
		`eventOne.dialog.dialog_sub_type===sign_up_to_save, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'INFORMATION',
		`eventOne.dialog.dialog_type===INFORMATION, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.video_player_page.video_id).equal(
		episodeId,
		`dialogEvent.dialog.video_player_page.video_id===episodeId, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}
