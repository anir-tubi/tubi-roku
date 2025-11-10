const fs = require('fs');
const path = require('path');
const https = require('https');
const log = require('fancy-log');
const { NoStackError } = require('./utilities');
const { fetchJSON } = require('./network');
const { getCurrentBranch } = require('./git');
const prompts = require('prompts');
const axios = require('axios').default;

/* Allow the crowdinK token to be driven from an environment variable or thru command line param.
   Environment variables are set on options, along with any parameters passed in
   to the gulp command line call.
*/
const crowdinConfig = {
  "crowdinToken": (process.env.ROKU_CROWDIN_TOKEN || ''),
  "crowdinBaseDirectory": "roku",
  "projectId": 393299,
  "fileId": 46,
  "fileName": "en-US.json"
};

const _sLocalTranslationFilename = "translations/en-US.json";
const _sLocalTranslationFilePath = `${process.cwd()}/${_sLocalTranslationFilename}`;
const _sLocalTranslationCodeFilenameAndPath = 'src/channel/source/lib/TubiLanguageTranslate.brs';
const _sBRSReturn = "  return "

// Whitelisted locales that are allowed to have translation functions in TubiLanguageTranslate.brs
const WHITELISTED_LOCALES = ['en-US', 'en_US', 'es-MX', 'es_MX', 'fr-CA', 'fr_CA'];

// fetch command line arguments and replace params in crowdinConfig. Right now it just replaces the "crowdinToken"
// @Source: https://www.sitepoint.com/pass-parameters-gulp-tasks/
const arg = (argList => {

  let arg = {}, a, opt, thisOpt, curOpt;
  for (a = 0; a < argList.length; a++) {

    thisOpt = argList[a].trim();
    opt = thisOpt.replace(/^\-+/, '');

    if (opt === thisOpt) {
      // argument value
      if (curOpt) arg[curOpt] = opt;
      curOpt = null;
    }
    else {
      // argument name
      curOpt = opt;
      arg[curOpt] = true;
    }
  }

  if (arg["crowdinToken"] !== undefined) {
    crowdinConfig["crowdinToken"] = arg["crowdinToken"]
  }
})(process.argv);

const crowdin = require('@crowdin/crowdin-api-client');
const { translationsApi, uploadStorageApi, sourceFilesApi } = new crowdin.default({
  token: crowdinConfig.crowdinToken
});

//Get the already created zip file of the locale translation files from crowdin server
async function getTranslationsZipFile(url) {
  return await makeGetRequest(url);
}


/**
 * removeEmptyTranslations
 *
 * This function removes translations with empty message strings from a JSON object.
 *
 * @param {string} localeData - A JSON string containing translations with the "message" property
 * @returns {string} - A JSON string with the filtered translations
 */
function removeEmptyTranslations(localeData, sLocale) {
  const jsonTranslationFile = JSON.parse(localeData);
  const emptyTranslationKeys = [];
  for (const key in jsonTranslationFile) {
    if (jsonTranslationFile[key].message === "") {
      if ((sLocale === "es-MX") && !emptyTranslationKeys.includes(key)) {
        emptyTranslationKeys.push(key);
      }
      delete jsonTranslationFile[key];
    }
  }

  if (sLocale === "es-MX" && emptyTranslationKeys.length > 0) {
    // Update en-US.json with noTranslationRequired flag for empty keys
    const englishTranslations = JSON.parse(fs.readFileSync(_sLocalTranslationFilePath, 'utf8'));

    for (const key of emptyTranslationKeys) {
      if (englishTranslations[key]) {
        englishTranslations[key].noTranslationRequired = true;
      }
    }

    // Write updated translations back to en-US.json
    fs.writeFileSync(_sLocalTranslationFilePath, JSON.stringify(englishTranslations, null, 2) + '\n', 'utf8');
  }

  const jsonString = JSON.stringify(jsonTranslationFile, null, 2);
  return jsonString;
}


async function processTranslationFiles(directory) {
  if (directory && directory.files) {

    // iterate over each file in the zipped directory
    for (const file of directory.files) {
      let unZippedFilePath = file.path;

      // if the file path contains 'roku' and '.json', we want to process it
      // expect the file path looks like 'es-MX/roku/translations/es-MX.json'
      if (unZippedFilePath.indexOf(crowdinConfig.crowdinBaseDirectory) >= 0 && unZippedFilePath.indexOf('.json') >= 0) {
        const nDestinationPathIndex = unZippedFilePath.indexOf(crowdinConfig.crowdinBaseDirectory) + crowdinConfig.crowdinBaseDirectory.length + 1
        let destinationPath = unZippedFilePath.substring(nDestinationPathIndex);
        destinationPath = path.resolve(destinationPath);

        //Remove '.json' from the file path to get the locale ID
        let sLocale = path.parse(unZippedFilePath).name;

        log('Attempting to write downloaded crowdin translation to: ', destinationPath);
        fs.accessSync(destinationPath.substring(0, destinationPath.lastIndexOf('/')), fs.constants.F_OK);
        let fileBuffer = await file.buffer();

        // temporarily write the translation json to file
        await writeToFile(destinationPath, fileBuffer);

        if (destinationPath !== '') {
          // read contents of temporarily written json file
          var localeData = fs.readFileSync(destinationPath, 'utf-8');

          //remove any translation that are empty strings
          const jsonString = removeEmptyTranslations(localeData, sLocale)

          // write the contents of the translation json to the appropriate function
          // in the TubiLanguageTranslate.brs file
          writeLocaleDataToBRS_sync(sLocale, jsonString);

          sLocale = sLocale.toLowerCase();
          if (sLocale !== 'en-us' && sLocale !== 'en_us') {
            //Let's delete the translation JSON file that was just downloaded, but let's not
            //delete the default US English translation if for some reason the US English is downloaded.
            //The US English file should not download from crowdin, but just in case, we should not delete it as we should keep the US English file in the project as the source file
            fs.unlinkSync(destinationPath);
          }
        }
      }
    }
  }
}


