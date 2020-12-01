'use strict';
const {series, parallel, src, dest} = require('gulp');
const del = require('del');
const fs = require('fs');
const debug = require('gulp-debug-streams');
const dedupe = require('gulp-dedupe');
const gulpif = require('gulp-if');
const replace = require('gulp-replace');
const { server, serverClose } = require('gulp-connect');
const filter = require('gulp-filter');
const zip = require('gulp-zip');
const mergeStream = require('merge-stream');
const http = require('http');
const mkdirp = require('mkdirp');
const request = require('request');
const clipboardy = require('clipboardy');
const prompts = require('prompts');
const { RooibosProcessor, createProcessorConfig, ProcessorConfig } = require('rooibos-cli');
const shell = require('shelljs');
shell.config.silent = true;
// Uncomment the next line if there are connection issues to the Roku device
// const requestDebug = require('request-debug')(request);

// Github API wrapper
const { Octokit } = require('@octokit/rest');
const octokit = new Octokit({
  auth: process.env.GITHUB_PAT,
  userAgent: 'project-total-recall-build-server',
  baseUrl: 'https://api.github.com'
});

// constants used for interacting with the github API
const ghInfo = {
  owner: 'adRise',
  rokuRepo: 'project-total-recall',
  cdnRepo: 'adrise_cdn',
};

//Importing old build functions
const {load, getBuildTag, incrementBuildNumber} = require('./js/config');
const {createManifest, createSettings} = require('./js/build');
const {keypress, deeplink, uploadPkg, signPkg} = require('./js/network');

//Functions to upload and download static string translations  
const {downloadTranslations, updateLocalTranslations, uploadTranslations} = require('./js/translate');

// provide a custom error so as to not get a full stack trace which will be misleading
// in the case that the error is not with the code, but rather with git or aws or something else.
class NoStackError extends Error {
  constructor(...params) {
    super(...params);
    this.stack = this.message;
  }
}

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
}

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
  }

  // only allow args with a single preceding "-", ie. '--staging'
  if (arg.slice(0, 2) === '--' && arg.charAt(2) !== '-') {
    // strip any initial "-"
    let strippedArg = arg.slice(2);
 
    // check for one of the config values
    if (allowedConfigs[strippedArg]) {
      options.config = strippedArg;
    } else if (allowedTelnetConfigs[strippedArg]) { 
      options.telnet = strippedArg
    } else if(strippedArg.split('.').length === 4) {
      //check if the arg is an IP address
      let ipBlocks = strippedArg.split('.');
      let isIp = ipBlocks.reduce((acc, block) => {
        block = parseInt(block);
        return (block >= 0 && block < 256) ? true : false;
      }, true);

      if (isIp) {
        options.target = strippedArg;
      }
    }
  }
});

console.log(`PROFILE = ${options.config}`);

/* Timeout for any network traffic to the Roku device */
const deviceTimeout = 15000;


// deletes the contents of the build folder, all of which will be recreated.
function clean(done) {
  del.sync(['build/**/*'])
  done();  //inform gulp that the task has completed.
};


