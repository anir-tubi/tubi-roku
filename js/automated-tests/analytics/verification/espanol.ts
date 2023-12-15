import { Events, EventsValues, DialogAction } from '../utils/constants';
import {
	getMatchedEventsFromLastEvent,
	getMatchedFullEventsFromLastEvent,
	fullAnalyticEventOnSteps,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC116492() {
	let playProgress;
	let i = 1;
	while (playProgress === undefined && i < 10) {
		const pulletEvents = await getMatchedFullEventsFromLastEvent(
			Events.play_progress,
			30 + i
		);
		playProgress = pulletEvents.find((event) => event.event.play_progress);

		i++;
	}
	expect(playProgress.app.app_mode).equal(
		'LATINO_MODE',
		`autoplayevent.app.app_mode==='LATINO_MODE', Event: \n
  ${JSON.stringify(playProgress)} \n`
	);
}

export async function verifyC116525() {
	const playProgressEvent = await getMatchedFullEventsFromLastEvent(
		Events.play_progress,
		3
	);
	expect(playProgressEvent[0].app.app_mode).equal(
		'LATINO_MODE',
		`autoplayevent.app.app_mode==='LATINO_MODE', Event: \n
	${JSON.stringify(playProgressEvent[0])} \n`
	);
	expect(playProgressEvent[0].event.play_progress.video_player).equal(
		'DEFAULT',
		`eventOne.event.play_progress.video_player==='DEFAULT', Event: \n
	${JSON.stringify(playProgressEvent[0])} \n`
	);
}

export async function verifyC115421PageLoad() {
	let eventPageLoad;
	let i = 1;
	while (eventPageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			30 + i
		);
		eventPageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.home_page &&
				event.page_load.home_page.content_mode === EventsValues.conentModeLatino
		);

		i++;
	}
	expect(eventPageLoad.page_load.home_page.content_mode).equal(
		EventsValues.conentModeLatino,
		`eventPageLoad.page_load.home_page.content_mode===EventsValues.conentModeLatino, Event: \n
      ${JSON.stringify(eventPageLoad)} \n`
	);
}

export async function verifyC115421Autoplay() {
	let autoplayevent;
	let i = 1;
	while (autoplayevent === undefined && i < 10) {
		const pulletEvents = await getMatchedFullEventsFromLastEvent(
			Events.auto_play,
			15
		);

		autoplayevent = pulletEvents.find(
			(evented) =>
				evented.event.auto_play &&
				evented.event.auto_play.auto_play_action &&
				evented.event.auto_play.auto_play_action === DialogAction.show
		);
		i++;
	}
	expect(autoplayevent.event.auto_play.auto_play_action).equal(
		DialogAction.show,
		`autoplayevent.event.auto_play.auto_play_action==='SHOW', Event: \n
  ${JSON.stringify(autoplayevent)} \n`
	);
	expect(autoplayevent.app.app_mode).equal(
		'LATINO_MODE',
		`autoplayevent.app.app_mode==='LATINO_MODE', Event: \n
  ${JSON.stringify(autoplayevent)} \n`
	);
}

export async function verifyC115421() {
	const fullEvents = await fullAnalyticEventOnSteps([12, 13, 14, 15, 20, 23]);
	fullEvents.forEach((event) => {
		expect(event.app.app_mode).equal(
			'LATINO_MODE',
			`fullEventOne.app.app_mode==='LATINO_MODE', Event: \n
      ${JSON.stringify(event)} \n`
		);
	});
}