async function writeToFile(path, bufferOrString) {
  return new Promise((resolve, reject) => {
    let writeStream = fs.createWriteStream(path);
    writeStream.write(bufferOrString);
    writeStream.on('finish', () => {
      log(path, 'successfully written to.');
      resolve();
    });
    writeStream.on('error', (err) => {
      log('Could not write to: ', path);
      reject(err);
    });
    writeStream.end('');
  });
}


//Helper function to change characters to be Regular Expressions friendly
function escapeRegExp(stringToGoIntoTheRegex) {
  return stringToGoIntoTheRegex.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
}


//process the Crowdin JSON data so it returns a string that is ready to be displayed in the app.
//  @localeData: String, the stringified version of the JSON translation data
//  @return: The string that is returned will be have every string removed or replaced from it that the app cannot display: i.e. '\"'
function processRemoteJSONData(localeData) {
  let sJsonReturn;
  if (localeData !== undefined && localeData !== "") {
    // add appropriate indentation to localeData and remove any empty lines
    const localeDataLines = localeData.split('\n');
    const localDataLinesIndented = localeDataLines.reduce((acc, line, index) => {

      // Checking the line has \" in it.
      if (line.includes('\\"')) {
        // If present replace \"  with Chr(34)
        // for ex: "les \"Adolescents\" ont" will be convert to "les " + Chr(34) + "Adolescents" + Chr(34) + " ont"
        line = line.replace(/\\"/g, `" + Chr(34) + "`)
      }

      if (index === 0) {
        acc.push(line);
        return acc;
      } else if (line.trim() === '') {
        return acc
      } else {
        let newLine = `  ${line}`.trimEnd()
        acc.push(newLine);
        return acc;
      }
    }, []);
    sJsonReturn = localDataLinesIndented.join('\n');
  }

  return sJsonReturn;
}


//when the JSON is received from Crowdin, it is processed to make it acceptable to be written to the .brs file
//This function removes some of the processing of the string so it can be changed back to a JSON object and
//be compared to a more recently downloaded version of the Crowdin JSON. If this is not done, then these special characters 
//that were added during processing will make it impossible to convert the raw strings into JSON objects.  
//@see this and the processRemoteJSONData()functions to see what is is being processed/unprocessed.
function unprocessJSONString(sJSONData) {
  //Replace Chr(34) with \"
  let sJsonReturn = sJSONData.replace(/"\s\+\sChr\(34\)\s\+\s"/g, '\\"');
  sJsonReturn = sJsonReturn.replace(_sBRSReturn, "");

  const jsonReturn = JSON.parse(sJsonReturn);
  return jsonReturn;
}


//get the JSON data of the passed locale from the translations BRS file
function getJSONFromBRS(sLocale) {
  let jsonReturn;

  var data = fs.readFileSync(_sLocalTranslationCodeFilenameAndPath, 'utf-8');
  const sStartFunctionString = getLocaleFunctionStartString(sLocale);
  const sEndFunctionString = getFunctionEndString();

  // Convert data and search strings to lowercase
  const sLowerCaseData = data.toLowerCase();
  const sLowerCaseStartFunction = sStartFunctionString.toLowerCase();
  const sLowerCaseEndFunction = sEndFunctionString.toLowerCase();

  // Find the start position of the function
  const nStartIndex = sLowerCaseData.indexOf(sLowerCaseStartFunction);

  // Find the end position of the function
  const nEndIndex = sLowerCaseData.indexOf(sLowerCaseEndFunction, nStartIndex);

  // Extract the JSON string
  let sJsonReturn = data.substring(nStartIndex + sStartFunctionString.length + 1, nEndIndex);
  // Parse the JSON string into an object
  jsonReturn = unprocessJSONString(sJsonReturn);

  return jsonReturn;
}

//  Get the Function name of the function that will be be placed in the .brs file for a particular locale: i.e. "Function getTranslation_en_US()".
//  The function will be used by the app to process an ID and return a translation string.
//  @sLocale: String, the ID of the locale: i.e. en_us
//  @return The string to represent the start of the function described the above description. 
function getLocaleFunctionStartString(sLocale) {
  sLocale = sLocale.replace("-", "_");
  const sFunctionName = `getTranslation_${sLocale}`;
  const sStartFunctionString = `Function ${sFunctionName}()`;

  return sStartFunctionString;
}


function getFunctionEndString() {
  return "End Function";
}


//Write the translation contents of a locale into the translations BRS file if they don't exist yet or replace them if they do.
function writeLocaleDataToBRS_sync(sLocale, localeData) {
  if (localeData !== undefined && localeData !== "") {
    localeData = processRemoteJSONData(localeData);

    var data = fs.readFileSync(_sLocalTranslationCodeFilenameAndPath, 'utf-8');
    var sStartFunctionString = getLocaleFunctionStartString(sLocale);
    var sEndFunctionString = getFunctionEndString();

    var newValue = ""
    var sNewString = `${sStartFunctionString}\n${_sBRSReturn}${localeData}\n${sEndFunctionString}`

    if (data.indexOf(sStartFunctionString) >= 0) {
      //If the locale function exists, then update the function with the new translations
      log(`Found ${sLocale} locale function. Now replace it within the BRS file: '${_sLocalTranslationCodeFilenameAndPath}'`);
      var re = new RegExp(escapeRegExp(sStartFunctionString) + "[\\s\\S]*?" + sEndFunctionString, "i");
      newValue = data.replace(re, sNewString);
    } else {
      // Only create new translation functions for whitelisted locales
      if (!WHITELISTED_LOCALES.includes(sLocale)) {
        log(`Skipping ${sLocale} - not a whitelisted locale. Only ${WHITELISTED_LOCALES.join(', ')} are allowed.`);
        return;
      }
      //If the locale function does not exist, then create a new function with the new translations
      log(`Could not find ${sLocale} locale function. Appending it to the end of the BRS file: '${_sLocalTranslationCodeFilenameAndPath}'`);
      newValue = `${data}\n\n\n${sNewString}`;
    }

    fs.writeFileSync(_sLocalTranslationCodeFilenameAndPath, newValue, 'utf-8');
  }
}


//helper function to upload file to crowdin
async function updateFilesRequest(filePath) {
  const fileContent = fs.readFileSync(filePath);
  const storageResponse = await uploadStorageApi.addStorage(crowdinConfig.fileName, fileContent);
  const requestParam = {
    storageId: storageResponse.data.id,
  };
  return await sourceFilesApi.updateOrRestoreFile(crowdinConfig.projectId, crowdinConfig.fileId, requestParam);
}


//helper function to make a request to crowdin server
function makeGetRequest(options) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (resp) => {
      if (resp.statusCode >= 300) {
        // Build URL from request options instead of socket properties
        const protocol = options.protocol || 'https:';
        const host = options.hostname || options.host || 'unknown';
        const path = options.path || '/';
        const url = `${protocol}//${host}${path}`;
        const method = options.method || 'GET';
        const errorMessage = `Received ${resp.statusCode} while attempting a ${method} request to ${url}`;
        const err = new Error(errorMessage);
        reject(err);
      } else {
        let data = [];
        resp.on('data', (chunk) => {
          data.push(chunk);
        });

        resp.on('end', () => {
          const buff = Buffer.concat(data)
          resolve(buff);
        });
      }
    }).on('error', (err) => {
      reject(err);
    });

    req.end();
  });
}