// used by: buildLocal/buildInstalled
// gather up the sources, dedupe files and run debug on them
// returns a pipeable stream
function collect(sources, srcOptions) {
  sources.map((source) => {
    console.log(`Adding ${source}`);
  });
  return src(sources, srcOptions)
        .pipe(dedupe())
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
  const buildTag = getBuildTag(false, false);
  let build = new Promise((res, rej) => {
    /* Installed bundle */
    mkdirp.sync(`${process.env.PWD}/build/local/source`);
    createSettings(options.config, 'build/local/source/Settings.brs');
    createManifest(options.config, 'build/local/manifest', 'manifest');

    let sources = [
      'src/channel/**/*',
      //make sure not to include the following files
      '!src/channel/**/.keep',
      '!src/channel/**/.DS_Store',
      '!src/channel/**/*.md',
      '!src/channel/components/controllers/StarterController/**',
      '!src/channel/components/tasks/ExperimentsTask/**',
      '!src/channel/components/tasks/AnalyticsTask/**',
    ];

    let testSources = [
      '!src/channel/components/tests/**',
      '!src/channel/source/tests/**',
      '!src/channel/source/rooibosFunctionMap.brs'
    ];

    // don't include test files if the config is not 'test'
    if (options.config !== 'test') {
      sources = [...sources , ...testSources];
    }

    // don't include RALE files if config is not 'dev'
    if (options.config !== 'dev') {
      sources.push('!src/channel/components/controllers/TubiScene/TrackerTask.xml')
    }
    
    // don't include SignUp Task if config is not 'qa'
    if (options.config !== 'qa') {
      sources.push('!src/channel/components/tasks/SignUpTask/**')
    }    

    let srcOptions = {
      base: 'src/channel'
    };

    let stream = collect(sources, srcOptions)
      .pipe(dest('build/local'));

    stream.on('end', () => {
      res();
    })
  });

  return build
    .then(() => {
      return zipAsPromise('build/local/**/*', `tubi_${buildTag}.zip`, 'build/');
    });
};


function buildStarter() {
  const minorBuildTag = getBuildTag(true, false);
  
  let build = new Promise((res, rej) => {
    /* Installed bundle */
    mkdirp.sync(`${process.env.PWD}/build/starter/source`);
    createSettings(options.config, 'build/starter/source/Settings.brs');
    createManifest(options.config, 'build/starter/manifest', 'starter_library_manifest');

    // touch the main.brs, can be empty for starter components
    fs.closeSync(fs.openSync('build/starter/source/main.brs', 'w'));

    // include StarterController in starter components
    let starterControllerSrc = [
      'src/channel/components/controllers/StarterController/**/*',
    ];
    let starterControllerSrcOptions = {
      base: 'src/channel/components/controllers'
    };

    // include ExperimentsTask in starterComponents
    let experimentsTaskSrc = [
      'src/channel/components/tasks/ExperimentsTask/**/*'
    ];
    let experimentsTaskSrcOptions = {
      base: 'src/channel/components/tasks'
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
      'src/channel/source/3rdparty/roku/generalUtils.brs'
    ];
    let genUtilSrcOptions = {
      base: 'src/channel/source/3rdparty/roku/'
    };

    // include TubiExperiments, TubiExternalConfig, and Request modules in starterComponents
    let sourceLibsSrc = [
      'src/channel/source/lib/Request.brs',
      'src/channel/source/lib/Log.brs',
      'src/channel/source/lib/TubiExperiments.brs',
      'src/channel/source/lib/TubiExternalConfig.brs',
      'src/channel/source/lib/TubiTracking.brs',
      'src/channel/source/lib/Auth.brs',
    ];
    let sourceLibsSrcOptions = {
      base: 'src/channel/source/lib/'
    };
    
    // include AnimationMixin in starterComponents
    let componentLibSrc = [
      'src/channel/components/lib/AnimationMixin.brs',
    ];
    let componentLibSrcOptions = {
      base: 'src/channel/components/lib/'
    };    

    //move all the necessary starter component files to the build/starter directory
    let stream = mergeStream(
      collect(starterControllerSrc, starterControllerSrcOptions)
        .pipe(dest('build/starter/components/')),
      collect(experimentsTaskSrc, experimentsTaskSrcOptions)
        .pipe(dest('build/starter/components/')),
      collect(constantsSrc, constantsSrcOptions)
        .pipe(dest('build/starter/')),
      collect(genUtilSrc, genUtilSrcOptions)
        .pipe(dest('build/starter/source')),
      collect(sourceLibsSrc, sourceLibsSrcOptions)
        .pipe(dest('build/starter/source')),
      collect(componentLibSrc, componentLibSrcOptions)
        .pipe(dest('build/starter/source'))        
    );

    stream.on('finish', () => {
      res();
    })
  })

  // then zip up the starter component files after all the files have been moved
  return build
  .then(() => {
    return zipAsPromise('build/starter/**/*', `tubi_starter_components_${minorBuildTag}.zip`, 'build/');
  });
};


