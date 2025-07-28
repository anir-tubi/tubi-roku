import {
	Events,
	PlaybackSource,
	milisecondsToMinutes,
	EventsValues,
	MidleNavComponents,
	CategorySlug,
	ButtomValues,
} from '../utils/constants';
import {
	getMatchedEventsFromLastEvent,
	getSeekEvent,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC268957WithinPage() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.home_page &&
				event.navigate_within_page.home_page.content_mode &&
				event.navigate_within_page.home_page.content_mode ===
				EventsValues.conentModeUnknown &&
				event.navigate_within_page.left_side_nav_component &&
				event.navigate_within_page.left_side_nav_component.left_nav_section &&
				event.navigate_within_page.left_side_nav_component.left_nav_section ===
				'LINEAR'
		);
		i++;
	}
	expect(navigateWithinPage.navigate_within_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown
	);
	expect(
		navigateWithinPage.navigate_within_page.left_side_nav_component
			.left_nav_section
	).equal('LINEAR');
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(10);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(1);
}

export async function verifyC690751NavigateWithinPage(slugCategory) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug &&
				event.navigate_within_page.category_component.category_slug ===
				slugCategory.toLowerCase()
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.category_component.category_slug
	).equal(
		slugCategory.toLowerCase(),
		`event should contains navigate_within_page.category_component.category_slug==${slugCategory}, Event: \n
${JSON.stringify(navigateWithinPage)}\n`
	);
}

export async function verifyC690753NavigateWithinPage(slugCategory: string) {
	let navigateWithinPage;
	let i = 1;

	// Loop to fetch and find the matching event
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);

		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug &&
				event.navigate_within_page.category_component.category_slug ===
				slugCategory.toLowerCase() &&
				event.navigate_within_page.category_component.category_col === 1 &&
				event.navigate_within_page.category_component.content_tile &&
				event.navigate_within_page.category_component.content_tile.col === 1
		);
		i++;
	}

	// Assertions to verify the object structure and values
	expect(
		navigateWithinPage.navigate_within_page.category_component.category_slug
	).equal(
		slugCategory.toLowerCase(),
		`event should contain navigate_within_page.category_component.category_slug==${slugCategory}, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.category_component.category_col
	).equal(
		1,
		`event should contain navigate_within_page.category_component.category_col===1, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.category_component.category_row
	).equal(
		1,
		`event should contain navigate_within_page.category_component.category_row===1, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.category_component.content_tile.col
	).equal(
		1,
		`event should contain navigate_within_page.category_component.content_tile.col===1, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.category_component.content_tile.row
	).equal(
		1,
		`event should contain navigate_within_page.category_component.content_tile.row===1, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.category_list_page.personalization_id
	).to.match(
		/^[a-f0-9\-]{36}$/,
		`event should contain navigateWithinPage.navigate_within_page.category_list_page.personalization_id==id, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.horizontal_location
	).to.match(
		/\d/,
		`event should contain navigate_within_page.horizontal_location===1, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.means_of_navigation
	).equal(
		"BUTTON",
		`event should contain navigate_within_page.means_of_navigation===BUTTON, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);

	expect(
		navigateWithinPage.navigate_within_page.vertical_location
	).to.match(
		/\d/,
		`event should contain navigate_within_page.vertical_location===1, Event: \n${JSON.stringify(
			navigateWithinPage
		)}\n`
	);
}

export async function verifyC76715NavigateWithinPage(slugCategory) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug &&
				event.navigate_within_page.category_component.category_slug ===
				slugCategory.toLowerCase()
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.category_component.category_slug
	).equal(
		slugCategory.toLowerCase(),
		`event should contains navigate_within_page.category_component.category_slug==${slugCategory}, Event: \n
${JSON.stringify(navigateWithinPage)}\n`
	);
}

export async function verifyC76717(slugCategory) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug &&
				event.navigate_within_page.category_component.category_slug ===
				slugCategory.toLowerCase()
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.category_component.category_slug
	).equal(
		slugCategory.toLowerCase(),
		`event should contains navigate_within_page.category_component.category_slug==${slugCategory}, Event: \n
${JSON.stringify(navigateWithinPage)}\n`
	);
}

