const path = require('path');
const http = require('http');
const fs = require('fs');
const request = require('request');
const Rx = require('rx');
const SSDPClient = require('node-ssdp').Client;
import { ecp, utils, proxy } from 'roku-test-automation';
const log = require('fancy-log');
import { expect } from 'chai';
import { odc } from 'roku-test-automation';
import { EventsValues } from '../../utils/constants';

export interface ClientImpressionRequest {
  url: string;
  method: string;
  requestBody: {
    sent_timestamp: string;
    platform: string;
    device_id: string;
    personalization_id: string;
    containers: {
      id: string;
      contents: {
        series_id?: number;
        video_id?: number;
        row: number;
        col: number;
        duration: number;
      }[];
    }[];
    [key: string]: any;
  };
}

export interface ImpressionEvent {
  sent_timestamp: string;
  platform: string;
  device_id: string;
  personalization_id: string;
  containers: {
    id: string;
    contents: {
      video_id?: number;
      series_id?: number;
      row: number;
      col: number;
      duration: number;
    }[];
  }[];
  [key: string]: any;
}

export async function waitForClientImpressionEvent(filter: (impressionEvent: ImpressionEvent) => boolean, timeout: number = 10000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      console.error('waitForRequest failed');
      reject(new Error('waitForRequest timeout'));
    }, timeout);
    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('user-signals')) {
          console.log('Request intercepted', args.requestBody);
          checkMandatoryElements([args.requestBody]);
          return filter(args.requestBody);
        }
        return false;
      },
      processRequest(args) {
        console.log('Request intercepted', args.url);
        clearTimeout(timer);
        args.removeCallback();
        resolve(args.requestBody as ImpressionEvent);
      }
    });
  });
}

export async function waitForNumberClientImpressionEvents(
  amountOfEvents: number,
  filter: (impressionEvent: ImpressionEvent) => boolean,
  timeout: number = 10000
): Promise<ImpressionEvent[]> {
  return new Promise((resolve, reject) => {
    const matchingEvents: ImpressionEvent[] = [];
    const timer = setTimeout(() => {
      console.error(`waitForNumberRequests failed: Only ${matchingEvents.length} events collected out of ${amountOfEvents}`);
      reject(new Error(`waitForNumberRequests timeout: Only ${matchingEvents.length} events collected out of ${amountOfEvents}`));
    }, timeout);

    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('user-signals')) {
          console.log('Request intercepted', args.requestBody);
          checkMandatoryElements([args.requestBody]);
        }
        return args.url.includes('user-signals') && filter(args.requestBody);
      },
      processRequest(args) {
        console.log('Request intercepted', args.url);
        matchingEvents.push(args.requestBody as ImpressionEvent);
        if (matchingEvents.length >= amountOfEvents) {
          clearTimeout(timer);
          args.removeCallback();
          resolve(matchingEvents);
        }
      }
    });
  });
}

export async function waitForNumberClientImpressionEventsOrEmpty(
  amountOfEvents: number,
  filter: (impressionEvent: ImpressionEvent) => boolean,
  timeout: number = 10000
): Promise<ImpressionEvent[]> {
  return waitForNumberClientImpressionEvents(amountOfEvents, filter, timeout).catch(() => []);
}

export async function waitForClientImpressionEventsForTime(
  filter: (impressionEvent: ImpressionEvent) => boolean,
  duration: number = 10000
): Promise<ImpressionEvent[]> {
  return new Promise((resolve) => {
    const matchingEvents: ImpressionEvent[] = [];
    const timer = setTimeout(() => {
      console.log(`waitForClientImpressionEventsForTime: Time expired. Collected ${matchingEvents.length} events.`);
      resolve(matchingEvents); // Resolve with all collected events
    }, duration);
    proxy.addCallback({
      shouldProcess: (args) => {
        if (args.url.includes('user-signals')) {
          console.log('Request intercepted', args.requestBody);
          checkMandatoryElements([args.requestBody]);
          return filter(args.requestBody as ImpressionEvent);
        }
      },
      processRequest(args) {
        matchingEvents.push(args.requestBody as ImpressionEvent);
      }
    });
  });
}

export function checkMandatoryElements(impressionEvents: ImpressionEvent[]) {
  impressionEvents.forEach((impressionEvent) => {
    const currentTime = getCurrentDateTimeUTC();
    expect(impressionEvent.sent_timestamp).to.match(
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/,
      `Each event has to contain a valid sent_timestamp. Event: \n ${impressionEvent}`
    );
    expect(isWithinTenMinutes(impressionEvent.sent_timestamp, currentTime)).to.be.true;
    expect(impressionEvent.platform).to.match(
      /Roku|roku|Roku OS|ROKU/,
      `Each event has to contain device.os event: \n ${impressionEvent}`
    );
    expect(impressionEvent.device_id).to.match(
      /^[a-f0-9-]{36}$/,
      `Each event has to contain a valid device_id. Event: \n ${impressionEvent}`
    );
    expect(impressionEvent.personalization_id).to.match(
      /^[a-f0-9-]{36}$/,
      `Each event has to contain a valid personalization_id. Event: \n ${impressionEvent}`
    );
  });
}

function isWithinTenMinutes(sentTimestamp: string, currentTime: string): boolean {
  const sentTime = new Date(sentTimestamp);
  const currentTimeWithSeconds = new Date(`${currentTime}:00.000Z`);

  const diffInMilliseconds = Math.abs(sentTime.getTime() - currentTimeWithSeconds.getTime());
  const diffInMinutes = diffInMilliseconds / (1000 * 60);

  return diffInMinutes <= 10;
}



export function getCurrentDateTimeUTC(): string {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, '0'); // Months are zero-based
  const day = String(now.getUTCDate()).padStart(2, '0');
  const hours = String(now.getUTCHours()).padStart(2, '0');
  const minutes = String(now.getUTCMinutes()).padStart(2, '0');

  return `${year}-${month}-${day}T${hours}:${minutes}`;
}
