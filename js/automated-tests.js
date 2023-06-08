'use strict';
// This file provides some functions for running our own automated tests.

const prompts = require('prompts');
const mocha = require('gulp-mocha');
const {src} = require('gulp');
const env = require('gulp-env');
const {utils} = require('roku-test-automation');
const fs = require('fs');

const {execShellCommand} = require('./utilities');

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

  const {branch} = await prompts({
    type: 'text',
    name: 'branch',
    message: 'Enter the branch name you would like to run against. If you would like to use the current checked out version then just hit enter'
  });

  let applicationFolder = './';
  if (branch) {
    applicationFolder = './out/automated_tests_branch';
    execShellCommand(done, `rm -rf ${applicationFolder}`);
    execShellCommand(done, `git clone --branch ${branch} --depth 1 git@github.com:adRise/project-total-recall.git ${applicationFolder}`);
  }

  execShellCommand(done, `gulp --cwd ${applicationFolder} buildAutomatedTests`);

  const config = utils.getConfigFromConfigFile();
  const envs = env.set({
    buildFolder: `${applicationFolder}/build/local`,
    rtaConfig: JSON.stringify(config)
  });

  src(['js/automated-tests/tests/*.ts'], { read: false })
    .pipe(envs)
    .pipe(mocha({
      grep: tags.join('|')
    }));
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
      for (const tag of match[1].split(',')) {
        tags[tag] = true;
      }
    }
  }

  return Object.keys(tags).sort();
}


module.exports = {
  runAutomatedTestsCli
};
