'use strict';

const { load } = require('./config');
const fs = require('fs');
const log = require('fancy-log');

/**
 * generate manifest file based on the manifest section
 *
 * @param options: object with at least the keys 'env' (as "production", "qa", etc.), and "port"
 * @param filename
 * @param manifestName
 */
function createManifest(options, filename, manifestName) {
  const data = load(options)[manifestName];
  // reduce the array so as to not include manifest keys that don't have a value.
  // This can happen if no bs_consts are defined.
  var content = Object.keys(data).reduce((accumulatedValue, key) => {
    if (data[key] !== undefined) {
      accumulatedValue.push(`${key}=${data[key]}`);
      return accumulatedValue;
    } else {
      return accumulatedValue;
    }
  }, []).join('\n');
  fs.writeFileSync(filename, content);
  log(`Generated the file: ${filename}.`);
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
  const functions = Object.keys(data).map(key => genConfigFunction(key, data[key]));
  fs.writeFileSync(filename, functions.join('\n'));
  log(`Generated the file: ${filename}.`);
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
