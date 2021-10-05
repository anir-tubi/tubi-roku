const log = require('fancy-log');
const clipboardy = require('clipboardy');
const prompts = require('prompts');
const shell = require('shelljs');
shell.config.silent = true;

const {getBuildTag} = require('./config');
const {NoStackError} = require('./utilities');

// constants used for interacting with the github API
const ghInfo = {
  owner: 'adRise',
  rokuRepo: 'project-total-recall',
  cdnRepo: 'adrise_cdn',
};

// Github API wrapper
const { Octokit } = require('@octokit/rest');
const octokit = new Octokit({
  auth: process.env.GITHUB_PAT,
  userAgent: 'project-total-recall-build-server',
  baseUrl: 'https://api.github.com'
});


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
  log(`...Renaming the local branch to ${releaseBranchName}`);
  const gitRename = `git branch -m ${releaseBranchName}`;
  const gitRenameErrorMsg = `Could not rename the local branch to ${releaseBranchName}`;
  execGitCommand(gitRename, gitRenameErrorMsg, done);

  // attempt to checkout master in the CDN repo
  log(`...Checking out master on the local ${ghInfo.cdnRepo} repo`)
  const gitCheckoutMasterCDN = `git -C ${cdnPath} checkout master`;
  const gitCheckoutMasterCDNErrorMsg = `Could not checkout master on the ${cdnPath}`;
  execGitCommand(gitCheckoutMasterCDN, gitCheckoutMasterCDNErrorMsg, done);

  // attempt to pull origin master for the CDN repo
  log(`...Pulling remote master to the local ${ghInfo.cdnRepo} repo`);
  const gitPullMasterCDN = `git -C ${cdnPath} pull origin master`;
  const gitPullMasterCDNErrorMsg = `Could not pull master from origin at ${cdnPath}`;
  execGitCommand(gitPullMasterCDN, gitPullMasterCDNErrorMsg, done);

  // attempt to check out a new branch off master for the CDN repo
  const cdnBranchName = `roku_${fullBuildTag}`;
  // check if there is already a branch with the cdnBranchName and delete it if there is
  log(`...Checking if there already exists a local branch named ${cdnBranchName} on ${cdnPath}`);
  const gitListCDNBranch = `git -C ${cdnPath} branch --list ${cdnBranchName}`;
  const gitListCDNBranchErrorMsg = `Could not list the "${cdnBranchName}" at ${cdnPath}`;
  const gitListRes = execGitCommand(gitListCDNBranch, gitListCDNBranchErrorMsg, done);

  if (gitListRes) {
    // there exists a branch with the cdnBranchName already, so delete it.
    // We've already switched to master on `${cdnPath}` earlier in this flow.
    log(`...Deleting the ${cdnBranchName} on ${cdnPath}`);
    const gitDeleteCDNBranch = `git -C ${cdnPath} branch -D ${cdnBranchName}`;
    const gitDeleteCDNBranchErrorMsg = `Could not delete the "${cdnBranchName}" branch at ${cdnPath}`;
    execGitCommand(gitDeleteCDNBranch, gitDeleteCDNBranchErrorMsg, done);
  }

  log(`...Creating a new ${cdnBranchName} branch on the local ${ghInfo.cdnRepo} repo`);
  const gitCheckoutNewCDNBranch = `git -C ${cdnPath} checkout -b ${cdnBranchName}`;
  const gitCheckoutNewCDNBranchErrorMsg = `Could not checkout a new branch "${cdnBranchName}" at ${cdnPath}`;
  execGitCommand(gitCheckoutNewCDNBranch, gitCheckoutNewCDNBranchErrorMsg, done);

  const starterComponentsFileName = `tubi_starter_components_${minorBuildTag}.pkg`;
  const remoteComponentsFileName = `tubi_remote_components_${fullBuildTag}.pkg`;

  const cdnStarterComponentsPath = `${cdnPath}/hotpatches/roku/starter-components/${starterComponentsFileName}`;
  const cdnRemoteComponentsPath = `${cdnPath}/hotpatches/roku/components/${remoteComponentsFileName}`;
  
  const localStarterComponentsPath = `build/tubi_starter_components_${minorBuildTag}.pkg`;
  const localRemoteComponentsPath = `build/tubi_remote_components_${fullBuildTag}.pkg`;
  
  // copy the starter components from the /build directory to the CDN repo directory
  log(`...Copying the starter components to the local ${ghInfo.cdnRepo} repo`);
  const moveStarterComponentsResult = shell.cp(localStarterComponentsPath, cdnStarterComponentsPath);
  if (moveStarterComponentsResult.stderr) {
    const errorMsg = `There was an error moving the starter components. You will need to manually copy the starter components and remote components and manually make a PR.
           Error Message: ${moveStarterComponentsResult.stderr}`;
    done(new NoStackError(errorMsg));
  }

  // copy the remote components from the /build directory to the CDN repo directory
  log(`...Copying the remote components to the local ${ghInfo.cdnRepo} repo`);
  const moveRemoteComponentsRes = shell.cp(localRemoteComponentsPath, cdnRemoteComponentsPath);
  if (moveRemoteComponentsRes.stderr) {
    const errorMsg = `There was an error moving the remote components. You will need to manually copy the remote components and manually make a PR.
           Error Message: ${moveRemoteComponentsRes.stderr}`;
    done(new NoStackError(errorMsg));
  }

  // add the updates so they are staged for commit
  log(`...Staging changes for commit on the local ${ghInfo.cdnRepo} repo`);
  const gitAddCDNBranch = `git -C ${cdnPath} add . `;
  const gitAddCDNBranchErrorMsg = `Could not run "git add . " on ${cdnPath}`;
  execGitCommand(gitAddCDNBranch, gitAddCDNBranchErrorMsg, done);

  // commit the updates to the branch
  log(`...Committing the staged changes on the local ${ghInfo.cdnRepo} repo`);
  const gitCommitCDNBranch = `git -C ${cdnPath} commit -m 'Updating the starter and remote components for ${cdnBranchName}'`;
  const gitCommitCDNBranchErrorMsg = `"git commit" failed on ${cdnPath}`;
  execGitCommand(gitCommitCDNBranch, gitCommitCDNBranchErrorMsg, done);

  // push the branch to Github
  log(`...Pushing the local ${cdnBranchName} branch to the remote ${ghInfo.rokuRepo} repo`)
  const gitPushCDNBranch = `git -C ${cdnPath} push origin ${cdnBranchName}`;
  const gitPushCDNBranchErrorMsg = `Could not push ${cdnBranchName} to origin (Github) at ${cdnPath}`;
  execGitCommand(gitPushCDNBranch, gitPushCDNBranchErrorMsg, done);

  // make a PR against master on the CDN repo at Github
  log(`...Making a PR on ${ghInfo.cdnRepo} against the remote master branch`);
  let cdnPrUrl = '';
  try {
    const cdnPrRes = await octokit.pulls.create({
      owner: ghInfo.owner,
      repo: ghInfo.cdnRepo,
      title: `Updating starter and remote components for roku ${fullBuildTag}`,
      head: cdnBranchName,
      base: 'master'
    });
    cdnPrUrl = cdnPrRes.data.html_url;
  } catch(err) {
    console.log(err);
    done(new NoStackError(err));
  }

  // push the release branch to the project-total-recall repo
  log(`...Pushing the local ${releaseBranchName} branch to the remote ${ghInfo.rokuRepo} repo`);
  const gitPushReleaseBranch = `git push origin ${releaseBranchName}`;
  const gitPushReleaseBranchErrorMsg = `Could not push ${releaseBranchName} to ${ghInfo.rokuRepo} origin (Github)`;
  execGitCommand(gitPushReleaseBranch, gitPushReleaseBranchErrorMsg, done);

  // make a PR against the production branch on the project-total-recall repo at Github
  const prodRokuBranchName = `${minorBuildTag}_branch`;
  log(`...Making a PR from the remote ${releaseBranchName} on ${ghInfo.rokuRepo} against the ${prodRokuBranchName} branch`);  
  let releasePrUrl = '';
  try {
    const releasePrRes = await octokit.pulls.create({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      title: `Release ${fullBuildTag}`,
      body: 'Verify: The last commit in this PR is a build bump. If the last commit in this PR is not a build bump, the release needs to be run again. Any other commit that is not a build bump, including a merge, indicates a commit has been included that was not included in the package that was built and sent to the CDN.',
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
    log(`The release PR url and the CDN PR url have been placed on your clipboard. Please share with the team!`)
  } else {
    const errorMsg = 'The urls for the release PR and the CDN PR are not available. Please share manually.'
    done(new NoStackError(errorMsg));
  }
}


async function pushTag(done) {
  const buildTag = getBuildTag(false, false);
  log(`...Pushing the ${buildTag} tag to origin (Github)`);
  const pushTagRes = shell.exec(`git push origin ${buildTag}`);

  if (pushTagRes.code) {
    let errorMsg = `Could not push ${buildTag} tag to origin (Github)`;
    if (pushTagRes.stderr) {
      errorMsg = pushTagRes.stderr
    }
    done(new NoStackError(errorMsg));
  }
}


async function createGithubRelease(done) {
  // Prompt if the dev wants to make a release via the CLI (as opposed to Github UI)
  const {releaseConfirmation} = await prompts({
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

  const buildTag = getBuildTag(false, false);

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
    const topTags = await octokit.repos.listTags({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo
    });

    let isTagOnGithub = false;
    for (const tag of topTags.data) {
      if (tag.name === buildTag && tag.commit.sha === tagSha){
        isTagOnGithub = true;
        break;
      }
    }

    if (!isTagOnGithub) {
      const errorMsg = `The ${buildTag} tag is not on Github. Not creating a release here or else Github will make automatically make a tag from master - which will be inaccurate for our purposes.`
      done(new NoStackError(errorMsg));
    }
  } catch(err) {
    console.log(err);
    done(new NoStackError(err));
  }

  const remote = 'Remote Release';
  const submission = 'Submission Release';
  const {releaseType, isPreRelease, preReleaseDate} = await prompts([
    // prompt the dev for the release type to be used as the Release title
    {
      type: 'toggle',
      name: 'releaseType',
      message: 'Choose a release type (use arrow or tab keys to select)',
      initial: false,
      inactive: remote,
      active: submission,
      format: (val) => {
        // format the releaseType value as a remote/submission string instead of boolean
        return val ? submission : remote;
      }
    },
    // if it's a "Remote Release", prompt if it should be marked as a pre-release
    {
      type: (prev) => {
        // only show this prompt if it's a remote release, as submission releases are assumed
        // to be pre releases by default.
        return (prev === remote) ? 'confirm' : null;
      },
      name: 'isPreRelease',
      message: 'Should this release be marked as a pre release? Select no if the release will be deployed today. (y/n)',
    },
    // if it's a pre-release, prompt what the release date should be
    {
      type: (prev, values) => {
        return (values.isPreRelease || values.releaseType === submission) ? 'date' : null;
      },
      name: 'preReleaseDate',
      message: 'What date will this release be deployed? (use tab/arrow/number keys to modify date)',
      mask: 'MM/DD/YYYY',
      validate: (userDate) => {
        return userDate > Date.now() ? true : 'Release date must be in the future.';
      }
    },
  ]);

  // prompt the dev for the release notes to be used as the Release body
  let releaseNotes = preReleaseDate ? preReleaseDate.toLocaleDateString("en-US") : new Date().toLocaleDateString("en-US");  // '12/25/2020'

  while (true) {
    // multi-line string
    let releaseNotesState = `Current release notes:\n${releaseNotes}`;

    log(releaseNotesState); //this is part of the CLI UI - leave in
    const {releaseNotesConfirmation, releaseNote} = await prompts([
      {
        type: 'confirm',
        name: 'releaseNotesConfirmation',
        message: 'Add another release note? (y/n)'
      },
      {
        type: (prev) => {
          // only show this prompt if user selected yes in previous prompt.
          // returning null won't show this prompt.
          return prev ? 'text' : null;
        },
        name: 'releaseNote',
        message: "Please type the next release note: "
      }
    ]);

    if (!releaseNotesConfirmation) {
      break;
    } else if (releaseNotesConfirmation && releaseNote) {
      // only add release notes if something was typed
      releaseNotes += `\n${releaseNote}`;
    }
  }

  log(`...Creating a release from the ${buildTag} tag on Github`);
  try {
    await octokit.repos.createRelease({
      owner: ghInfo.owner,
      repo: ghInfo.rokuRepo,
      tag_name: buildTag,
      name: releaseType,
      body: releaseNotes,
      //mark as pre-release if there is a date associated with the pre release.
      prerelease: preReleaseDate ? true : false
    });
  } catch(err) {
    console.log(err);
    done(new NoStackError(err));
  }
}


async function findCommitsNotInProduction(done) {
  const minorVersionNumber = getBuildTag(true, false);
  const prodBranch = `${minorVersionNumber}_branch`;

  // verify clean working directory
  verifyGit(done);

  // Add a prompt asking if engineer wants to fetch latest from prod and master branches
  const {prepareConfirmation} = await prompts({
    type: 'confirm',
    name: 'prepareConfirmation',
    message: `Running this script will apply updates from origin master and origin ${prodBranch} to your local master and ${prodBranch} branches. Do you wish to proceed? (y/n)`,
  });

  if (!prepareConfirmation) {
    const declineMsg = 'Script aborted';
    log(declineMsg);
    return done();
  }

  // pull origin production branch
  execGitCommand(`git fetch origin ${prodBranch}:${prodBranch}`, 'Could not fetch the current production branch', done);

  // get commits on production branch
  const gitLogProd = execGitCommand(`git log ${prodBranch} -200`, 'Could not get git logs from prod branch.', done);

  // process/store commits on production branch
  // const prodLogs = mapGitLogs(gitLogProd);
  const prodLogs = {}
  gitLogProd.split('\n')
    .forEach((item) => {
      prId = extractPrIdFromCommitInfo(item);
      if (prId) {
        prodLogs[prId] = true;
      }
    });

  // pull origin master
  execGitCommand('git fetch origin master:master', 'Could not fetch origin from master.', done);

  // get commits on master
  const gitLogMaster = execGitCommand('git log master --oneline -200', 'Could not get git logs from master branch.', done);

  // filter logs from master that aren't on production
  const commitsFromMasterNotOnProd = gitLogMaster
    .split('\n')
    .filter((item) => {
      const prId = extractPrIdFromCommitInfo(item);
      return prId && !prodLogs[prId];
    });

  console.log('');
  console.log(`COMMITS THAT HAVE NOT BEEN CHERRY PICKED FROM master TO ${prodBranch}`);
  console.log('-----------------------------------------------------------------------');
  commitsFromMasterNotOnProd.forEach((item) => {
    console.log(item);
  });
  console.log('-----------------------------------------------------------------------');
  return done();
}

// @gitCommand: string, a git command to be executed, for example "git pull origin master"
// @defaultErrorMessage: string, an error message explaining which command was not able to be completed
// @done: function, the 'done' function from gulp.
function execGitCommand(gitCommand, defaultErrorMsg, done) {
  log(`Performing: ${gitCommand}`)
  const gitCommandRes = shell.exec(gitCommand);
  // console.log(gitCommand, ' - ', gitCommandRes);

  if (gitCommandRes.code) {
    log(defaultErrorMsg);
    const errorMsg = gitCommandRes.stderr ? gitCommandRes.stderr : defaultErrorMsg;
    done(new NoStackError(errorMsg));
  } else {
    return gitCommandRes.stdout;
  }
}


// extractPrIdFromCommitInfo extracts a Github PR ID from the end of a string, presumably
// a line as returned by 'git log'. For example the following line has a Github PR ID of (#1666):
// '34a35ht7 change the linear countdown timer to 20 sec before fullscreen (#1666)'
//
// @commitInfo: string
//
// @returns: string, the PR ID like '(#1234)'
function extractPrIdFromCommitInfo(commitInfo) {
  rev = commitInfo
    .split('')
    .reverse()
    .join('')

  prIdPosition = rev.indexOf('#( ')

  if (prIdPosition > 0){
    return rev
      .slice(0, prIdPosition + 2)
      .split('')
      .reverse()
      .join('')
  } else {
    return ""
  }
}


// get the character position of '(#1234)' string in the commit message
// @commitInfo: string, has format `abcdefgh some commit message (#1234)`
//                      where "abcdefg" is the abbreviated commit sha
//                      and where "(#1234)" is the Github PR ID for the commit within the repo.
function getPrIdPosition(commitInfo){
  prIdPosition = commitInfoinStr('(#');

  return prIdPosition
}

module.exports = {
  verifyGit,
  makeReleasePrs,
  pushTag,
  createGithubRelease,
  findCommitsNotInProduction
};
