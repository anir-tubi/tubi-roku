'use strict';

const archiver = require('archiver');
const bluebird = require('bluebird');
const { load, getBuildTag } = require('./config');
const fs = require('fs');
const path = require('path');
const templating = require('./templating');

bluebird.promisifyAll(fs);

/**
 * generate a hotpatch file from a template
 *
 * @param buildProfile
 */
function createHotpatch(buildProfile) {
  const validBuildProfiles = {
    dev: true,
    staging: true,
    production: true,
    default: true,
  };

  if (!validBuildProfiles[buildProfile]) {
    console.log('Hotpatch not built because of non valid build profile. Must be one of dev, staging, production, default.');
    return;
  }

  const build = load(buildProfile)
  const versionUnderscored = getBuildTag(false, false);
  const hotpatchFilename = `${getBuildTag(true, true)}.brs`;
  const hotpatchSourcePath = path.join(process.cwd(), 'src', 'hotpatch', hotpatchFilename);
  const hotpatchDestinationPath = path.join(process.cwd(), 'build', 'hotpatch', hotpatchFilename);
  const remoteComponentsLocation = getRemoteComponentsLocation(buildProfile, build);

  // this sets up the template values that will be placed in the template
  const handlebarData = {
    profile: buildProfile,
    versionUnderscored,
    remoteComponentsLocation,
  };

  // read the hotpatch source file, fill the template, and write to output directory
  if (hotpatchSourcePath !== '') {
    let template = fs.readFileSync(hotpatchSourcePath, 'utf8')
    let hotpatchOutput = templating.renderTemplate(template, handlebarData)
    fs.writeFileAsync(hotpatchDestinationPath, hotpatchOutput)
    .then(() => {
      console.log(`Hotpatch built.`);
    })
    .catch(err => {
      console.log(err);
    });
  }
}

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
    console.log('Generated the file %s.', filename);
  }).catch(err => {
    console.log(err);
  })
}

function getRemoteComponentsLocation(buildProfile, build) {
  const configuration = load(buildProfile, true);
  const { settings } = configuration;
  const { remoteComponentsHost, remoteComponentsExtension } = settings;
  const filename = `tubi_remote_components_${getBuildTag(false, false)}.${remoteComponentsExtension}`
  return `${remoteComponentsHost}/${filename}`;
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
    console.log('Generated the file: %s.', filename);
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


/**
 * create a zip file from recursive contents of a directory
 *
 * @param name
 * @param data
 * @returns {string}
 */
function zipDir(dirPath) {
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
  createHotpatch,
  createManifest,
  createSettings,
  zipDir
}
