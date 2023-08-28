'use strict';
const {series, src, dest} = require('gulp');
const del = require('del');
const fs = require('fs');
const dedupe = require('gulp-dedupe');
const replace = require('gulp-replace');
const { server, serverClose } = require('gulp-connect');
const filter = require('gulp-filter');
const zip = require('gulp-zip');
const mocha = require('gulp-mocha');
const env = require('gulp-env');
const log = require('fancy-log');
const mkdirp = require('mkdirp');
const prompts = require('prompts');
const { RooibosProcessor, createProcessorConfig } = require('rooibos-cli');
const shell = require('shelljs');
shell.config.silent = true;
const clipboardy = require('clipboardy');
// Uncomment the next line if there are connection issues to the Roku device
// const requestDebug = require('request-debug')(request);

//Importing old build functions
const {load, getBuildTag, incrementBuildNumber, incrementRevisionNumber} = require('./js/config');
const {createManifest, createSettings} = require('./js/build');
const {keypress, deeplink, uploadPkg, signPkg, installWithSquashfs} = require('./js/network');

//Functions to upload and download static string translations
const {downloadTranslations, updateLocalTranslations, uploadTranslations} = require('./js/translate');
const {listUnusedImages,listUnusedTranslations} = require('./js/codeclean.js');
const {replaceColorConstants} = require('./js/colorreplace.js');

// Importing functions with Git functionality
const {NoStackError} = require('./js/utilities');

// Importing functions with Git functionality
const {verifyGit, makeReleasePrs, pushTag, createGithubRelease, findCommitsNotOnProductionBranch, addMissingImagesToRemoteLibrary, findCommitsNotOnCurrentBranch, pushBranch, buildReleaseNotes, buildQaChanges} = require('./js/git');

// Importing functions related to Suitest
const {retrieveSuitestTests, runSuitestTests, convertXpathsToKeyPaths, convertSuitestTest} = require('./js/suitest');

// Importing functions related to Automated Tests
const {runAutomatedTestsCli} = require('./js/automated-tests');

// Importing functions related to Github action runners
const {setupAutomatedTestsGithubActionRunner, startAutomatedTestsGithubActionRunner, removeAutomatedTestsGithubActionRunner} = require('./js/action-runner');

/* Allow some environment variables to drive which config we're building.
   Environment variables are set on options, along with any parameters passed in
   to the gulp command line call.
*/
const options = {
  config: (process.env.ROKU_CONFIG || process.env.ROKU_PROFILE || 'dev'),
  target: process.env.ROKU_DEV_TARGET,
  devPass: (process.env.ROKU_DEV_PASSWORD || process.env.DEV_PASSWORD || ''),
  pkgPass: (process.env.ROKU_PKG_PASSWORD || process.env.PKG_PASSWORD || ''),
  rekeyPkg: '',
  port: 8090,
  telnet: process.env.ROKU_DEV_TELNET
};

// overwrite the config and/or target default options with passed in arguments;
// for example a -staging argument will set options.config to 'staging'
const passedArgs = process.argv.slice(2);


passedArgs.forEach(arg => {
  const allowedConfigs = {
    dev: true,
    production: true,
    qa: true,
    staging: true,
    test: true
  };

  const allowedTelnetConfigs = {
    sametab: true,
  };

  // only allow args with a single preceding "-", ie. '--staging'
  if (arg.slice(0, 2) === '--' && arg.charAt(2) !== '-') {
    // strip any initial "-"
    let strippedArg = arg.slice(2);

    // check for one of the config values
    if (allowedConfigs[strippedArg]) {
      options.config = strippedArg;
    } else if (allowedTelnetConfigs[strippedArg]) {
      options.telnet = strippedArg;
    } else if(strippedArg.split('.').length === 4) {
      //check if the arg is an IP address
      let ipBlocks = strippedArg.split('.');
      let isIp = ipBlocks.reduce((acc, block) => {
        const blockInteger = parseInt(block);
        return (blockInteger >= 0 && blockInteger < 256) ? true : false;
      }, true);

      if (isIp) {
        options.target = strippedArg;
      }
    }
  }
});

log(`PROFILE = ${options.config}`);


// deletes the contents of the build folder, all of which will be recreated.
function clean(done) {
  del.sync(['build/**/*']);
  done();  //inform gulp that the task has completed.
}