const BUILD_CONFIG = {
  MAX_BUILD_RETRIES: 10,
  BUILD_RETRY_DELAY: 30000,      // 30 seconds
  MAX_STATUS_CHECKS: 150,
  STATUS_CHECK_INTERVAL: 5000    // 5 seconds
};

/**
 * Checks if a Crowdin API error is due to another build being in progress
 * 
 * Crowdin allows only one build to run at a time per project. When attempting to start a new build
 * while another is running, the API returns an error containing "build is currently in progress".
 * This function inspects the error object to detect this specific condition, allowing the code to
 * implement retry logic rather than failing immediately.
 * 
 * The function checks multiple locations in the error object because the error message structure
 * can vary (error.message, error.error.message, or nested in the JSON structure).
 * 
 * Used by: startBuild() to determine if it should retry or throw the error
 * 
 * @param {Error|Object} error - The error object from Crowdin API
 * @returns {boolean} True if error indicates a build is in progress, false otherwise
 */
function isBuildInProgressError(error) {
  const errorMessage = error.message || error.error?.message || '';
  const errorString = JSON.stringify(error).toLowerCase();

  return errorMessage.toLowerCase().includes('build is currently in progress') ||
    errorString.includes('build is currently in progress');
}

/**
 * Pauses execution for a specified number of milliseconds
 * 
 * This utility function creates a Promise-based delay, allowing async functions to wait
 * without blocking the event loop. It's essential for implementing polling and retry logic
 * where we need to wait between API calls.
 * 
 * Why it's needed:
 * - Crowdin API rate limiting: Prevents hitting API too frequently
 * - Build completion polling: Waits between status checks (every 5 seconds)
 * - Build slot availability: Waits for existing builds to complete (every 30 seconds)
 * 
 * Used by:
 * - startBuild(): Waits 30 seconds between retries when another build is in progress
 * - pollBuildStatus(): Waits 5 seconds between build status checks
 * 
 * @param {number} ms - Number of milliseconds to sleep/wait
 * @returns {Promise<void>} Promise that resolves after the specified delay
 * @example
 * await sleep(5000); // Wait for 5 seconds
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Initiates a Crowdin translation build with automatic retry logic for concurrent build conflicts
 * 
 * A Crowdin build is the process where Crowdin compiles all translations into downloadable files.
 * Since only one build can run at a time per project, this function implements retry logic to wait
 * for any existing builds to complete before starting a new one.
 * 
 * Build process:
 * 1. Attempts to start a new build via Crowdin API
 * 2. If successful, returns the build ID immediately
 * 3. If "build in progress" error occurs, waits 30 seconds and retries (up to 10 times = 5 minutes)
 * 4. If a different error occurs, throws immediately (no retry)
 * 5. After max retries, throws error indicating timeout
 * 
 * The skipUntranslatedStrings parameter determines if incomplete translations should be included:
 * - true (default): Only download fully translated strings, leaving gaps for incomplete translations
 * - false: Download all strings, including partially translated ones
 * 
 * @param {boolean} [bSkipUntranslatedStrings=true] - Whether to exclude untranslated strings from the build
 * @returns {Promise<number>} The Crowdin build ID that can be used to check status and download files
 * @throws {Error} If build fails for non-retry reasons or max retries exceeded
 */
async function startBuild(bSkipUntranslatedStrings = true) {
  for (let i = 0; i < BUILD_CONFIG.MAX_BUILD_RETRIES; i++) {
    try {
      log('Attempting to start Crowdin build...');
      const result = await translationsApi.buildProject(crowdinConfig.projectId, {
        skipUntranslatedStrings: bSkipUntranslatedStrings
      });
      log(`Build started successfully with ID: ${result.data.id}`);
      return result.data.id;
    } catch (error) {
      if (!isBuildInProgressError(error) || i === BUILD_CONFIG.MAX_BUILD_RETRIES - 1) {
        log(`Build error: ${error.message}`);
        log(`Full error object: ${JSON.stringify(error, null, 2)}`);
        throw error;
      }
      log(`Another build is in progress. Waiting ${BUILD_CONFIG.BUILD_RETRY_DELAY / 1000} seconds before retry ${i + 1}/${BUILD_CONFIG.MAX_BUILD_RETRIES}...`);
      await sleep(BUILD_CONFIG.BUILD_RETRY_DELAY);
    }
  }
  throw new Error('Failed to start build after maximum retries');
}

