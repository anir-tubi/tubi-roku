import { Events, EventsValues } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC21253() {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.home_page &&
				event.page_load.home_page.content_mode &&
				event.page_load.home_page.content_mode == EventsValues.conentModeMovie
		);
		i++;
	}
	expect(pageLoad.page_load.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`pageLoadEventHome.page_load.home_page.content_mode==='CONTENT_MODE_UNKNOWN', Event: \n
${JSON.stringify(pageLoad)} \n`
	);
}
export async function verifyC21254(id) {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.video_page &&
				event.page_load.video_page.video_id &&
				event.page_load.video_page.video_id == parseInt(id)
		);
		i++;
	}
	expect(pageLoad.page_load.status).equal('SUCCESS');
	expect(pageLoad.page_load.video_page.video_id).equal(parseInt(id));
}

export async function verifyC21254PlayerLoad(id) {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.video_player_page &&
				event.page_load.video_player_page.video_id &&
				event.page_load.video_player_page.video_id == parseInt(id)
		);
		i++;
	}
	expect(pageLoad.page_load.video_player_page.video_id).equal(parseInt(id));
}

export async function verifyC76715PageLoad() {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) => event.page_load && event.page_load.channel_list_page
		);
		i++;
	}
	expect(pageLoad.page_load.channel_list_page).to.be.empty;
	expect(pageLoad.page_load.status).equal(
		'SUCCESS',
		`event should contains page_load.status=SUCCESS, Event: \n
${JSON.stringify(pageLoad)}\n`
	);
	expect(pageLoad.page_load.load_time).to.match(
		/\d/,
		`Each event has to contain load_time event: \n ${pageLoad}`
	);
}

export async function verifyC543703() {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) => event.page_load && event.page_load.category_list_page
		);
		i++;
	}
	expect(pageLoad.page_load.category_list_page).to.be.empty;
	expect(pageLoad.page_load.status).equal(
		'SUCCESS',
		`event should contains page_load.status=SUCCESS, Event: \n
${JSON.stringify(pageLoad)}\n`
	);
	expect(pageLoad.page_load.load_time).to.match(
		/\d/,
		`Each event has to contain load_time event: \n ${pageLoad}`
	);
}

export async function verifyC76715(slugCategory) {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.category_page &&
				event.page_load.category_page.category_slug
		);
		i++;
	}
	expect(pageLoad.page_load.status).equal(
		'SUCCESS',
		`event should contains page_load.status=SUCCESS, Event: \n
${JSON.stringify(pageLoad)}\n`
	);
	expect(pageLoad.page_load.category_page.category_slug).equal(
		slugCategory,
		`event should contains page_load.category_page.category_slug==${slugCategory}, Event: \n
${JSON.stringify(pageLoad)}\n`
	);
}

export async function verifyC543704(slugCategory) {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.category_page &&
				event.page_load.category_page.category_slug
		);
		i++;
	}
	expect(pageLoad.page_load.status).equal(
		'SUCCESS',
		`event should contains page_load.status=SUCCESS, Event: \n
${JSON.stringify(pageLoad)}\n`
	);
	expect(pageLoad.page_load.category_page.category_slug).equal(
		slugCategory,
		`event should contains page_load.category_page.category_slug==${slugCategory}, Event: \n
${JSON.stringify(pageLoad)}\n`
	);
}

export async function verifyC3856() {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoad = pulletEvents.find(
			(event) => event.page_load && event.page_load.search_page
		);
		i++;
	}
	expect(pageLoad.page_load.search_page).to.be.empty;
	expect(pageLoad.page_load.status).equal(
		'SUCCESS',
		`pageLoad.page_load.status=SUCCESS, Event: \n ${JSON.stringify(pageLoad)}
      \n`
	);
	expect(pageLoad.page_load.load_time).equal(
		0,
		`pageLoad.page_load.load_time=0, Event: \n ${JSON.stringify(pageLoad)}
      \n`
	);
}