// used by: buildLocal/buildInstalled
// gather up the sources, dedupe files and run debug on them
// returns a pipeable stream
function collect(sources, srcOptions) {
  sources.map((source) => {
    log(`Adding ${source}`);
  });
  return src(sources, srcOptions)
        .pipe(dedupe());
        // uncomment the next line for more info on which files are being collected
        // .pipe(debug())
}


function zipAsPromise(srcPath, zipPath, destPath) {
  return new Promise((res, rej) => {
    let stream = src(srcPath)
      .pipe(zip(zipPath))
      .pipe(dest(destPath));

    stream.on('end', () => {
      res();
    });
  });
}


function buildInstalled() {
  const buildTag = getBuildTag('revision');
  let build = new Promise((res, rej) => {
    /* Installed bundle */
    mkdirp.sync(`${process.env.PWD}/build/local/source`);
    let { settings } = load(options);

    let sources = [
      'src/channel/**/*',
      //make sure not to include the following files
      '!src/channel/**/.keep',
      '!src/channel/**/.DS_Store',
      '!src/channel/**/*.md',
      '!src/channel/components/controllers/StarterController/**',
      '!src/channel/components/tasks/GeneralTask/StarterGeneralTask.xml',
      '!src/channel/components/tasks/GeneralTask/StarterGeneralTask.brs',
      '!src/channel/components/tasks/AnalyticsTask/**',
    ];

    let testSources = [
      '!src/channel/components/tests/**',
      '!src/channel/source/tests/**',
      '!src/channel/source/rooibosFunctionMap.brs'
    ];

    // don't include test files if the config is not 'test'
    if (options.config !== 'test') {
      sources = [...sources, ...testSources];
    }

    // don't include RALE files if config is not 'dev' or it's disabled
    if (options.config !== 'dev' || settings.raleEnabled !== true) {
      sources.push('!src/channel/components/controllers/TubiScene/TrackerTask.xml');
    }

    // don't include Suitest files if config is not 'qa' and suitest is not enabled
    if (options.config !== 'qa' || settings.suitest === false) {
      sources.push('!src/channel/components/controllers/Suitest/**');
    }
    // don't include TestAid files if config is production
    if (options.config === 'production') {
      sources.push('!src/channel/components/screens/SettingsScreen/TestAid/**');
    }

    let srcOptions = {
      base: 'src/channel'
    };

    let stream = collect(sources, srcOptions)
      .pipe(dest('build/local'));

    stream.on('end', () => {
      res();
    });
  });

  return build
    .then(() => {
      replaceColorConstants('build/local');
      createSettings(options, 'build/local/source/Settings.brs');
      createManifest(options, 'build/local/manifest', 'manifest');
      return zipAsPromise('build/local/**/*', `tubi_${buildTag}.zip`, 'build/');
    });
}


