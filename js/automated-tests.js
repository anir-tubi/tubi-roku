'use strict';
// This file provides some functions for running our own automated tests.

const branchTestingFolder = './out/automated_tests_branch';

// We're using TypeScript code here so have to include this
require('ts-node/register');

const prompts = require('prompts');
const env = require('gulp-env');
const {device, utils} = require('roku-test-automation');
const fs = require('fs');
const log = require('fancy-log');
const path = require('path');

const {execShellCommand, spawnShellCommand} = require('./utilities');

const { testUtils, auth, ContentTypes, ContentRatings } = require('./automated-tests/test-utils');

const jsonReportOutputPath = `${testUtils.testsOutputFolder}/report.json`;

async function runAutomatedTestsCli(done, testsPath = 'js/automated-tests/tests/*.ts') {
  const testsFolder = path.dirname(testsPath);
  const availableTags = getAvailableTags(testsFolder);

  const choices = [];

  for (const tag of availableTags) {
    choices.push({
      title: tag,
      value: tag
    });
  }

  const {tags} = await prompts({
    type: 'multiselect',
    name: 'tags',
    message: 'Use the space bar to select the tag(s) you would like to test.',
    choices: choices,
  });

  if (tags === undefined) {
    // User hit control-c to exit so don't continue
    done();
    return;
  } else if (tags.length === 0) {
    console.log('No tags selected. Exiting.');
    done();
    return;
  }

  let shouldUseExistingBranch = false;

  if (fs.existsSync(branchTestingFolder)) {
    // If we have a branch folder then ask them if they want to use that instead of inputting a new one
    const existingBranchName = execShellCommand(done, `git -C ${branchTestingFolder} branch --show-current`).trim();
    const result = await prompts({
      type: 'confirm',
      name: 'shouldUseExistingBranch',
      message: `An existing branch '${existingBranchName}' was found. Would you like to reuse it and pull down the latest changes?`
    });
    shouldUseExistingBranch = result.shouldUseExistingBranch;
  }

  let branch = '';
  if (!shouldUseExistingBranch) {
    const {branchInput} = await prompts({
      type: 'text',
      name: 'branchInput',
      message: 'Enter the branch name you would like to run against. If you would like to use the current checked out version then just hit enter'
    });

    if (branchInput === undefined) {
      // User hit control-c to exit so don't continue
      done();
      return;
    } else {
      branch = branchInput;
    }
  }

  await runAutomatedTests(done, branch, tags, testsPath, shouldUseExistingBranch);
  done();
}

async function runAutomatedAnalyticsTestsCli(done) {
  env.set({
    analyticAutomatedTests: 'true'
  });
  await runAutomatedTestsCli(done, 'js/automated-tests/analytics/tests/*.ts');
  done();
}

async function runAutomatedAnalyticsTestsForAdsCli(done) {
	env.set({
		enableAdsForTesting: 'true',
	});
	await runAutomatedTestsCli(done, 'js/automated-tests/analytics/tests/*.ts');
	done();
}