function buildRemote() {
  /* Remote components */
  const buildTag = getBuildTag(false, false);
  const minorBuildTag = getBuildTag(true, false);

  let build = new Promise((res, rej) => {
    mkdirp.sync(`${process.env.PWD}/build/remote/source`);
    mkdirp.sync(`${process.env.PWD}/build/remote/images`);
    createManifest(options.config, 'build/remote/manifest', 'component_library_manifest');

    // touch the main.brs, can be empty for remote components
    fs.closeSync(fs.openSync('build/remote/source/main.brs', 'w'));

    let sources = [
      // "src/channel/images/**/*",
      "src/channel/source/lib/**/*",
      "src/channel/source/3rdparty/**/*",
      "src/channel/components/**/*",
      //make sure not to include the following files
      '!src/channel/components/tests/**',
      '!src/channel/components/controllers/StarterController/**',
      '!src/channel/components/tasks/ExperimentsTask/**',
      '!src/channel/components/tasks/AnalyticsTask/**',
      '!src/channel/source/3rdparty/ComponentTestFramework.brs',
      '!src/channel/source/3rdparty/roku/NotesOnRokuTestFramework.brs',
      '!src/channel/source/3rdparty/roku/UnitTestFramework.brs',
      '!src/channel/source/tests/**'
    ];

    // don't include RALE files if config is not 'dev'
    if (options.config !== 'dev') {
      sources.push('!src/channel/components/controllers/TubiScene/TrackerTask.xml')
    }
    
    // don't include SignUp Task if config is not 'qa'
    if (options.config !== 'qa') {
      sources.push('!src/channel/components/tasks/SignUpTask/**')
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
    const newImages = fs.readFileSync(newImagesFile, "utf8").split('\n').filter(function(e) {
      e = e.trim();
      return (!e.startsWith("#") && (e.endsWith("png") || e.endsWith('jpg')));
    });
    console.log(`Found ${newImages.length} lines in ${newImagesFile}`);
    const imagePathRegex = /pkg:\/[0-9a-zA-Z\.\/\-_]*/g;

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
            console.log(`Redirecting ${newImage} to remote components`);
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
            console.log(`Filtering ${file.relative}`);
          }
          return newImagesMap[file.relative] ? true : false;
      }))
      .pipe(dest('build/remote'));

    stream.on('end', () => {
      res();
    })
  })

  // zip up the remote components
  return build
  .then(() => {
    return zipAsPromise('build/remote/**/*', `tubi_remote_components_${buildTag}.zip`, 'build/');
  });
};



// upload - upload the zip package file to a roku device
// returns a promise
// @zipPath: the relative path to the zip file that will be uploaded to the roku
function upload(zipPath) {
  const address = options.target;
  const password = options.devPass;
  return keypress('home', address, password)
  .then(() => {
    console.log('Uploading %s to %s using dev password %s...', zipPath, address, password);
    return uploadPkg(zipPath, address, password);
  })
  .then(data => {
    console.log('Uploaded %s to %s successfully.', zipPath, address);
  });
}