function buildStarter() {
  const minorBuildTag = getBuildTag('minor');

  mkdirp.sync(`${process.env.PWD}/build/starter/source`);

  // touch the main.brs, can be empty for starter components
  fs.closeSync(fs.openSync('build/starter/source/main.brs', 'w'));

  // include StarterController in starter components
  let starterControllerSrc = [
    'src/channel/components/controllers/StarterController/**/*'
  ];
  let starterControllerSrcOptions = {
    base: 'src/channel/components'
  };

  // include GeneralTask in starterComponents
  let generalTaskSrc = [
    'src/channel/components/tasks/GeneralTask/BaseGeneralTask.xml',
    'src/channel/components/tasks/GeneralTask/BaseGeneralTask.brs',
    'src/channel/components/tasks/GeneralTask/StarterGeneralTask.xml',
    'src/channel/components/tasks/GeneralTask/StarterGeneralTask.brs',
    'src/channel/components/tasks/GeneralTask/Parsers/TubiExperimentParsers.brs',
    'src/channel/components/tasks/GeneralTask/Parsers/UncategorizedParsers.brs',
  ];
  let generalTaskSrcOptions = {
    base: 'src/channel/components'
  };

  // include Constants in starter components
  let constantsSrc = [
    'src/channel/source/Constants.brs'
  ];
  let constantsSrcOptions = {
    base: 'src/channel'
  };

  // include generalUtils in starterComponents
  let genUtilSrc = [
    'src/channel/source/3rdparty/roku/generalUtils.brs',
    'src/channel/source/3rdparty/rta/typeUtils.brs',
    'src/channel/source/3rdparty/rodash/rodash.cat.brs'
  ];
  let genUtilSrcOptions = {
    base: 'src/channel/source'
  };

  // include TubiExperiments, TubiExternalConfig, and Request modules in starterComponents
  let sourceLibsSrc = [
    'src/channel/source/lib/GeneralTaskModule.brs',
    'src/channel/source/lib/Auth.brs',
    'src/channel/source/lib/Request.brs',
    'src/channel/source/lib/Log.brs',
    'src/channel/source/lib/TubiExperiments.brs',
    'src/channel/source/lib/TubiExternalConfig.brs',
    'src/channel/source/lib/TubiTracking.brs',
    'src/channel/source/lib/TimeOffsetUtils.brs',
    'src/channel/source/lib/StringUtils.brs'
  ];
  let sourceLibsSrcOptions = {
    base: 'src/channel/source'
  };

  // include Mixin in starterComponents
  let componentLibSrc = [
    'src/channel/components/lib/AnimationMixin.brs',
    'src/channel/components/lib/GlobalMixin.brs'
  ];
  let componentLibSrcOptions = {
    base: 'src/channel/components'
  };

  // Creating a list that holds all the sub tasks.
  const subTaskPaths = [
    {
      src: starterControllerSrc,
      options: starterControllerSrcOptions,
      dest: 'build/starter/components'
    },
    {
      src: constantsSrc,
      options: constantsSrcOptions,
      dest: 'build/starter/'
    },
    {
      src: genUtilSrc,
      options: genUtilSrcOptions,
      dest: 'build/starter/source'
    },
    {
      src: sourceLibsSrc,
      options: sourceLibsSrcOptions,
      dest: 'build/starter/source'
    },
    {
      src: componentLibSrc,
      options: componentLibSrcOptions,
      dest: 'build/starter/components'
    },
    {
      src: generalTaskSrc,
      options: generalTaskSrcOptions,
      dest: 'build/starter/components'
    }
  ];

  // Loops through each item in the sub task and creates individual promises.
  const promises = [];
  subTaskPaths.forEach(subTaskPath => {
    // Creating promise and adding it to the promises array.
    // Each task promises will be resolved or rejected.
    let stream = new Promise((resolve, reject) => {
      collect(subTaskPath.src, subTaskPath.options).pipe(dest(subTaskPath.dest))
        .on('finish', () => {
          resolve();
        })
        .on('error', () => {
          reject();
        });
    });
    // Pushing the promise to list.
    promises.push(stream);
  });
  // Adding a promise all which will make sure that success callback will be triggered only after all file moving is completed.
  return Promise.all(promises)
    .then(() => {
      replaceColorConstants('build/starter');
      createSettings(options, 'build/starter/source/Settings.brs');
      createManifest(options, 'build/starter/manifest', 'starter_library_manifest');
      return zipAsPromise('build/starter/**/*', `tubi_starter_components_${minorBuildTag}.zip`, 'build/');
    });
}


