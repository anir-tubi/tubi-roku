const log = require('fancy-log');
const clipboardy = require('clipboardy');
const prompts = require('prompts');
const fs = require('fs');
const path = require('path');
const os = require('os');
const shell = require('shelljs');
const webFetch = require('node-fetch');
shell.config.silent = true;

const { getBuildTag, incrementBuildNumber, incrementRevisionNumber } = require('./config');
const { NoStackError, execShellCommand } = require('./utilities');

const githubDeveloperInfo = require('./github-developer-info.json');

// constants used for interacting with the github API
const ghInfo = {
  owner: 'adRise',
  rokuRepo: 'project-total-recall',
  rcdnRepo: 'rcdn',
};

const hotfixRelease = 'Hotfix Release';
const remoteRelease = 'Remote Release';
const submissionRelease = 'Submission Release';

// Github API wrapper
let _octokit;
function octokit() {
  if (!_octokit) {
    const { Octokit } = require('@octokit/rest');
    _octokit = new Octokit({
      auth: process.env.GITHUB_PAT,
      userAgent: 'project-total-recall-build-server',
      baseUrl: 'https://api.github.com'
    });
  }
  return _octokit;
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
    directory = directory ? directory : process.cwd();
    done(new NoStackError(`Git error: current directory (${directory}) is not part of a git repo.`));
    return false;
  } else if (shell.exec(`git ${gitDirectory} status --porcelain`).stdout) {
    directory = directory ? directory : process.cwd();
    done(new NoStackError(`Git error: working directory (${directory}) is dirty - stash or commit your changes before proceeding.`));
    return false;
  } else {
    return true;
  }
}


// Calls function createCdnPrUrl to push and create PR to rcdn repo
// Additionally make a PR against the production release branch on project-total-recall and copy the
// urls to the local clipboard.
async function makeReleasePrs(done) {
  // Note that git commands will have a code = 0 when there is no error and code > 0 when an error occurred.
  // Also note that git commands have a stderr output even if the code === 0.

  const minorBuildTag = getBuildTag('minor');
  const fullBuildTag = getBuildTag('revision');

  // rename the local branch name so it looks like "release_2_14_34"
  const releaseBranchName = `release_${fullBuildTag}`;
  log(`...Renaming the local branch to ${releaseBranchName}`);
  const gitRename = `git branch -m ${releaseBranchName}`;
  const gitRenameErrorMsg = `Could not rename the local branch to ${releaseBranchName}`;
  execShellCommand(done, gitRename, gitRenameErrorMsg);

  const cdnBranchName = `roku_${fullBuildTag}`;

  const commitMessage = `Updating the starter and remote components for ${cdnBranchName}`;

  const starterComponentsFileName = `tubi_starter_components_${minorBuildTag}.pkg`;
  const remoteComponentsFileName = `tubi_remote_components_${fullBuildTag}.pkg`;

  const localStarterComponentsPath = `build/${starterComponentsFileName}`;
  const localRemoteComponentsPath = `build/${remoteComponentsFileName}`;

  //create PR against rcdn repository
  let filePaths = [{
    src: localStarterComponentsPath,
    dest: `appFiles/starter-components/${starterComponentsFileName}`
  }, {
    src: localStarterComponentsPath,
    dest: `rollbackStarterComponents/${fullBuildTag}/${starterComponentsFileName}` // Only sending to rcdn
  }, {
    src: localRemoteComponentsPath,
    dest: `appFiles/components/${remoteComponentsFileName}`
  }];

  const rcdnPrUrl = await createCdnPullRequest(done, {
    filePaths: filePaths,
    cdnBranchName: cdnBranchName,
    commitMessage: commitMessage
  });

  // push the release branch to the project-total-recall repo
  log(`...Pushing the local ${releaseBranchName} branch to the remote ${ghInfo.rokuRepo} repo`);
  const gitPushReleaseBranch = `git push origin ${releaseBranchName}`;
  const gitPushReleaseBranchErrorMsg = `Could not push ${releaseBranchName} to ${ghInfo.rokuRepo} origin (Github)`;
  execShellCommand(done, gitPushReleaseBranch, gitPushReleaseBranchErrorMsg);

  // make a PR against the production branch on the project-total-recall repo at Github
  const prodRokuBranchName = `${minorBuildTag}_branch`;
  log(`...Making a PR from the remote ${releaseBranchName} on ${ghInfo.rokuRepo} against the ${prodRokuBranchName} branch`);
  let releasePrUrl = '';
  let bodyText = 'Verify: The last commit in this PR is a build bump. If the last commit in this PR is not a build bump, the release needs to be run again. Any other commit that is not a build bump, including a merge, indicates a commit has been included that was not included in the package that was built and sent to the CDN.\n\nPlease verify README item #18 in the Remote Release section (ie. do any changes in this remote release disallow falling back to the submitted version)';
  try {
    const releasePrRes = await octokit().pulls.create({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      title: `Release ${fullBuildTag}`,
      body: bodyText,
      head: releaseBranchName,
      base: prodRokuBranchName
    });

    releasePrUrl = releasePrRes.data.html_url;
  } catch (err) {
    console.log(err);
    done(new NoStackError(err));
  }

  // copy the PR urls to the clipboard
  if (releasePrUrl && rcdnPrUrl) {
    // multi line string
    const prUrlsForPasting = `${releasePrUrl}
${rcdnPrUrl}`;

    clipboardy.writeSync(prUrlsForPasting);
    log(`The release PR url and the CDN PR url have been placed on your clipboard. Please share with the team!`);
  } else {
    const errorMsg = 'The urls for the release PR and the CDN PR are not available. Please share manually.';
    done(new NoStackError(errorMsg));
  }
}


