import { Events } from '../utils/constants';
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
