/**
 * Manage Branch Component Library Manifest
 *
 * Maintains a JSON manifest of deployed branch component libraries in S3.
 * Uses the AWS CLI (available on the self-hosted runner) for S3 operations.
 *
 * All manifest mutations use optimistic locking via S3 ETags to prevent
 * concurrent deployments from different PRs from overwriting each other.
 *
 * Commands:
 *   upsert           - Add or update a build entry in the manifest
 *   remove           - Remove a build entry from the manifest
 *   rename           - Update only the display name for an existing entry
 * Environment Variables:
 *   COMMAND          - One of: upsert, remove, rename (required)
 *   S3_BUCKET        - S3 bucket name (required)
 *   PR_NUMBER        - Pull request number (required)
 *   DISPLAY_NAME     - Human-readable name for the build (upsert only)
 *   BRANCH           - Git branch name (upsert only)
 *   COMMIT_SHA       - Short commit SHA (upsert only)
 *   AUTHOR           - GitHub username of the PR author (upsert only)
 *   PKG_URL          - CDN URL to the built .pkg (upsert only)
 *   LIB_PROVIDED     - Roku component lib name, e.g. TubiRemoteLib-1234 (upsert only)
 *
 * Usage:
 *   COMMAND=upsert S3_BUCKET=my-bucket PR_NUMBER=1234 ... node .github/scripts/manageBranchManifest.js
 */
var childProcess = require('child_process');
var fs = require('fs');
var path = require('path');

var MANIFEST_KEY = 'appFiles/components/branches/manifest.json';
var LOCAL_MANIFEST = path.join(process.cwd(), '.branch-manifest.json');
var PROFILE_FLAG = process.env.AWS_PROFILE ? ' --profile "' + process.env.AWS_PROFILE + '"' : '';
var MAX_RETRIES = 5;

function checkIfNotEmpty(name) {
  var val = process.env[name];
  if (!val) {
    console.error('Missing required environment variable: ' + name);
    process.exit(1);
  }
  return val;
}

/** Fetch the manifest from S3 and return { manifest, etag }. */
function fetchManifest(bucket) {
  try {
    var metaOutput = childProcess.execSync(
      'aws s3api get-object' +
      ' --bucket "' + bucket + '"' +
      ' --key "' + MANIFEST_KEY + '"' +
      ' "' + LOCAL_MANIFEST + '"' +
      PROFILE_FLAG,
      { stdio: 'pipe' }
    ).toString();
    var meta = JSON.parse(metaOutput);
    var manifest = JSON.parse(fs.readFileSync(LOCAL_MANIFEST, 'utf8'));
    return { manifest: manifest, etag: meta.ETag };
  } catch (err) {
    var stderr = (err.stderr || '').toString();
    if (stderr.indexOf('NoSuchKey') !== -1 || stderr.indexOf('404') !== -1 || stderr.indexOf('Not Found') !== -1) {
      return { manifest: [], etag: null };
    }
    throw err;
  }
}

/**
 * Write the manifest to S3 with optimistic locking.
 * If etag is provided, the write is conditional: it only succeeds when the
 * remote object still has the same ETag (no concurrent modification).
 * Returns true on success, false on conflict (PreconditionFailed).
 */
function writeManifest(bucket, manifest, etag) {
  fs.writeFileSync(LOCAL_MANIFEST, JSON.stringify(manifest, null, 2));
  try {
    var cmd =
      'aws s3api put-object' +
      ' --bucket "' + bucket + '"' +
      ' --key "' + MANIFEST_KEY + '"' +
      ' --body "' + LOCAL_MANIFEST + '"' +
      ' --content-type "application/json"' +
      ' --cache-control "no-cache"';
    if (etag) {
      cmd += ' --if-match \'' + etag + '\'';
    }
    cmd += PROFILE_FLAG;
    childProcess.execSync(cmd, { stdio: 'pipe' });
    return true;
  } catch (err) {
    var stderr = (err.stderr || '').toString();
    if (stderr.indexOf('PreconditionFailed') !== -1 || stderr.indexOf('412') !== -1) {
      return false;
    }
    throw err;
  } finally {
    try { fs.unlinkSync(LOCAL_MANIFEST); } catch (_) { /* ignore */ }
  }
}

function findEntryIndex(manifest, prNumber) {
  for (var i = 0; i < manifest.length; i++) {
    if (String(manifest[i].prNumber) === String(prNumber)) {
      return i;
    }
  }
  return -1;
}

function sleepMs(ms) {
  childProcess.execSync('sleep ' + (ms / 1000));
}

/**
 * Execute a manifest mutation with optimistic-locking retry.
 * @param {string} bucket - S3 bucket name
 * @param {function} mutateFn - receives the manifest array, mutates it in place
 */
function withRetry(bucket, mutateFn) {
  for (var attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    var result = fetchManifest(bucket);
    mutateFn(result.manifest);
    if (writeManifest(bucket, result.manifest, result.etag)) {
      return;
    }
    console.log('Conflict detected (attempt ' + attempt + '/' + MAX_RETRIES + '), retrying...');
    sleepMs(500 * attempt);
  }
  console.error('Failed to update manifest after ' + MAX_RETRIES + ' retries due to concurrent writes');
  process.exit(1);
}

function upsert(bucket) {
  var prNumber = parseInt(checkIfNotEmpty('PR_NUMBER'), 10);
  var entry = {
    prNumber: prNumber,
    displayName: checkIfNotEmpty('DISPLAY_NAME'),
    branch: checkIfNotEmpty('BRANCH'),
    commitSha: checkIfNotEmpty('COMMIT_SHA'),
    author: checkIfNotEmpty('AUTHOR'),
    timestamp: new Date().toISOString(),
    url: checkIfNotEmpty('PKG_URL'),
    libProvided: checkIfNotEmpty('LIB_PROVIDED'),
  };

  withRetry(bucket, function (manifest) {
    var existing = findEntryIndex(manifest, prNumber);
    if (existing >= 0) {
      manifest[existing] = entry;
    } else {
      manifest.unshift(entry);
    }
  });
  console.log('Manifest updated for PR #' + prNumber);
}

function remove(bucket) {
  var prNumber = checkIfNotEmpty('PR_NUMBER');
  withRetry(bucket, function (manifest) {
    var existing = findEntryIndex(manifest, prNumber);
    if (existing >= 0) {
      manifest.splice(existing, 1);
    }
  });
  console.log('Manifest entry removed for PR #' + prNumber);
}

function rename(bucket) {
  var prNumber = checkIfNotEmpty('PR_NUMBER');
  var newName = checkIfNotEmpty('DISPLAY_NAME');
  withRetry(bucket, function (manifest) {
    var existing = findEntryIndex(manifest, prNumber);
    if (existing < 0) {
      console.error('No manifest entry found for PR #' + prNumber);
      process.exit(1);
    }
    manifest[existing].displayName = newName;
  });
  console.log('Display name updated to "' + newName + '" for PR #' + prNumber);
}

var command = checkIfNotEmpty('COMMAND');
var bucket = checkIfNotEmpty('S3_BUCKET');

switch (command) {
  case 'upsert':
    upsert(bucket);
    break;
  case 'remove':
    remove(bucket);
    break;
  case 'rename':
    rename(bucket);
    break;
  default:
    console.error('Unknown command: ' + command + '. Use: upsert, remove, rename');
    process.exit(1);
}
