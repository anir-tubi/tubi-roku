import { Events, EventsValues, STATUS } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyAgeGatePageLoad() {
	let pageLoadEvent;
	let i = 1;
	while (pageLoadEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoadEvent = pulletEvents.find((event) => event.page_load.age_gate_page);
		i++;
	}
	expect(parseInt(pageLoadEvent.page_load.load_time)).equal(
		0,
		`pageLoad.page_load.load_time===0, Event: \n
${JSON.stringify(pageLoadEvent)} \n`
	);
	expect(pageLoadEvent.page_load.age_gate_page).to.be.empty;
	expect(pageLoadEvent.page_load.status).equal(
		'SUCCESS',
		`pageLoadEvent.page_load.status===SUCCESS, Event: \n
${JSON.stringify(pageLoadEvent)} \n`
	);
}

export async function verifyDialogEvent() {
	let dialogEvent;
	let i = 1;
	while (dialogEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			60 + i
		);
		dialogEvent = pulletEvents.find(
			(event) =>
				event.dialog.dialog_type &&
				event.dialog.dialog_type === 'EXIT_KIDS_MODE' &&
				event.dialog.dialog_action === 'SHOW'
		);
		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'SHOW',
		`dialogEvent.dialog.dialog_action===SHOW, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'cannot_exit_kids',
		`dialogEvent.dialog.dialog_sub_type===SHOW, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		'EXIT_KIDS_MODE',
		`dialogEvent.dialog.dialog_type===EXIT_KIDS_MODE, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`dialogEvent.dialog.home_page.content_mode===EventsValues.conentModeUnknown, Event: \n
${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyRequestForInfo() {
	let requestInfoEvent;
	let i = 1;
	while (requestInfoEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.request_for_info,
			60 + i
		);
		requestInfoEvent = pulletEvents.find(
			(event) => event.request_for_info.prompt
		);
		i++;
	}
	expect(requestInfoEvent.request_for_info.prompt).equal(
		'Enter your date of birth',
		`requestInfoEvent.request_for_info.promt===Enter your date of birth, Event: \n
${JSON.stringify(requestInfoEvent)} \n`
	);
	expect(requestInfoEvent.request_for_info.request_for_info_action).equal(
		'BIRTHDAY',
		`requestInfoEvent.request_for_info.request_for_info_action===BIRTHDAY, Event: \n
${JSON.stringify(requestInfoEvent)} \n`
	);
	expect(
		requestInfoEvent.request_for_info.string_selector.string_selector_type
	).equal(
		'BIRTHDAY',
		`requestInfoEvent.request_for_info.request_for_info_action===BIRTHDAY, Event: \n
${JSON.stringify(requestInfoEvent)} \n`
	);
	expect(requestInfoEvent.request_for_info.string_selector.sub_type).equal(
		'age-gate',
		`requestInfoEvent.request_for_info.request_for_info_action===age-gate, Event: \n
${JSON.stringify(requestInfoEvent)} \n`
	);
	expect(requestInfoEvent.request_for_info.string_selector.options[0]).equal(
		'1995-12-31',
		`requestInfoEvent.request_for_info.string_selector.options[0]===1995-12-31, Event: \n
${JSON.stringify(requestInfoEvent)} \n`
	);
	expect(requestInfoEvent.request_for_info.string_selector.selections[0]).equal(
		1,
		`requestInfoEvent.request_for_info.string_selector.selections[0]===1, Event: \n
${JSON.stringify(requestInfoEvent)} \n`
	);
}

export async function verifyC5229(titleId) {
	let pageLoadEvent;
	let i = 1;
	while (pageLoadEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoadEvent = pulletEvents.find((event) => event.page_load.video_page);
		i++;
	}
	expect(parseInt(pageLoadEvent.page_load.load_time)).equal(
		0,
		`pageLoad.page_load.load_time===0, Event: \n
${JSON.stringify(pageLoadEvent)} \n`
	);
	expect(parseInt(pageLoadEvent.page_load.video_page.video_id)).equal(
		parseInt(titleId),
		`pageLoad.page_load.video_page.video_id===id, Event: \n
${JSON.stringify(pageLoadEvent)} \n`
	);
}

export async function verifyC439647PageLoad() {
	let pageLoadEvent;
	let i = 1;
	while (pageLoadEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			60 + i
		);
		pageLoadEvent = pulletEvents.find((event) => event.page_load.for_you_page);
		i++;
	}
	expect(pageLoadEvent.page_load.status).equal(
		'SUCCESS',
		`pageLoadEvent.page_load.status===SUCCESS, Event: \n
${JSON.stringify(pageLoadEvent)} \n`
	);
	expect(pageLoadEvent.page_load.load_time).to.match(
		/\d/,
		`pageLoadEvent.page_load.load_time===, Event: \n
	${JSON.stringify(pageLoadEvent)} \n`
	);
	expect(pageLoadEvent.page_load.for_you_page).to.be.empty;
}

export async function verifyC130131(idOfTitleFromAutoplay) {
	let eventPageLoad;
	let i = 1;
	while (eventPageLoad === undefined && i < 30) {
		let pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			i + 6
		);
		
		eventPageLoad = pulletEvents.find(
			(event) =>
				event.page_load.status === STATUS.success &&
				event.page_load.video_player_page
		);
		i++;
	}
		expect(eventPageLoad.page_load.video_player_page.video_id).equal(
			parseInt(idOfTitleFromAutoplay.id),
			`event.auto_play.video_id===${idOfTitleFromAutoplay.id}, Event: \n
			${JSON.stringify(eventPageLoad)} \n`
		);
	}

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
