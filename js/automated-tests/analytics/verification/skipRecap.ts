import {
	Events,
	PlaybackSource,
	milisecondsToMinutes,
} from '../utils/constants';
import {
	getMatchedEventsFromLastEvent,
	getSeekEvent,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC215937(episodeId) {
	const seekEvent = await getSeekEvent();
	expect(seekEvent[0].event.seek.video_id).equal(
		parseInt(episodeId),
		`event should contain .event.seek.video_id===${episodeId}, Event \n ${JSON.stringify(
			seekEvent
		)} \n`
	);
	expect(seekEvent[0].event.seek.video_player).equal(
		'DEFAULT',
		`event should contain .event.seek.video_player==='DEFAULT', Event \n ${JSON.stringify(
			seekEvent
		)} \n`
	);
	expect(seekEvent[0].event.seek.from_position).to.match(
		/\d/,
		`event should contain event.seek.from_position===, Event: \n
${JSON.stringify(seekEvent)} \n`
	);
	expect(seekEvent[0].event.seek.to_position).to.match(
		/\d/,
		`event should contain event.seek.to_position===, Event: \n
${JSON.stringify(seekEvent)} \n`
	);
}
