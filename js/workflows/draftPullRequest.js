
const {getOctokit, context} = require('@actions/github');
const inProgressLabel = 'not ready for review';

(async () => {
  const octokit = getOctokit(process.env.TOKEN).rest;
  const {repo, owner} = context.repo;
  const baseParams = {
    owner: owner,
    repo: repo,
    issue_number: context.payload.pull_request.number
  }
  if (context.payload.pull_request.draft) {
    await octokit.issues.addLabels({
      ...baseParams,
      labels: [inProgressLabel]
    });
  } else {
    // Will fail if it doesn't exist so wrap to silence it
    try {
      await octokit.issues.removeLabel({
        ...baseParams,
        name: inProgressLabel
      });
    } catch (e) {}
  }
})();
