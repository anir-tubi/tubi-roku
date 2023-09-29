const fs = require('fs');
const {jsonReportOutputPath} = require('../automated-tests');
import {testUtils} from '../automated-tests/test-utils';

const report = JSON.parse(fs.readFileSync(jsonReportOutputPath, 'utf8'));
const env = process.env;
const workflowRunUrl = `${env.GITHUB_SERVER_URL}/${env.GITHUB_REPOSITORY}/actions/runs/${env.GITHUB_RUN_ID}`;


let emoji = '✅';
if (report.stats.failures > 0) {
  emoji = '❌';
}

void testUtils.sendNetworkRequest({
  method: 'post',
  url: 'https://hooks.slack.com/services/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',
  body: {
    text: `${emoji} ${env.runName} ${report.stats.passes} out of ${report.stats.tests} passed. You can view the full report here: ${workflowRunUrl}`
  }
});