function buildRemote() {
  /* Remote components */
  const buildTag = getBuildTag('revision');
  const minorBuildTag = getBuildTag('minor');

  let build = new Promise((res, rej) => {
    mkdirp.sync(`${process.env.PWD}/build/remote/source`);
    mkdirp.sync(`${process.env.PWD}/build/remote/images`);

    // touch the main.brs, can be empty for remote components
    fs.closeSync(fs.openSync('build/remote/source/main.brs', 'w'));

    let sources = [
      // "src/channel/images/**/*",
      'src/channel/source/lib/**/*',
      'src/channel/source/3rdparty/**/*',
      'src/channel/components/**/*',
      //make sure not to include the following files
      '!src/channel/components/tests/**',
      '!src/channel/components/controllers/StarterController/**',
      '!src/channel/components/tasks/GeneralTask/StarterGeneralTask.xml',
      '!src/channel/components/tasks/GeneralTask/StarterGeneralTask.brs',
      '!src/channel/components/controllers/TubiScene/**',
      '!src/channel/components/controllers/BackgroundScene/**',
      '!src/channel/components/tasks/AnalyticsTask/**',
      '!src/channel/source/tests/**',
      '!src/channel/source/Settings.brs',
      '!src/channel/components/controllers/TubiScene/TrackerTask.xml',
      '!src/channel/components/tasks/GeneralTask/Parsers/TubiExperimentParsers.brs'
    ];

    // don't include TestAid files if config is production
    if (options.config === 'production') {
      sources.push('!src/channel/components/screens/SettingsScreen/TestAid/**');
    }

    let srcOptions = {
      base: 'src/channel'
    };

    /* Filtering for images.  Image files are large so in order to keep the remote
     * components bundle as small as possible we only deliver the images which were added since
     * the most recent submitted build.
     */

    /* Replace the image urls of those images that are part of the remote components package,
     * ie. those images that are in the new_images_since file, so that the images are pulled from
     * the remote component package instead of the installed package.
     */
    const newImagesFile = `new_images_since/new_images_since_${minorBuildTag}`;
    const newImages = fs.readFileSync(newImagesFile, 'utf8').split('\n').filter(function(e) {
      e = e.trim();
      return (!e.startsWith('#') && (e.endsWith('png') || e.endsWith('jpg') || e.endsWith('webp')));
    });
    log(`Found ${newImages.length} lines in ${newImagesFile}`);
    const imagePathRegex = /pkg:\/[0-9a-zA-Z./\-_]*/g;

    // prepare a map of new image file paths to make filtering quicker
    let newImagesMap = {};
    newImages.forEach(filePath => {
      newImagesMap[filePath] = true;
    });

    let stream = collect(sources, srcOptions)
      // do the actual uri string replacement
      .pipe(replace(imagePathRegex, function(match) {
        let replacement = match;
        newImages.forEach(function(newImage) {
          if (match.indexOf(newImage) !== -1) {
            log(`Redirecting ${newImage} to remote components`);
            replacement = match.replace('pkg:','libpkg:');
          }
        });
        return replacement;
      }))
      .pipe(dest('build/remote'))

      // filter all image files so that only those images in new_images_since file
      // are included in the remote components pkg
      .pipe(src('src/channel/images/**/*', srcOptions))
      .pipe(filter(file => {
          if (newImagesMap[file.relative]) {
            log(`Filtering ${file.relative}`);
          }
          return newImagesMap[file.relative] ? true : false;
      }))
      .pipe(dest('build/remote'));

    stream.on('end', () => {
      res();
    });
  });

  // zip up the remote components
  return build
  .then(() => {
    replaceColorConstants('build/remote');
    createManifest(options, 'build/remote/manifest', 'component_library_manifest');
    return zipAsPromise('build/remote/**/*', `tubi_remote_components_${buildTag}.zip`, 'build/');
  });
}


// upload - upload the zip package file to a roku device
// returns a promise
// @zipPath: the relative path to the zip file that will be uploaded to the roku
function upload(zipPath) {
  const address = options.target;
  const password = options.devPass;
  return keypress('home', address, password)
  .then(() => {
    log(`Uploading ${zipPath} to ${address} using dev password ${password}...`);
    return uploadPkg(zipPath, address, password);
  })
  .then(data => {
    log(`Uploaded ${zipPath} to ${address} successfully.`);
  });
}


function serverMiddleware(req, res, next) {
  // If we receive a request to this endpoint then we know our unit test have finished so we should stop the process.
  if (req.url === '/unit_tests_completed') {
    setTimeout(() => {
      process.exit();
    }, 2000);
  }
  next();
}


// Uploads the tubi_x_y_z.zip to the roku and launches a server to serve the starter and remote components
function sideLoad(done) {
  const address = options.target;
  const buildTag = getBuildTag('revision');
  const zipPath = `build/tubi_${buildTag}.zip`;
  return upload(zipPath)
  .then(() => {
    let { settings } = load(options);

    if (!settings.useStarterComponents) {
      done();
    } else {
      return server({
        host: '0.0.0.0',
        port: options.port,
        root: 'build',
        debug: true,
        middleware: () => {
          return [
            serverMiddleware
          ];
        }
      });
    }
  })
  .catch((err) => {
    if (typeof err === 'string' && err.trim() === 'Application Received: Identical to previous version -- not replacing.') {
      log('Build already installed, launching dev channel via deeplink.');
      return deeplink('dev', address);
    } else {
      if (err.errno === 'ENOTFOUND') {
        log('Hint: Double check that ROKU_DEV_TARGET is set.');
      } else if (err.errno === 'EHOSTUNREACH') {
        log('Hint: Double check that you are sending to an available Roku device IP.');
        log(`The IP ${options.target} does not seem to be accessible.`);
      }
      throw err;
    }
  })
  .then(() => {
    log(`${options.config.toUpperCase()} channel launched.`);

    if (options.telnet === 'sametab') {
      shell.config.silent = false;
      shell.exec(`telnet ${options.target} 8085`,{async: true});
    }
  })
  .catch(err => {
    console.log(`sideLoad error: `, err);
    serverClose();
  })
  .then(done());
}


