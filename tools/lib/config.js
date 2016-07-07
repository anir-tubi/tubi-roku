const bluebird = require('bluebird');
const extend = require('node.extend');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const cwd = path.join(process.cwd(), 'config');
const defaultProfile = 'default';

bluebird.promisifyAll(fs);

/**
 * Parse a yml file. If it does not exist, return {}.
 * @param profile: ['default', 'dev', 'staging', 'production']
 * @returns {*}
 */
function parse(profile) {
  const filename = path.join(cwd, profile + '.yml');
  if (!fs.existsSync(filename)) return {};
  return yaml.load(fs.readFileSync(filename));
}

/**
 * A simple stringify function to generate equivalent brs value
 * TODO(chris): it doesn't work for nested configuration yet.
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

/**
 * generate a brs function for a configuration section
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
 * load configuration. env specific environment will override defaults.
 *
 * @param env: environment, dev, staging, or production
 * @returns {*}
 */
function load(env) {
  var data = parse(defaultProfile);
  var envData = parse(env);
  return extend(true, data, envData);
}

/**
 * save yml configuration to roku setting script
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
function save(env, filename) {
  const data = load(env);
  fs.openAsync(filename, 'w').then(fd => {
    const functions = Object
        .keys(data)
        .map(key => genConfigFunction(key, data[key]));
    return fs.writeAsync(fd, functions.join('\n'));
  }).then(() => {
    console.log('Generated the file: %s.', filename);
  }).catch(err => {
    console.log(err);
  });
}

/**
 * generate manifest file based on the manifest section
 *
 * @param env: environment, dev, staging, or production
 * @param filename
 */
function genManifest(env, filename) {
  fs.openAsync(filename, 'w').then(fd => {
    const data = load(env).manifest;
    const content = Object.keys(data).map(key => {
      return `${key}=${data[key]}`;
    }).join('\n');
    return fs.writeAsync(fd, content);
  }).then(() => {
    console.log('Generated the file %s.', filename);
  }).catch(err => {
    console.log(err);
  })
}

exports.load = load;
exports.save = save;
exports.genManifest = genManifest;
