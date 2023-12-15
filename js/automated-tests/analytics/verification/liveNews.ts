import { Events } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC118162() {
	let startLiveVideo;
	let i = 1;
	while (startLiveVideo === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.start_live_video,
			10 + i
		);
		startLiveVideo = pulletEvents.find(
			(event) =>
				event.start_live_video &&
				event.start_live_video.video_player === 'BANNER'
		);
		i++;
	}
	expect(startLiveVideo.start_live_video.has_subtitles).to.match(
		/true|false/,
		`Each event has to contain start_live_video.has_subtitles===true or false Event: \n ${JSON.stringify(
			startLiveVideo
		)}\n `
	);
	expect(startLiveVideo.start_live_video.video_player).equal(
		'BANNER',
		`Each event has to contain start_live_video.video_player===BANNER, Event \n ${JSON.stringify(
			startLiveVideo
		)} \n`
	);
	expect(startLiveVideo.start_live_video.video_resource_type).to.match(
		/VIDEO_RESOURCE_TYPE_HLSV3/,
		`Each event has to contain event.start_live_video.video_resource_type===VIDEO_RESOURCE_TYPE_HLSV3 or false Event: \n ${JSON.stringify(
			startLiveVideo
		)}\n `
	);
	expect(startLiveVideo.start_live_video.video_resource_url).to.match(
		/./,
		`Each event has to contain event.start_live_video.video_resource_url===url or false Event: \n ${JSON.stringify(
			startLiveVideo
		)}\n `
	);
}

export async function verifyC120934() {
	let subtitlesEvent;
	let i = 1;
	while (subtitlesEvent === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.subtitles_toggle,
			40 + i
		);
		subtitlesEvent = pulletEvents.find((event) => event.subtitles_toggle);
		i++;
	}
	expect(subtitlesEvent.subtitles_toggle.toggle_state).to.match(
		/ON|OFF/,
		`Each event has to contain subtitles_toggle.toggle_state===OFF, Event \n ${JSON.stringify(
			subtitlesEvent
		)} \n`
	);
}

export async function verifyCC125523() {
	let fullScreenToggle;
	let i = 1;
	while (fullScreenToggle === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.fullscreen_toggle,
			40 + i
		);
		fullScreenToggle = pulletEvents.find(
			(event) =>
				event.fullscreen_toggle &&
				event.fullscreen_toggle.toggle_state === 'OFF'
		);
		i++;
	}
	expect(fullScreenToggle.fullscreen_toggle.toggle_state).equal(
		'OFF',
		`Each event has to contain fullscreen_toggle.toggle_state===ON, Event \n ${JSON.stringify(
			fullScreenToggle
		)} \n`
	);
	expect(fullScreenToggle.fullscreen_toggle.video_id).to.match(
		/\d/,
		`Each event has to contain fullscreen_toggle.video_id===id or false Event: \n ${JSON.stringify(
			fullScreenToggle
		)}\n `
	);
}

export async function verifyC118175() {
	let fullScreenToggle;
	let i = 1;
	while (fullScreenToggle === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.fullscreen_toggle,
			40 + i
		);
		fullScreenToggle = pulletEvents.find(
			(event) =>
				event.fullscreen_toggle && event.fullscreen_toggle.toggle_state === 'ON'
		);
		i++;
	}
	expect(fullScreenToggle.fullscreen_toggle.toggle_state).equal(
		'ON',
		`Each event has to contain fullscreen_toggle.toggle_state===ON, Event \n ${JSON.stringify(
			fullScreenToggle
		)} \n`
	);
	expect(fullScreenToggle.fullscreen_toggle.video_id).to.match(
		/\d/,
		`Each event has to contain fullscreen_toggle.video_id===id or false Event: \n ${JSON.stringify(
			fullScreenToggle
		)}\n `
	);
}