/**
 * Continuously polls Crowdin build status until completion, failure, or timeout
 * 
 * After a build is started, it takes time for Crowdin to compile all translations. This function
 * repeatedly checks the build status every 5 seconds until the build reaches a terminal state.
 * With 150 max checks at 5-second intervals, it will wait up to 12.5 minutes for build completion.
 * 
 * Build status progression:
 * - "in_progress" / "queued" → Keep polling
 * - "finished" → Success! Return build data
 * - "canceled" → Throw error (build was manually canceled)
 * - "failed" → Throw error (build encountered an error)
 * - Timeout after 150 checks → Throw error (likely a stuck build)
 * 
 * The function logs progress with each check, showing elapsed time and check count to help
 * monitor long-running builds in CI/CD environments.
 * 
 * @param {number} buildId - The Crowdin build ID returned from startBuild()
 * @returns {Promise<Object>} The completed build data object from Crowdin API
 * @throws {Error} If build is canceled, failed, or times out after 12.5 minutes
 */
async function pollBuildStatus(buildId) {
  for (let i = 0; i < BUILD_CONFIG.MAX_STATUS_CHECKS; i++) {
    const result = await translationsApi.checkBuildStatus(crowdinConfig.projectId, buildId);
    const status = result.data.status.toLowerCase();

    if (status === 'finished') {
      log('Build completed successfully.');
      return result.data;
    } else if (status === 'canceled' || status === 'failed') {
      throw new Error(`Build ${status}`);
    }

    log(`Crowdin is currently building the project. Status: ${result.data.status}`);
    log(`Will check status again in ${BUILD_CONFIG.STATUS_CHECK_INTERVAL / 1000} seconds. Check ${i + 1} out of ${BUILD_CONFIG.MAX_STATUS_CHECKS}.`);
    await sleep(BUILD_CONFIG.STATUS_CHECK_INTERVAL);
  }

  throw new Error('Build timeout: Crowdin is busy creating a build. Please try again later.');
}

/**
 * Downloads the compiled translation files from a completed Crowdin build
 * 
 * After a build finishes, Crowdin provides a download URL for a zip file containing all
 * translation files. This function:
 * 1. Requests the download URL from Crowdin API using the build ID
 * 2. Downloads the zip file buffer from the provided URL
 * 3. Opens/parses the zip file in memory using the unzipper library
 * 4. Returns the parsed zip directory structure for further processing
 * 
 * The returned object contains a files array where each file has properties like:
 * - path: File path within the zip (e.g., "es-MX/roku/translations/es-MX.json")
 * - buffer(): Method to get file contents as a buffer
 * 
 * These files are later processed by processTranslationFiles() which writes them to
 * TubiLanguageTranslate.brs.
 * 
 * @param {number} buildId - The Crowdin build ID of a completed build
 * @returns {Promise<Object>} Unzipped directory object containing all translation files
 * @throws {Error} If download fails or zip file cannot be parsed
 */
async function downloadBuildFiles(buildId) {
  log('Starting to download the translations.');
  const translationInfo = await translationsApi.downloadTranslations(crowdinConfig.projectId, buildId);
  const translationsFileBuffer = await getTranslationsZipFile(translationInfo.data.url);
  const unzipper = require('unzipper');
  const translationFiles = await unzipper.Open.buffer(translationsFileBuffer);
  log('DONE DOWNLOADING TRANSLATIONS.');
  return translationFiles;
}

/**
 * Orchestrates the complete Crowdin translation download workflow
 * 
 * This is the main function that coordinates the entire process of getting translations from Crowdin.
 * It combines three sub-operations in sequence:
 * 1. startBuild() - Initiates a new Crowdin build (with retry logic for concurrent builds)
 * 2. pollBuildStatus() - Waits for the build to complete (polling every 5 seconds)
 * 3. downloadBuildFiles() - Downloads and parses the compiled translation zip file
 * 
 * The function is designed to be resilient:
 * - Validates Crowdin token before starting
 * - Catches all errors and logs them gracefully
 * - Returns undefined on failure (instead of throwing) to allow calling code to continue
 * 
 * Total possible wait time:
 * - Build slot retry: up to 5 minutes (10 retries × 30 seconds)
 * - Build completion: up to 12.5 minutes (150 checks × 5 seconds)
 * - Maximum total: ~17.5 minutes in worst case scenario
 * 
 * Environment variable required: ROKU_CROWDIN_TOKEN
 * 
 * @param {boolean} [bSkipUntranslatedStrings=true] - If true, excludes incomplete translations from the build
 * @returns {Promise<Object|undefined>} Unzipped directory object containing translation files, or undefined on failure
 */
async function downloadTranslations(bSkipUntranslatedStrings = true) {
  if (!crowdinConfig.crowdinToken) {
    log('COULD NOT DOWNLOAD TRANSLATIONS. MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_TOKEN) OR COMMAND LINE PARAMETER');
    return;
  }

  try {
    const buildId = await startBuild(bSkipUntranslatedStrings);
    await pollBuildStatus(buildId);
    const translationFiles = await downloadBuildFiles(buildId);
    return translationFiles;
  } catch (error) {
    log(`FAILED TO BUILD TRANSLATIONS: "${error.message}"`);
    return;
  }
}


/**
 * Updates the en-US translation function in TubiLanguageTranslate.brs with the latest English strings
 * 
 * This function serves as the bridge between the source translation file (translations/en-US.json)
 * and the BrightScript code (TubiLanguageTranslate.brs) that the Roku app actually uses at runtime.
 * 
 * Process:
 * 1. Reads translations/en-US.json (the source of truth for English translations)
 * 2. Calls writeLocaleDataToBRS_sync() to update the getTranslation_en_US() function
 * 3. The BRS file is modified in place, replacing old translations with new ones
 * 
 * When to use:
 * - After editing translations/en-US.json to add/update English strings
 * - Before uploading to Crowdin (to ensure Crowdin has latest English source)
 * - As part of the translation workflow to keep BRS and JSON in sync
 * 
 * This is typically run as a gulp task: `gulp updateLocalTranslations`
 * 
 * @param {Function} done - Gulp callback function to signal task completion
 * @returns {void}
 */