//All the steps necessary to push starter and remote components to the CDN and make a PR to the CDN
// returns the URL string of created PR.
// @args: object, args to be passed in function:
//    filePaths: array of objects, each object has src and dest keys. The value for src is the path to the file being added to the CDN. The value for dest is the path within the CDN repo to which the file will be copied.
//    cdnBranchName: string, the branch name to be created on the CDN repo
//    commitMessage: string, the commit message to be used for the PR
async function createCdnPullRequest(done, {
  filePaths,
  cdnBranchName,
  commitMessage
}) {
  let cdnPath = process.env.RCDN_GIT_DIRECTORY;
  let ghInfoCDNRepo = `${ghInfo.rcdnRepo}`;
  let cdnDirVariable = `RCDN_GIT_DIRECTORY`;

  // fs.mkdir does not handle the tilde correctly so we need to replace it with the absolute path to the home directory to avoid failing
  if (cdnPath.startsWith('~')) {
    cdnPath = path.join(os.homedir(), cdnPath.slice(1));
  }


  // check if the environment variable for the path to the CDN repo has been set
  if (!cdnPath) {
    const errorMsg = `You did not set a ${cdnDirVariable} variable in your .bash_profile or .bashrc or .zsh_profile file.`;
    done(new NoStackError(errorMsg));
  }

  // check that the CDN repo is clean - verifyGit() handles any error messages as necessary
  verifyGit(done, cdnPath);


  // attempt to checkout master in the CDN repo
  log(`...Checking out master on the local ${ghInfoCDNRepo} repo`);
  const gitCheckoutMasterCDN = `git -C ${cdnPath} checkout master`;
  const gitCheckoutMasterCDNErrorMsg = `Could not checkout master on the ${cdnPath}`;
  execShellCommand(done, gitCheckoutMasterCDN, gitCheckoutMasterCDNErrorMsg);

  // attempt to pull origin master for the CDN repo
  log(`...Pulling remote master to the local ${ghInfoCDNRepo} repo`);
  const gitPullMasterCDN = `git -C ${cdnPath} pull origin master`;
  const gitPullMasterCDNErrorMsg = `Could not pull master from origin at ${cdnPath}`;
  execShellCommand(done, gitPullMasterCDN, gitPullMasterCDNErrorMsg);

  // attempt to check out a new branch off master for the CDN repo
  // check if there is already a branch with the cdnBranchName and delete it if there is
  log(`...Checking if there already exists a local branch named ${cdnBranchName} on ${cdnPath}`);
  const gitListCDNBranch = `git -C ${cdnPath} branch --list ${cdnBranchName}`;
  const gitListCDNBranchErrorMsg = `Could not list the "${cdnBranchName}" at ${cdnPath}`;
  const gitListRes = execShellCommand(done, gitListCDNBranch, gitListCDNBranchErrorMsg);

  if (gitListRes) {
    // there exists a branch with the cdnBranchName already, so delete it.
    // We've already switched to master on `${cdnPath}` earlier in this flow.
    log(`...Deleting the ${cdnBranchName} on ${cdnPath}`);
    const gitDeleteCDNBranch = `git -C ${cdnPath} branch -D ${cdnBranchName}`;
    const gitDeleteCDNBranchErrorMsg = `Could not delete the "${cdnBranchName}" branch at ${cdnPath}`;
    execShellCommand(done, gitDeleteCDNBranch, gitDeleteCDNBranchErrorMsg);
  }

  log(`...Creating a new ${cdnBranchName} branch on the local ${ghInfoCDNRepo} repo`);
  const gitCheckoutNewCDNBranch = `git -C ${cdnPath} checkout -b ${cdnBranchName}`;
  const gitCheckoutNewCDNBranchErrorMsg = `Could not checkout a new branch "${cdnBranchName}" at ${cdnPath}`;
  execShellCommand(done, gitCheckoutNewCDNBranch, gitCheckoutNewCDNBranchErrorMsg);

  // Loops through each filePath object and copies the file from the src path to the dest path.
  for (const filePath of filePaths) {
    const destinationFilePath = `${cdnPath}/${filePath.dest}`;

    // We want to make sure the folder always exists first or else the copy will fail
    fs.mkdirSync(path.dirname(destinationFilePath), { recursive: true });

    const moveRemoteComponentsRes = shell.cp(filePath.src, destinationFilePath);
    if (moveRemoteComponentsRes.stderr) {
      const errorMsg = `There was an error moving ${filePath.src}. You will need to manually copy ${filePath.src} and manually make a PR.
            Error Message: ${moveRemoteComponentsRes.stderr}`;
      done(new NoStackError(errorMsg));
      return;
    }
  }

  // add the updates so they are staged for commit
  log(`...Staging changes for commit on the local ${ghInfoCDNRepo} repo`);
  const gitAddCDNBranch = `git -C ${cdnPath} add .`;
  const gitAddCDNBranchErrorMsg = `Could not run "git add ." on ${cdnPath}`;
  execShellCommand(done, gitAddCDNBranch, gitAddCDNBranchErrorMsg);

  // commit the updates to the branch
  log(`...Committing the staged changes on the local ${ghInfoCDNRepo} repo`);
  const gitCommitCDNBranch = `git -C ${cdnPath} commit -m '${commitMessage}'`;
  const gitCommitCDNBranchErrorMsg = `"git commit" failed on ${cdnPath}`;
  execShellCommand(done, gitCommitCDNBranch, gitCommitCDNBranchErrorMsg);

  // push the branch to Github
  log(`...Pushing the local ${cdnBranchName} branch to the remote ${ghInfoCDNRepo} repo`);
  const gitPushCDNBranch = `git -C ${cdnPath} push origin ${cdnBranchName}`;
  const gitPushCDNBranchErrorMsg = `Could not push ${cdnBranchName} to origin (Github) at ${cdnPath}`;
  execShellCommand(done, gitPushCDNBranch, gitPushCDNBranchErrorMsg);

  // make a PR against master on the CDN repo at Github
  log(`...Making a PR on ${ghInfoCDNRepo} against the remote master branch`);
  let cdnPrUrl = '';
  let errMsg = `Failed to create CDN PR. Please create manually.`;
  try {
    const cdnPrRes = await octokit().pulls.create({
      owner: ghInfo.owner,
      repo: `${ghInfoCDNRepo}`,
      title: commitMessage,
      head: cdnBranchName,
      base: 'master'
    });
    cdnPrUrl = cdnPrRes.data.html_url;
  } catch (err) {
    errMsg = err;
  }

  // failed to make PR on CDN/RCDN repo at Github due to git process steps. In this event stop execution of the script.
  if (!cdnPrUrl) {
    return done(new NoStackError(errMsg));
  } else {
    return cdnPrUrl;
  }
}


