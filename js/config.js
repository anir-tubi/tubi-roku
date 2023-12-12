'use strict';
const extend = require('node.extend');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const localIp = require('my-local-ip')();
const templating = require('./templating');
const cwd = path.join(process.cwd(), 'config');
const defaultProfile = 'default';
const buildProfile = 'build';

/**
 * Parse a yml file, inserting special values. If it does not exist, return {}.
 * @param profile: ['default', 'dev', 'staging', 'production']
 * @param templateValues: object whose values will be rendered into the yaml profile template before parsing
 * @returns {*}
 */
function parse(profile, templateValues={}) {
  const filename = path.join(cwd, `${profile}.yml`);
  if (!fs.existsSync(filename)) return {};
  let template = fs.readFileSync(filename, 'utf8');
  let rendered = templating.renderTemplate(template, templateValues);
  const yamlOutput = yaml.load(rendered);
  return removeNullsFromObject(yamlOutput)
}


/**
 * A simple function that returns the version number as defined in build.yml with version out to section specified by includeTo param
 * @includeTo 'minor' outputs "2.19", 'build' outputs "2.19.0", 'revision' outputs "2.19.0.0"
 * @connector string - string we join the version parts together with. Defaults to `_`
 * @returns string
 */
function getBuildTag(includeTo, connector = '_') {
  let build = parse(buildProfile, {});
  return formatBuildTag(build, includeTo, connector);
}

/**
 * A simple function that returns the version number as defined in build param with version out to section specified by includeTo param
 * @build build object - build information including manifest object that we pull version info from
 * @includeTo string - 'minor' outputs "1.2", 'build' outputs "1.2.3", 'revision' outputs "1.2.3.4"
 * @connector string - string we join the version parts together with. Defaults to '_'. Use '.' to connect with dots.
 * @returns string
 */
function formatBuildTag(build, includeTo, connector = '_') {
  const buildParts = [];
  const manifest = build.manifest;
  buildParts.push(manifest.major_version);
  buildParts.push(manifest.minor_version);

  if (includeTo === 'build' || includeTo === 'revision') {
    buildParts.push(manifest.build_version);
  }

  if (includeTo === 'revision') {
    buildParts.push(manifest.revision_version);
  }

  return buildParts.join(connector);
}


/**
 * load configuration. env specific environment will override defaults.
 *
 * @param options: object with at least the keys 'env' (as "production", "qa", etc.), and "port"
 * @returns {*}
 */
function load(options) {
  const env = options.config;
  const { port } = options;
  const overrides = options.overrides ?? {};
  const build = parse(buildProfile);

  // Preliminarily gather all the values from the default/environment/build ymls.
  // This allows values from the ymls to be placed into the templateValue object below.
  // The values in templateValues will replace handlebar template strings in the ymls
  // in subsequent calls to parse().
  // In other words, running parse() twice per profile/file allows us to fill in template
  // placeholders with template values that exist in the same profile/file.
  const defaultDataPre = parse(defaultProfile, {});
  const envDataPre = parse(env, {});
  const overWrittenDataPre = extend(true, defaultDataPre, envDataPre, build, overrides);

  let templateValues = {
    localHostAddress: `${localIp}`,
    localHostUri: `${localIp}:${port}`,
    versionUnderscored: formatBuildTag(build, 'revision'),
    versionMinorUnderscored: formatBuildTag(build, 'minor'),
    versionMinorDotted: formatBuildTag(build, 'minor', '.'),
    remoteComponentLibProvided: `TubiRemoteLib-${build.component_library_manifest.build_version}`,
    fileType: overWrittenDataPre.settings.remoteComponentsExtension,
    bsConst: getBsConstsFromSettings(overWrittenDataPre.settings),
  };

  const defaultDataPost = parse(defaultProfile, templateValues);
  const envDataPost = parse(env, templateValues);

  // Squashes the build, envData, and defaultData objects into a single object.
  // Overwriting (if necessary) happens in reverse parameter order (ie. build overwrites envData, etc.)
  return extend(true, defaultDataPost, envDataPost, build, overrides);
}


function incrementBuildNumber(incrementAmount = 1) {
  let build = parse(buildProfile, {});

  build.manifest.build_version = build.manifest.build_version + incrementAmount
  build.component_library_manifest.build_version = build.manifest.build_version
  build.starter_library_manifest.build_version = build.manifest.build_version
  build.manifest.revision_version = 0
  build.component_library_manifest.revision_version = build.manifest.revision_version
  build.starter_library_manifest.revision_version = build.manifest.revision_version
  const buildPath = path.join(cwd, `${buildProfile}.yml`);
  const data = yaml.dump(build);
  fs.writeFileSync(buildPath, data);
  console.log('Incremented the build number to %d_%d_%d_%d', build.manifest.major_version, build.manifest.minor_version, build.manifest.build_version, build.manifest.revision_version);
}


function incrementRevisionNumber() {
  let build = parse(buildProfile, {});

  build.manifest.revision_version = build.manifest.revision_version + 1
  build.component_library_manifest.revision_version = build.manifest.revision_version
  build.starter_library_manifest.revision_version = build.manifest.revision_version
  const buildPath = path.join(cwd, `${buildProfile}.yml`);
  const data = yaml.dump(build);
  fs.writeFileSync(buildPath, data);
  console.log('Incremented the build number to %d_%d_%d_%d', build.manifest.major_version, build.manifest.minor_version, build.manifest.build_version, build.manifest.revision_version);
}


function getBsConstsFromSettings(settings) {
  const bsConst = settings.bs_const;

  if (bsConst) {
    return Object.keys(bsConst)
    .map((key) => {
      return `${key}=${bsConst[key]}`;
    })
    .join(';');
  } else {
    return '';
  }
}


// removes key/value pairs from the passed in object if the value is null.
// If the value is an object, recursively removes nulls from child objects.
function removeNullsFromObject(obj){
  for (const prop in obj) {
    const value = obj[prop];
    if (value === null) {
      delete obj[prop];
    } else if (typeof value === 'object' && value !== null) {
      // only recurse for explicit "objects" (as opposed to strings or functions)
      // which are also technically "objects" in JS land
      removeNullsFromObject(value);
    }
  }
  return obj
}


module.exports = {
  load,
  incrementBuildNumber,
  incrementRevisionNumber,
  getBuildTag
};
