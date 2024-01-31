import { Events, UserInteraction } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';

export async function verifyC374784ExplicitFeedback(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.LIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.LIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.LIKE, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
}

export async function verifyC374793(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.UNDO_LIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.UNDO_LIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.UNDO_LIKE, Event: \n
  ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.series_id).equal(
		parseInt(id),
		`componentInteraction.video_page.viseries_iddeo_id===${id}.TOGGLE_ON, Event: \n
  ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.series_detail_page.series_id).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
  ${JSON.stringify(explicitFeedback)} \n`
	);
}

export async function verifyC374795(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.UNDO_DISLIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.UNDO_DISLIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.UNDO_LIKE, Event: \n
      ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.series_id).equal(
		parseInt(id),
		`componentInteraction.video_page.viseries_iddeo_id===${id}.TOGGLE_ON, Event: \n
      ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.series_detail_page.series_id).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
      ${JSON.stringify(explicitFeedback)} \n`
	);
}

export async function verifyC374794(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.UNDO_DISLIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.UNDO_DISLIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.UNDO_DISLIKE, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
}

export async function verifyC374790ExplicitFeedback(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.DISLIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.DISLIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.LIKE, Event: \n
      ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.series_id).equal(
		parseInt(id),
		`componentInteraction.video_page.viseries_iddeo_id===${id}.TOGGLE_ON, Event: \n
      ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.series_detail_page.series_id).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
      ${JSON.stringify(explicitFeedback)} \n`
	);
}

export async function verifyC374787ExplicitFeedback(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.DISLIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.DISLIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.DISLIKE, Event: \n
			${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.video_page.video_id).equal(
		parseInt(id),
		`componentInteraction.video_page.video_id===${id}.TOGGLE_ON, Event: \n
			${JSON.stringify(explicitFeedback)} \n`
	);
}
export async function verifyC374785ExplicitFeedback(id) {
	let explicitFeedback;
	let i = 1;
	while (explicitFeedback === undefined && i < 16) {
		const pulletEvents = await getMatchedEventsFromLastEvent(
			Events.explicit_feedback,
			10 + i
		);
		explicitFeedback = pulletEvents.find(
			(event) =>
				event.explicit_feedback.content.user_interaction &&
				event.explicit_feedback.content.user_interaction ===
					UserInteraction.LIKE
		);
		i++;
	}
	expect(explicitFeedback.explicit_feedback.content.user_interaction).equal(
		UserInteraction.LIKE,
		`explicitFeedback.explicit_feedback.content.user_interaction=== UserInteraction.LIKE, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.content.series_id).equal(
		parseInt(id),
		`componentInteraction.video_page.viseries_iddeo_id===${id}.TOGGLE_ON, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
	expect(explicitFeedback.explicit_feedback.series_detail_page.series_id).equal(
		parseInt(id),
		`componentInteraction.series_detail_page.series_id===${id}.TOGGLE_ON, Event: \n
    ${JSON.stringify(explicitFeedback)} \n`
	);
}