async function createCdnPullRequestForOneTrustSDK(done, buildTag) {
  const oneTrustComponentsFileName = `tubi_one_trust_components_${buildTag}.pkg`;

  const filePaths = [{
    src: `build/${oneTrustComponentsFileName}`,
    dest: `appFiles/one-trust-components/${oneTrustComponentsFileName}`
  }];

  const cdnBranchName = `roku_one_trust_${buildTag}`;
  await createCdnPullRequest(done, {
    cdnBranchName: cdnBranchName,
    filePaths: filePaths,
    commitMessage: `Updating the one trust components for ${cdnBranchName}`
  });
}


async function createCdnPullRequestForFoxVideoPlayer(done, buildTag, pkgPath) {
  const filePaths = [{
    src: pkgPath,
    dest: `appFiles/fox-video-player-components/${path.basename(pkgPath)}`
  }];

  const cdnBranchName = `roku_fox_video_player_${buildTag}`;
  await createCdnPullRequest(done, {
    cdnBranchName: cdnBranchName,
    filePaths: filePaths,
    commitMessage: `Updating the fox video player components for ${cdnBranchName}`
  });
}


function pushTag(done) {
  const buildTag = getBuildTag('revision');
  log(`...Pushing the ${buildTag} tag to origin (Github)`);
  const pushTagRes = shell.exec(`git push origin ${buildTag}`);

  if (pushTagRes.code) {
    let errorMsg = `Could not push ${buildTag} tag to origin (Github)`;
    if (pushTagRes.stderr) {
      errorMsg = pushTagRes.stderr;
    }
    done(new NoStackError(errorMsg));
  }
  done();
}


function pushBranch(done) {
  log(`...Pushing QA branch to origin (Github)`);
  const currentBranch = getCurrentBranch(done);
  const gitPushCurrentBranch = `git push origin ${currentBranch}`;
  const gitPushCurrentBranchErrorMsg = `Could not push ${currentBranch} to origin (Github). Please push it manually`;

  execShellCommand(done, gitPushCurrentBranch, gitPushCurrentBranchErrorMsg);
  done();
}