// Uploads the tubi_x_y_z.zip to the roku and launches a server to serve the starter and remote components
function sideLoad(done) {
  const address = options.target;
  const buildTag = getBuildTag(false, false);
  const zipPath = `build/tubi_${buildTag}.zip`;
  upload(zipPath)
  .then(
    server({
      host: "0.0.0.0",
      port: options.port,
      root: 'build',
      debug: true
    })
  )
  .catch((err) => {
    if (typeof err === 'string' && err.trim() === 'Application Received: Identical to previous version -- not replacing.') {
      console.log("Build already installed, launching dev channel via deeplink.");
      return deeplink('dev', address);
    } else {
      if (err.errno === 'ENOTFOUND') {
        console.log('Hint: Double check that ROKU_DEV_TARGET is set.');
      } else if (err.errno === 'EHOSTUNREACH') {
        console.log('Hint: Double check that you are sending to an available Roku device IP.');
        console.log(`The IP ${options.target} does not seem to be accessible.`);
      }
      throw err;
    }
  })
  .then(() => {
    console.log(`${options.config.toUpperCase()} channel launched.`)
    
    if (options.telnet === 'sametab') {
      shell.exec(`telnet ${options.target} 8085`,{async: true});
    }
  })
  .catch(err => {
    console.log('sideLoad error: ', err);
    serverClose();
  })
  .then(done());
}


function packageLocal() {
  let buildTag = getBuildTag(false, false);
  let zipPath = `build/tubi_${buildTag}.zip`;
  let appName = `tubi_${buildTag}`;
  return upload(zipPath)
    .then(() => {
      console.log('Signing %s', zipPath);
      return signPkg(options.target, options.devPass, options.pkgPass, appName, 'build')
    })
    .then(path => {
      console.log('Signed package at %s.', zipPath);
    })
    .catch(err => {
      console.log(err);
    });
}


function packageStarter() {
  let minorBuildTag = getBuildTag(true, false);
  var appName = `tubi_starter_components_${minorBuildTag}`;
  var zipPath = `build/tubi_starter_components_${minorBuildTag}.zip`;
  return upload(zipPath)
    .then(() => {
      console.log('Signing %s', zipPath);
      return signPkg(options.target, options.devPass, options.pkgPass, appName, 'build')
    })
    .then(path => {
     console.log("Signed package at %s.", zipPath);
    })
    .catch(err => {
     console.log(err);
    });
}


function packageRemote() {
  let buildTag = getBuildTag(false, false);
  let zipPath = `build/tubi_remote_components_${buildTag}.zip`;
  let appName = `tubi_remote_components_${buildTag}`;
  return upload(zipPath)
    .then(() => {
      console.log('Signing %s', zipPath);
      return signPkg(options.target, options.devPass, options.pkgPass, appName, 'build')
    })
    .then(path => {
      console.log("Signed package at %s.", zipPath);
    })
    .catch(err => {
      console.log(err);
    });
}


function conditionalPackage(done) {
  let { config } = options
  let { settings } = load(config);

  if ((config !== 'dev' && config !== 'test') || settings.remoteComponentsExtension === 'pkg') {
    return packageAll();  //informs gulp that task has completed by returnin a promise
  } else {
    done();  //inform gulp that the task has completed.
  }
}


function packageAll() {
  console.log("starting packageAll");
  return packageStarter()
  .then(() => packageRemote())
  .then(() => packageLocal())
}


// ensure git exists on the system and that the working directory is clean
function verifyGit(done, directory = '') {
  let gitDirectory = '';
  if (directory) {
    gitDirectory = `-C ${directory}`;
  }

  if (!shell.which('git')) {
    done(new NoStackError('Git error: git not installed'));
    return false;
  } else if (shell.exec(`git ${gitDirectory} rev-parse --is-inside-work-tree`
    ).stdout.trim() !== 'true') {
    directory = !!directory ? directory : process.cwd();
    done(new NoStackError(`Git error: current directory (${directory}) is not part of a git repo.`));
    return false;
  } else if (shell.exec(`git ${gitDirectory} status --porcelain`).stdout) {
    directory = !!directory ? directory : process.cwd();
    done(new NoStackError(`Git error: working directory (${directory}) is dirty - stash or commit your changes before proceeding.`));
    return false;
  } else {
    return true;
  }
}


// increase the build/patch numbers in config/build.yml
function bumpBuild(done) {
  if (verifyGit(done)) {
    return incrementBuildNumber()
    .then(() => {
      const buildTag = getBuildTag(false, false);
      console.log(`Commiting build bump to ${buildTag}`);
      shell.exec(`git commit -m "incrementbuild: Bump build number to ${buildTag}" config/build.yml`, {silent: true});
    });
  } else {
    // errors should be handled in verifyGit()
  }
}