async function buildTestAccountCli(done) {
  // We don't want to have to hit a Roku device for this helper so we just make up a fake device id
  auth['deviceId'] = utils.randomStringGenerator(36);

  const userChoices = [
    'Create new user',
    'Use existing user'
  ];

  const {userChoiceIndex} = await prompts({
    type: 'select',
    name: 'userChoiceIndex',
    message: 'What user would would like to use?',
    choices: userChoices
  });
  if (userChoiceIndex === undefined) {
    // User hit control-c to exit so don't continue
    done();
    return;
  }

  // create new user
  let user;
  if (userChoiceIndex == 0) {
    user = await testUtils.createRegisteredUser();
  } else {
    // use existing user
    const emailPrompt = {
      type: 'text',
      name: 'email',
      message: 'Please provide the user\'s email'
    };

    const emailPassword = {
      type: 'text',
      name: 'password',
      message: 'Please provide the user\'s password'
    };
    const credentials = await prompts([emailPrompt, emailPassword]);
    if (credentials.password === undefined) {
      // User hit control-c to exit so don't continue
      done();
      return;
    }

    user = await testUtils.loginAsUser(credentials);
  }

  let shouldContinue = true;
  while (shouldContinue) {
    const content = user.getContent();

    // We are using this file from TypeScript and so have to prevent the compile error by typing more loosely
    /** @type any[] */
    const contentTypeChoices = Object.keys(ContentTypes);
    const {contentTypeIndex} = await prompts({
      type: 'select',
      name: 'contentTypeIndex',
      message: 'What type of content would you like to add?',
      choices: Object.keys(ContentTypes)
    });
    if (contentTypeIndex === undefined) {
      // User hit control-c to exit so don't continue
      done();
      return;
    }
    const contentType = contentTypeChoices[contentTypeIndex];
    content.ofContentType(contentType);

    const ratingChoices = Object.keys(ContentRatings);
    const {ratingIndexes} = await prompts({
      type: 'multiselect',
      name: 'ratingIndexes',
      message: 'What ratings would like to allow?',
      choices: ratingChoices
    });
    if (ratingIndexes === undefined) {
      // User hit control-c to exit so don't continue
      done();
      return;
    }
    const ratings = ratingIndexes.map(index => ratingChoices[index]);
    content.withRating(ratings);

    const {limit} = await prompts({
      type: 'number',
      name: 'limit',
      message: 'How many would you like to add?',
      min: 1
    });
    if (limit === undefined) {
      // User hit control-c to exit so don't continue
      done();
      return;
    }

    let contentsLimit = Math.floor(limit / 5);
    if (contentsLimit < 10) {
      contentsLimit = 10;
    }

    const retrievedContents = await content.retrieve({
      limit: limit,
      contentsLimit: contentsLimit
    });

    log(`Retrieved ${retrievedContents.length} matching ${contentType}`);
    if (retrievedContents.length) {
      const whereToAddChoices = ['Continue Watching', 'Watch List'];
      const {whereToAddChoiceIndex} = await prompts({
        type: 'select',
        name: 'whereToAddChoiceIndex',
        message: 'Where would you like to add this content?',
        choices: whereToAddChoices
      });
      if (whereToAddChoiceIndex === undefined) {
        // User hit control-c to exit so don't continue
        done();
        return;
      }

      // Continue Watching
      if (whereToAddChoiceIndex === 0) {
        await user.addContentToViewHistory(retrievedContents, 500);
      } else {
        await user.addContentToWatchList(retrievedContents);
      }
    }

    const continuePrompt = {
      type: 'confirm',
      name: 'shouldContinue',
      message: 'Would you like to add more content?'
    };
    ({shouldContinue} = await prompts(continuePrompt));
  }

  log(`Generated user info:
  email: ${user['userInfo'].email}
  password: ${user['userInfo'].password}`);
  done();
}


function runAutomatedTestsSmoke(done) {
  return runAutomatedTests(done, '', ['@smoke']);
}


async function runAutomatedTests(done, branch = '', tags = [], testsPath = 'js/automated-tests/tests/*.ts', shouldUseExistingBranch = false) {
  // Load env file to allow overrides while developing tests
  const envPath = '.vscode/.env';
  if (fs.existsSync(envPath)) {
    env({
      file: envPath,
      type: '.ini',
    });
  }

  // Clear out any existing output. Should be ok to do asynchronous since we have several long steps before we start writing to output folder
  fs.rm(testUtils.testsOutputFolder, { recursive: true, force: true }, (e) => {});

  const mochaOptions = [
    '--reporter js/automated-tests/mocha-reporter.ts', // Tell mocha to use our custom reporter
    `--reporter-option output=${jsonReportOutputPath}`, // output path for json reporter
    `--reporter-option reportDir=${testUtils.testsOutputFolder}/html`, // folder for mochawesome
    `--reporter-option reportFilename=report`, // filename for mochawesome
    `--reporter-option json=false` // turn off json output for mochawesome
  ];

  // Used to allow specifying a tag to limit to when run from the Github UI for the Automated UI Tests Github runner. Also used to specify if we are using a custom string instead.
  if (process.env.tag) {
    let tag = process.env.tag;
    if (tag === 'Custom String') {
      tags = process.env.customString.split('|');
    } else if (tag.startsWith('@')) {
      tags = [tag];
    }
  }

  if (tags.length > 0) {
    mochaOptions.push(`--grep "${tags.join('|')}"`);
  }

  // Used to allow specifying whether we should bail when run from the Github UI for the Automated UI Tests Github runner or while developing tests
  if (process.env.bail === 'true' || process.env.ENABLE_MOCHA_BAIL === 'true') {
    mochaOptions.push('--bail');
  }

  let applicationFolder = './';
  if (shouldUseExistingBranch) {
    applicationFolder = branchTestingFolder;
    execShellCommand(done, `git -C ${applicationFolder} pull`);
  } else if (branch) {
    applicationFolder = branchTestingFolder;
    execShellCommand(done, `rm -rf ${applicationFolder}`);
    execShellCommand(done, `git clone --branch ${branch} --depth 1 git@github.com:adRise/project-total-recall.git ${applicationFolder}`);
  }

  execShellCommand(done, `gulp --cwd ${applicationFolder} buildAutomatedTests`);

  const buildFolder = `${applicationFolder}/build/local`;
  env.set({
    buildFolder: buildFolder
  });

  const config = utils.getConfigFromConfigFile();
  // Enable parallel testing if multiple devices are included and we haven't disabled running in parallel
  if (config.RokuDevice.devices.length > 1 && process.env.DISABLE_MOCHA_PARALLEL !== 'true') {
    mochaOptions.push(`--parallel --jobs ${config.RokuDevice.devices.length}`);
  }

  // Adding retries. May eventually want to allow turning on or off
  mochaOptions.push('--retries 1');

  // We need to make our package here or else when we run in parallel they will all attempt to make the package at the same time
  await device.createPackage({
    rootDir: buildFolder,
    files: [
      '**/*'
    ]
  });

  const code = await spawnShellCommand(done, `npx mocha ${mochaOptions.join(' ')} ${testsPath}`, true);
  await appendDataToJsonReport(branch);
  if (code !== 0) {
    done(new Error('Tests failed'));
  } else {
    done();
  }
}


