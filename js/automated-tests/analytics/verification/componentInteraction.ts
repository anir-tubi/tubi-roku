import { Events, EventsValues } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC125524() {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction &&
				event.component_interaction.user_interaction === 'TOGGLE_ON'
		);
		i++;
	}
	expect(componentInteraction.component_interaction.user_interaction).equal(
		'TOGGLE_ON',
		`Each event has to contain component_interaction.user_interaction===TOGGLE_ON, Event \n ${JSON.stringify(
			componentInteraction
		)} \n`
	);
}

export async function verifyC268957() {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction &&
				event.component_interaction.home_page &&
				event.component_interaction.home_page.content_mode &&
				event.component_interaction.home_page.content_mode ===
					EventsValues.conentModeLatino &&
				event.component_interaction.left_side_nav_component &&
				event.component_interaction.left_side_nav_component.left_nav_section &&
				event.component_interaction.left_side_nav_component.left_nav_section ===
					`ESPANOL`
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.home_page.content_mode
	).equal(
		EventsValues.conentModeLatino,
		`Event should contain componentInteractionEvent.home_page.content_mode=CONTENT_MODE_UNKNOWN, Event: \n ${JSON.stringify(
			componentInteraction
		)}
		\n`
	);
	expect(
		componentInteraction.component_interaction.left_side_nav_component
			.left_nav_section
	).equal(
		`ESPANOL`,
		`Event should contain  componentInteractionEvent.component_interaction.left_side_nav_component..left_nav_section=ESPANOL, Event: \n ${JSON.stringify(
			componentInteraction
		)}
\n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		`TOGGLE_ON`,
		`Event should contain componentInteractionEvent.component_interaction.user_interaction=TOGGLE_ON, Event: \n ${JSON.stringify(
			componentInteraction
		)}
		\n`
	);
}

export async function verifyC268956ComponentInteraction() {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction &&
				event.component_interaction.home_page &&
				event.component_interaction.home_page.content_mode &&
				event.component_interaction.home_page.content_mode ===
					EventsValues.conentModeUnknown &&
				event.component_interaction.left_side_nav_component &&
				event.component_interaction.left_side_nav_component.left_nav_section &&
				event.component_interaction.left_side_nav_component.left_nav_section ===
					`ESPANOL`
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.home_page.content_mode
	).equal(
		EventsValues.conentModeUnknown,
		`Event should contain componentInteractionEvent.home_page.content_mode=CONTENT_MODE_UNKNOWN, Event: \n ${JSON.stringify(
			componentInteraction
		)}
		\n`
	);
	expect(
		componentInteraction.component_interaction.left_side_nav_component
			.left_nav_section
	).equal(
		`ESPANOL`,
		`Event should contain  componentInteractionEvent.component_interaction.left_side_nav_component..left_nav_section=ESPANOL, Event: \n ${JSON.stringify(
			componentInteraction
		)}
\n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		`CONFIRM`,
		`Event should contain componentInteractionEvent.component_interaction.user_interaction=CONFIRM, Event: \n ${JSON.stringify(
			componentInteraction
		)}
		\n`
	);
}