async function createGithubRelease(done) {
  // Prompt if the dev wants to make a release via the CLI (as opposed to Github UI)
  const { releaseConfirmation } = await prompts({
    type: 'confirm',
    name: 'releaseConfirmation',
    message: 'Do you want to make a Github release now, in the CLI? (y/n)',
  });

  if (!releaseConfirmation) {
    const declineMsg = 'Github release not created by choice of dev. Please make a release by going to http://github.com/adRise/project-total-recall/tags';
    log(declineMsg);
    return done();
  }

  // Double check that the tag we want to make a release from exists on Github. According to Github API
  // docs, if we make a release and the tag does not exist, the API will automatically make a tag
  // based on master. But our release is not based on master. See the following doc links:
  // https://octokit.github.io/rest.js/v18#repos-create-release
  // https://octokit.github.io/rest.js/v18#repos-list-tags

  const buildTag = getBuildTag('revision');

  log(`...Double checking that the ${buildTag} tag exists on Github`);
  const gitLocalTagShaRes = shell.exec(`git rev-parse ${buildTag}`);
  if (gitLocalTagShaRes.code) {
    let errorMsg = `Could not get SHA for commit ${buildTag}`;
    if (gitLocalTagShaRes.stderr) {
      errorMsg += `\n${gitLocalTagShaRes.stderr}`;
    }
    done(new NoStackError(errorMsg));
  }

  const tagSha = gitLocalTagShaRes.stdout.trim();
  try {
    const topTags = await octokit().repos.listTags({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo
    });

    let isTagOnGithub = false;
    for (const tag of topTags.data) {
      if (tag.name === buildTag && tag.commit.sha === tagSha) {
        isTagOnGithub = true;
        break;
      }
    }

    if (!isTagOnGithub) {
      const errorMsg = `The ${buildTag} tag is not on Github. Not creating a release here or else Github will make automatically make a tag from master - which will be inaccurate for our purposes.`;
      done(new NoStackError(errorMsg));
    }
  } catch (err) {
    console.log(err);
    done(new NoStackError(err));
  }

  const { releaseType, isPreRelease, preReleaseDate } = await prompts([
    // prompt the dev for the release type to be used as the Release title
    {
      type: 'toggle',
      name: 'releaseType',
      message: 'Choose a release type (use arrow or tab keys to select)',
      initial: false,
      inactive: remoteRelease,
      active: submissionRelease,
      format: (val) => {
        // format the releaseType value as a remote/submission string instead of boolean
        return val ? submissionRelease : remoteRelease;
      }
    },
    // if it's a "Remote Release", prompt if it should be marked as a pre-release
    {
      type: (prev) => {
        // only show this prompt if it's a remote release, as submission releases are assumed
        // to be pre releases by default.
        return (prev === remoteRelease) ? 'confirm' : null;
      },
      name: 'isPreRelease',
      message: 'Should this release be marked as a pre release? Select no if the release will be deployed today. (y/n)',
    },
    // if it's a pre-release, prompt what the release date should be
    {
      type: (prev, values) => {
        return (values.isPreRelease || values.releaseType === submissionRelease) ? 'date' : null;
      },
      name: 'preReleaseDate',
      message: 'What date will this release be deployed? (use tab/arrow/number keys to modify date)',
      mask: 'MM/DD/YYYY',
      validate: (userDate) => {
        return userDate > Date.now() ? true : 'Release date must be in the future.';
      }
    },
  ]);

  const releaseNotes = await buildReleaseNotes(done);

  const date = preReleaseDate ? preReleaseDate.toLocaleDateString('en-US') : new Date().toLocaleDateString('en-US'); // '12/25/2020'
  releaseNotes.unshift(date);

  let formattedReleaseNotes = releaseNotes.join('\n');

  let releaseNotesState = `Current release notes:\n\n${formattedReleaseNotes}\n`;

  // prompt the dev to confirm the generated release notes
  log(releaseNotesState); //this is part of the CLI UI - leave in
  const { releaseNotesConfirmation } = await prompts([
    {
      type: 'confirm',
      name: 'releaseNotesConfirmation',
      message: 'Do the release notes above look correct? If you choose "no", you will need to update the release notes in Github manually. (y/n)'
    }
  ]);

  if (!releaseNotesConfirmation) {
    formattedReleaseNotes = date;
  }

  log(`...Creating a release from the ${buildTag} tag on Github`);
  try {
    await octokit().repos.createRelease({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      tag_name: buildTag,
      name: releaseType,
      body: formattedReleaseNotes,
      //mark as pre-release if there is a date associated with the pre release.
      prerelease: preReleaseDate ? true : false
    });
  } catch (err) {
    console.log(err);
    done(new NoStackError(err));
  }
}


