
const {extractQaChangesFromPullRequestBody, extractReleaseNotesFromPullRequestBody} = require('../git');

const fs = require('fs');
const event = JSON.parse(
  fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8')
);

let success = true;
const qaChanges = extractQaChangesFromPullRequestBody(event.pull_request.body);
if (qaChanges === undefined) {
  console.error('Could not find QA changes section');
  success = false;
}

const releaseNotes = extractReleaseNotesFromPullRequestBody(event.pull_request.body);
if (releaseNotes === undefined) {
  console.error('Could not find release notes section');
  success = false;
}

if (success) {
  console.log('PR info verified successfully');
} else {
  process.exit(1);
}
