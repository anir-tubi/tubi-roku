const bluebird = require('bluebird');
const extend = require('node.extend');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const localIp = require('my-local-ip')();
// const jszip = require('jszip');
const archiver = require('archiver');

const cwd = path.join(process.cwd(), 'config');
const defaultProfile = 'default';
const buildProfile = 'build';

bluebird.promisifyAll(fs);

/**
 * Parse a yml file, inserting special values. If it does not exist, return {}.
 * @param profile: ['default', 'dev', 'staging', 'production']
 * @param withReplace: boolean, dictates if replacing functionality will be performed
 * @returns {*}
 */
function parse(profile, withReplace) {
  const filename = path.join(cwd, profile + '.yml');
  if (!fs.existsSync(filename)) return {};
  const raw = fs.readFileSync(filename, { encoding: 'utf8' });

  if (withReplace){
    /* URI-TO-REPLACE is the localhost server of dynamic components zip */
    const remoteComponentDir = localIp + ':8090';
    let rendered = raw.replace(/<<URI-TO-REPLACE>>/g, remoteComponentDir);

    const version = getBuildTag(false, false);
    rendered = rendered.replace(/<<VER-TO-REPLACE>>/g, version);
    return yaml.load(rendered);
  }
  
  return yaml.load(raw);
}


/**
 * A simple function that returns the version number as defined in build.yml
 * @returns string (ex. '2_1_3')
 */
function getBuildTag(isMinor=false, isDot=false) {
  let connector = '.';
  if (!isDot || isDot === 'false') {
    connector = '_';
  }
  
  var build = parse(buildProfile, false);

  if (!isMinor || isMinor === 'false') {
    return `${build.manifest.major_version}${connector}${build.manifest.minor_version}${connector}${build.manifest.build_version}`;
  } else {
    return `${build.manifest.major_version}${connector}${build.manifest.minor_version}`;
  }
}


/**
 * Prints the version number as defined in build.yml
 * @returns string (ex. '2_1_3')
 */
function getBuildTagExternal(isMinor=false, isDot=false) {
  console.log(getBuildTag(isMinor, isDot));
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
  var data = parse(defaultProfile, true);
  var envData = parse(env, true);
  var build = parse(buildProfile, true);
  return extend(true, data, envData, build);
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
function genManifest(env, filename, manifestName) {
  fs.openAsync(filename, 'w').then(fd => {
    const data = load(env)[manifestName];
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


function incrementBuildNumber() {
  let build = parse(buildProfile, true);

  build.manifest.build_version = build.manifest.build_version + 1
  build.component_library_manifest.build_version = build.manifest.build_version
  const buildPath = path.join(cwd, buildProfile + '.yml');

  fs.openAsync(buildPath, 'w').then(fd => {
    const data = yaml.dump(build);
    return fs.writeAsync(fd, data);
  }).then(() => {
    console.log('Incremented the build number to %d.%d.%d', build.manifest.major_version, build.manifest.minor_version, build.manifest.build_version);
  }).catch(err => {
    console.log(err);
  });
}


function zipDir(dirPath) {
  // const zip = new jszip();
  const version = getBuildTag(false, false);

  const localPath = 'build/local';
  const remotePath = 'build/remote';

  // set up the source and destination paths of the zip file
  if (dirPath === localPath) {
    var zipSource = path.join(process.cwd(), localPath);
    var zipName = `tubi_${version}.zip`;
  } else if (dirPath === remotePath) {
    var zipSource = path.join(process.cwd(), remotePath);
    var zipName = `tubi_remote_components_${version}.zip`;
  } else {
    console.log('The directory to be zipped is not recognized. No zip created!');
    return;
  }
  
  const zipDest = path.join(process.cwd(), 'build', zipName);
  const output = fs.createWriteStream(zipDest);
  const archive = archiver('zip', {
    zlib: { level: 9 } // Sets the compression level.
  });

  // listen for all archive data to be written
  // 'close' event is fired only when a file descriptor is involved
  output.on('close', function() {
    console.log(`${zipName} has been successfully created`);
  });

  archive.pipe(output);

  // good practice to catch this error explicitly  
  archive.on('error', function(err) {
    console.log('zip error', dirPath, err);
  });

  archive.directory(zipSource, false);
  archive.finalize();
}


module.exports = {
  parse,
  load,
  save,
  genManifest,
  incrementBuildNumber,
  getBuildTagExternal,
  zipDir,
};
