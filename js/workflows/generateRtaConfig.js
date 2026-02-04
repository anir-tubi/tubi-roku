#!/usr/bin/env node

/**
 * Generates rta-config.json for Roku test automation.
 * 
 * Supports two modes:
 * - Multi-device mode: When ROKU_DEVICES env var is set (JSON array of devices)
 * - Single-device mode: Falls back to ROKU_DEV_TARGET and DEV_PASSWORD env vars
 * 
 * Usage: node js/workflows/generateRtaConfig.js
 */

const fs = require('fs');

/** @constant {string} Path to the output rta-config.json file */
const CONFIG_PATH = './rta-config.json';

/** @constant {string} Path to the example config template file */
const EXAMPLE_CONFIG_PATH = './rta-config.example.json';

/**
 * Generates an RTA config object with the given devices.
 * Uses the example config as the base template and replaces the devices array.
 * 
 * @param {Array<{host: string, password: string}>} devices - Array of device configurations
 * @returns {Object} Complete RTA config object ready for JSON serialization
 */
function generateConfig(devices) {
  if (!fs.existsSync(EXAMPLE_CONFIG_PATH)) {
    console.error(`Template file not found: ${EXAMPLE_CONFIG_PATH}`);
    process.exit(1);
  }
  const config = JSON.parse(fs.readFileSync(EXAMPLE_CONFIG_PATH, 'utf8'));
  config.RokuDevice.devices = devices.map(d => ({ host: d.host, password: d.password }));
  return config;
}

/**
 * Main entry point. Determines device list based on environment variables:
 * - If ROKU_DEVICES is set: Parses JSON array of devices
 * - Otherwise: Uses ROKU_DEV_TARGET and DEV_PASSWORD for a single device
 * 
 * Exits with code 1 on error.
 */
function main() {
  let devices;

  if (process.env.ROKU_DEVICES) {
    // Multi-device mode: parse JSON array
    try {
      devices = JSON.parse(process.env.ROKU_DEVICES);
      if (!Array.isArray(devices) || devices.length === 0) {
        console.error('ROKU_DEVICES must be a non-empty JSON array');
        process.exit(1);
      }
      const invalidDevice = devices.find(d => !d.host || !d.password);
      if (invalidDevice) {
        console.error('Each device in ROKU_DEVICES must have host and password');
        process.exit(1);
      }
      console.log(`Using ${devices.length} device(s) from ROKU_DEVICES`);
    } catch (e) {
      console.error('Failed to parse ROKU_DEVICES:', e.message);
      process.exit(1);
    }
  } else {
    // Single-device mode: use legacy environment variables
    const deviceIp = process.env.ROKU_DEV_TARGET;
    const devicePassword = process.env.DEV_PASSWORD;

    if (!deviceIp || !devicePassword) {
      console.error('Missing required environment variables: ROKU_DEV_TARGET and/or DEV_PASSWORD');
      process.exit(1);
    }

    devices = [{ host: deviceIp, password: devicePassword }];
    console.log('Using single device from ROKU_DEV_TARGET');
  }

  const config = generateConfig(devices);
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 4));
  console.log(`Generated rta-config.json with ${devices.length} device(s)`);
}

main();