function packageLocal(done) {
  log('Starting packageLocal');
  let buildTag = getBuildTag('revision');
  let zipPath = `build/tubi_${buildTag}.zip`;
  let appName = `tubi_${buildTag}`;
  return installWithSquashfs(zipPath, options.target, options.devPass)
    .then(() => {
      log(`Signing ${zipPath}`);
      return signPkg(options.target, options.devPass, options.pkgPass, appName, 'build');
    })
    .then(path => {
      log(`Signed package at ${zipPath}`);
    })
    .catch(err => {
      console.log(err);
      log('Could not package local components');
      log('HINT: Make sure you are using the correct Roku device IP.');
      done(err);
    });
}


function packageStarter(done) {
  log('Starting packageStarter');
  let minorBuildTag = getBuildTag('minor');
  var appName = `tubi_starter_components_${minorBuildTag}`;
  var zipPath = `build/tubi_starter_components_${minorBuildTag}.zip`;
  return installWithSquashfs(zipPath, options.target, options.devPass)
    .then(() => {
      log(`Signing ${zipPath}`);
      return signPkg(options.target, options.devPass, options.pkgPass, appName, 'build');
    })
    .then(path => {
      log(`Signed package at ${zipPath}`);
    })
    .catch(err => {
      console.log(err);
      log('Could not package starter components');
      log('HINT: Make sure you are using the correct Roku device IP.');
      done(err);
    });
}


function packageRemote(done) {
  log('Starting packageRemote');
  let buildTag = getBuildTag('revision');
  let zipPath = `build/tubi_remote_components_${buildTag}.zip`;
  let appName = `tubi_remote_components_${buildTag}`;
  return installWithSquashfs(zipPath, options.target, options.devPass)
    .then(() => {
      log(`Signing ${zipPath}`);
      return signPkg(options.target, options.devPass, options.pkgPass, appName, 'build');
    })
    .then(path => {
      log(`Signed package at ${zipPath}`);
    })
    .catch(err => {
      console.log(err);
      log('Could not package remote components');
      log('HINT: Make sure you are using the correct Roku device IP.');
      done(err);
    });
}


function conditionalPackage(done) {
  let { config } = options;
  let { settings } = load(options);

  const configsNotPkgd = {
    dev: true,
    test: true,
    qa: true
  };

  if (!configsNotPkgd[config] || settings.remoteComponentsExtension === 'pkg') {
    return packageAll(done);  //informs gulp that task has completed by returning a promise
  } else {
    done();  //inform gulp that the task has completed.
  }
}


function packageAll(done) {
  log('starting packageAll');
  return packageStarter(done)
  .then(() => packageRemote(done))
  .then(() => packageLocal(done));
}


// increase the build/patch numbers in config/build.yml
function bumpBuild(done) {
  if (verifyGit(done)) {
    incrementBuildNumber();
    const buildTag = getBuildTag('revision');
    log(`Committing build bump to ${buildTag}`);
    shell.exec(`git commit -m "incrementbuild: Bump build number to ${buildTag}" config/build.yml`, {silent: true});
    done();
  } else {
    // errors should be handled in verifyGit()
  }
}


// increase the revision number in config/build.yml
function bumpRevision(done) {
  if (verifyGit(done)) {
    incrementRevisionNumber();
    const buildTag = getBuildTag('revision');
    log(`Committing build bump to ${buildTag}`);
    shell.exec(`git commit -m "incrementbuild: Bump revision number to ${buildTag}" config/build.yml`, {silent: true});
    done();
  } else {
    // errors should be handled in verifyGit()
  }
}


// tag the build that will be released
function tagBuild(done) {
  const buildTag = getBuildTag('revision');
  log(`Tagging ${buildTag}`);
  shell.exec(`git tag ${buildTag}`);
  done();
}


