import {
	Events,
	FullEvent,
	DialogTypes,
	DialogAction,
	EventsValues,
	LeftNavSection,
	UserInteraction,
} from '../utils/constants';
import {
	getMatchedEventsFromLastEvent,
	getMatchedFullEventsFromLastEvent,
} from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC116493() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedFullEventsFromLastEvent(
			Events.navigate_to_page,
			14 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.app &&
				event.app.app_mode &&
				event.app.app_mode === FullEvent.defaultMode
		);
		i++;
	}
	expect(navigateToPageEvent.app.app_mode).equal(
		FullEvent.defaultMode,
		`app.app_mode===DEFAULT_MODE, Event: \n
  ${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC163671(idOfTitle) {
	let dialogEvent;
	let i = 1;
	while (dialogEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			i + 15
		);
		dialogEvent = pulletEvents.find(
			(event) =>
				event.dialog &&
				event.dialog.dialog_type &&
				event.dialog.dialog_type === DialogTypes.addToQueue
		);

		i++;
	}
	expect(dialogEvent.dialog.dialog_type).equal(
		DialogTypes.addToQueue,
		`dialog.dialog_type===SIGNIN_REQUIRED, Event: \n
      ${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_action).equal(
		DialogAction.show,
		`dialog.dialog_type===SIGNIN_REQUIRED, Event: \n
      ${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'sign-in-bookmark',
		`dialog.dialog_type===SIGNIN_REQUIRED, Event: \n
      ${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.video_page.video_id).equal(
		parseInt(idOfTitle),
		`vent.dialog.video_page===${idOfTitle}, Event: \n
      ${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyC150664(idOfTitle) {
	let dialogEvent;
	let i = 1;
	while (dialogEvent === undefined && i < 55) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			i + 25
		);
		dialogEvent = pulletEvents.find(
			(event) =>
				event.dialog && event.dialog.dialog_type === DialogTypes.addToQueue
		);
		i++;
	}
	expect(dialogEvent.dialog.dialog_action).equal(
		'SHOW',
		`dialog.dialog_action===SHOW, Event: \n
  ${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_sub_type).equal(
		'sign-in-bookmark',
		`dialog.dialog_sub_type===sign-in-bookmark, Event: \n
	${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.dialog_type).equal(
		DialogTypes.addToQueue,
		`dialog.dialog_type===ADD_TO_QUEUE, Event: \n
  ${JSON.stringify(dialogEvent)} \n`
	);
	expect(dialogEvent.dialog.series_detail_page.series_id).equal(
		parseInt(idOfTitle),
		`event.dialog.video_page===${idOfTitle}, Event: \n
  ${JSON.stringify(dialogEvent)} \n`
	);
}

export async function verifyC150666andC150672andC150665() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			i + 15
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page.dest_for_you_page &&
				event.navigate_to_page.home_page &&
				event.navigate_to_page.home_page.content_mode &&
				event.navigate_to_page.home_page.content_mode ===
					EventsValues.conentModeMovie
		);

		i++;
	}
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
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

export async function verifyC439643() {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 25) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			i + 15
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.left_side_nav_component &&
				event.component_interaction.left_side_nav_component.left_nav_section &&
				event.component_interaction.left_side_nav_component.left_nav_section ===
					LeftNavSection.queue &&
				event.component_interaction.home_page &&
				event.component_interaction.home_page.content_mode &&
				event.component_interaction.home_page.content_mode ===
					EventsValues.conentModeMovie
		);

		i++;
	}
	expect(
		componentInteraction.component_interaction.left_side_nav_component
			.left_nav_section
	).equal(
		LeftNavSection.queue,
		`componentInteraction.component_interaction.left_side_nav_component.left_nav_section===ButtomValues.queue, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.home_page.content_mode
	).equal(
		EventsValues.conentModeMovie,
		`componentInteraction.component_interaction.home_page.content_mode===CONTENT_MODE_UNKNOWN, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC439643PageLoad() {
	let pageLoad;
	let i = 1;
	while (pageLoad === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			i + 15
		);
		pageLoad = pulletEvents.find((event) => event.page_load.for_you_page);

		i++;
	}
	expect(pageLoad.page_load.for_you_page).to.be.empty;
	expect(pageLoad.page_load.load_time).equal(
		0,
		`pageLoad.page_load.load_time===0, Event: \n
			${JSON.stringify(pageLoad)} \n`
	);
	expect(pageLoad.page_load.status).equal(
		'SUCCESS',
		`pageLoad.page_load.status===SUCCESS, Event: \n
			${JSON.stringify(pageLoad)} \n`
	);
}

export async function verifyC439644() {
	let dialog;
	let i = 1;
	while (dialog === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			i + 15
		);
		dialog = pulletEvents.find(
			(event) =>
				event.dialog.dialog_action &&
				event.dialog.dialog_action === DialogAction.show
		);

		i++;
	}
	expect(dialog.dialog.dialog_action).equal(
		DialogAction.show,
		`dialog.dialog.dialog_action===SHOW, Event: \n
	${JSON.stringify(dialog)} \n`
	);
	expect(dialog.dialog.dialog_sub_type).equal(
		'email-prefill',
		`dialog.dialog.dialog_sub_type===email-prefill, Event: \n
	${JSON.stringify(dialog)} \n`
	);
	expect(dialog.dialog.dialog_type).equal(
		'REGISTRATION',
		`dialog.dialog.dialog_type===REGISTRATION, Event: \n
	${JSON.stringify(dialog)} \n`
	);
}

export async function verifyC3840() {
	let componentIteractionEvent;
	let i = 1;
	while (componentIteractionEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			15
		);
		componentIteractionEvent = pulletEvents.find(
			(event) =>
				event.component_interaction.left_side_nav_component &&
				event.component_interaction.left_side_nav_component.left_nav_section &&
				event.component_interaction.left_side_nav_component.left_nav_section ===
					'HOME' &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_ON
		);
		i++;
	}
	expect(
		componentIteractionEvent.component_interaction.left_side_nav_component
			.left_nav_section
	).equal(
		'HOME',
		` componentIteractionEvent.component_interaction.left_side_nav_component
			.left_nav_section===HOME, Event: \n
	${JSON.stringify(componentIteractionEvent)} \n`
	);
	expect(componentIteractionEvent.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_ON,
		`componentIteractionEvent.component_interaction.user_interaction===TOGGLE_ON, Event: \n
	${JSON.stringify(componentIteractionEvent)} \n`
	);

	expect(
		componentIteractionEvent.component_interaction.home_page.content_mode
	).equal(
		EventsValues.conentModeMovie,
		`componentIteractionEvent.component_interaction.user_interaction===TOGGLE_ON, Event: \n
			${JSON.stringify(componentIteractionEvent)} \n`
	);
}

export async function verifyC439645() {
	let dialog;
	let i = 1;
	while (dialog === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			i + 15
		);
		dialog = pulletEvents.find(
			(event) =>
				event.dialog.dialog_action &&
				event.dialog.dialog_action === DialogAction.acceptDeliberate
		);

		i++;
	}
	expect(dialog.dialog.dialog_action).equal(
		DialogAction.acceptDeliberate,
		`dialog.dialog.dialog_action===${DialogAction.acceptDeliberate}, Event: \n
	${JSON.stringify(dialog)} \n`
	);
	expect(dialog.dialog.dialog_sub_type).equal(
		'email-prefill',
		`dialog.dialog.dialog_sub_type===email-prefill, Event: \n
	${JSON.stringify(dialog)} \n`
	);
	expect(dialog.dialog.dialog_type).equal(
		'REGISTRATION',
		`dialog.dialog.dialog_type===REGISTRATION, Event: \n
	${JSON.stringify(dialog)} \n`
	);
}

export async function verifyC439646() {
	let dialog;
	let i = 1;
	while (dialog === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.dialog,
			i + 15
		);
		dialog = pulletEvents.find(
			(event) =>
				event.dialog.dialog_action &&
				event.dialog.dialog_action === DialogAction.dismissDeliberate
		);

		i++;
	}
	expect(dialog.dialog.dialog_action).equal(
		DialogAction.dismissDeliberate,
		`dialog.dialog.dialog_action===${DialogAction.dismissDeliberate}, Event: \n
	${JSON.stringify(dialog)} \n`
	);
	expect(dialog.dialog.dialog_sub_type).equal(
		'email-prefill',
		`dialog.dialog.dialog_sub_type===email-prefill, Event: \n
	${JSON.stringify(dialog)} \n`
	);
	expect(dialog.dialog.dialog_type).equal(
		'REGISTRATION',
		`dialog.dialog.dialog_type===REGISTRATION, Event: \n
	${JSON.stringify(dialog)} \n`
	);
}

export async function verifyC348168() {
	let componentIteractionEvent;
	let i = 1;
	while (componentIteractionEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			15
		);
		componentIteractionEvent = pulletEvents.find(
			(event) =>
				event.component_interaction.left_side_nav_component &&
				event.component_interaction.left_side_nav_component.left_nav_section &&
				event.component_interaction.left_side_nav_component.left_nav_section ===
					'QUEUE' &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === 'CONFIRM'
		);
		i++;
	}
	expect(
		componentIteractionEvent.component_interaction.left_side_nav_component
			.left_nav_section
	).equal(
		'QUEUE',
		` componentIteractionEvent.component_interaction.left_side_nav_component
			.left_nav_section===QUEUE, Event: \n
	${JSON.stringify(componentIteractionEvent)} \n`
	);
	expect(componentIteractionEvent.component_interaction.user_interaction).equal(
		'CONFIRM',
		`componentIteractionEvent.component_interaction.user_interaction===TOGGLE_ON, Event: \n
	${JSON.stringify(componentIteractionEvent)} \n`
	);
	expect(
		componentIteractionEvent.component_interaction.home_page.content_mode
	).equal(
		EventsValues.conentModeMovie,
		`componentIteractionEvent.component_interaction.user_interaction===TOGGLE_ON, Event: \n
			${JSON.stringify(componentIteractionEvent)} \n`
	);
}

export async function verifyC348168NavigateToPage() {
	let navigateToPageEvent;
	let i = 1;
	while (navigateToPageEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.navigate_to_page,
			8 + i
		);
		navigateToPageEvent = pulletEvents.find(
			(event) =>
				event.navigate_to_page &&
				event.navigate_to_page.left_side_nav_component &&
				event.navigate_to_page.left_side_nav_component.left_nav_section &&
				event.navigate_to_page.left_side_nav_component.left_nav_section ===
					'QUEUE'
		);
		i++;
	}
	expect(
		navigateToPageEvent.navigate_to_page.left_side_nav_component
			.left_nav_section
	).equal(
		'QUEUE',
		` navigateToPage.navigate_to_page.left_side_nav_component.left_nav_section===QUEUE, Event: \n
	${JSON.stringify(navigateToPageEvent)} \n`
	);
	expect(navigateToPageEvent.navigate_to_page.home_page.content_mode).equal(
		EventsValues.conentModeMovie,
		`componentIteractionEvent.component_interaction.user_interaction===TOGGLE_ON, Event: \n
			${JSON.stringify(navigateToPageEvent)} \n`
	);
}

export async function verifyC348168PageLoad() {
	let pageLoadEvent;
	let i = 1;
	while (pageLoadEvent === undefined && i < 10) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.page_load,
			i + 8
		);
		pageLoadEvent = pulletEvents.find(
			(event) => event.page_load && event.page_load.for_you_page
		);
		i++;
	}
	expect(pageLoadEvent.page_load.status).equal(
		'SUCCESS',
		`pageLoadEvent.page_load.status===SUCCESS, Event: \n
	${JSON.stringify(pageLoadEvent)} \n`
	);
	expect(pageLoadEvent.page_load.for_you_page).to.be.empty;
}
