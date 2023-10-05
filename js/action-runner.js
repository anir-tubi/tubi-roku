'use strict';
const log = require('fancy-log');
// This file provides functions related to Github action runner creation and running

const prompts = require('prompts');
const {execShellCommand, spawnShellCommand, NoStackError} = require('./utilities');
const fs = require('fs');
const path = require('path');
const shell = require('shelljs');

const runnerImageName = 'automated-tests-runner';
const basePath = 'docker/automated-tests-runner';


async function setupAutomatedTestsGithubActionRunner(done) {
  // First check if podman is available
  await verifyPodmanIsAvailable(done);

  // Next see if we have all the necessary things ready to go

  // First see if we've already setup the runner
  const inspectResult = shell.exec(`podman inspect ${runnerImageName}`);
  if (inspectResult.code === 0) {
    log('Automated tests Github action runner already setup.\nTo remove it run: gulp removeAutomatedTestsGithubActionRunner\nTo start the runner run: gulp startAutomatedTestsRunner');
    // If code is zero we're good to go and can exit
    return;
  }
  // If code isn't 0 then we need to make the docker image

  // Check to make sure we have our rta-config.json file
  const runnerRtaConfigPath = path.resolve(`${basePath}/rta-config.json`);
  let hasRtaConfig = true;
  if (!fs.existsSync(runnerRtaConfigPath)) {
    hasRtaConfig = false;
    const projectRtaConfigPath = path.resolve('rta-config.json');
    if (fs.existsSync(projectRtaConfigPath)) {
      const {copyExisting} = await prompts({
        type: 'confirm',
        initial: true,
        name: 'copyExisting',
        message: `An existing rta-config.json file was found at ${projectRtaConfigPath}. Would you like to copy this for use with your automated tests runner?`
      });

      if (copyExisting) {
        fs.copyFileSync(projectRtaConfigPath, runnerRtaConfigPath);
        hasRtaConfig = true;
      } else {
        done(new NoStackError(`You have chosen not to use the existing rta-config.json. Please manually add the file at ${runnerRtaConfigPath}`));
      }
    }
  } else {
    log('Existing rta-config.json file found. Reusing it.');
  }

  if (!hasRtaConfig) {
    done(new NoStackError('No existing runner rta-config.json was found. Please follow these steps for creating your config:\nhttps://tubitv.atlassian.net/wiki/spaces/QA/pages/2827419649/Roku+RTA+tests+environment+setup+and+getting+started+writing+tests'));
  }

  // Check the system architecture and have the runner match that architecture
  let runnerArch = 'arm64';
  if (execShellCommand(done, 'uname -m').trim() !== runnerArch) {
    runnerArch = 'x64';
  }

  // Runner config
  const {configLine} = await prompts({
    type: 'text',
    name: 'configLine',
    message: 'To get your runner setup please go to:\nhttps://github.com/adRise/project-total-recall/settings/actions/runners/new.\nYou will see a line like:\n"./config.sh --url https://github.com/adRise/project-total-recall --token XXXXXXXXXXX"\nCopy and paste it here. If you do not have access to this page, please ask a developer such as Brian Leighty to provide the required token for you to paste here.'
  });

  const configMatch = configLine?.match(/--url (\S*) --token (\S*)/);
  if (!configMatch) {
    done(new NoStackError('Could not extract config information from the text supplied'));
  }
  const url = configMatch[1];
  const token = configMatch[2];

  const {runnerName} = await prompts({
    type: 'text',
    name: 'runnerName',
    message: 'What would you like to name this runner?'
  });

  if (!runnerName) {
    done(new NoStackError('You must supply a nonempty runner name'));
  }

  // Finally go ahead and build the image
  const command = `podman build --build-arg url=${url} --build-arg token=${token} --build-arg "name=${runnerName}" --tag ${runnerImageName} --build-arg RUNNER_ARCH=${runnerArch} ${basePath}`;
  await spawnShellCommand(done, command);

  log('Runner setup successfully. To start it run:\ngulp startAutomatedTestsRunner');
}


async function startAutomatedTestsGithubActionRunner(done) {
  await verifyPodmanIsAvailable(done);

  const inspectResult = shell.exec(`podman inspect ${runnerImageName}`);
  if (inspectResult.code !== 0) {
    done(new NoStackError('Runner has not been setup yet. Please run:\ngulp setupAutomatedTestsGithubActionRunner'));
  }

  const command = `podman run --name ${runnerImageName} --rm -ti ${runnerImageName}`;
  await spawnShellCommand(done, command, true);
}


async function removeAutomatedTestsGithubActionRunner(done) {
  await verifyPodmanIsAvailable(done);

  const command = `podman image rm ${runnerImageName}`;
  await spawnShellCommand(done, command, true);
}


async function verifyPodmanIsAvailable(done) {
  // Check if podman is installed
  const podmanResult = shell.exec(`which podman`);
  if (podmanResult.code !== 0) {
    // If not installed then check if brew is installed
    const brewResult = shell.exec(`which brew`);
    if (brewResult.code !== 0) {
      const {installBrew} = await prompts({
        type: 'confirm',
        name: 'installBrew',
        message: `Required dependency brew not found. Would you like to install it now?`
      });

      if (installBrew) {
        // If not installed then install brew
        const command = `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`;
        await spawnShellCommand(done, command);
      } else {
        done(new NoStackError('brew not available. Exiting...'));
      }
    }
    log('podman not found. Installing...');
    const command = `brew install podman`;
    await spawnShellCommand(done, command);
  }

  // Make sure the virtual machine is setup
  const podmanMachineResult = shell.exec(`podman machine inspect`);
  if (podmanMachineResult.code !== 0) {
    log('podman does not have a virtual machine yet. Installing...');
    // We don't have the virtual machine setup yet
    const command = `podman machine init`;
    await spawnShellCommand(done, command);
  }

  // Make sure the virtual machine is running
  const podmanInfoResult = shell.exec(`podman info`);
  if (podmanInfoResult.code !== 0) {
    // We don't have the virtual machine started yet
    const command = `podman machine start`;
    await spawnShellCommand(done, command);
  }
}


module.exports = {
  setupAutomatedTestsGithubActionRunner,
  startAutomatedTestsGithubActionRunner,
  removeAutomatedTestsGithubActionRunner
};
