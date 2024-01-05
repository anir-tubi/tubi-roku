const path = require('path');
const http = require('http');
const fs = require('fs');
const request = require('request');
const Rx = require('rx');
const SSDPClient = require('node-ssdp').Client;
const log = require('fancy-log');
import { expect } from 'chai';
import { odc } from 'roku-test-automation';

const proxyServer = 'https://qa-proxy.staging-public.tubi.io';
let DEVICE_ID_APP;

async function getDeviceId() {
	const { value } = await odc.getValue({
		base: 'global',
		keyPath: 'constants.deviceInfo.deviceId',
	});
	process.env.DEVICE_ID_APP = value;
}

export const eventOnStep = async (number) => {
	const events = await getAnalyticsEvents();
	return events[number].event;
};

export const eventOnLastStep = async () => {
	const events = await getAnalyticsEvents();
	return events[events.length - 1].event;
};

export const fullAnalyticEventOnStep = async (number) => {
	const events = await getAnalyticsEvents();
	return events[number];
};

export const fullAnalyticEventOnSteps = async (numbers) => {
	const result = [];
	const events = await getAnalyticsEvents();
	numbers.forEach((ev) => {
		if (ev >= events.length) {
			result.push(events[events.length - 1]);
		} else {
			result.push(events[ev]);
		}
	});
	return result;
};

export const eventOnSteps = async (numbers) => {
	const result = [];
	const events = await getAnalyticsEvents();
	numbers.forEach((ev) => {
		console.log(events[ev]);
		if (ev >= events.length) {
			result.push(events[events.length - 1].event);
		} else {
			result.push(events[ev].event);
		}
	});
	return result;
};

export const fullEventOnSteps = async (numbers) => {
	const result = [];
	const events = await getAnalyticsEvents();
	numbers.forEach((ev) => {
		if (ev >= events.length) {
			result.push(events[events.length - 1]);
		} else {
			result.push(events[ev]);
		}
	});
	return result;
};

export const getMatchedEvents = async (numbers, firstObj) => {
	const result = await eventOnSteps(numbers);
	const event = null;
	const events = [];
	result.forEach((ev) => {
		if (ev[firstObj] !== undefined) {
			events.push(ev);
		}
	});
	return events;
};

export const getMatchedEventsFromLastEvent = async (eventObj, fromLast) => {
	const returnEvents = [];
	const events = await getAnalyticsEventsMatchedFromLastEvent(
		eventObj,
		fromLast
	);
	events.forEach((ev) => {
		returnEvents.push(ev.event);
	});
	return returnEvents;
};

export const getMatchedFullEventsFromLastEvent = async (eventObj, fromLast) => {
	const returnEvents = await getAnalyticsEventsMatchedFromLastEvent(
		eventObj,
		fromLast
	);
	return returnEvents;
};

export async function createNewTestInProxy() {
	await getDeviceId();
	const url = `${proxyServer}/roku/test`;
	const data = { deviceId: process.env.DEVICE_ID_APP, testStarted: 'true' };
	const response = await request.post({ url: url, json: data });
	const responseBody = JSON.parse(response.body);
	if (typeof responseBody.warningMessage !== 'undefined') {
		expect(responseBody.testStarted).equal('true');
		log(
			`Created new bucket in QA Proxy, but previous bucket not closed: ${responseBody.warningMessage}`
		);
	} else {
		expect(responseBody.testStarted).equal('true');
	}
}

export async function createNewLiveNewsTestInProxy() {
	await getDeviceId();
	const url = `${proxyServer}/roku/test/liveNews`;
	const data = { deviceId: process.env.DEVICE_ID_APP, testStarted: 'true' };
	await request.post({ url: url, json: data }, (err, response, body) => {
		if (err) {
			log(`Error creating new bucket in QA proxy: ${err}`);
		}
		if (typeof body.warningMessage !== 'undefined') {
			expect(body.docs.testStarted).equal(true);
			log(
				`Created new bucket in QA Proxy, but previous bucket not closed: ${body.warningMessage}`
			);
		} else {
			expect(body.testStarted).equal(true);
		}
	});
}

export async function closeTestInProxy() {
	const url = `${proxyServer}/roku/${process.env.DEVICE_ID_APP}`;
	await request.put({ url: url }, (err, response, body) => {
		if (err) {
			log(err);
		}
		if (typeof body.Error !== 'undefined') {
			throw body.Error;
		} else {
			expect(body.testStarted).equal(false);
		}
	});
}

export async function closeLiveNewsTestInProxy() {
	const url = `${proxyServer}/roku/liveNews/${DEVICE_ID_APP}`;
	await request.put({ url: url }, (err, response, body) => {
		if (err) {
			log(err);
		}
		if (typeof body.Error !== 'undefined') {
			throw body.Error;
		} else {
			expect(body.testStarted).equal(false);
		}
	});
}

async function checkMandatoryElementsInEventsRoku(events) {
	events.forEach((event) => {
		const jsonObject = JSON.stringify(event);
		expect(event.device.os).to.match(
			/Roku|roku/,
			`Each event has to contain device.os event: \n ${jsonObject}`
		);
		expect(event.app.platform).to.match(
			/Roku|roku|ROKU/,
			`Each event has to contain device.os event: \n ${jsonObject}`
		);
		expect(event.sent_timestamp).to.match(
			/2024-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/,
			`Each event has to contain sent_timestamp event: \n ${jsonObject}`
		);
		expect(event.connection.network).to.match(
			/WIFI|wifi|ETHERNET/,
			`Each event has to contain connection.network event: \n ${jsonObject}`
		);
	});
}

