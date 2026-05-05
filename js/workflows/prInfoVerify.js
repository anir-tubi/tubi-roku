
const {extractQaChangesFromPullRequestBody, extractReleaseNotesFromPullRequestBody} = require('../git');

const fs = require('fs');
const event = JSON.parse(
  fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8')
);

let success = true;
const body = event.pull_request.body;

const qaChanges = extractQaChangesFromPullRequestBody(body);
if (qaChanges === undefined) {
  console.error('Could not find QA changes section');
  success = false;
}

const testingTypeSection = body ? body.match(/## QA Testing Type[^\n]*\n([\s\S]*?)## QA What Changed/) : null;
if (!testingTypeSection) {
  console.error('Could not find QA Testing Type section. Please use the PR template and select one of: Testing Required, Regression, or No Testing');
  success = false;
} else {
  const checkedCount = (testingTypeSection[1].match(/- \[x\]/gi) || []).length;
  if (checkedCount === 0) {
    console.error('Please select a QA Testing Type (Testing Required, Regression, or No Testing)');
    success = false;
  } else if (checkedCount > 1) {
    console.error('Please select only one QA Testing Type');
    success = false;
  }
}

const releaseNotes = extractReleaseNotesFromPullRequestBody(body);

if (releaseNotes === undefined) {
  console.error('Could not find release notes section');
  success = false;
} else if (releaseNotes.length > 0) {
  let releaseNotesValidPrefixes = [
    'Experiment',
    'Graduation',
    'Feature',
    'BugFix',
    'Enhancement'
  ]
  let result = releaseNotesValidPrefixes.filter(s => releaseNotes.startsWith(`${s}:`));

  if (result.length === 0) {
    const releaseNotesValidPrefixesString = releaseNotesValidPrefixes.join(", ")
    console.error(`Prefix your release notes with ${releaseNotesValidPrefixesString}`);
    success = false;
  }
}

if (success) {
  console.log('PR info verified successfully');
} else {
  process.exit(1);
}
