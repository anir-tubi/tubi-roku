import { Events } from '../utils/constants';
import { getMatchedEventsFromLastEvent } from '../utils/network/qaProxy';
import { expect } from 'chai';
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