//function to send slack reminders to create experiments for PRs that have "Experiment:" in the release notes
async function sendSlackReminders(done) {
  log(`...Sending slack reminders to the team`);
  const prodBranch = getProductionBranchName();
  const currentBranch = getCurrentBranch(done);
  const webHookUrl = 'https://hooks.slack.com/services/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';

  const pullRequestCommits = await findPullRequestCommitDifferences(done, currentBranch, prodBranch, true);

  // filter down to pull requests from currentBranch that aren't on prodBranch
  for (const commit of pullRequestCommits) {
    const prId = commit.prId;

    const response = await octokit().pulls.get({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      pull_number: +prId
    });

    const prReleaseNotes = extractReleaseNotesFromPullRequestBody(response.data.body);

    if (prReleaseNotes && prReleaseNotes.includes('Experiment:')) {
      log(`...Sending slack reminder for PR #${prId}`);
      const author = githubDeveloperInfo[response.data.user.login];
      const memberId = author.slackId;
      const message = `<@${memberId}> , Please create the experiment if needed for : \n\`\`\`  ${prReleaseNotes}\`\`\``;

      //post and forget
      webFetch(webHookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: message,
        }),
      });
    }

  }
  done();
}



// Helper to work around the fact you can't fetch if you're already on the branch
async function pullOrFetchBranch(done, branch) {
  if (!isBranchTrackingPresent(done, branch)) {
    // Add a prompt asking if engineer wants to proceed with the build.
    const { proceedWithGitPull } = await prompts({
      type: 'confirm',
      name: 'proceedWithGitPull',
      message: `${branch} is missing remote tracking. Do you wish to proceed? (y/n)`,
    });

    if (!proceedWithGitPull) {
      return done(new NoStackError('Script aborted'));
    } else {
      return;
    }
  }

  // pull origin of compareBranch
  if (getCurrentBranch(done) === branch) {
    // Have to pull if on the current branch as fetch will fail https://stackoverflow.com/questions/2236743/git-refusing-to-fetch-into-current-branch
    execShellCommand(done, `git pull`, `Could not pull ${branch} branch`);
  } else {
    execShellCommand(done, `git fetch origin ${branch}:${branch}`, `Could not fetch ${branch} branch`);
  }
}


// Checking if the branch has a remote branch tracking.
function isBranchTrackingPresent(done, branchName) {
  const remoteTrackingInfo = execShellCommand(done, `git ls-remote --heads origin ${branchName}`, `Could not execute get remote tracking info`);

  const result = shell.exec(`git rev-parse --abbrev-ref ${branchName}@{upstream}`, { silent: true });
  return remoteTrackingInfo.trim().length > 0 && result.code === 0;
}


async function buildReleaseNotes(done) {
  const prodBranch = getProductionBranchName();
  const currentBranch = getCurrentBranch(done);

  const pullRequestCommits = await findPullRequestCommitDifferences(done, currentBranch, prodBranch);

  const releaseNotes = [];

  // filter down to pull requests from currentBranch that aren't on prodBranch
  for (const commit of pullRequestCommits) {
    const prId = commit.prId;
    const response = await octokit().pulls.get({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      pull_number: +prId
    });

    const prReleaseNotes = extractReleaseNotesFromPullRequestBody(response.data.body);
    if (prReleaseNotes === undefined) {
      console.log(`Could not retrieve release notes for pull request #${prId}`);
    } else if (prReleaseNotes) {
      releaseNotes.push(prReleaseNotes);
    }
  }
  return releaseNotes;
}


