/**
 * Notify PR of Component Library Deploy
 *
 * 1. Posts a confirmation comment with build details.
 * 2. Appends a deeplink curl command to the PR description (if not already present).
 *
 * Environment Variables:
 *   PR_NUMBER        - Pull request number (required)
 *   DISPLAY_NAME     - Human-readable name for the build (required)
 *   CDN_BASE_URL     - CDN base URL, e.g. https://mrcdn-staging.tubitv.com (required)
 *   GITHUB_TOKEN     - GitHub token for API calls (required)
 *   GITHUB_API       - GitHub API base URL (required)
 *   REPOSITORY       - GitHub repository in owner/repo format (required)
 *
 * Usage:
 *   PR_NUMBER=1234 DISPLAY_NAME="My Feature" CDN_BASE_URL=... node .github/scripts/notifyPrDeploy.js
 */
var https = require('https');
var http = require('http');

var PR_NUMBER = process.env.PR_NUMBER;
var DISPLAY_NAME = process.env.DISPLAY_NAME;
var CDN_BASE_URL = process.env.CDN_BASE_URL;
var GITHUB_TOKEN = process.env.GITHUB_TOKEN;
var GITHUB_API = process.env.GITHUB_API;
var REPOSITORY = process.env.REPOSITORY;

if (!PR_NUMBER || !DISPLAY_NAME || !CDN_BASE_URL || !GITHUB_TOKEN || !GITHUB_API || !REPOSITORY) {
  console.error('Missing required environment variables.');
  process.exit(1);
}

var PKG_URL = CDN_BASE_URL + '/appFiles/components/branches/' + PR_NUMBER + '/tubi_remote_components.pkg';
var LIB_NAME = 'TubiRemoteLib-' + PR_NUMBER;
var DEEPLINK_MARKER = '<!-- component-lib-deeplink -->';

function buildCommentBody() {
  return [
    '**Component library deployed!**',
    '',
    'Select in Test Aid > Branch Builds on your Roku device.',
    'Use `/rename <new name>` to update the display name.',
    '',
    '**Name:** ' + DISPLAY_NAME,
    '**URL:** `' + PKG_URL + '`',
    '**Lib:** `' + LIB_NAME + '`'
  ].join('\n');
}

function buildDeeplinkSection() {
  var registryJson = JSON.stringify({
    configurationOverrides: {
      remoteComponentsUrl: PKG_URL,
      remoteComponentLibProvided: LIB_NAME
    }
  });
  var encodedJson = encodeURIComponent(registryJson);

  return [
    DEEPLINK_MARKER,
    '---',
    '<details>',
    '<summary><strong>Component Library Deeplink</strong></summary>',
    '',
    '```bash',
    'curl -d \'\' "http://<ROKU_IP>:8060/launch/dev?setRegistry=' + encodedJson + '"',
    '```',
    '',
    'Replace `<ROKU_IP>` with your device IP. The app will restart with this branch build active.',
    '',
    '</details>'
  ].join('\n');
}

function githubRequest(method, apiPath, body) {
  return new Promise(function (resolve, reject) {
    var url = new URL(GITHUB_API + apiPath);
    var transport = url.protocol === 'https:' ? https : http;
    var options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method: method,
      headers: {
        'Authorization': 'token ' + GITHUB_TOKEN,
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'notify-pr-deploy'
      }
    };

    var payload;
    if (body) {
      payload = JSON.stringify(body);
      options.headers['Content-Type'] = 'application/json';
      options.headers['Content-Length'] = Buffer.byteLength(payload);
    }

    var req = transport.request(options, function (res) {
      var data = '';
      res.on('data', function (chunk) { data += chunk; });
      res.on('end', function () {
        if (res.statusCode >= 400) {
          reject(new Error('GitHub API ' + res.statusCode + ': ' + data));
        } else {
          resolve(JSON.parse(data));
        }
      });
    });
    req.on('error', reject);
    if (payload) { req.write(payload); }
    req.end();
  });
}

var prPath = '/repos/' + REPOSITORY + '/pulls/' + PR_NUMBER;
var issuePath = '/repos/' + REPOSITORY + '/issues/' + PR_NUMBER;

async function main() {
  await githubRequest('POST', issuePath + '/comments', { body: buildCommentBody() });
  console.log('Deploy confirmation comment posted.');

  var pr = await githubRequest('GET', prPath);
  var currentBody = pr.body || '';

  if (currentBody.indexOf(DEEPLINK_MARKER) !== -1) {
    console.log('Deeplink section already present, skipping PR description update.');
    return;
  }

  var newBody = currentBody + '\n\n' + buildDeeplinkSection();
  await githubRequest('PATCH', prPath, { body: newBody });
  console.log('PR description updated with deeplink curl command.');
}

main().catch(function (err) {
  console.error(err.message);
  process.exit(1);
});