export async function verifyC268959() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.home_page &&
				event.navigate_within_page.home_page.content_mode &&
				event.navigate_within_page.home_page.content_mode ===
				EventsValues.conentModeUnknown &&
				event.navigate_within_page.means_of_navigation &&
				event.navigate_within_page.means_of_navigation === 'SCROLL' &&
				event.navigate_within_page.left_side_nav_component &&
				event.navigate_within_page.left_side_nav_component.left_nav_section &&
				event.navigate_within_page.left_side_nav_component.left_nav_section ===
				'HOME'
		);
		i++;
	}
	expect(navigateWithinPage.navigate_within_page.home_page.content_mode).equal(
		EventsValues.conentModeUnknown
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL'
	);
	expect(
		navigateWithinPage.navigate_within_page.left_side_nav_component
			.left_nav_section
	).equal('HOME');
	expect(navigateWithinPage.navigate_within_page.vertical_location).to.match(
		/\d/,
		`event should contain eventNavigateWithinPageFirst.navigate_within_page.vertical_location===, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).to.match(
		/\d/,
		`event should contain eventNavigateWithinPageFirst.navigate_within_page.horizontal_location===, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC543668andC543669(titleId) {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			8 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.means_of_navigation &&
				event.navigate_within_page.means_of_navigation === 'BUTTON' &&
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug &&
				event.navigate_within_page.category_component.category_slug ===
				'featured'
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_within_page.means_of_navigation).equal(
		'BUTTON'
	);
	expect(eventNavigateToPage.navigate_within_page.vertical_location).equal(2);
	expect(eventNavigateToPage.navigate_within_page.horizontal_location).equal(1);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.category_slug
	).equal('featured');
	expect(
		eventNavigateToPage.navigate_within_page.category_component.category_row
	).equal(1);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.content_tile.row
	).equal(1);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.content_tile
			.video_id
	).equal(parseInt(titleId));
	expect(
		eventNavigateToPage.navigate_within_page.category_component.content_tile.col
	).equal(1);
	expect(eventNavigateToPage.navigate_within_page.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`eventOne.page_load.home_page.content_mode==='CONTENT_MODE_UNKNOWN', Event: \n
  ${JSON.stringify(eventNavigateToPage)} \n`
	);
}

export async function verifyC543671(details) {
	let eventNavigateToPage;
	let i = 1;
	while (eventNavigateToPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			8 + i
		);
		eventNavigateToPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.means_of_navigation &&
				event.navigate_within_page.means_of_navigation === 'BUTTON' &&
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug &&
				event.navigate_within_page.category_component.category_slug ===
				'featured' &&
				event.navigate_within_page.horizontal_location === 1
		);
		i++;
	}
	expect(eventNavigateToPage.navigate_within_page.means_of_navigation).equal(
		'BUTTON'
	);
	expect(eventNavigateToPage.navigate_within_page.vertical_location).equal(2);
	expect(eventNavigateToPage.navigate_within_page.horizontal_location).equal(1);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.category_slug
	).equal(details.categorySlug);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.category_row
	).equal(1);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.content_tile.row
	).equal(1);
	expect(
		eventNavigateToPage.navigate_within_page.category_component.content_tile.col
	).equal(1);
	// expect(event.navigate_within_page.home_page).to.be.empty;
	expect(eventNavigateToPage.navigate_within_page.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`eventOne.page_load.home_page.content_mode==='CONTENT_MODE_UNKNOWN', Event: \n
  ${JSON.stringify(eventNavigateToPage)} \n`
	);
	if (
		eventNavigateToPage.navigate_within_page.category_component.content_tile
			.video_id === undefined
	) {
		expect(
			eventNavigateToPage.navigate_within_page.category_component.content_tile
				.series_id
		).equal(parseInt(details.contentId));
	} else {
		expect(
			eventNavigateToPage.navigate_within_page.category_component.content_tile
				.video_id
		).equal(parseInt(details.contentId));
	}
}