async function buildQaChanges(done) {
  let prodBranch = getProductionBranchName();
  const currentBranch = getCurrentBranch(done);

  if (prodBranch === currentBranch) {
    prodBranch = getPreviousProductionBranchName();
  }

  let pullRequestCommits = await findPullRequestCommitDifferences(done, currentBranch, prodBranch);
  pullRequestCommits = pullRequestCommits.reverse();

  const qaChangesData = [];
  const qaChangesText = [];

  // filter down to pull requests from currentBranch that aren't on prodBranch
  for (const commit of pullRequestCommits) {
    const prId = commit.prId;
    const message = commit.message;
    const commitHash = message.split(' ')[0];

    const octokitRequestSharedParams = {
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
    };
    const { data: pullRequest } = await octokit().pulls.get({
      ...octokitRequestSharedParams,
      pull_number: +prId
    });

    const qaInfo = extractQaChangesFromPullRequestBody(pullRequest.body);
    if (!qaInfo) {
      console.log(`Could not retrieve qa info for pull request #${prId}`);
      continue;
    }

    if (!qaInfo.whatChanged) {
      continue;
    }

    let ticketUrl = '';
    const { data: prComments } = await octokit().issues.listComments({ ...octokitRequestSharedParams, issue_number: +prId });
    for (const prComment of prComments) {
      const commentShortcutLinkMatch = prComment.body.match(/\((https:\/\/app.shortcut.com\/tubi\/story\/[^)]+)\)/);
      if (commentShortcutLinkMatch) {
        ticketUrl = commentShortcutLinkMatch[1];
      }
      break;
    }

    const userLogin = pullRequest.user.login;
    if (!githubDeveloperInfo[userLogin]) {
      // If the user is not in the list then don't include in the QA changes.
      continue;
    }

    const qaChange = {
      pullNumber: prId,
      commit: commitHash,
      whatChanged: qaInfo.whatChanged,
      testingSteps: qaInfo.testingSteps,
      pointDeveloper: githubDeveloperInfo[userLogin],
      ticketUrl: ticketUrl
    };
    qaChangesData.push(qaChange);

    let formattedWhatChangedText = qaChange.whatChanged;
    if (ticketUrl) {
      formattedWhatChangedText += '\n' + ticketUrl;
    }

    qaChangesText.push(`**${qaChangesData.length}) What changed**
${formattedWhatChangedText}

**How to test (plus any other areas this change might affect)**
${qaChange.testingSteps}

**Point Developer**
${qaChange.pointDeveloper.name}`);
  }

  const minorVersionNumber = getBuildTag('minor');
  const buildVersionNumber = getBuildTag('build');
  let qaChangesTextOutput = `**Target Release Date**
<DEVELOPER-TO-FILL-IN>

**Staging Channel**
${minorVersionNumber}

**Branch Name (for automated testing)**
\`qa_${buildVersionNumber}\`
https://github.com/adRise/project-total-recall/tree/qa_${buildVersionNumber}

## Changes

${qaChangesText.join('\n\n<hr>\n\n')}`;

  return {
    changes: qaChangesData,
    text: qaChangesTextOutput
  };
}


