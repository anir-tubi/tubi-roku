import {
	Events,
	PlaybackSource,
	milisecondsToMinutes,
	EventsValues,
	MidleNavComponents,
	CategorySlug,
	LEFT_NAV_SECTIONS,
	CAT_SLUG,
	LeftNavSection,
} from '../utils/constants';
import {
	getMatchedEventsFromLastEvent,
	getSeekEvent,
	fullAnalyticEventOnSteps,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC112683() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.left_side_nav_component &&
				event.navigate_to_page.left_side_nav_component.left_nav_section &&
				event.navigate_to_page.left_side_nav_component.left_nav_section ===
					LEFT_NAV_SECTIONS.CHANNEL
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		LEFT_NAV_SECTIONS.CHANNEL,
		`event should contain     navigateToPageEvent.navigate_to_page.left_side_nav_component.left_nav_section=LEFT_NAV_SECTIONS.CATEGORIES Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`event should contain     navigateToPageEvent.navigate_to_page.home_page.content_moden- EventsValues.conentModeUnknown Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.dest_channel_list_page).to.be
		.empty;
}

export async function verifyC543694() {
	let accountEvent;
	let i = 1;
	while (accountEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.account,
			40 + i
		);
		accountEvent = pulletEvents.find(
			(event) => event.account.current === 'EMAIL'
		);
		i++;
	}
	expect(accountEvent.account.current).equal(
		'EMAIL',
		`event.account.current === 'EMAIL', Event: \n
${JSON.stringify(accountEvent)} \n`
	);
	expect(accountEvent.account.manip).equal(
		'SIGNIN',
		`event.account.manip === 'SIGNIN', Event: \n
${JSON.stringify(accountEvent)} \n`
	);
	expect(accountEvent.account.status).equal(
		'SUCCESS',
		`event.account.status === 'SUCCESS', Event: \n
${JSON.stringify(accountEvent)} \n`
	);
}

export async function verifyC543693() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page.dest_home_page &&
				event.navigate_to_page.dest_home_page.content_mode &&
				event.navigate_to_page.dest_home_page.content_mode ===
					EventsValues.conentModeUnknown
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.dest_home_page.content_mode
	).equal(
		EventsValues.conentModeUnknown,
		`navigateToPageEvent.navigate_to_page.dest_home_page.content_mode===CONTENT_MODE_UNKNOWN, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.login_page.choice).equal(
		'EMAIL',
		`navigateToPageEvent.navigate_to_page.login_page.choice===EMAIL, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC543693NavigateToPage() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) => event.navigate_to_page.dest_login_page
		);
		i++;
	}
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`navigateToPageEvent.navigate_to_page.dest_home_page.content_mode===CONTENT_MODE_UNKNOWN, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		navigateToPageEvent.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		EventsValues.account,
		`navigateToPageEvent.navigate_to_page.dest_home_page.content_mode===ACCOUNT, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.dest_login_page.choice).equal(
		'EMAIL',
		`navigateToPageEvent.navigate_to_page.login_page.choice===EMAIL, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC439647() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) => event.navigate_to_page.dest_for_you_page
		);
		i++;
	}
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`navigate_to_page.home_page.content_mode===CONTENT_MODE_UNKNOWN, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		navigateToPageEvent.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		LeftNavSection.queue,
		`navigate_to_page.left_side_nav_component.left_nav_section===QUEUE, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.dest_for_you_page).to.be.empty;
}

export async function verifyC439648() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) => event.navigate_to_page.dest_home_page
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.dest_home_page.content_mode
	).equal(
		EventsValues.conentModeUnknown,
		`navigateToPageEvent.navigate_to_page.dest_home_page.content_mode===CONTENT_MODE_UNKNOWN, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.for_you_page).to.be.empty;
}

