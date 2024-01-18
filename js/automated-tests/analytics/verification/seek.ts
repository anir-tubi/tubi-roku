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

export async function verifyC21365(videoId) {
	const events = await getSeekEvent();
	expect(events[0].event.seek.video_id).equal(
		parseInt(videoId),
		`event should contain .event.seek.video_id===${videoId}, Event \n ${JSON.stringify(
			events[0]
		)} \n`
	);
}

export async function verifyC21370(titleId) {
	const events = await getSeekEvent();
	expect(events[0].event.seek.video_id).equal(
		parseInt(titleId),
		`event should contain event.seek.video_id===${titleId}, Event: \n ${JSON.stringify(
			events
		)} \n`
	);
	expect(events[1].event.seek.video_id).equal(
		parseInt(titleId),
		`event should contain event.seek.video_id===${titleId}, Event: \n ${JSON.stringify(
			events
		)} \n`
	);
}

export async function verifyC21368andC21368() {
	const seekEvents = await getSeekEvent();
	expect(seekEvents.length).equal(
		2,
		`2 seek events should happen, Event: \n ${JSON.stringify(seekEvents)} \n`
	);
}

export async function verifyC21366(
	timeFromPlaybackBeforeSeek,
	timeFromPlaybackAfterSeek
) {
	const events = await getSeekEvent();
	const timeFromEventToPosition = await milisecondsToMinutes(
		events[0].event.seek.to_position
	);
	const timeFromEventFromPosition = await milisecondsToMinutes(
		events[0].event.seek.from_position
	);
	expect(timeFromPlaybackBeforeSeek).equal(
		timeFromEventFromPosition,
		`Time from playback in minutes: ${timeFromPlaybackBeforeSeek} should be same as time from event before seek ${timeFromEventFromPosition}`
	);
	expect(timeFromPlaybackAfterSeek).equal(
		timeFromEventToPosition,
		`Time from playback in minutes: ${timeFromPlaybackAfterSeek} should be same as time from event after seek ${timeFromEventToPosition}`
	);
}