function updateLocalTranslations(done) {
  //update the BRS file with the American English file before uploading to Crowdin
  log(`Updating the BRS file with the latest version found in: ${_sLocalTranslationFilePath}`)
  const localeData = fs.readFileSync(_sLocalTranslationFilePath, 'utf-8');
  writeLocaleDataToBRS_sync("en-US", localeData);

  log('');
  log('FINISHED UPDATING THE ENGLISH STRINGS IN THE BRS FILE WITH THE LOCAL ENGLISH TRANSLATION FILE');

  done();  //inform gulp that the task has completed.
}


/**
 * Uploads the latest en-US.json source file to Crowdin for translation
 * 
 * This function sends the local translations/en-US.json file to Crowdin, updating the source
 * strings that translators will work from. This is a critical step in the translation workflow
 * because Crowdin needs the latest English text before translators can update other languages.
 * 
 * Upload process:
 * 1. Reads translations/en-US.json from local filesystem
 * 2. Uploads file to Crowdin storage (temporary storage)
 * 3. Updates the project's source file (file ID: 46) with the new content
 * 
 * When to use:
 * - After adding new translation keys to en-US.json
 * - After modifying existing English text that needs re-translation
 * - Before creating a Jira ticket for missing translations (ensures Crowdin is up-to-date)
 * 
 * Typically called by:
 * - uploadLatestTranslationsAndCreateTicketForMissingTranslations() workflow
 * - Manually via gulp task when updating source strings
 * 
 * Environment variable required: ROKU_CROWDIN_TOKEN
 * 
 * @returns {Promise<void>}
 * @throws {Error} If upload fails or Crowdin token is missing
 */
async function uploadTranslations() {
  if (crowdinConfig.crowdinToken !== undefined && crowdinConfig.crowdinToken !== "") {
    try {
      await updateFilesRequest(_sLocalTranslationFilePath);
    } catch (error) {
      new NoStackError(`ERROR UPLOADING THE TRANSLATION FILE TO CROWDIN: "${error}"`);
      throw error;
    }
  } else {
    log('MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_TOKEN) OR COMMAND LINE PARAMETER');
  }
}


/**
 * Downloads translations from Crowdin and processes them into the local codebase
 * 
 * This is the main entry point for the translation download workflow. It downloads the latest
 * translations from Crowdin (triggering a build if needed), then processes each translation file
 * by writing the content to the appropriate locale function in TubiLanguageTranslate.brs.
 * 
 * @param {Function} done - Gulp callback function to signal task completion
 * @returns {Promise<void>}
 */
async function downloadAndProcessTranslations(done) {
  const translationFiles = await downloadTranslations();
  if (translationFiles !== undefined) {
    await processTranslationFiles(translationFiles);
    log('DONE PROCESSING TRANSLATIONS.');
  }

  done();
  return;
}


/**
 * Identifies missing and outdated translations, uploads source to Crowdin, and creates/updates a Jira ticket
 * 
 * This function orchestrates the translation quality check workflow by:
 * 1. Finding translation keys that exist in en-US but are missing in es_MX and fr_CA
 * 2. Identifying keys where the English source has changed and needs re-translation
 * 3. If any issues are found, uploads the latest en-US source to Crowdin
 * 4. Creates a new Jira ticket or updates an existing one with the missing/outdated keys
 * 
 * @param {Function} done - Gulp callback function to signal task completion
 * @returns {Promise<void>}
 */
async function uploadLatestTranslationsAndCreateTicketForMissingTranslations(done) {
  if (crowdinConfig.crowdinToken !== undefined && crowdinConfig.crowdinToken !== "") {
    const untranslatedTranslations = await findMissingTranslationKeys();
    const reTranslationRequiredKeys = await getTranslationKeysWhichNeedsReTranslation();


    if (Object.keys(untranslatedTranslations).length > 0 || reTranslationRequiredKeys.length > 0) {
      await uploadTranslations();
      await createTicketForMissingTranslations(untranslatedTranslations, reTranslationRequiredKeys);
    }

    done();
    return;
  } else {
    log('MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_TOKEN) OR COMMAND LINE PARAMETER');
    done();
    return;
  }
}


/**
 * Finds translation keys that exist in en-US but are missing in other locales
 * 
 * This function compares the en-US translation keys with es_MX and fr_CA locale keys
 * stored in TubiLanguageTranslate.brs. Any keys present in English but absent in a
 * target locale are identified as needing translation.
 * 
 * @returns {Object} Object with locale codes as keys (e.g., 'es_MX', 'fr_CA') and arrays 
 *                   of missing translation keys as values. Empty if all keys are translated.
 * @example
 * // Returns: { "es_MX": ["new_feature_title", "error_message"], "fr_CA": ["new_feature_title"] }
 */
function findMissingTranslationKeys() {
  const locales = ["es_MX", "fr_CA"];
  const englishTranslations = JSON.parse(fs.readFileSync(_sLocalTranslationFilePath, 'utf8'))

  // Get all keys from both
  const englishTranslationKeys = Object.keys(englishTranslations);
  const untranslatedKeys = {};
  for (const locale of locales) {
    // Extract JSON from target locale function
    const localeData = getJSONFromBRS(locale);
    const localeKeys = Object.keys(localeData);
    const missingKeys = englishTranslationKeys.filter(key =>
      !localeKeys.includes(key) && !englishTranslations[key].noTranslationRequired
    );
    if (missingKeys.length > 0) {
      untranslatedKeys[locale] = missingKeys;
    }
  }

  return untranslatedKeys;
}


/**
 * Compares local English translations with remote Crowdin source file to identify keys that need re-translation
 * 
 * This function downloads the source file from Crowdin (remote en-US.json) and compares it with the local
 * en-US translations stored in TubiLanguageTranslate.brs. Any keys where the message content differs
 * between local and remote indicate that the English text has been updated locally but not yet translated
 * in other languages on Crowdin. Re-translation is needed because when the English source changes, all
 * existing translations in other languages become outdated and must be updated to match the new English text.
 * 
 * @returns {Promise<Array<string>>} Array of translation keys where the local English message differs from 
 *                                   the remote Crowdin source, indicating re-translation is needed
 * @throws {Error} If unable to download or parse the remote source file
 */