export async function verifyC439651NavigateToPageMovie(id) {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page.category_component &&
				event.navigate_to_page.category_component.category_slug &&
				event.navigate_to_page.category_component.category_slug ===
					CAT_SLUG.queue
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.category_component.category_slug
	).equal(
		CAT_SLUG.queue,
		`navigateToPageEvent.navigate_to_page.category_component.category_slug===CAT_SLUG.queue, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.category_row
		)
	).equal(
		2,
		`navigateToPageEvent.navigate_to_page.category_component.category_row===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.category_col
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.category_col===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile.col
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.col===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile.row
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.row===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile
				.video_id
		)
	).equal(
		id,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.video_id===, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(navigateToPageEvent.navigate_to_page.dest_video_page.video_id)
	).equal(
		id,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.video_id===, Event: \n
		${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC439651NavigateToPage(id) {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page.category_component &&
				event.navigate_to_page.category_component.category_slug &&
				event.navigate_to_page.category_component.category_slug ===
					CAT_SLUG.queue
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.category_component.category_slug
	).equal(
		CAT_SLUG.queue,
		`navigateToPageEvent.navigate_to_page.category_component.category_slug===CAT_SLUG.queue, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.category_row
		)
	).equal(
		2,
		`navigateToPageEvent.navigate_to_page.category_component.category_row===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.category_col
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.category_col===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile.col
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.col===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile.row
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.row===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile
				.series_id
		)
	).equal(
		id,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.video_id===, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.dest_series_detail_page.series_id
		)
	).equal(
		id,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.video_id===, Event: \n
		${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC439649NavigateToPage(id) {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page.category_component &&
				event.navigate_to_page.category_component.category_slug &&
				event.navigate_to_page.category_component.category_slug ===
					CAT_SLUG.continueWatching
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.category_component.category_slug
	).equal(
		CAT_SLUG.continueWatching,
		`navigateToPageEvent.navigate_to_page.category_component.category_slug===CAT_SLUG.continueWatching, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.category_row
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.category_row===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.category_col
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.category_col===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile.col
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.col===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile.row
		)
	).equal(
		1,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.row===1, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(
			navigateToPageEvent.navigate_to_page.category_component.content_tile
				.video_id
		)
	).equal(
		id,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.video_id===, Event: \n
${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		parseInt(navigateToPageEvent.navigate_to_page.dest_video_page.video_id)
	).equal(
		id,
		`navigateToPageEvent.navigate_to_page.category_component.content_tile.video_id===, Event: \n
		${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC118158() {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			20 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.category_component &&
				event.navigate_to_page.category_component.category_slug &&
				event.navigate_to_page.category_component.category_slug ===
					'recommended_linear_channels'
		);
		i++;
	}
	expect(
		eventNavigateToPage.navigate_to_page.category_component.category_slug
	).equal(
		'recommended_linear_channels',
		`event should contain navigate_to_page.category_component.category_slug===live_news, Event: \n
${JSON.stringify(eventNavigateToPage)} \n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id
	).to.match(
		/\d/,
		`event should contain navigate_to_page.dest_video_player_page.video_id===id, Event: \n
${JSON.stringify(eventNavigateToPage)} \n`
	);
	// expect(eventOne.navigate_to_page.home_page).to.be.empty;
	expect(eventNavigateToPage.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`event should contain navigate_to_page.category_component.category_slug===live_news, Event: \n
${JSON.stringify(eventNavigateToPage)} \n`
	);
}

export async function verifyC21261(movieId) {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_video_player_page &&
				event.navigate_to_page.video_page
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.dest_video_player_page.video_id
	).equal(
		parseInt(movieId),
		`event should contain event.navigate_to_page.dest_video_player_page.video_id=${movieId} Event: \n
		${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.video_page.video_id).equal(
		parseInt(movieId),
		`event should contain event.navigate_to_page.video_page.video_id=${movieId} Event: \n
		${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC21262(id) {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_series_detail_page &&
				event.navigate_to_page.category_component
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.dest_series_detail_page.series_id
	).equal(
		parseInt(id),
		`Event should contain event.navigate_to_page.dest_series_detail_page.series_id=${id}, Event: \n ${JSON.stringify(
			navigateToPageEvent
		)} \n`
	);
	expect(
		navigateToPageEvent.navigate_to_page.category_component.content_tile
			.series_id
	).equal(
		parseInt(id),
		`Event should contain event.category_component.content_tile.series_id=${id}, Event: \n ${JSON.stringify(
			navigateToPageEvent
		)} \n`
	);
}

export async function verifyC63513(tag) {
	expect(tag.split(' ')[2]).equal('Series');
}
export async function verifyC76713(category) {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 20) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			8 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page && event.navigate_to_page.category_list_page
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_to_page.category_list_page).to.be.empty;
	expect(
		eventNavigateToPage.navigate_to_page.dest_category_page.category_slug
	).equal(
		category,
		`event should navigate_to_page.dest_category_page.category_slug===action, Event: \n
	${JSON.stringify(eventNavigateToPage)}\n`
	);
}
export async function verifyC21267(id) {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			8 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_video_player_page &&
				event.navigate_to_page.dest_video_player_page.video_id &&
				event.navigate_to_page.dest_video_player_page.video_id === parseInt(id)
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_to_page.video_page.video_id).equal(
		parseInt(id),
		`Event should contain event.navigate_to_page.video_page.video_id=${id}, Event: \n ${JSON.stringify(
			eventNavigateToPage
		)}
			\n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.dest_video_player_page.video_id
	).equal(
		parseInt(id),
		`Event should contain dest_video_player_page.video_id=${id}, Event: \n ${JSON.stringify(
			eventNavigateToPage
		)}
	\n`
	);
}

export async function verifyC116493() {
	const fullEvents = await fullAnalyticEventOnSteps([
		6, 7, 8, 9, 10, 11, 12, 13, 14,
	]);
	fullEvents.forEach((fullEvent) => {
		expect(fullEvent.app.app_mode).not.equal(
			'LATINO_MODE',
			`fullEventOne.app.app_mode!=='LATINO_MODE', Event: \n
${JSON.stringify(fullEvent)} \n`
		);
	});
}

export async function verifyC3854() {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			60 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_search_page &&
				event.navigate_to_page.left_side_nav_component &&
				event.navigate_to_page.left_side_nav_component.left_nav_section &&
				event.navigate_to_page.left_side_nav_component.left_nav_section ===
					'SEARCH'
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`Event should contain eventNavigateToPage.navigate_to_page.home_page.content_mode=${
			EventsValues.conentModeUnknown
		}, Event: \n ${JSON.stringify(eventNavigateToPage)}
			\n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		'SEARCH',
		`Event should contain eventNavigateToPage.navigate_to_page.left_side_nav_component.left_nav_section=SEARCH, Event: \n ${JSON.stringify(
			eventNavigateToPage
		)}
			\n`
	);
	expect(eventNavigateToPage.navigate_to_page.dest_search_page).to.be.empty;
}

export async function verifyC145000() {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			60 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_for_you_page &&
				event.navigate_to_page.left_side_nav_component &&
				event.navigate_to_page.left_side_nav_component.left_nav_section &&
				event.navigate_to_page.left_side_nav_component.left_nav_section ===
					'QUEUE'
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`Event should contain eventNavigateToPage.navigate_to_page.home_page.content_mode=${
			EventsValues.conentModeUnknown
		}, Event: \n ${JSON.stringify(eventNavigateToPage)}
			\n`
	);
	expect(
		eventNavigateToPage.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		'QUEUE',
		`Event should contain eventNavigateToPage.navigate_to_page.left_side_nav_component.left_nav_section=SEARCH, Event: \n ${JSON.stringify(
			eventNavigateToPage
		)}
			\n`
	);
	expect(eventNavigateToPage.navigate_to_page.dest_for_you_page).to.be.empty;
}

export async function verifyC112680() {
	let navigateToPage;
	let i = 1;
	while (navigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			60 + i
		);
		navigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_home_page &&
				event.navigate_to_page.dest_home_page.content_mode &&
				event.navigate_to_page.dest_home_page.content_mode ===
					EventsValues.conentModeMovie
		);
		i++;
	}
	expect(navigateToPage.navigate_to_page.dest_home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`navigateToPage.dest_home_page.content_mode, Event: \n ${JSON.stringify(
			navigateToPage
		)}
			\n`
	);
	expect(navigateToPage.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`navigateToPage.dest_home_page.content_mode, Event: \n ${JSON.stringify(
			navigateToPage
		)}
			\n`
	);
	expect(
		navigateToPage.navigate_to_page.left_side_nav_component.left_nav_section
	).equal(
		'MOVIES',
		`navigateToPage.navigate_to_page.top_nav_component, Event: \n ${JSON.stringify(
			navigateToPage
		)}
			\n`
	);
}

export async function verifyC21263(movieId) {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_video_player_page &&
				event.navigate_to_page.video_page
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.dest_video_player_page.video_id
	).equal(parseInt(movieId));
	expect(navigateToPageEvent.navigate_to_page.video_page.video_id).equal(
		parseInt(movieId)
	);
}

export async function verifyC112681() {
	let navigateToPage;
	let i = 1;
	while (navigateToPage === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			60 + i
		);
		navigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.dest_home_page &&
				event.navigate_to_page.dest_home_page.content_mode &&
				event.navigate_to_page.dest_home_page.content_mode ===
					EventsValues.conentModeTv
		);
		i++;
	}
	expect(navigateToPage.navigate_to_page.dest_home_page.content_mode).equal(
		EventsValues.conentModeTv,
		`navigateToPage.dest_home_page.content_mode, Event: \n ${JSON.stringify(
			navigateToPage
		)}
			\n`
	);
	expect(navigateToPage.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`navigateToPage.dest_home_page.content_mode, Event: \n ${JSON.stringify(
			navigateToPage
		)}
			\n`
	);
	expect(
		navigateToPage.navigate_to_page.left_side_nav_component.left_nav_section
	).equal(
		'SERIES',
		`navigateToPage.navigate_to_page.top_nav_component===SERIES, Event: \n ${JSON.stringify(
			navigateToPage
		)}
			\n`
	);
}

export async function verifyC76112andC76048(movieId) {
	let pageLoadEvent;
	let i = 1;
	while (pageLoadEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			9 + i
		);
		pageLoadEvent = pulletEvents.find(
			(event) =>
				event.page_load &&
				event.page_load.video_page &&
				event.page_load.video_page.video_id === movieId
		);
		i++;
	}
	expect(pageLoadEvent.page_load.video_page.video_id).equal(
		parseInt(movieId),
		`event should contain event.navigate_to_page.video_page.video_id=${movieId} Event: \n
	${JSON.stringify(pageLoadEvent)} \n`
	);
}
export async function verifyC118164() {
	let subtitlesToggleEvent;
	let i = 1;
	while (subtitlesToggleEvent === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.subtitles_toggle,
			20 + i
		);
		subtitlesToggleEvent = pulletEvents.find(
			(event) => event.subtitles_toggle && event.subtitles_toggle.toggle_state
		);
		i++;
	}
	expect(subtitlesToggleEvent.subtitles_toggle.toggle_state).to.match(
		/ON|OFF/,
		`Each event has to contain subtitles_toggle.toggle_state===ON, Event \n ${JSON.stringify(
			subtitlesToggleEvent
		)} \n`
	);
}

export async function verifyC112684() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.left_side_nav_component &&
				event.navigate_to_page.left_side_nav_component.left_nav_section &&
				event.navigate_to_page.left_side_nav_component.left_nav_section ===
					LEFT_NAV_SECTIONS.SETTINGS
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		LEFT_NAV_SECTIONS.SETTINGS,
		`event should contain     navigateToPageEvent.navigate_to_page.left_side_nav_component.left_nav_section=LEFT_NAV_SECTIONS.CATEGORIES Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown,
		`event should contain     navigateToPageEvent.navigate_to_page.home_page.content_moden= EventsValues.conentModeUnknown Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(
		navigateToPageEvent.navigate_to_page.dest_account_page.account_page_type
	).equal(
		'PARENTAL',
		`event should contain     navigateToPageEvent.navigate_to_page.dest_account_page.account_page_type= PARENTAL Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC112682() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			40 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.left_side_nav_component &&
				event.navigate_to_page.left_side_nav_component.left_nav_section &&
				event.navigate_to_page.left_side_nav_component.left_nav_section ===
					LEFT_NAV_SECTIONS.CATEGORIES
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		LEFT_NAV_SECTIONS.CATEGORIES,
		`event should contain     navigateToPageEvent.navigate_to_page.left_side_nav_component.left_nav_section=LEFT_NAV_SECTIONS.CATEGORIES Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`event should contain     navigateToPageEvent.navigate_to_page.home_page.content_moden- EventsValues.conentModeUnknown Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.dest_category_list_page).to.be
		.empty;
}
