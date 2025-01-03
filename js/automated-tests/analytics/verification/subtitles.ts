import { Events, DialogTypes, DialogAction } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';
import { utils } from 'roku-test-automation';

export async function verifyC21386andC21388andC21379(episodeId) {
	let subtitlesEvent;
	let i = 1;
	while (subtitlesEvent === undefined && i < 20) {
		const pulledEvents = await getMatchedEventsFromLastEvent(
			Events.subtitles_toggle,
			i + 15
		);
		subtitlesEvent = pulledEvents.find((event) => event.subtitles_toggle);
		i++;
	}
	expect(subtitlesEvent.subtitles_toggle.video_id).equal(parseInt(episodeId));
	expect(subtitlesEvent.subtitles_toggle.language_code).equal('EN');
	expect(subtitlesEvent.subtitles_toggle.toggle_state).to.match(
		/ON/,
		`event should event.subtitles_toggle.toggle_state===ON or OFF, Event: \n ${JSON.stringify(
			subtitlesEvent
		)} \n`
	);
}

export async function verifyC66349(titleId) {
	let subtitlesEvent;
	let i = 1;
	while (subtitlesEvent === undefined && i < 20) {
		const pulledEvents = await getMatchedEventsFromLastEvent(
			Events.subtitles_toggle,
			i + 15
		);
		subtitlesEvent = pulledEvents.find((event) => event.subtitles_toggle);
		i++;
	}
	expect(subtitlesEvent.subtitles_toggle.video_id).equal(parseInt(titleId));
	expect(subtitlesEvent.subtitles_toggle.toggle_state).to.match(
		/ON|OFF|/,
		`event should event.subtitles_toggle.toggle_state===ON or OFF, Event: \n ${JSON.stringify(
			subtitlesEvent
		)} \n`
	);
}

export async function verifyC543688(id) {
	await utils.sleep(2000);
	const events = await getMatchedEventsFromLastEvent(
		Events.subtitles_toggle,
		15
	);
	// no loop here, need to check that 2 events
	expect(events[1].subtitles_toggle.video_id).equal(parseInt(id));
	expect(events[1].subtitles_toggle.toggle_state).to.match(
		/OFF/,
		`event should event.subtitles_toggle.toggle_state===ON or OFF, Event: \n ${JSON.stringify(
			events[0]
		)} \n`
	);
	expect(events[0].subtitles_toggle.video_id).equal(parseInt(id));
	expect(events[0].subtitles_toggle.language_code).equal('EN');
	expect(events[0].subtitles_toggle.toggle_state).to.match(
		/ON/,
		`event should event.subtitles_toggle.toggle_state===ON or OFF, Event: \n ${JSON.stringify(
			events[0]
		)} \n`
	);
}

export async function verifyC434294() {
	let dialogEvent;
	let i = 1;
	while (dialogEvent === undefined && i < 20) {
		const pulledEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			i + 15
		);
		dialogEvent = pulledEvents.find(
			(event) =>
				event.dialog.dialog_type &&
				event.dialog.dialog_type === DialogTypes.subtitleAudio
		);
		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(DialogAction.show);
	expect(dialogEvent.dialog.dialog_type).equal(DialogTypes.subtitleAudio);
}