export async function verifyC425240(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.middle_nav_component &&
				event.navigate_within_page.middle_nav_component.middle_nav_section &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.episodeList
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.likeOrDislike,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===PLAY \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.episodeList,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		3,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.series_detail_page.series_id
	).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC118157() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.epg_component &&
				event.navigate_within_page.epg_component.category_slug &&
				event.navigate_within_page.epg_component.category_slug ===
				CategorySlug.FEATURED_CHANNELS
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.epg_component.category_slug
	).equal(
		CategorySlug.FEATURED_CHANNELS,
		`event should contain navigateWithinPage.navigate_within_page.epg_component.category_slug===CategorySlug.FEATURED_CHANNELS, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.epg_component.content_tile.col
	).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.epg_component.content_tile.col===1, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.epg_component.content_tile.row
	).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.epg_component.content_tile.row===1, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.epg_component.content_tile.video_id
	).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.epg_component.content_tile.video_id===1, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===n, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===n, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'BUTTON',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===BUTTON, Event: \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.linear_browse_page).to.be
		.empty;
}

export async function verifyC425233(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.middle_nav_component &&
				event.navigate_within_page.middle_nav_component.middle_nav_section &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.watchTrailer
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.addToMyList,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===START_FROM_BEGINNING \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.watchTrailer,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===WATCH_TRAILER \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC690744() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.left_side_nav_component &&
				event.navigate_within_page.left_side_nav_component.left_nav_section &&
				event.navigate_within_page.left_side_nav_component.left_nav_section === 'CATEGORIES'
		);
		i++;
	}
	expect(navigateWithinPage.navigate_within_page.left_side_nav_component
		.left_nav_section).equal(
			'CATEGORIES', `event should contain navigateWithinPage.navigate_within_page.browse_menu_page.category_slug===slug \n
	${JSON.stringify(navigateWithinPage)} \n`
		);
}

export async function verifyC690748(categorySlug) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.category_component &&
				event.navigate_within_page.category_component.category_slug
		);
		i++;
	}
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location== \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'BUTTON',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===BUTTON \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.category_component
			.category_slug
	).equal(
		categorySlug,
		`event should contain navigateWithinPage.navigate_within_page.category_component.category_slug===featured \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}