// tag the build that will be released
function tagBuild(done) {
  const buildTag = getBuildTag(false, false);
  console.log(`Tagging ${buildTag}`);
  shell.exec(`git tag ${buildTag}`);
  done();
}


// force production on options, so we ensure our build is using the production config
function setProduction(done) {
  if(options) {
    options.config = 'production';
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
    projectPath: "./src/channel",
    testsFilePattern: [
      "**/tests/**/*.brs",
      "!**/rooibosDist.brs",
      "!**/rooibosFunctionMap.brs",
      "!**/TestsScene.brs"
    ]
  };

  const config = createProcessorConfig(configSettings);
  const processor = new RooibosProcessor(config);
  await processor.processFiles();
}


//send starter components and remote components to AWS S3
function pushStaging(done) {
  const buildTag = getBuildTag(false, false);
  const minorBuildTag = getBuildTag(true, false);
  const localRemoteComponentsPath = `build/tubi_remote_components_${buildTag}.pkg`;
  const s3RemoteComponentsPath = `s3://adrise-bryan-playground/roku-staging/components/tubi_remote_components_${buildTag}.pkg`
  const localStarterComponentsPath = `build/tubi_starter_components_${minorBuildTag}.pkg`;
  const s3starterComponentsPath = `s3://adrise-bryan-playground/roku-staging/starter-components/tubi_starter_components_${minorBuildTag}.pkg`
  
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
  const msg = 'Are you sure you want to run the release process? This will push branches to Github and create multiple PRs in the appropriate places. (y/n)'
  const confirmation = await prompts({
    type: 'confirm',
    name: 'confirmRelease',
    message: msg
  });

  if (!confirmation || !confirmation.confirmRelease) {
    const errorMsg = 'Release process not confirmed'
    done(new NoStackError(errorMsg));
  }
}


