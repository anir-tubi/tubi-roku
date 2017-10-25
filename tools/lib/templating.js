const Handlebars = require('handlebars');
const fs = require('fs');
const path = require('path');
const localIp = require('my-local-ip')();
const bluebird = require('bluebird');
const {parse} = require('./config');

bluebird.promisifyAll(fs);


function getHotpatchSourcePath(buildProfile, ui, build) {
  let filename = '';
  if (buildProfile === 'dev'){
    filename = `dev.${ui}.brs`;
  } else if (buildProfile === 'staging' || buildProfile === 'production' || buildProfile === 'default' ) {
    filename = `${build.major_version}.${build.minor_version}.${ui}.brs`;
  }

  const pathToHotpatch = path.join(process.cwd(), 'src', 'hotpatch', filename);

  return pathToHotpatch;
}


function getHotpatchDestinationPath(ui, build) {
  const filename = `${build.major_version}.${build.minor_version}.${ui}.brs`;
  return path.join(process.cwd(), 'build', 'hotpatch', filename);
}


function getRemoteComponentsLocation(buildProfile, build) {
  const filename = `tubi_remote_components_${build.major_version}_${build.minor_version}_${build.build_version}.pkg`;

  const config = parse(buildProfile, true);
  const {settings} = config;
  const {remoteComponentsHost} = settings;
  return `${remoteComponentsHost}/${filename}`;
}


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

  const build = parse('build', true).manifest;
  const versionUnderscored = `${build.major_version}_${build.minor_version}_${build.build_version}`;

  const uis = ['oldui', 'newui'];

  uis.forEach(ui => {
    const hotpatchSourcePath = getHotpatchSourcePath(buildProfile, ui, build);
    const hotpatchDestinationPath = getHotpatchDestinationPath(ui, build);
    const remoteComponentsLocation = getRemoteComponentsLocation(buildProfile, build);

    //this sets up the template values that will be placed in the template
    const handlebarData = {
      profile: buildProfile,
      versionUnderscored,
      remoteComponentsLocation,
    };

    //read the hotpatch source file, fill the template, and write to output directory
    if (hotpatchSourcePath !== '') {
      fs.readFileAsync(hotpatchSourcePath, 'utf8')
      .then((data) => {
        const template = Handlebars.compile(data, { noEscape: true });
        const hotpatchOutput = template(handlebarData);
        return fs.writeFileAsync(hotpatchDestinationPath, hotpatchOutput);
      })
      .then(() => {
        console.log(`Hotpatch for ${ui} built.`);
      })
      .catch(err => {
        console.log(err);
      });
    }
  });
}

module.exports = { createHotpatch };