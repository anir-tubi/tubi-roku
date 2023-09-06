'use strict';
// This file provides some functions for running our own automated tests.

const prompts = require('prompts');
const mocha = require('gulp-mocha');
const {src} = require('gulp');
const env = require('gulp-env');
const {device, utils} = require('roku-test-automation');
const fs = require('fs');

const {execShellCommand, spawnShellCommand} = require('./utilities');

const testsOutputFolder = `out/ui-tests-output`;
const jsonReportOutputPath = `${testsOutputFolder}/report.json`;

// Tries to convert the supplied suitest test over to our own test format
async function runAutomatedTestsCli (done) {
  const availableTags = getAvailableTags();

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

  const {branch} = await prompts({
    type: 'text',
    name: 'branch',
    message: 'Enter the branch name you would like to run against. If you would like to use the current checked out version then just hit enter'
  });

  if (branch === undefined) {
    // User hit control-c to exit so don't continue
    done();
    return;
  }
  await runAutomatedTests(done, branch, tags);
  done();
}


async function runAutomatedTests(done, branch = '', tags = [], bail = false) {
  const mochaOptions = [
    '--reporter js/automated-tests/mocha-reporter.ts', // Tell mocha to use our custom reporter
    `--reporter-option output=${jsonReportOutputPath}`, // output path for json reporter
    `--reporter-option reportDir=${testsOutputFolder}/html`, // folder for mochawesome
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

  // Used to allow specifying whether we should bail when run from the Github UI for the Automated UI Tests Github runner
  if (process.env.bail === 'true') {
    mochaOptions.push('--bail');
  }

  let applicationFolder = './';
  if (branch) {
    applicationFolder = './out/automated_tests_branch';
    execShellCommand(done, `rm -rf ${applicationFolder}`);
    execShellCommand(done, `git clone --branch ${branch} --depth 1 git@github.com:adRise/project-total-recall.git ${applicationFolder}`);
  }

  execShellCommand(done, `gulp --cwd ${applicationFolder} buildAutomatedTests`);

  const config = utils.getConfigFromConfigFile();
  env.set({
    buildFolder: `${applicationFolder}/build/local`,
    rtaConfig: JSON.stringify(config)
  });

  await spawnShellCommand(done, `npx mocha ${mochaOptions.join(' ')} js/automated-tests/tests/*.ts`);
  await appendDataToJsonReport(branch);
  done();
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

  fs.writeFileSync(jsonReportOutputPath, JSON.stringify(report));
}


// Gets a list of all tags available for our tests.
// Pulled from the actual tests
function getAvailableTags(folder = 'js/automated-tests/tests') {
  const tags = {};
  const files = fs.readdirSync(folder);
  const pattern = /it\([^@]*([@a-zA-Z_0-9,]*)/g;
  for (const file of files) {
    if (file.split('.').pop() !== 'ts') {
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
  runAutomatedTests,
  outputAvailableAutomatedTestTags
};
