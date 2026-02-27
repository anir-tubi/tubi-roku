/**
 * Download GitHub Actions Artifact
 *
 * Finds an artifact by name from a specific workflow run, downloads it,
 * and extracts it to a target directory.
 *
 * Usage:
 *   node .github/scripts/downloadArtifact.js
 *
 * Environment Variables:
 *   GITHUB_TOKEN       - GitHub PAT for API authentication (required)
 *   GITHUB_REPOSITORY  - Repository in owner/repo format (auto-set by GitHub Actions)
 *   ARTIFACT_NAME      - Name of the artifact to download (required)
 *   RUN_ID             - Workflow run ID that produced the artifact (required)
 *   OUTPUT_DIR         - Directory to extract into (default: 'allure-report')
 */
var https = require('https');
var fs = require('fs');
var path = require('path');
var childProcess = require('child_process');

var GITHUB_TOKEN = process.env.GITHUB_TOKEN;
var GITHUB_REPOSITORY = process.env.GITHUB_REPOSITORY;
var ARTIFACT_NAME = process.env.ARTIFACT_NAME;
var RUN_ID = process.env.RUN_ID;
var OUTPUT_DIR = process.env.OUTPUT_DIR || 'allure-report';

/**
 * Validates that all required environment variables are set.
 * Exits with error listing any missing variables.
 */
function validateEnv() {
  var missing = [];
  if (!GITHUB_TOKEN) missing.push('GITHUB_TOKEN');
  if (!GITHUB_REPOSITORY) missing.push('GITHUB_REPOSITORY');
  if (!ARTIFACT_NAME) missing.push('ARTIFACT_NAME');
  if (!RUN_ID) missing.push('RUN_ID');
  if (missing.length > 0) {
    console.error('Missing required environment variables: ' + missing.join(', '));
    process.exit(1);
  }
}

/**
 * Makes an authenticated GET request to the GitHub API.
 * Returns redirect info for 3xx responses instead of following them,
 * allowing callers to handle redirects with different auth strategies.
 * @param {string} urlPath - API path (e.g. '/repos/owner/repo/actions/...')
 * @returns {Promise<{statusCode: number, data?: Object, redirect?: string}>}
 */
function githubGet(urlPath) {
  return new Promise(function(resolve, reject) {
    var options = {
      hostname: 'api.github.com',
      path: urlPath,
      method: 'GET',
      headers: {
        'Authorization': 'token ' + GITHUB_TOKEN,
        'User-Agent': 'roku-automation',
        'Accept': 'application/vnd.github+json'
      }
    };

    var req = https.request(options, function(res) {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        resolve({ statusCode: res.statusCode, redirect: res.headers.location });
        res.resume();
        return;
      }

      var body = '';
      res.on('data', function(chunk) { body += chunk; });
      res.on('end', function() {
        var parsed;
        try { parsed = JSON.parse(body); } catch(e) { parsed = body; }
        resolve({ statusCode: res.statusCode, data: parsed });
      });
    });

    req.on('error', reject);
    req.end();
  });
}

/**
 * Downloads a file from a URL and writes it to disk.
 * Follows HTTP redirects, stripping the Authorization header on redirects
 * to external URLs (GitHub redirects artifact downloads to cloud storage
 * which rejects the GitHub token).
 * @param {string} url - URL to download from
 * @param {string} destPath - Local file path to write to
 * @param {boolean} [includeAuth=true] - Whether to include the GitHub auth header
 * @returns {Promise<void>}
 */
function downloadFile(url, destPath, includeAuth) {
  if (includeAuth === undefined) includeAuth = true;
  return new Promise(function(resolve, reject) {
    var mod = url.indexOf('https') === 0 ? https : require('http');
    var headers = { 'User-Agent': 'roku-automation' };
    if (includeAuth) {
      headers['Authorization'] = 'token ' + GITHUB_TOKEN;
    }

    mod.get(url, { headers: headers }, function(res) {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        downloadFile(res.headers.location, destPath, false).then(resolve).catch(reject);
        res.resume();
        return;
      }

      if (res.statusCode !== 200) {
        res.resume();
        reject(new Error('Download failed with HTTP ' + res.statusCode));
        return;
      }

      var file = fs.createWriteStream(destPath);
      res.pipe(file);
      file.on('finish', function() { file.close(resolve); });
      file.on('error', reject);
    }).on('error', reject);
  });
}

/**
 * Main entry point. Searches for the named artifact in the given workflow run,
 * downloads the ZIP archive, extracts it, and normalizes the directory structure.
 * If the ZIP contains a nested allure-report/ folder, that is used as the output.
 * @returns {Promise<void>}
 */
function main() {
  validateEnv();

  var encodedName = encodeURIComponent(ARTIFACT_NAME);
  var listPath = '/repos/' + GITHUB_REPOSITORY + '/actions/runs/' + RUN_ID + '/artifacts?name=' + encodedName + '&per_page=100';

  console.log('Looking for artifact "' + ARTIFACT_NAME + '" in run ' + RUN_ID);

  return githubGet(listPath).then(function(response) {
    if (response.statusCode !== 200) {
      console.error('Failed to list artifacts (HTTP ' + response.statusCode + ')');
      process.exit(1);
    }

    var artifacts = (response.data && response.data.artifacts) || [];
    console.log('Found ' + artifacts.length + ' matching artifact(s)');

    var match = null;
    for (var i = 0; i < artifacts.length; i++) {
      if (artifacts[i].name === ARTIFACT_NAME) {
        if (!match || artifacts[i].created_at > match.created_at) {
          match = artifacts[i];
        }
      }
    }

    if (!match) {
      console.error('No artifact named "' + ARTIFACT_NAME + '" in run ' + RUN_ID);
      for (var j = 0; j < artifacts.length; j++) {
        console.log('  - ' + artifacts[j].name + ' (id: ' + artifacts[j].id + ')');
      }
      process.exit(1);
    }

    var downloadPath = '/repos/' + GITHUB_REPOSITORY + '/actions/artifacts/' + match.id + '/zip';
    var zipFile = 'artifact-file.zip';

    console.log('Downloading artifact ' + match.id);
    return downloadFile('https://api.github.com' + downloadPath, zipFile).then(function() {
      var rawDir = 'artifact-raw';
      childProcess.execSync('unzip -o ' + zipFile + ' -d ' + rawDir, { stdio: 'inherit' });

      var nestedDir = path.join(rawDir, 'allure-report');
      if (fs.existsSync(nestedDir) && fs.statSync(nestedDir).isDirectory()) {
        childProcess.execSync('mv ' + nestedDir + ' ' + OUTPUT_DIR);
        childProcess.execSync('rm -rf ' + rawDir);
      } else {
        childProcess.execSync('mv ' + rawDir + ' ' + OUTPUT_DIR);
      }

      childProcess.execSync('rm -f ' + zipFile);

      var contents = fs.readdirSync(OUTPUT_DIR);
      console.log('Extracted to ' + OUTPUT_DIR + '/ (' + contents.length + ' items)');
    });
  });
}

main().catch(function(err) {
  console.error('Failed to download artifact: ' + err.message);
  process.exit(1);
});
