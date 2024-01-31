import {
	Events,
	EventsValues,
	ButtomValues,
	UserInteraction,
	MidleNavComponents,
	LeftNavSection,
} from '../utils/constants';
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

export async function verifyC439647ComponentInteraction() {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.left_side_nav_component &&
				event.component_interaction.left_side_nav_component.left_nav_section &&
				event.component_interaction.left_side_nav_component.left_nav_section ===
					LeftNavSection.queue
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.left_side_nav_component
			.left_nav_section
	).equal(
		LeftNavSection.queue,
		`componentInteraction.component_interaction.left_side_nav_component.left_nav_section===QUEUE, Event: \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.home_page.content_mode
	).equal(
		EventsValues.conentModeUnknown,
		`componentInteraction.component_interaction.left_side_nav_component.left_nav_section===QUEUE, Event: \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.home_page.user_interaction===CONFIRM, Event: \n
	${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC439648ComponentInteraction() {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.CONFIRM &&
				event.component_interaction.button_component &&
				event.component_interaction.button_component.button_value ===
					MidleNavComponents.goToHome
		);
		i++;
	}
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===CONFIRM, Event: \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.button_component.button_value
	).equal(
		MidleNavComponents.goToHome,
		`componentInteraction.component_interaction.button_component.button_value===GO_TO_HOME, Event: \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.button_component.button_type
	).equal(
		ButtomValues.TEXT,
		`componentInteraction.component_interaction.button_component.button_type===ButtomValues.TEXT, Event: \n
	${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.for_you_page).to.be.empty;
}

export async function verifyC374782(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.DISLIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_OFF
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.DISLIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE_OR_DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_OFF,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_OFF, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374790(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.DISLIKE &&
				event.component_interaction.user_interaction === UserInteraction.CONFIRM
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.DISLIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374783(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.DISLIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_OFF
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.DISLIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE_OR_DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_OFF,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_OFF, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374787(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.DISLIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === UserInteraction.CONFIRM
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.DISLIKE,
		`componentInteraction.component_interaction.button_component.button_value===ButtomValues.DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.CONFIRM, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374779(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_OFF
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_OFF,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374785(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE &&
				event.component_interaction.user_interaction === UserInteraction.CONFIRM
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374778(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_OFF
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_OFF,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374784(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE &&
				event.component_interaction.user_interaction === UserInteraction.CONFIRM
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374774(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE_OR_DISLIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === UserInteraction.CONFIRM
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE_OR_DISLIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE_OR_DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.CONFIRM, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.component_interaction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374777(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_ON
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_ON,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.component_interaction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374771(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE_OR_DISLIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_ON
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE_OR_DISLIKE,
		`componentInteraction.component_interaction.button_component.button_value===ButtomValues.LIKE_OR_DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_ON,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(
		componentInteraction.component_interaction.series_detail_page.series_id
	).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374775(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE_OR_DISLIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction === UserInteraction.CONFIRM
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE_OR_DISLIKE,
		`componentInteraction.component_interaction.middle_nav_component.middle_nav_section===ButtomValues.LIKE_OR_DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.CONFIRM,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.CONFIRM, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374776(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE &&
				event.component_interaction.user_interaction &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_ON
		);
		i++;
	}
	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE,
		`componentInteraction.component_interaction.button_component.button_value===ButtomValues.LIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_ON,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
}

export async function verifyC374770(id) {
	let componentInteraction;
	let i = 1;
	while (componentInteraction === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.component_interaction,
			10 + i
		);
		componentInteraction = pulletEvents.find(
			(event) =>
				event.component_interaction.middle_nav_component &&
				event.component_interaction.middle_nav_component.middle_nav_section &&
				event.component_interaction.middle_nav_component.middle_nav_section ===
					ButtomValues.LIKE_OR_DISLIKE &&
				event.component_interaction.user_interaction ===
					UserInteraction.TOGGLE_ON
		);
		i++;
	}

	expect(
		componentInteraction.component_interaction.middle_nav_component
			.middle_nav_section
	).equal(
		ButtomValues.LIKE_OR_DISLIKE,
		`componentInteraction.component_interaction.middle_nav_section.middle_nav_section===ButtomValues.LIKE_OR_DISLIKE, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.user_interaction).equal(
		UserInteraction.TOGGLE_ON,
		`componentInteraction.component_interaction.user_interaction===UserInteraction.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
	);
	expect(componentInteraction.component_interaction.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(componentInteraction)} \n`
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