// Used to convert Roku ECP output with dashes between words to our standard camel case. Courtesy of chatgpt
function capitalizeAfterDash(str) {
  const words = str.split('-');
  const capitalizedWords = words.map((word, index) => {
  if (index === 0) {
    return word;
  } else {
    const firstLetter = word.charAt(0).toUpperCase();
    const restOfWord = word.slice(1);
    return firstLetter + restOfWord;
  }
  });
  return capitalizedWords.join('');
}


// We want to add a few more things to the json report that aren't included in the standard output
async function appendDataToJsonReport(branch) {
  const report = JSON.parse(fs.readFileSync(jsonReportOutputPath, 'utf-8'));

  // Retrieve info about the device that ran the tests
  const {body: deviceInfoBody} = await device.sendEcpGet('query/device-info');
  const deviceInfo = {};
  const deviceInfoKeyList = [
    'uptime',
    'software-version',
    'software-build',
    'model-name',
    'model-number',
    'user-device-name',
    'ui-resolution',
    'serial-number',
    'model-region',
    'network-type'
  ];
  for (const key of deviceInfoKeyList) {
    for (const child of deviceInfoBody.children) {
      if(child.name === key) {
        deviceInfo[capitalizeAfterDash(key)] = child.value;
        break;
      }
    }
  }
  report.deviceInfo = deviceInfo;

  let runName = 'unavailable';
  if (process.env.runName) {
    runName = process.env.runName;
  }

  let runId = 'unavailable';
  if (process.env.runId) {
    runId = process.env.runId;
  }

  if (!branch) {
    branch = process.env.branch;
  }

  if (!branch) {
    branch = 'unavailable';
  }

  // Retrieve application version that ran the tests
  let applicationVersion = 'unavailable';
  const {body: appsBody} = await device.sendEcpGet('query/apps');
  for (const child of appsBody.children) {
    if(child.attributes.id === 'dev') {
      applicationVersion = child.attributes.version;
    }
  }

  report.runInfo = {
    runName: runName,
    runId: runId,
    applicationVersion: applicationVersion,
    branch: branch
  };

  fs.writeFileSync(jsonReportOutputPath, JSON.stringify(report, undefined, 2));
}


// Gets a list of all tags available for our tests.
// Pulled from the actual tests
function getAvailableTags(folder = 'js/automated-tests/tests') {
  const tags = {};
  const files = fs.readdirSync(folder);
  const pattern = /it\([^@]*([@a-zA-Z_0-9,]*)/g;
  for (const file of files) {
    if (!folder.includes('analytics') && file.split('.').pop() !== 'ts') {
      continue;
    }

    const fileContents = fs.readFileSync(`${folder}/${file}`, 'utf-8');
    for (const match of fileContents.matchAll(pattern)) {
      for (let tag of match[1].split(',')) {
        tag = tag.trim();
        if (tag.length === 0) {
          continue;
        }
        tags[tag] = true;
      }
    }
  }

  return Object.keys(tags).sort();
}

// Used to output an updated list of tags for use in .github/workflows/automatedTests.yml file
function outputAvailableAutomatedTestTags(done) {
  const tags = getAvailableTags();

  for (const tag of tags) {
    console.log(`- '${tag}'`);
  }
  done();
}


module.exports = {
  runAutomatedTestsCli,
  runAutomatedAnalyticsTestsCli,
  runAutomatedAnalyticsTestsForAdsCli,
  buildTestAccountCli,
  runAutomatedTests,
  outputAvailableAutomatedTestTags,
  jsonReportOutputPath,
  runAutomatedTestsSmoke
};
