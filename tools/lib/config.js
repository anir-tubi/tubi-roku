'use strict';
const bluebird = require('bluebird');
const extend = require('node.extend');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const localIp = require('my-local-ip')();
const templating = require('./templating');
const cwd = path.join(process.cwd(), 'config');
const defaultProfile = 'default';
const buildProfile = 'build';

bluebird.promisifyAll(fs);

/**
 * Parse a yml file, inserting special values. If it does not exist, return {}.
 * @param profile: ['default', 'dev', 'staging', 'production']
 * @param templateValues: object whose values will be rendered into the yaml profile template before parsing
 * @returns {*}
 */
function parse(profile, templateValues={}) {
  const filename = path.join(cwd, `${profile}.yml`);
  if (!fs.existsSync(filename)) return {};
  let template = fs.readFileSync(filename, 'utf8')
  let rendered = templating.renderTemplate(template, templateValues);
  return yaml.load(rendered);
}


/**
 * A simple function that returns the version number as defined in build.yml
 * @returns string (ex. '2_1_3')
 */
function getBuildTag(isMinor, isDot) {
  let build = parse(buildProfile, {});
  return formatBuildTag(build, isMinor, isDot);
}

function formatBuildTag(build, isMinor, isDot) {
  let connector = '.';
  if (!isDot || isDot === 'false') {
    connector = '_';
  }
  if (!isMinor || isMinor === 'false') {
    return `${build.manifest.major_version}${connector}${build.manifest.minor_version}${connector}${build.manifest.build_version}`;
  } else {
    return `${build.manifest.major_version}${connector}${build.manifest.minor_version}`;
  }
}


/**
 * load configuration. env specific environment will override defaults.
 *
 * @param env: environment, dev, staging, or production
 * @returns {*}
 */
function load(env) {
  var build = parse(buildProfile);
  const templateValues = {
    hostUri: `${localIp}:8090`,
    versionUnderscored: formatBuildTag(build, false, false),
    versionMinorDotted: formatBuildTag(build, true, true),
  };
  var data = parse(defaultProfile, templateValues);
  var envData = parse(env, templateValues);
  return extend(true, data, envData, build);
}


function incrementBuildNumber() {
  let build = parse(buildProfile, {});

  build.manifest.build_version = build.manifest.build_version + 1
  build.component_library_manifest.build_version = build.manifest.build_version
  const buildPath = path.join(cwd, `${buildProfile}.yml`);

  fs.openAsync(buildPath, 'w').then(fd => {
    const data = yaml.dump(build);
    return fs.writeAsync(fd, data);
  }).then(() => {
    console.log('Incremented the build number to %d.%d.%d', build.manifest.major_version, build.manifest.minor_version, build.manifest.build_version);
  }).catch(err => {
    console.log(err);
  });
}


module.exports = {
  load,
  incrementBuildNumber,
  getBuildTag
};