async function checkMandatoryElementsInEvents(events) {
	await checkMandatoryElementsInEventsRoku(events);
	events.forEach((event) => {
		const jsonObject = JSON.stringify(event);
		expect(event.request.key).to.match(
			/./,
			`Each event has to contain request.key event: \n ${jsonObject}`
		);
		expect(event.device.device_id).to.match(
			/./,
			`Each event has to contain device.device_id event: \n ${jsonObject}`
		);
		expect(event.device.manufacturer).to.match(
			/./,
			`Each event has to contain device.manufacturer event: \n ${jsonObject}`
		);
		expect(event.device.model).to.match(
			/./,
			`Each event has to contain device.manufacturer event: \n ${jsonObject}`
		);
		expect(event.device.os_version).to.match(
			/[\d.]/,
			`Each event has to contain device.os_version event: \n ${jsonObject}`
		);
		expect(event.device.user_agent).to.match(
			/./,
			`Each event has to contain user_agent event: \n ${jsonObject}`
		);
		expect(event.device.is_mobile).to.match(
			/false/,
			`Each event has to contain is_mobile event: \n ${jsonObject}`
		);
		expect(event.device.device_width).to.match(
			/\d/,
			`Each event has to contain device_width event: \n ${jsonObject}`
		);
		expect(event.device.device_height).to.match(
			/\d/,
			`Each event has to contain device_height event: \n ${jsonObject}`
		);
		expect(event.app.app_version_numeric).to.match(
			/[\d.]/,
			`Each event has to contain app.app_version_numeric event: \n ${jsonObject}`
		);
		expect(event.app.app_height).to.match(
			/\d/,
			`Each event has to contain app.app_height event: \n ${jsonObject}`
		);
		expect(event.app.app_width).to.match(
			/\d/,
			`Each event has to contain app.app_version_width event: \n ${jsonObject}`
		);
	});
}

export const getAnalyticsEvents = async () => {
	let bodyResponse;
	try {
		await new Promise((res, rej) => {
			const url = `${proxyServer}/roku/${process.env.DEVICE_ID_APP}`;
			request.get({ url: url }, (err, response, body) => {
				if (err) {
					rej(err);
					return;
				}
				if (response.statusCode === 500 || response.statusCode === 502) {
					log(`QA proxy returns 500 or 502`);
					rej(response.statusCode);
					return;
				}
				bodyResponse = JSON.parse(body);
				if (typeof bodyResponse.Error !== 'undefined') {
					rej(response.statusCode);
				}
				res(bodyResponse);
			});
		});
		await checkMandatoryElementsInEvents(bodyResponse.events);
		return bodyResponse.events;
	} catch (error) {
		console.error('An error occurred:', error);
		throw error;
	}
};

export const getAnalyticsEventsMatchedFromLastEvent = async (
	eventObj,
	fromLast
) => {
	let responseBody;
	try {
		await new Promise((res, rej) => {
			const url = `${proxyServer}/roku/${process.env.DEVICE_ID_APP}/events?${eventObj}&inEventsFromLast=${fromLast}`;
			request.get({ url: url }, (err, response, body) => {
				if (err) {
					rej(err);
					return;
				}
				if (response.statusCode === 500 || response.statusCode === 502) {
					log(`QA proxy returns 500 or 502`);
					rej(response.statusCode);
					return;
				}
				responseBody = JSON.parse(body);
				if (typeof responseBody.Error !== 'undefined') {
					rej(response.statusCode);
				}
				res(responseBody);
			});
		});
		await checkMandatoryElementsInEvents(responseBody.events);
		return responseBody.events;
	} catch (error) {
		console.error('An error occurred:', error);
		throw error;
	}
};

export const getLiveNewsManifest = async () => {
	let bodyResponse;
	const url = `${proxyServer}/roku/liveNews/${DEVICE_ID_APP}/`;
	await request.get({ url: url }, (err, response, body) => {
		if (err) {
			log(err);
		}
		if (response.statusCode === 500 || response.statusCode === 502) {
			throw response.statusCode;
		}
		bodyResponse = body;
	});
	return bodyResponse.liveNews;
};

export const getSeekEvent = async () => {
	let responseBody;
	await new Promise((res, rej) => {
		const url = `${proxyServer}/roku/${process.env.DEVICE_ID_APP}/event?seek`;
		request.get({ url: url }, (err, response, body) => {
			if (err) {
				rej(err);
			}
			if (response.statusCode === 500 || response.statusCode === 502) {
				log(`QA proxy returns 500 or 502`);
				throw response.statusCode;
			}
			responseBody = JSON.parse(body);
			if (typeof responseBody.Error !== 'undefined') {
				throw responseBody.Error;
			}
			res(responseBody);
		});
	});
	await checkMandatoryElementsInEvents(responseBody.events);
	return responseBody.events;
};

export const getResumeAfterBreakEvents = async () => {
	let bodyResponse;
	const url = `${proxyServer}/roku/${DEVICE_ID_APP}/event?resume_after_break`;
	await request.get({ url: url }, (err, response, body) => {
		if (err) {
			log(err);
		}
		if (response.statusCode === 500 || response.statusCode === 502) {
			throw response.statusCode;
		}
		bodyResponse = body;
	});
	await checkMandatoryElementsInEvents(bodyResponse.events);
	return bodyResponse.events;
};
