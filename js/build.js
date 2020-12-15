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
 * @param env: environment, dev, staging, or production
 * @param filename
 * @param manifestName
 */
function createManifest(env, filename, manifestName) {
  fs.openAsync(filename, 'w').then(fd => {
    const data = load(env)[manifestName];
    const content = Object.keys(data).map(key => {
      return `${key}=${data[key]}`;
    }).join('\n');
    return fs.writeAsync(fd, content);
  }).then(() => {
    log('Generated the file %s.', filename);
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
 * @param env: environment, dev, staging, or production
 * @param filename: output filename
 */
function createSettings(env, filename) {
  const data = load(env);
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