async function getTranslationKeysWhichNeedsReTranslation() {
  const reTranslationRequiredKeys = [];
  try {
    const sourceResponse = await sourceFilesApi.downloadFile(crowdinConfig.projectId, crowdinConfig.fileId);
    const remoteEnglishTranslations = await fetchJSON(sourceResponse.data.url, {})
    const englishTranslations = getJSONFromBRS('en-US');

    // Compare messages between remote and local English translations
    for (const key in englishTranslations) {
      const localMessage = englishTranslations[key]?.message || '';
      const remoteMessage = remoteEnglishTranslations[key]?.message || '';

      // If key exists in both but messages don't match
      if (remoteEnglishTranslations.hasOwnProperty(key) && localMessage !== remoteMessage) {
        reTranslationRequiredKeys.push(key);
      }
    }

  } catch (error) {
    log(`Failed to get translation keys which needs re-translation: ${error.message}`);
    throw error;
  }
  return reTranslationRequiredKeys;
}


/**
 * Searches for existing open ROKU translation tickets in Jira
 * 
 * Uses JQL (Jira Query Language) to find tickets matching:
 * - Project: TINTL
 * - Summary contains: "ROKU Translations"
 * - Status: Not Done
 * - Labels: Localization AND current branch name
 * 
 * This prevents creating duplicate tickets when translation work is already tracked
 * for the same branch.
 * 
 * @param {string} auth - Base64 encoded authentication string (email:token)
 * @param {string} JIRA_BASE_URL - Jira instance base URL (e.g., 'tubitv.atlassian.net')
 * @returns {Promise<Object|null>} The most recently created open ticket, or null if none exist
 */
async function findExistingOpenTranslationTicket(auth, JIRA_BASE_URL) {
  try {
    const currentBranch = getCurrentBranch();

    // JQL query to find open ROKU translation tickets for the current branch
    // Using summary match instead of custom field to avoid field ID issues
    const jql = `project = TINTL AND summary ~ "ROKU Translations" AND status NOT IN (Done, Released) AND labels = Localization AND labels = "${currentBranch}" ORDER BY created DESC`;

    const response = await axios.get(
      `https://${JIRA_BASE_URL}/rest/api/3/search/jql`,
      {
        params: {
          jql: jql,
          maxResults: 1,
          fields: 'key,summary,status'
        },
        headers: {
          'Authorization': `Basic ${auth}`,
          'Accept': 'application/json'
        }
      }
    );

    if (response.data.issues && response.data.issues.length > 0) {
      const issue = response.data.issues[0];
      log(`Found existing open ticket for branch "${currentBranch}": ${issue.key} - ${issue.fields.summary}`);
      return issue;
    }

    log(`No existing open translation tickets found for branch "${currentBranch}".`);
    return null;
  } catch (error) {
    log(`Error searching for existing tickets: ${error.message}`);
    return null;
  }
}

/**
 * Adds a comment to an existing Jira ticket
 * 
 * Uses Jira REST API v3 to add a timestamped comment to track when the ticket
 * was updated with additional translation keys.
 * 
 * @param {string} issueKey - The Jira ticket key (e.g., 'TINTL-123')
 * @param {Array<Object>} commentContent - ADF (Atlassian Document Format) content array for the comment
 * @param {string} auth - Base64 encoded authentication string (email:token)
 * @param {string} JIRA_BASE_URL - Jira instance base URL (e.g., 'tubitv.atlassian.net')
 * @returns {Promise<Object>} The created comment object from Jira API
 * @throws {Error} If unable to add comment to the ticket
 */