// All the steps necessary to push starter and remote components to the CDN and make a PR to the CDN.
// Additionally make a PR against the production release branch on project-total-recall and copy the
// urls to the local clipboard.
async function makeReleasePrs(done) {
  // Note that git commands will have a code = 0 when there is no error and code > 0 when an error occurred.
  // Also note that git commands have a stderr output even if the code === 0.

  const minorBuildTag = getBuildTag(true, false);
  const fullBuildTag = getBuildTag(false, false);
  const cdnPath = process.env.CDN_GIT_DIRECTORY;

  // check if the environment variable for the path to the CDN repo has been set
  if (!cdnPath) {
    const errorMsg = `You did not set a CDN_GIT_DIRECTORY environment variable in your .bash_profile or .bashrc file.`
    done(new NoStackError(errorMsg));
  }

  // check that the CDN repo is clean - verifyGit() handles any error messages as necessary
  verifyGit(done, cdnPath);

  // rename the local branch name so it looks like "release_2_14_34"
  const releaseBranchName = `release_${fullBuildTag}`
  console.log(`...Renaming the local branch to ${releaseBranchName}`);
  const branchRenameRes = shell.exec(`git branch -m ${releaseBranchName}`);
  if (branchRenameRes.code) {
    let errorMsg = `Could not rename the local branch to ${releaseBranchName}`;
    if (pushBranchRes.stderr) {
      errorMsg = branchRenameRes.stderr
    }
    done(new NoStackError(errorMsg));
  }

  // attempt to checkout master in the CDN repo
  console.log(`...Checking out master on the local ${ghInfo.cdnRepo} repo`)
  const checkoutMasterRes = shell.exec(`git -C ${cdnPath} checkout master`).code;
  if (checkoutMasterRes.code) {
    let errorMsg = `Could not check out master at ${cdnPath}.`;
    if (checkoutMasterRes.stderr) {
      errorMsg = checkoutMasterRes.stderr;
    }
    done(new NoStackError(errorMsg));
  }

  // attempt to pull origin master for the CDN repo
  console.log(`...Pulling remote master to the local ${ghInfo.cdnRepo} repo`);
  const pullMasterRes = shell.exec(`git -C ${cdnPath} pull origin master`).code;
  if (pullMasterRes.code) {
    let errorMsg = `Could not pull master from origin at ${cdnPath}.`;
    if (pullMasterRes.stderr) {
      errorMsg = pullMasterRes.stderr;
    }
    done(new NoStackError(errorMsg));
  }

  // attempt to check out a new branch off master for the CDN repo
  const cdnBranchName = `roku_${fullBuildTag}`;
  console.log(`...Creating a new ${cdnBranchName} branch on the local ${ghInfo.cdnRepo} repo`);
  const checkoutNewBranchRes = shell.exec(`git -C ${cdnPath} checkout -b ${cdnBranchName}`);
  if (checkoutNewBranchRes.code) {
    let errorMsg = `Could not checkout a new branch "${cdnBranchName}" at ${cdnPath}`;
    if (checkoutNewBranchRes.stderr) {
      errorMsg = `${checkoutNewBranchRes.stderr} at ${cdnPath}`;
    }
    done(new NoStackError(errorMsg));
  }

  const starterComponentsFileName = `tubi_starter_components_${minorBuildTag}.pkg`;
  const remoteComponentsFileName = `tubi_remote_components_${fullBuildTag}.pkg`;

  const cdnStarterComponentsPath = `${cdnPath}/hotpatches/roku/starter-components/${starterComponentsFileName}`;
  const cdnRemoteComponentsPath = `${cdnPath}/hotpatches/roku/components/${remoteComponentsFileName}`;
  
  const localStarterComponentsPath = `build/tubi_starter_components_${minorBuildTag}.pkg`;
  const localRemoteComponentsPath = `build/tubi_remote_components_${fullBuildTag}.pkg`;
  
  // copy the starter components from the /build directory to the CDN repo directory
  console.log(`...Copying the starter components to the local ${ghInfo.cdnRepo} repo`);
  const moveStarterComponentsResult = shell.cp(localStarterComponentsPath, cdnStarterComponentsPath);
  if (moveStarterComponentsResult.stderr) {
    const errorMsg = `There was an error moving the starter components. You will need to manually copy the starter components and remote components and manually make a PR.
           Error Message: ${moveStarterComponentsResult.stderr}`;
    done(new NoStackError(errorMsg));
  }

  // copy the remote components from the /build directory to the CDN repo directory
  console.log(`...Copying the remote components to the local ${ghInfo.cdnRepo} repo`);
  const moveRemoteComponentsRes = shell.cp(localRemoteComponentsPath, cdnRemoteComponentsPath);
  if (moveRemoteComponentsRes.stderr) {
    const errorMsg = `There was an error moving the remote components. You will need to manually copy the remote components and manually make a PR.
           Error Message: ${moveRemoteComponentsRes.stderr}`;
    done(new NoStackError(errorMsg));
  }

  // add the updates so they are staged for commit
  console.log(`...Staging changes for commit on the local ${ghInfo.cdnRepo} repo`);
  const gitAddRes = shell.exec(`git -C ${cdnPath} add . `);
  if (gitAddRes.code) {
    let errorMsg = `Could not run "git add . " on ${cdnPath}`;
    if (gitAddRes.stderr) {
      errorMsg = gitAddRes.stderr
    }
    done(new NoStackError(errorMsg))
  }

  // commit the updates to the branch
  console.log(`...Committing the staged changes on the local ${ghInfo.cdnRepo} repo`);
  const gitCommitRes = shell.exec(`git -C ${cdnPath} commit -m 'Updating the starter and remote components for ${cdnBranchName}'`);
  if (gitCommitRes.code) {
    let errorMsg = `"git commit" failed on ${cdnPath}`;
    if (gitCommitRes.stderr) {
      errorMsg = gitCommitRes.stderr;
    }
    done(new NoStackError(errorMsg))
  }

  // push the branch to Github
  console.log(`...Pushing the local ${cdnBranchName} branch to the remote ${ghInfo.rokuRepo} repo`)
  const pushCdnBranchRes = shell.exec(`git -C ${cdnPath} push origin ${cdnBranchName}`);
  if (pushCdnBranchRes.code) {
    let errorMsg = `Could not push ${cdnBranchName} to origin (Github) at ${cdnPath}`;
    if (pushCdnBranchRes.stderr) {
      errorMsg = pushCdnBranchRes.stderr
    }
    done(new NoStackError(errorMsg));
  }

  // make a PR against master on the CDN repo at Github
  console.log(`...Making a PR on ${ghInfo.cdnRepo} against the remote master branch`);
  let cdnPrUrl = '';
  try {
    const cdnPrRes = await octokit.pulls.create({
      owner: ghInfo.owner,
      repo: ghInfo.cdnRepo,
      title: `Updating start up and remote components for roku ${fullBuildTag}`,
      head: cdnBranchName,
      base: 'master'
    });
    cdnPrUrl = cdnPrRes.data.html_url;
  } catch(err) {
    console.log(err);
    done(new NoStackError(err));
  }

  // push the release branch to the project-total-recall repo
  console.log(`...Pushing the local ${releaseBranchName} branch to the remote ${ghInfo.rokuRepo} repo`);
  const pushReleaseBranchRes = shell.exec(`git push origin ${releaseBranchName}`);
  if (pushReleaseBranchRes.code) {
    let errorMsg = `Could not push ${releaseBranchName} to ${ghInfo.rokuRepo} origin (Github)`;
    if (pushReleaseBranchRes.stderr) {
      errorMsg = pushReleaseBranchRes.stderr;
    }
    done(new NoStackError(errorMsg));
  }

  // make a PR against the production branch on the project-total-recall repo at Github
  const prodRokuBranchName = `${minorBuildTag}_branch`;
  console.log(`...Making a PR from the remote ${releaseBranchName} on ${ghInfo.rokuRepo} against the ${prodRokuBranchName} branch`);  
  let releasePrUrl = '';
  try {
    const releasePrRes = await octokit.pulls.create({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      title: `Release ${fullBuildTag}`,
      head: releaseBranchName,
      base: prodRokuBranchName
    });
    releasePrUrl = releasePrRes.data.html_url;
  } catch(err) {
    console.log(err);
    done(new NoStackError(err));
  }

  // copy the PR urls to the clipboard
  if (releasePrUrl && cdnPrUrl) {
    
    // multi line string
    const prUrlsForPasting = `${releasePrUrl}
${cdnPrUrl}`;

    clipboardy.writeSync(prUrlsForPasting);
    console.log(`The release PR url and the CDN PR url have been placed on your clipboard. Please share with the team!`)
  } else {
    const errorMsg = 'The urls for the release PR and the CDN PR are not available. Please share manually.'
    done(new NoStackError(errorMsg));
  }
}


exports.build = series(clean, buildInstalled, buildStarter, buildRemote);
exports.sideload = sideLoad;
exports['build-downloads'] = series(buildStarter, buildRemote, packageStarter, packageRemote);
exports.bump = bumpBuild;
exports.install = series(exports.build, conditionalPackage, sideLoad);
exports.test = series(setTest, clean, preprocessTests, buildInstalled, sideLoad);
exports.stage = series(setStaging, exports.build, packageAll, pushStaging);
exports.release = series(confirmRelease, setProduction, bumpBuild, tagBuild, exports.build, packageAll, makeReleasePrs);

//command lines related to the crowdin language translations
exports.update_local_translations = updateLocalTranslations;
exports.upload_translations = series(updateLocalTranslations, uploadTranslations);
exports.download_translations = downloadTranslations;
