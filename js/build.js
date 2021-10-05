'use strict';

const bluebird = require('bluebird');
const { load, getBuildTag } = require('./config');
const fs = require('fs');
const path = require('path');
const log = require('fancy-log');

bluebird.promisifyAll(fs);

/**
 * generate manifest file based on the manifest section
 *
 * @param options: object with at least the keys 'env' (as "production", "qa", etc.), and "port"
 * @param filename
 * @param manifestName
 */
function createManifest(options, filename, manifestName) {
  fs.openAsync(filename, 'w').then(fd => {
    const data = load(options)[manifestName];

    // reduce the array so as to not include manifest keys that don't have a value.
    // This can happen if no bs_consts are defined.
    var content = Object.keys(data).reduce((accumulatedValue, key) => {
      if (data[key]) {
        accumulatedValue.push(`${key}=${data[key]}`);
        return accumulatedValue;
      } else {
        return accumulatedValue;
      }
    }, []).join('\n');

    return fs.writeAsync(fd, content);
  }).then(() => {
    log(`Generated the file ${filename}`);
  }).catch(err => {
    console.log(err);
  })
}


/**
 * generate a roku setting script from build configuration
 *
 * format:
 * Function getSettings ()
 *   return {
 *     ...
 *   }
 * end Function
 *
 * Function getTheme ()
 *   return {
 *     ...
 *   }
 * end Function
 *
 * @param options: object with at least the keys 'env' (as "production", "qa", etc.), and "port"
 * @param filename: output filename
 */
function createSettings(options, filename) {
  const data = load(options);
  fs.openAsync(filename, 'w').then(fd => {
    const functions = Object
        .keys(data)
        .map(key => genConfigFunction(key, data[key]));
    return fs.writeAsync(fd, functions.join('\n'));
  }).then(() => {
    log('Generated the file: %s.', filename);
  }).catch(err => {
    console.log(err);
  });
}


/**
 * generate a brs function for a configuration section
 *
 * @param name
 * @param data
 * @returns {string}
 */
function genConfigFunction(name, data) {
  const capitalize = s => s[0].toUpperCase() + s.substr(1).toLowerCase();

  const space2 = ' '.repeat(2);
  const space4 = space2.repeat(2);
  const prefix = 'function get'.concat(capitalize(name), ' ()\n')
      .concat(space2, 'return {\n');
  const suffix = space2.concat('}\n', 'end function\n');
  const body = Object.keys(data).map(key => {
    const value = stringify(data[key]);
    return space4.concat(key, ': ', value);
  });

  return prefix.concat(body.join('\n'), '\n', suffix);
}

/**
 * A simple stringify function to generate equivalent brs value
 *
 * @param value
 * @returns {*}
 */
function stringify(value) {
  switch(typeof value) {
    case 'number': return value;
    default: return JSON.stringify(value);
  }
}


module.exports = {
  createManifest,
  createSettings,
}