export async function verifyC690746() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.left_side_nav_component &&
				event.navigate_within_page.left_side_nav_component.left_nav_section &&
				event.navigate_within_page.left_side_nav_component.left_nav_section ===
				'CATEGORIES'
		);
		i++;
	}
	expect(navigateWithinPage.navigate_within_page.home_page
		.content_mode).equal(
			EventsValues.conentModeMovie,
			`event should contain navigateWithinPage.navigate_within_page.home_page.content_mode  \n
	${JSON.stringify(navigateWithinPage)} \n`
		);
	expect(navigateWithinPage.navigate_within_page.left_side_nav_component.left_nav_section).equal(
		'CATEGORIES',
		`event should contain navigateWithinPage.navigate_within_page.left_side_nav_component.left_nav_section===CATEGORIES \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC524595() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.video_player_page &&
				event.navigate_within_page.video_player_page.video_id
		);
		i++;
	}
	expect(navigateWithinPage.navigate_within_page.video_player_page
		.video_id).to.match(
			/\d/,
			`event should contain navigateWithinPage.navigate_within_page.video_player_page.video_id===id \n
	${JSON.stringify(navigateWithinPage)} \n`
		);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		2,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'BUTTON',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===BUTTON \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.category_component
			.category_slug
	).equal(
		'recommended_for_you',
		`event should contain navigateWithinPage.navigate_within_page.category_component.category_slug===featured \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		2,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425236(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.middle_nav_component &&
				event.navigate_within_page.middle_nav_component.middle_nav_section &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.dislike
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.like,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===START_FROM_BEGINNING \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.dislike,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425235(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.middle_nav_component &&
				event.navigate_within_page.middle_nav_component.middle_nav_section &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.like
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.dislike,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===START_FROM_BEGINNING \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.like,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		2,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425251(videoId) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			25 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
				MidleNavComponents.goToNetwork &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === 'CONFIRM'
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.goToNetwork,
		`event should contain componentInteraction.component_interaction.middle_nav_component.middle_nav_section===GO_TO_NETWORK \n
${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		'CONFIRM',
		`event should contain componentInteraction.component_interaction.user_interaction===CONFIRM \n
${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.video_page === undefined
			? componentInteraction.component_interaction.series_detail_page.series_id
			: componentInteraction.component_interaction.video_page.video_id
	).equal(
		parseInt(videoId),
		`event should contain componentInteraction.component_interaction.video_page.video_id===${videoId} \n
${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC425244() {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.middle_nav_component &&
				event.navigate_within_page.middle_nav_component.middle_nav_section &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.addToMyList
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.goToNetwork,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===PLAY \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.addToMyList,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425241(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.dest_middle_nav_component &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section === MidleNavComponents.addToMyList
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.addToMyList,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===PLAY \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.likeOrDislike,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		3,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC374781(id) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.dest_middle_nav_component &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section === ButtomValues.DISLIKE &&
				event.navigate_within_page.means_of_navigation &&
				event.navigate_within_page.means_of_navigation === 'SCROLL' &&
				event.navigate_within_page.vertical_location
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.DISLIKE,
		`navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_section===ButtomValues.DISLIKE, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		parseInt(navigateWithinPage.navigate_within_page.horizontal_location)
	).equal(
		1,
		`navigateWithinPage.navigate_within_page.horizontal_location===1, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`avigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_section===LIKE, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		parseInt(navigateWithinPage.navigate_within_page.vertical_location)
	).equal(
		2,
		`navigateWithinPage.navigate_within_page.vertical_location===2, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.series_detail_page.series_id
	).equal(
		parseInt(id),
		`navigateWithinPage.navigate_within_page.video_page.video_id===${id}, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC374780(id) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.dest_middle_nav_component &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section === ButtomValues.DISLIKE &&
				event.navigate_within_page.means_of_navigation &&
				event.navigate_within_page.means_of_navigation === 'SCROLL' &&
				event.navigate_within_page.vertical_location
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.DISLIKE,
		`navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_section===ButtomValues.DISLIKE, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		parseInt(navigateWithinPage.navigate_within_page.horizontal_location)
	).equal(
		1,
		`navigateWithinPage.navigate_within_page.horizontal_location===1, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`avigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_section===LIKE, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		parseInt(navigateWithinPage.navigate_within_page.vertical_location)
	).equal(
		2,
		`navigateWithinPage.navigate_within_page.vertical_location===2, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(id),
		`navigateWithinPage.navigate_within_page.video_page.video_id===${id}, Event: \n
			${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425243(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.dest_middle_nav_component &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section === MidleNavComponents.removeFromHistory
		);
		i++;
	}

	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.removeFromHistory,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===START_FROM_BEGINNING \n
	${JSON.stringify(navigateWithinPage)} \n`
	);

	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.addToMyList,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).to.match(
		/\d/,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425242(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			25 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.dest_middle_nav_component &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section &&
				event.navigate_within_page.dest_middle_nav_component
					.middle_nav_section === MidleNavComponents.removeFromMyList &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.addToMyList
		);
		i++;
	}
	if (
		navigateWithinPage.navigate_within_page.dest_middle_nav_component // could be something else, add fix
			.middle_nav_section === MidleNavComponents.watchTrailer
	) {
		expect(
			navigateWithinPage.navigate_within_page.dest_middle_nav_component // could be something else, add fix
				.middle_nav_section
		).equal(
			MidleNavComponents.watchTrailer,
			`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===START_FROM_BEGINNING \n
	${JSON.stringify(navigateWithinPage)} \n`
		);
	} else {
		expect(
			navigateWithinPage.navigate_within_page.dest_middle_nav_component // could be something else, add fix
				.middle_nav_section
		).equal(
			MidleNavComponents.removeFromMyList,
			`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===START_FROM_BEGINNING \n
			${JSON.stringify(navigateWithinPage)} \n`
		);
	}
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.addToMyList,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).to.match(
		/3|4/,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===3 or 4 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.video_page.video_id).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC425250(videoId) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			25 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
				MidleNavComponents.signUpToSaveProgress &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === 'CONFIRM'
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.signUpToSaveProgress,
		`event should contain componentInteraction.component_interaction.middle_nav_component.middle_nav_section===PLAY \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		'CONFIRM',
		`event should contain componentInteraction.component_interaction.user_interaction===CONFIRM \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(videoId),
		`event should contain componentInteraction.component_interaction.video_page.video_id===${videoId} \n
	${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC425249(videoId) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			25 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
				MidleNavComponents.episodeList &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === 'CONFIRM'
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.episodeList,
		`event should contain componentInteraction.component_interaction.middle_nav_component.middle_nav_section===PLAY \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		'CONFIRM',
		`event should contain componentInteraction.component_interaction.user_interaction===CONFIRM \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(videoId),
		`event should contain componentInteraction.component_interaction.video_page.video_id===${videoId} \n
	${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC425239(titleId) {
	let navigateWithinPage;
	let i = 1;
	while (navigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			8 + i
		);
		navigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page.middle_nav_component &&
				event.navigate_within_page.middle_nav_component.middle_nav_section &&
				event.navigate_within_page.middle_nav_component.middle_nav_section ===
				MidleNavComponents.play
		);
		i++;
	}
	expect(
		navigateWithinPage.navigate_within_page.dest_middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.episodeList,
		`event should contain navigateWithinPage.navigate_within_page.dest_middle_nav_component.middle_nav_sectionn===PLAY \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.horizontal_location).equal(
		1,
		`event should contain navigateWithinPage.navigate_within_page.horizontal_location===1 \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.means_of_navigation).equal(
		'SCROLL',
		`event should contain navigateWithinPage.navigate_within_page.means_of_navigation===SCROLL \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(
		navigateWithinPage.navigate_within_page.middle_nav_component
			.middle_nav_section
	).equal(
		MidleNavComponents.play,
		`event should contain navigateWithinPage.navigate_within_page.middle_nav_component.middle_nav_sectionn===LIKE_OR_DISLIKE \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
	expect(navigateWithinPage.navigate_within_page.vertical_location).equal(
		2,
		`event should contain navigateWithinPage.navigate_within_page.vertical_location===2 \n
	${JSON.stringify(navigateWithinPage)} \n`
	); // if sign up button not present should be 3
	expect(
		navigateWithinPage.navigate_within_page.series_detail_page.series_id
	).equal(
		parseInt(titleId),
		`event should contain navigateWithinPage.navigate_within_page.video_page===${titleId} \n
	${JSON.stringify(navigateWithinPage)} \n`
	);
}

export async function verifyC543672(id) {
	let eventNavigateWithinPage;
	let i = 1;
	while (eventNavigateWithinPage === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_within_page,
			23 + i
		);
		eventNavigateWithinPage = pulletEvents.find(
			(event) =>
				event.navigate_within_page &&
				event.navigate_within_page.video_player_page &&
				event.navigate_within_page.video_player_page.video_id === parseInt(id)
		);
		i++;
	}
	expect(
		eventNavigateWithinPage.navigate_within_page.auto_play_component
			.content_tile.video_id
	).to.match(/\d/, `Wrong title id after selecting next title in autoplay`);
	expect(
		eventNavigateWithinPage.navigate_within_page.auto_play_component
			.content_tile.col
	).equal(1);
	expect(
		eventNavigateWithinPage.navigate_within_page.auto_play_component
			.content_tile.row
	).equal(1);
	expect(
		eventNavigateWithinPage.navigate_within_page.means_of_navigation
	).equal('BUTTON');
}
