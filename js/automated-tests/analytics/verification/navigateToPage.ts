import {
	Events,
	PlaybackSource,
	milisecondsToMinutes,
	EventsValues,
	MidleNavComponents,
	CategorySlug,
	LEFT_NAV_SECTIONS,
} from '../utils/constants';
import {
	getMatchedEventsFromLastEvent,
	getSeekEvent,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

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