// force production on options, so we ensure our build is using the production config
function setProduction(done) {
  if(options) {
    options.config = 'production';
    options.overrides = {
      settings: {
        useStarterComponents: true
      }
    };
    done();
  } else {
    done(new Error('setProduction: options not found.'));
  }
}


// force staging on options, so we ensure our build is using the staging config
function setStaging(done) {
  if(options) {
    options.config = 'staging';
    done();
  } else {
    done(new Error('setStaging: options not found.'));
  }
}


// force qa on options, so we ensure our build is using the qa config and set other automated test config settings
function setAutomatedTestsConfig(done) {
  if(options) {
    options.config = 'qa';
    options.overrides = {
      settings: {
        injectRtaOnDeviceComponent: true,
        hideStartupModals: true,
        noAds: true,
        printReqAndResInfo: false,
        bs_const: {
          consoleLoggingEnabled: false
        }
      }
    };
    done();
  } else {
    done(new Error('setAutomatedTestsConfig: options not found.'));
  }
}


function setRerunAutomatedTestsEnvironment(done) {
  env.set({
    isAlreadyDeployed: 'true'
  });
  done();
}


function runAutomatedTests() {
  return src(['js/automated-tests/tests/*.ts'], { read: false })
    .pipe(mocha()); // Use {bail: true} if you want to stop after first one fails
}


// force qa on options, so we ensure our build is using the qa config and set other automated test config settings
function setPerformanceTestsConfig(done) {
  if(options) {
    options.config = 'qa';
    options.overrides = {
      settings: {
        injectRtaOnDeviceComponent: true,
        printReqAndResInfo: false,
        bs_const: {
          consoleLoggingEnabled: false
        }
      }
    };
    done();
  } else {
    done(new Error('setBenchmarkTestsConfig: options not found.'));
  }
}

function runPerformanceTests() {
  return src(['js/automated-tests/performance-tests/*.ts'], { read: false })
    .pipe(mocha({}));
}


function runToolingTests() {
  return src(['js/automated-tests/tooling-tests.ts'], { read: false })
    .pipe(mocha({}));
}


// force test on options, so we ensure our build is using the test config
function setTest(done) {
  if(options) {
    options.config = 'test';
    done();
  } else {
    done(new Error('setTest: options not found.'));
  }
}


async function preprocessTests() {
  const configSettings = {
    projectPath: './src/channel',
    testsFilePattern: [
      '**/tests/**/*.brs',
      '!**/rooibosDist.brs',
      '!**/rooibosFunctionMap.brs',
      '!**/TestsScene.brs'
    ]
  };

  const config = createProcessorConfig(configSettings);
  const processor = new RooibosProcessor(config);
  await processor.processFiles();
}


//send starter components and remote components to AWS S3
function pushStaging(done) {
  const buildTag = getBuildTag('revision');
  const minorBuildTag = getBuildTag('minor');
  const localRemoteComponentsPath = `build/tubi_remote_components_${buildTag}.pkg`;
  const s3RemoteComponentsPath = `s3://adrise-bryan-playground/roku-staging/components/tubi_remote_components_${buildTag}.pkg`;
  const localStarterComponentsPath = `build/tubi_starter_components_${minorBuildTag}.pkg`;
  const s3starterComponentsPath = `s3://adrise-bryan-playground/roku-staging/starter-components/tubi_starter_components_${minorBuildTag}.pkg`;

  let pushResult = shell.exec(`aws s3 cp ${localRemoteComponentsPath} ${s3RemoteComponentsPath}`);
  if (!pushResult.stderr) {
    pushResult = shell.exec(`aws s3 cp ${localStarterComponentsPath} ${s3starterComponentsPath}`);
  }

  if (!pushResult.stderr) {
    done();
  } else {
    done(new NoStackError(`AWS S3 error: Hint - check valet auth.`));
  }
}


async function confirmRelease(done) {
  const msg = 'Are you sure you want to run the release process? This will push branches to Github and create multiple PRs in the appropriate places. (y/n)';
  const confirmation = await prompts({
    type: 'confirm',
    name: 'confirmRelease',
    message: msg
  });

  if (!confirmation || !confirmation.confirmRelease) {
    const errorMsg = 'Release process not confirmed';
    done(new NoStackError(errorMsg));
  }
}