function extractQaChangesFromPullRequestBody(body) {
  if (body) {
    const match = body.match(/## QA What Changed.*?---(.*)## QA Testing Steps.*?---(.*)/s);
    if (match) {
      const whatChanged = match[1].trim();
      const testingSteps = match[2].trim();
      return {
        whatChanged: whatChanged,
        testingSteps: testingSteps
      };
    }
  }
}


function extractReleaseNotesFromPullRequestBody(body) {
  if (body) {
    const match = body.match(/## Release Notes.*?---(.*)## QA What Changed/s);
    if (match) {
      return match[1].trim();
    }
  }
}


function getPullRequestCommitsForBranch(done, branch, commitCount, oneLine = false, includeAuthorName = false) {
  let command;

  if (includeAuthorName) {
    command = `git log ${branch} -${commitCount} --pretty=format:"%h %s - %an"`;
  } else {
    command = `git log ${branch} -${commitCount}`;
    if (oneLine) {
      command += ' --oneline';
    }
  }
  const gitLogs = execShellCommand(done, command, `Could not get git logs from ${branch} branch.`);
  const pullRequestCommits = [];
  gitLogs.split('\n')
    .forEach((message) => {
      const prId = extractPrIdFromCommitInfo(message);
      if (prId) {
        pullRequestCommits.push({
          message: message,
          prId: prId
        });
      }
    });
  return pullRequestCommits;
}


// Compares the commits on branchA against the commits on branchB, based on their pull request numbers, and returns an array of commit messages for the commits that exist on branchA but do not exist on branchB.
// @branchA: string, the branch name we are comparing to branchA
// @branchB: string, the branch name we are comparing to branchB
// @includeAuthorName: boolean, based this value the author name will be displayed along with commit message. Default - false
// @commitCount: number, the number of maximum number of commits you want to compare between the branches
// @returns: string[], the PR ID like '1234'
async function findPullRequestCommitDifferences(done, branchA, branchB, includeAuthorName = false, commitCount = 400) {
  // verify clean working directory
  verifyGit(done);

  // process/store pull requests on branchA branch
  await pullOrFetchBranch(done, branchA);
  const branchACommits = getPullRequestCommitsForBranch(done, branchA, commitCount, true, includeAuthorName);

  // process/store pull requests on branchB branch
  await pullOrFetchBranch(done, branchB);
  const branchBCommits = getPullRequestCommitsForBranch(done, branchB, commitCount * 2); // Note we need to not use oneLine output to include pull requests that may have been squash merged in.

  const pullRequestCommitsNotInBranchB = [];
  // filter down to pullRequests from master that aren't on compareBranch
  for (const branchACommit of branchACommits) {
    // If we didn't find the pull request then add it to the list
    if (!branchBCommits.find(branchBCommit => branchBCommit.prId === branchACommit.prId)) {
      pullRequestCommitsNotInBranchB.push(branchACommit);
    }
  }

  return pullRequestCommitsNotInBranchB;
}


// @compareBranch: string, the branch name we are comparing to master
async function findCommitsOnMasterNotOnBranch(done, compareBranch) {
  const commitsFromMasterNotOnCompareBranch = await findPullRequestCommitDifferences(done, 'master', compareBranch, true);
  commitsFromMasterNotOnCompareBranch.reverse();
  console.log('');
  console.log(`COMMITS THAT HAVE NOT BEEN CHERRY PICKED FROM master TO ${compareBranch}`);
  console.log('-----------------------------------------------------------------------');
  commitsFromMasterNotOnCompareBranch.forEach((item) => {
    console.log(item.message);
  });
  console.log('-----------------------------------------------------------------------');
  return done();
}


function getProductionBranchName() {
  const minorVersionNumber = getBuildTag('minor');
  const prodBranch = `${minorVersionNumber}_branch`;
  return prodBranch;
}


function getPreviousProductionBranchName() {
  let minorVersionNumberParts = getBuildTag('minor').split('_');
  let currentMinorVersionNumber = +minorVersionNumberParts[1];
  if (currentMinorVersionNumber > 0) {
    currentMinorVersionNumber -= 1;
    minorVersionNumberParts[1] = currentMinorVersionNumber.toString();
  } else {
    throw new NoStackError(`Last production branch did not have the same major version as the current branch.`);
  }

  const minorVersionNumber = minorVersionNumberParts.join('_');

  const prodBranch = `${minorVersionNumber}_branch`;
  return prodBranch;
}


// @version: string, what version is this qa branch
function getQaBranchName(version) {
  const qaBranch = `qa_${version}`;
  return qaBranch;
}


function getCurrentBranch(done) {
  const errorMsg = 'Could not get current branch';
  const currentBranch = execShellCommand(done, 'git branch --show-current', errorMsg).trim();
  return currentBranch;
}


function findCommitsNotOnProductionBranch(done) {
  const prodBranch = getProductionBranchName();
  return findCommitsOnMasterNotOnBranch(done, prodBranch);
}


function findCommitsNotOnCurrentBranch(done) {
  const currentBranch = getCurrentBranch(done);
  return findCommitsOnMasterNotOnBranch(done, currentBranch);
}


// extractPrIdFromCommitInfo extracts a Github PR ID from the end of a string, presumably
// a line as returned by 'git log'. For example the following line has a Github PR ID of (#1666):
// '34a35ht7 change the linear countdown timer to 20 sec before fullscreen (#1666)'
// The PR ID can be found at the end of any PR commit message and is formatted like "(#1234)". This function returns just the number portion  "1234" for easier usage with other APIs using the PR ID.
//
// @commitInfo: string
//
// @returns: string, the PR ID like '1234'
function extractPrIdFromCommitInfo(commitInfo) {
  const match = commitInfo.match(/\(#(\d+)\)/);
  return match?.[1];
}


async function addMissingImagesToRemoteLibrary(done) {
  // First we need to find our last submission release
  const releases = await octokit().repos.listReleases({
    owner: ghInfo.owner,
    repo: ghInfo.rokuRepo
  });

  let lastSubmissionReleaseTag;
  for (const release of releases.data) {
    if (release.name === submissionRelease) {
      lastSubmissionReleaseTag = release.tag_name;
      break;
    }
  }

  if (!lastSubmissionReleaseTag) {
    log('Could not find last submission release. Exiting.');
    done();
    return;
  }

  log(`Found last submission release: '${lastSubmissionReleaseTag}' continuing`);

  // Do sanity check that we're on the same major/minor version
  const [currentBranchMajorVersion, currentBranchMinorVersion] = getBuildTag('minor', '_').split('_');
  const [lastSubmissionMajorVersion, lastSubmissionMinorVersion] = lastSubmissionReleaseTag.split('_').slice(0, 2);
  if (currentBranchMajorVersion !== lastSubmissionMajorVersion) {
    log('Major version did not match last submission release. Exiting.');
    done();
    return;
  }

  if (currentBranchMinorVersion !== lastSubmissionMinorVersion) {
    log('Minor version did not match last submission release. Exiting.');
    done();
    return;
  }

  // Now we need to find what images changed
  const baseChannelPath = 'src/channel/';
  const errorMsg = `Could not get git diff for ${lastSubmissionReleaseTag}`;
  const output = execShellCommand(done, `git diff --name-only ${lastSubmissionReleaseTag} ${baseChannelPath}`, errorMsg);
  const changedImageFilePaths = output.match(/^.*\.png|^.*\.jpg|^.*\.webp/gm);

  // And whether they're already included in our file
  const newImagesSinceFilePath = `new_images_since/new_images_since_${lastSubmissionMajorVersion}_${lastSubmissionMinorVersion}`;
  let newImagesSinceFileContents = fs.readFileSync(newImagesSinceFilePath, 'utf8');
  const imagesToAdd = [];

  if (changedImageFilePaths !== null) {
    for (const changedImageFilePath of changedImageFilePaths) {
      // First check the file exists as files that were deleted are also included in the diff
      if (!fs.existsSync(changedImageFilePath)) {
        continue;
      }

      const relativeChangedImageFilePath = changedImageFilePath.replace(baseChannelPath, '');
      if (newImagesSinceFileContents.search(relativeChangedImageFilePath) === -1) {
        imagesToAdd.push(relativeChangedImageFilePath);
      }
    }
  }

  if (imagesToAdd.length > 0) {
    const formattedNewImageContents = imagesToAdd.join('\n');
    log(`The following images were found that are not included in ${newImagesSinceFilePath} already:\n${formattedNewImageContents}`);
    // Prompt if the dev wants to add these images to new images since file
    const { addToFile } = await prompts({
      type: 'confirm',
      name: 'addToFile',
      message: `Do you want add these to ${newImagesSinceFilePath}?`,
    });
    if (addToFile) {
      newImagesSinceFileContents += '\n' + formattedNewImageContents;
      fs.writeFileSync(newImagesSinceFilePath, newImagesSinceFileContents);
    }
  } else {
    log(`No images were found that are not already included in ${newImagesSinceFilePath}`);
  }
  done();
}



// increase the build/patch numbers in config/build.yml
function bumpBuild(done) {
  if (verifyGit(done)) {
    incrementBuildNumber();
    const buildTag = getBuildTag('revision');
    log(`Committing build bump to ${buildTag}`);
    shell.exec(`git commit -m "incrementbuild: Bump build number to ${buildTag}" config/build.yml`, { silent: true });
    done();
  } else {
    // errors should be handled in verifyGit()
  }
}


// increase the build/patch numbers in config/build.yml by 10
function bumpBuildTen(done) {
  if (verifyGit(done)) {
    incrementBuildNumber(10);
    const buildTag = getBuildTag('revision');
    log(`Committing build bump to ${buildTag}`);
    shell.exec(`git commit -m "incrementbuild: Bump build number to ${buildTag}" config/build.yml`, { silent: true });
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
    shell.exec(`git commit -m "incrementbuild: Bump revision number to ${buildTag}" config/build.yml`, { silent: true });
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


async function buildQaBranch(done) {
  // verify clean working directory
  verifyGit(done);

  const { releaseType } = await prompts({
    type: 'select',
    name: 'releaseType',
    message: 'What type of release are you creating this QA branch for?',
    initial: 1,
    warn: `${submissionRelease} is not supported currently`,
    choices: [
      {
        title: hotfixRelease,
        value: hotfixRelease
      },
      {
        title: remoteRelease,
        value: remoteRelease
      },
      {
        title: submissionRelease,
        value: submissionRelease,
        disabled: true
      }
    ]
  });

  if (releaseType === undefined) {
    // User hit control-c to exit so don't continue
    done();
    return;
  }

  if ([remoteRelease, hotfixRelease].includes(releaseType)) {
    const currentBranch = getCurrentBranch();
    const productionBranchName = getProductionBranchName();

    // Should currently always be called from production branch so make sure before we do anything else
    if (currentBranch != productionBranchName) {
      throw new NoStackError(`Current branch ${currentBranch} should not be used for making a ${releaseType} qa branch. Switch to ${productionBranchName} before rerunning`);
    }

    const connector = '_';
    const buildParts = getBuildTag('build', connector).split(connector);

    // split out the build part and increment by the correct amount
    let buildVersion = +buildParts.pop();
    if (releaseType === remoteRelease) {
      buildVersion += 10;
    } else {
      buildVersion += 1;
    }
    buildParts.push(buildVersion.toString());

    const version = buildParts.join('.');
    const qaBranchName = getQaBranchName(buildParts.join(connector));

    const { confirm } = await prompts({
      type: 'confirm',
      name: 'confirm',
      message: `Confirm that you would like to make a qa branch named ${qaBranchName} and increment the version to ${version}`,
    });

    if (confirm) {
      const gitCheckoutNewBranch = `git checkout -b ${qaBranchName}`;
      execShellCommand(done, gitCheckoutNewBranch);

      if (releaseType === remoteRelease) {
        bumpBuildTen(done);
      } else {
        bumpBuild(done);
      }
    }
  }

  done();
}

module.exports = {
  verifyGit,
  makeReleasePrs,
  pushTag,
  createGithubRelease,
  sendSlackReminders,
  findCommitsNotOnProductionBranch,
  findCommitsNotOnCurrentBranch,
  addMissingImagesToRemoteLibrary,
  pushBranch,
  buildReleaseNotes,
  buildQaChanges,
  extractQaChangesFromPullRequestBody,
  extractReleaseNotesFromPullRequestBody,
  buildQaBranch,
  bumpBuild,
  bumpBuildTen,
  bumpRevision,
  tagBuild,
  createCdnPullRequestForOneTrustSDK,
  getCurrentBranch,
  isBranchTrackingPresent,
  createCdnPullRequestForFoxVideoPlayer
};