async function addCommentToTicket(issueKey, commentContent, auth, JIRA_BASE_URL) {
  try {
    const response = await axios.post(
      `https://${JIRA_BASE_URL}/rest/api/3/issue/${issueKey}/comment`,
      {
        body: {
          type: 'doc',
          version: 1,
          content: commentContent
        }
      },
      {
        headers: {
          'Authorization': `Basic ${auth}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      }
    );

    log(`✅ Comment added to ticket: ${issueKey}`);
    return response.data;
  } catch (error) {
    log(`Failed to add comment to ticket: ${error.message}`);
    if (error.response) {
      log(`Status: ${error.response.status}`);
      log(`Response: ${JSON.stringify(error.response.data)}`);
    }
    throw error;
  }
}

/**
 * Updates the description of an existing Jira ticket
 * 
 * Replaces the entire ticket description with new ADF content containing updated
 * translation keys. This is called when new missing keys are discovered or when
 * re-translation requirements change.
 * 
 * @param {string} issueKey - The Jira ticket key (e.g., 'TINTL-123')
 * @param {Array<Object>} descriptionContent - ADF (Atlassian Document Format) content array for the description
 * @param {string} auth - Base64 encoded authentication string (email:token)
 * @param {string} JIRA_BASE_URL - Jira instance base URL (e.g., 'tubitv.atlassian.net')
 * @returns {Promise<Object>} The updated ticket object from Jira API
 * @throws {Error} If unable to update the ticket description
 */
async function updateTicketDescription(issueKey, descriptionContent, auth, JIRA_BASE_URL) {
  try {
    const response = await axios.put(
      `https://${JIRA_BASE_URL}/rest/api/3/issue/${issueKey}`,
      {
        fields: {
          description: {
            type: 'doc',
            version: 1,
            content: descriptionContent
          }
        }
      },
      {
        headers: {
          'Authorization': `Basic ${auth}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      }
    );

    log(`✅ Description updated for ticket: ${issueKey}`);
    return response.data;
  } catch (error) {
    log(`Failed to update ticket description: ${error.message}`);
    if (error.response) {
      log(`Status: ${error.response.status}`);
      log(`Response: ${JSON.stringify(error.response.data)}`);
    }
    throw error;
  }
}

/**
 * Builds an ADF (Atlassian Document Format) paragraph node
 * 
 * Creates a simple paragraph with plain text content for use in Jira ticket
 * descriptions and comments.
 * 
 * @param {string} text - The text content for the paragraph
 * @returns {Object} ADF paragraph node with the specified text
 */
function buildAdfParagraph(text) {
  return {
    type: 'paragraph',
    content: [{ type: 'text', text }]
  };
}

/**
 * Builds an ADF (Atlassian Document Format) bullet list from an array of translation keys
 * 
 * Converts an array of strings into a formatted bullet list for Jira ticket descriptions.
 * Each key becomes a separate list item.
 * 
 * @param {Array<string>} keys - Array of translation keys to display as bullet points
 * @returns {Object} ADF bulletList node containing all the keys as list items
 */
function buildAdfBulletList(keys) {
  return {
    type: 'bulletList',
    content: keys.map(key => ({
      type: 'listItem',
      content: [{
        type: 'paragraph',
        content: [{ type: 'text', text: key }]
      }]
    }))
  };
}

/**
 * Builds ADF heading
 */
function buildAdfHeading(text, level = 3) {
  const content = [{ type: 'text', text }];
  if (level === 3) {
    content[0].marks = [{ type: 'strong' }];
  }
  return {
    type: 'heading',
    attrs: { level },
    content
  };
}

/**
 * Builds the complete Jira ticket description in ADF format
 * 
 * Constructs a structured ticket description containing:
 * 1. Introduction paragraph
 * 2. Re-translation required keys section (if any exist)
 * 3. Missing translation keys grouped by locale (es_MX, fr_CA)
 * 4. Note about identical translations
 * 
 * @param {Object} untranslatedTranslations - Object with locale codes as keys and arrays of missing keys as values
 * @param {Array<string>} reTranslationRequiredKeys - Array of keys where English source has changed
 * @returns {Array<Object>} ADF content array ready for Jira ticket description
 */
function buildTicketDescription(untranslatedTranslations, reTranslationRequiredKeys) {
  const descriptionContent = [
    buildAdfParagraph('Could you please help us with the translations for below keys:')
  ];

  // Add re-translation required keys section
  if (reTranslationRequiredKeys.length > 0) {
    descriptionContent.push(
      buildAdfParagraph('Below keys need re-translation to all languages:'),
      buildAdfBulletList(reTranslationRequiredKeys)
    );
  }

  // Add missing keys by locale
  for (const locale in untranslatedTranslations) {
    descriptionContent.push(
      buildAdfHeading(locale, 3),
      buildAdfBulletList(untranslatedTranslations[locale])
    );
  }

  // Add note
  descriptionContent.push(
    buildAdfHeading('Note: If any translation is identical to the American English, then it can be left blank, saved, and approved. The outcome should read: [empty translation]', 4)
  );

  return descriptionContent;
}

/**
 * Checks if a Jira ticket's description has changed by comparing with new content
 * 
 * Fetches the current ticket description from Jira and performs a JSON string comparison
 * with the new description content. This prevents unnecessary API calls and notification
 * spam when the description hasn't actually changed.
 * 
 * @param {string} issueKey - The Jira ticket key (e.g., 'TINTL-123')
 * @param {Array<Object>} newDescriptionContent - ADF content array for the new description
 * @param {string} auth - Base64 encoded authentication string (email:token)
 * @param {string} JIRA_BASE_URL - Jira instance base URL (e.g., 'tubitv.atlassian.net')
 * @returns {Promise<boolean>} True if description has changed, false if identical
 */
async function hasDescriptionChanged(issueKey, newDescriptionContent, auth, JIRA_BASE_URL) {
  try {
    const response = await axios.get(
      `https://${JIRA_BASE_URL}/rest/api/3/issue/${issueKey}`,
      {
        params: { fields: 'description' },
        headers: {
          'Authorization': `Basic ${auth}`,
          'Accept': 'application/json'
        }
      }
    );

    const currentDescription = response.data.fields.description;
    const newDescriptionStr = JSON.stringify(newDescriptionContent);
    const currentDescriptionStr = JSON.stringify(currentDescription?.content || []);

    return newDescriptionStr !== currentDescriptionStr;
  } catch (error) {
    log(`Warning: Could not fetch current ticket description: ${error.message}`);
    return true; // Assume changed if we can't fetch
  }
}

/**
 * Updates an existing open ROKU translation ticket with new or additional translation keys
 * 
 * This function first checks if the ticket's description has actually changed by comparing the new
 * description content with the current ticket description. If changes are detected, it updates the
 * ticket description and adds a timestamped comment to track the update. If no changes are detected,
 * it skips the update to avoid unnecessary API calls and notification spam.
 * 
 * @param {Object} existingTicket - The existing Jira ticket object (must contain at least the 'key' property)
 * @param {Array<Object>} descriptionContent - ADF (Atlassian Document Format) content array for the ticket description
 * @param {string} auth - Base64 encoded authentication string (email:token)
 * @param {string} JIRA_BASE_URL - Jira instance base URL (e.g., 'tubitv.atlassian.net')
 * @returns {Promise<Object>} The existing ticket object
 * @throws {Error} If unable to fetch current description, update ticket, or add comment
 */
async function updateExistingTicket(existingTicket, descriptionContent, auth, JIRA_BASE_URL) {
  log(`Updating existing ticket: ${existingTicket.key}`);

  const hasChanged = await hasDescriptionChanged(existingTicket.key, descriptionContent, auth, JIRA_BASE_URL);

  if (!hasChanged) {
    log('Description unchanged. No update needed.');
    log(`   View at: https://${JIRA_BASE_URL}/browse/${existingTicket.key}`);
    return existingTicket;
  }

  log('Description has changed. Updating ticket...');
  await updateTicketDescription(existingTicket.key, descriptionContent, auth, JIRA_BASE_URL);

  // Add update comment
  const date = new Date();
  const commentContent = [
    {
      type: 'paragraph',
      content: [{
        type: 'text',
        text: `Updated on ${date.toLocaleDateString('en-US')} at ${date.toLocaleTimeString('en-US')}`,
        marks: [{ type: 'strong' }]
      }]
    },
    buildAdfParagraph('Updated the ticket to include additional translation keys.')
  ];

  await addCommentToTicket(existingTicket.key, commentContent, auth, JIRA_BASE_URL);
  log(`   View at: https://${JIRA_BASE_URL}/browse/${existingTicket.key}`);

  return existingTicket;
}

/**
 * Creates a new Jira translation ticket in the TINTL project
 * 
 * Creates a new Story ticket with:
 * - Dynamic date-based summary (e.g., "ROKU Translations 10/16/2025")
 * - ADF formatted description with missing/outdated translation keys
 * - Custom fields: Story type = Chore, Request Type = Engineering, Platform = Roku
 * - Assigned to localization team member
 * - Linked to parent epic (TINTL-21)
 * - Tagged with Localization label
 * 
 * @param {Array<Object>} descriptionContent - ADF content array for the ticket description
 * @param {string} auth - Base64 encoded authentication string (email:token)
 * @param {string} JIRA_BASE_URL - Jira instance base URL (e.g., 'tubitv.atlassian.net')
 * @param {string} JIRA_PROJECT_ID - Jira project ID for TINTL
 * @param {string} JIRA_ASSIGNEE_ACCOUNT_ID - Account ID of the assignee
 * @returns {Promise<Object>} The created ticket object from Jira API
 * @throws {Error} If unable to create the ticket
 */
async function createNewTicket(descriptionContent, auth, JIRA_BASE_URL, JIRA_PROJECT_ID, JIRA_ASSIGNEE_ACCOUNT_ID) {
  log('Creating new translation ticket...');

  const date = new Date();
  const dateString = `${String(date.getMonth() + 1).padStart(2, '0')}/${String(date.getDate()).padStart(2, '0')}/${date.getFullYear()}`;
  const currentBranch = getCurrentBranch();

  const issueData = {
    fields: {
      project: { id: JIRA_PROJECT_ID.toString() },
      summary: `ROKU Translations ${dateString}`,
      description: {
        type: 'doc',
        version: 1,
        content: descriptionContent
      },
      issuetype: { name: 'Story' },
      assignee: { accountId: JIRA_ASSIGNEE_ACCOUNT_ID },
      customfield_10375: { value: 'Chore' },
      customfield_10276: { value: 'Engineering' },
      customfield_10247: [{ value: 'Roku' }],
      parent: { key: 'TINTL-21' },
      labels: ['Localization', currentBranch]
    }
  };

  try {
    const response = await axios.post(
      `https://${JIRA_BASE_URL}/rest/api/3/issue`,
      issueData,
      {
        headers: {
          'Authorization': `Basic ${auth}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      }
    );

    log(`✅ New Jira ticket created: ${response.data.key}`);
    log(`   View at: https://${JIRA_BASE_URL}/browse/${response.data.key}`);
    return response.data;
  } catch (error) {
    log(`Failed to create Jira ticket: ${error.message}`);
    if (error.response) {
      log(`Status: ${error.response.status}`);
      log(`Response: ${JSON.stringify(error.response.data)}`);
    }
    throw error;
  }
}

/**
 * Creates or updates a Jira ticket for missing and outdated translations
 * 
 * This is the main orchestrator for Jira ticket management. It:
 * 1. Builds the ticket description from missing/outdated translation keys
 * 2. Searches for an existing open ROKU translation ticket
 * 3. If found, updates the existing ticket (if description changed) and adds a comment
 * 4. If not found, creates a new ticket with all the required fields
 * 
 * Environment variables required:
 * - JIRA_TOKEN: Jira API token for authentication
 * - JIRA_EMAIL: Email associated with the Jira account
 * 
 * @param {Object} untranslatedTranslations - Object with locale codes as keys and arrays of missing keys as values
 * @param {Array<string>} reTranslationRequiredKeys - Array of keys where English source has changed
 * @returns {Promise<Object|void>} The created or updated ticket object, or void if env vars missing
 */
async function createTicketForMissingTranslations(untranslatedTranslations, reTranslationRequiredKeys) {
  const JIRA_TOKEN = process.env.JIRA_TOKEN;
  const JIRA_BASE_URL = 'tubitv.atlassian.net';
  const JIRA_EMAIL = process.env.JIRA_EMAIL;
  const JIRA_PROJECT_ID = '10222';
  const JIRA_ASSIGNEE_ACCOUNT_ID = '5ec76b76ae79a10c16ba92b4'; // Michael Jordan Morales

  if (!JIRA_TOKEN || !JIRA_EMAIL) {
    log('JIRA_TOKEN and JIRA_EMAIL environment variables are required');
    return;
  }

  const auth = Buffer.from(`${JIRA_EMAIL}:${JIRA_TOKEN}`).toString('base64');
  const descriptionContent = buildTicketDescription(untranslatedTranslations, reTranslationRequiredKeys);

  // Check for existing open ticket and either update or create
  const existingTicket = await findExistingOpenTranslationTicket(auth, JIRA_BASE_URL);

  if (existingTicket) {
    // Update the existing ticket
    const updatedTicket = await updateExistingTicket(existingTicket, descriptionContent, auth, JIRA_BASE_URL);

    // Show warning prompt after update
    await prompts({
      type: 'text',
      name: 'acknowledged',
      message: `⚠️  Please follow up on the existing translation ticket: https://${JIRA_BASE_URL}/browse/${existingTicket.key}\n   Press Enter to continue...`,
      initial: ''
    });

    return updatedTicket;
  } else {
    return await createNewTicket(descriptionContent, auth, JIRA_BASE_URL, JIRA_PROJECT_ID, JIRA_ASSIGNEE_ACCOUNT_ID);
  }
}


module.exports = {
  updateLocalTranslations,
  uploadTranslations,
  downloadAndProcessTranslations,
  uploadLatestTranslationsAndCreateTicketForMissingTranslations
}