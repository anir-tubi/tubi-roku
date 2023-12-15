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

export async function verifyC66349andC543679andC543680(videoId) {
	const playProgressEvent = await getMatchedEventsFromLastEvent(
		Events.play_progress,
		5
	);
	playProgressEvent.forEach((event) => {
		expect(event.play_progress.playback_source).equal(
			PlaybackSource.UNKNOWN_PLAYBACK_SOURCE,
			`each event should contain event.play_progress.from_autoplay_automatic=false \n Event:
            ${event}
            \n`
		);
	});
	playProgressEvent.forEach((event) => {
		expect(event.play_progress.video_id).equal(
			videoId,
			`each event should contain event.play_progress.videoId=${videoId} \n Event:
	        ${JSON.stringify(event)}
	        \n`
		);
	});
	for (let i = playProgressEvent.length - 1; i > 1; i--) {
		const grater =
			playProgressEvent[i - 1].play_progress.position -
			playProgressEvent[i].play_progress.position;
		expect(grater).greaterThan(9999);
	}
}

export async function verifyC66356() {
	const events = await getSeekEvent();
	expect(events[0].event.seek.video_player).equal(
		'DEFAULT',
		`event should contain .event.seek.video_player, Event: \n ${JSON.stringify(
			events[0]
		)}`
	);
}

export async function verifyC66359() {
	const pulledEvents = await getMatchedEventsFromLastEvent(
		Events.play_progress,
		15
	);
	expect(pulledEvents[0].play_progress.video_id).not.equal(
		pulledEvents[1].play_progress.video_id,
		`video_id shouldn't be same for play progress for both titles, Event: \n ${JSON.stringify(
			pulledEvents
		)}`
	);
}

export async function verifyC424695() {
	const playProgressEventFirst = await getMatchedEventsFromLastEvent(
		Events.play_progress,
		4
	);
	expect(parseInt(playProgressEventFirst.length)).equal(
		1,
		`Only one event playProgress should be present: \n ${JSON.stringify(
			playProgressEventFirst
		)}`
	);
}

export async function verifyC66349() {
	let firstPlayProgressEvent;
	let i = 1;
	while (firstPlayProgressEvent === undefined && i < 20) {
		const pulledEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			i + 15
		);
		firstPlayProgressEvent = pulledEvents.find(
			(event) => parseInt(event.play_progress.view_time) >= 10093
		);
		i++;
	}
	let secondPlayProgressEvent;
	let j = 1;
	while (secondPlayProgressEvent === undefined && j < 20) {
		const pulledEvents = await getMatchedEventsFromLastEvent(
			Events.play_progress,
			j + 15
		);
		secondPlayProgressEvent = pulledEvents.find(
			(event) => parseInt(event.play_progress.view_time) <= 10126
		);
		j++;
	}
	expect(
		parseInt(firstPlayProgressEvent.play_progress.view_time)
	).greaterThanOrEqual(
		10093,
		`event should contain firstPlayProgress.play_progress.view_time, Event: \n ${JSON.stringify(
			firstPlayProgressEvent
		)}`
	);
	expect(
		parseInt(secondPlayProgressEvent.play_progress.view_time)
	).lessThanOrEqual(
		10126,
		`event should contain secondPlayProgress.play_progress.view_time, Event: \n ${JSON.stringify(
			secondPlayProgressEvent
		)}`
	);
}

export async function verifyC543682andC543683(timeFromPlayback, titleId) {
	const events = await getSeekEvent();
	const timeFromEvent = await milisecondsToMinutes(
		events[0].event.seek.to_position
	);
	expect(timeFromPlayback).equal(
		timeFromEvent,
		`Time from playback in minutes: ${timeFromPlayback} should be same as time from event after seek ${timeFromEvent}`
	);
	expect(events[0].event.seek.video_id).equal(
		parseInt(titleId),
		`event should contain .event.seek.video_id===${titleId}, Event \n ${JSON.stringify(
			events[0]
		)} \n`
	);
}

export async function verifyC543684() {
	const playProgressEvent = await getMatchedEventsFromLastEvent(
		Events.play_progress,
		3
	);
	expect(playProgressEvent[0].play_progress.playback_source).equal(
		PlaybackSource.AUTOPLAY_AUTOMATIC,
		`event should contain playProgressEvent[0].play_progress.playback_sourcetrue=== PlaybackSource.AUTOPLAY_AUTOMATIC Event: \n ${JSON.stringify(
			playProgressEvent[0]
		)}`
	);
}

export async function verifyC543681(videoId) {
	const playProgressEvent = await getMatchedEventsFromLastEvent(
		Events.play_progress,
		5
	);
	playProgressEvent.forEach((event) => {
		expect(event.play_progress.playback_source).equal(
			PlaybackSource.UNKNOWN_PLAYBACK_SOURCE,
			`each event should contain event.play_progress.from_autoplay_automatic=false \n Event:
            ${event}
            \n`
		);
	});
	playProgressEvent.forEach((event) => {
		expect(event.play_progress.video_id).equal(
			videoId,
			`each event should contain event.play_progress.videoId=${videoId} \n Event:
					${JSON.stringify(event)}
					\n`
		);
	});
}