async function buildReleaseNotesOutput(done) {
  const releaseNotes = await buildReleaseNotes(done);
  console.log('');
  console.log(`RELEASE NOTES`);
  console.log('-----------------------------------------------------------------------');
  console.log(releaseNotes.join('\n'));
  done();
}


async function buildQaChangesOutput(done) {
  const qaChanges = await buildQaChanges(done);
  console.log('');
  console.log(`QA Changes`);
  console.log('-----------------------------------------------------------------------');
  console.log(qaChanges.text);
  console.log('-----------------------------------------------------------------------');
  console.log('');
  console.log(`Cherry Pick Commits`);
  console.log('-----------------------------------------------------------------------');
  for (const change of qaChanges.changes) {
    console.log(`${change.commit}: ${change.whatChanged}`);
    if(change.ticketUrl) {
      console.log(change.ticketUrl);
    }
    console.log('');
  }
  console.log('-----------------------------------------------------------------------');
  console.log('');
  clipboardy.writeSync(qaChanges.text);
  console.log('QA Changes have been copied to your clipboard! Paste into QA ticket.');

  done();
}


// Simple helper to avoid having to type the dashes each time to get the tasks list. Also prints a more compact version
function listTasks(done) {
  console.log(shell.exec(`gulp --tasks-simple`).stdout);
  done();
}


exports.codeClean = series(listUnusedImages, listUnusedTranslations);
exports.build = series(clean, buildInstalled, buildStarter, buildRemote);
exports.sideload = sideLoad;
exports['build-downloads'] = series(buildStarter, buildRemote, packageStarter, packageRemote);
exports.bump = bumpBuild;
exports.bumpQA = bumpRevision;
exports.bumpqa = exports.bumpQA; //Create bumpQA command alias
exports.bumpQa = exports.bumpQA; //Create bumpQA command alias
exports.install = series(exports.build, conditionalPackage, sideLoad);
exports.test = series(setTest, clean, preprocessTests, buildInstalled, sideLoad);
exports.stage = series(setStaging, bumpRevision, exports.build, packageAll, pushStaging, pushBranch);
exports.releaseOnGithub = series(tagBuild, pushTag, createGithubRelease);
exports.release = series(confirmRelease, setProduction, bumpBuild, exports.build, packageAll, makeReleasePrs, exports.releaseOnGithub);
exports.compareProd = findCommitsNotOnProductionBranch;
exports.compareCheckedOut = findCommitsNotOnCurrentBranch;
exports.addMissingImages = addMissingImagesToRemoteLibrary;
exports.tasks = listTasks;

// Suitest related
exports.retrieveSuitestTests = retrieveSuitestTests;
exports.runSuitestTests = series(setAutomatedTestsConfig, clean, buildInstalled, runSuitestTests);
exports.convertXpathsToKeyPaths = series(setAutomatedTestsConfig, clean, buildInstalled, convertXpathsToKeyPaths);
exports.convertSuitestTest = convertSuitestTest;


// Automated test related
exports.buildAutomatedTests = series(setAutomatedTestsConfig, buildInstalled);
exports.runAutomatedTests = series(setAutomatedTestsConfig, buildInstalled, runAutomatedTests);
exports.rerunAutomatedTests = series(setRerunAutomatedTestsEnvironment, runAutomatedTests);
exports.runAutomatedTestsCli = runAutomatedTestsCli;
exports.autotest = runAutomatedTestsCli;

exports.runToolingTests = series(setAutomatedTestsConfig, buildInstalled, runToolingTests);

exports.buildReleaseNotes = buildReleaseNotesOutput;
exports.buildQaChanges = buildQaChangesOutput;
exports.runPerformanceTests = series(setPerformanceTestsConfig, clean, buildInstalled, runPerformanceTests);

// Github action runner related
exports.setupAutomatedTestsRunner = setupAutomatedTestsGithubActionRunner;
exports.startAutomatedTestsRunner = startAutomatedTestsGithubActionRunner;
exports.removeAutomatedTestsRunner = removeAutomatedTestsGithubActionRunner;

//command lines related to the crowdin language translations
exports.update_local_translations = updateLocalTranslations;
exports.upload_translations = series(updateLocalTranslations, uploadTranslations);
exports.download_translations = downloadTranslations;
