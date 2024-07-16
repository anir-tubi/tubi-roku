const fs = require('fs');
const path = require('path');
const https = require('https');
const log = require('fancy-log');
const {NoStackError} = require('./utilities');
const {fetchJSON} = require('./network');
const prompts = require('prompts');

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

  if(arg["crowdinToken"] !== undefined){
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
function removeEmptyTranslations(localeData) {
  const jsonTranslationFile = JSON.parse(localeData);

  for (const key in jsonTranslationFile) {
    if (jsonTranslationFile[key].message === "") {
      delete jsonTranslationFile[key];
    }
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
          const jsonString = removeEmptyTranslations(localeData)
          
          // write the contents of the translation json to the appropriate function
          // in the TubiLanguageTranslate.brs file
          writeLocaleDataToBRS_sync(sLocale, jsonString);

          sLocale = sLocale.toLowerCase();
          if (sLocale !== 'en-us' && sLocale !== 'en_us'){
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
function processRemoteJSONData(localeData){
  let sJsonReturn;
  if(localeData !== undefined && localeData !== "") {
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
function  unprocessJSONString(sJSONData){
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
function getLocaleFunctionStartString(sLocale){
  sLocale = sLocale.replace("-", "_");
  const sFunctionName = `getTranslation_${sLocale}`;
  const sStartFunctionString = `Function ${sFunctionName}()`;

  return sStartFunctionString;
}


function getFunctionEndString(){
  return "End Function";
}


//Write the translation contents of a locale into the translations BRS file if they don't exist yet or replace them if they do.
function writeLocaleDataToBRS_sync(sLocale, localeData) {
  if(localeData !== undefined && localeData !== "") {
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
        const url = `${resp.socket.servername}${resp.req.path}`
        const method = resp.socket["_httpMessage"].method
        const errorMessage = `Received ${resp.statusCode} while attempting a ${method} request to ${url}`
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


//Download and return the translations
//@nMaxRetries: Integer, How many times should Crowdin be called to check the build status before displaying an error?
//@bSkipUntranslatedStrings: Boolean, Should the Untranslated Strings in Crowdin be skipped?
//@return if the process is successful, then this returns an associative array of the files returned from Crowdin. if the process fails, then this returns nothing.
async function downloadTranslations(nMaxRetries = 5, bSkipUntranslatedStrings = true) {
  let translationFiles;

  if(crowdinConfig.crowdinToken!== undefined && crowdinConfig.crowdinToken !== ""){
    try{
      const nRetryTiming = 2000; //The number of milliseconds to try to check the build status
      let nRetryCount = 0
      const result = await translationsApi.buildProject(crowdinConfig.projectId, {skipUntranslatedStrings: bSkipUntranslatedStrings});
      const buildId = result.data.id;

      while (nRetryCount < nMaxRetries){
        const resultCheckBuildStatus = await translationsApi.checkBuildStatus(crowdinConfig.projectId, buildId)

        let sStatus = resultCheckBuildStatus.data.status.toLowerCase();
        if (sStatus === 'finished'){
          log('Starting to download the translations.');
          const translationInfo = await translationsApi.downloadTranslations(crowdinConfig.projectId, result.data.id);

          const translationsFileBuffer = await getTranslationsZipFile(translationInfo.data.url);
          const unzipper = require('unzipper');
          translationFiles = await unzipper.Open.buffer(translationsFileBuffer);
          
          log('DONE DOWNLOADING TRANSLATIONS.');       
          return translationFiles;
        } else if(sStatus === 'canceled' || sStatus === 'failed') {
          log(`FAILED TO BUILD TRANSLATIONS. STATUS = ${sStatus}`);
          return;
        } else {
          nRetryCount++;
          if (nRetryCount < nMaxRetries) {
            log(`Crowdin is currently building the project. Status = ${resultCheckBuildStatus.data.status}`);
            log(`Will attempt to get the translations again in ${nRetryTiming} ms. ${nRetryCount} out of ${nMaxRetries} times.`);
            await new Promise(resolve => setTimeout(resolve, nRetryTiming));
          }
        }
      }

      log('FAILED TO BUILD TRANSLATIONS. Crowdin is busy creating a build. Please try again later.');
      return;
    } catch(error) {
      log(`FAILED TO BUILD TRANSLATIONS: "${error}"`);
      return;
    }
  } else {
    log('COULD NOT DOWNLOAD TRANSLATIONS. MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_KEY) OR COMMAND LINE PARAMETER');
    return;
  }
}


//update the English strings within the translation BRS file with the latest version of the US English locale file
function updateLocalTranslations(done) {
  //update the BRS file with the American English file before uploading to Crowdin
  log(`Updating the BRS file with the latest version found in: ${_sLocalTranslationFilePath}`)
  const localeData = fs.readFileSync(_sLocalTranslationFilePath, 'utf-8');
  writeLocaleDataToBRS_sync("en-US", localeData);

  log('');
  log('FINISHED UPDATING THE ENGLISH STRINGS IN THE BRS FILE WITH THE LOCAL ENGLISH TRANSLATION FILE');

  done();  //inform gulp that the task has completed.
}


//Get a list of strings that have the same value between the two passed objects: i.e.  
//objectLanguage1.key1.message === objectLanguage2.key1.message
//@objectLanguage1: Object, A JSON object literal containing all the language strings are ordered by the index of an id/key 
//@objectLanguage2: Object, It has the same format as the previous param. If the previous param was of locally stored translation, then this param would be the remotely stored, and visa versa.
function getListOfStringsThatMatch(objectLanguage1, objectLanguage2) {
  let aMatchedStrings = [];
  for(var key in objectLanguage1){
    if(objectLanguage1[key] !== undefined && objectLanguage2[key] !== undefined){
      if(objectLanguage1[key].message !== undefined && objectLanguage2[key].message !== undefined && objectLanguage1[key].message === objectLanguage2[key].message){
        aMatchedStrings.push(key);
      }
    }
  }
  return aMatchedStrings;
}


//Get an array of strings that do NOT have the same value between the two passed JSON objects: i.e.  
//jsonLanguage1.key1.message !== jsonLanguage1.key1.message
// Note: We do not need to be concerned with key/message pairs that might exist in one of the jsonLanguage objects, but not the other.
//  When the English strings are in sync (a previous check), then Crowdin will automatically ensure all translations have the same keys.
//@return An array as described above: [key1, key5, key22, etc]
function getListOfStringsThatDoNotMatch(jsonLanguage1, jsonLanguage2) {
  let aUnMatchedStrings = [];
  for(var key in jsonLanguage1){
    if(jsonLanguage1[key] !== undefined && jsonLanguage2[key] !== undefined){
      if(jsonLanguage1[key].message !== undefined && jsonLanguage2[key].message !== undefined && jsonLanguage1[key].message !== jsonLanguage2[key].message ){
        aUnMatchedStrings.push(key);
      }
    }
  }
  return aUnMatchedStrings;
}


// Check that the local English strings in en-US.json match with the remote Crowdin version.
// If the two JSON files do not match, then report the string keys associated with the strings that do not match.
// Ask if the developer would like to cancel to upload the strings to Crowdin and get the strings translated
// @remoteUSEnglishTranslations: The JSON object literal representing the crowdin, remote English translations
// @return Boolean, True if translations passed comparison test or user chose to ignore the failed comparison test.
async function compareEnglishTranslations(remoteUSEnglishTranslations) {
  log('COMPARE STEP #1: Checking if English strings needs to be uploaded to Crowdin...');
  const localeData = fs.readFileSync(_sLocalTranslationFilePath, 'utf-8');
  const localUSEnglishTranslations = JSON.parse(localeData);
  let aMissingData = [];

  for (const key in localUSEnglishTranslations) {
    let remoteTranslation = remoteUSEnglishTranslations[key];
    let localTranslation = localUSEnglishTranslations[key];
    if (remoteTranslation !== undefined){
        if (remoteTranslation.message !== localTranslation.message){
          //If the remote string does not match with the local string, then the local strings may still need to be uploaded to Crowdin
          aMissingData.push(key);
        }
    } else {
      //If the remote string does not exist, then the local strings may still need to be uploaded to Crowdin
      aMissingData.push(key);
    }
  }
  if(aMissingData.length > 0){
    log(`The US English strings associated with the following ID(s) are MISSING from Crowdin, or they are DIFFERENT from those found on Crowdin: ${aMissingData.join(", ")}.`);
    
    //Add a prompt asking if the engineer wants to cancel, so he/she can fix the English local and remote string mismatch.
    const {bEnglishMismatchCancel} = await prompts({
      type: 'confirm',
      name: 'bEnglishMismatchCancel',
      message: `You may need to run "gulp uploadTranslations" to upload the English strings to Crowdin.\n Do you wish to cancel the current process? (y/n)`,
    });

    if (bEnglishMismatchCancel) {
      return false;
    }

  } else {
    log('COMPARE STEP #1 Complete: Crowdin Source file matches with local US English JSON!');
    log(' ');
  }

  return true;
}


//  Check if there are any untranslated words in crowdin. The way to know if there are
//  untranslated words is if the string is the same as the US English version. This is because when we 
//  called downloadTranslations(), we passed false for the bSkipUntranslatedStrings param. If we had passed 
//  true, then the untranslated words would have a blank string in the JSON file.
//
//  Report if there are untranslated strings.
//  Ask if the developer would like to continue or stop so the developer can get the words translated and then to download the strings from Crowdin into the master branch and cherry pick that change into this branch
// @aaTranslations, an associative array of the locale and their corresponding remote JSON
// @jsonUSEnglishRemoteData, The US English JSON object that is located remotely on Crowdin. sourceFilesApi.downloadFile() must be called to get this object
// @return Boolean, Were there no errors or did the user choose to ignore the errors? 
async function checkForRemoteUntranslatedTranslations(aaTranslations, jsonUSEnglishRemoteData) {
  log('COMPARE STEP #2: Now checking to see if there are any untranslated strings in Crowdin...');
  let bUntranslatedStringsFound = false;
  for(let locale in aaTranslations){
    //strings from other languages should not match with English strings. If they do, then both strings are assumed to be in English. The foreign language is assumed to be untranslated.
    let aMatches = getListOfStringsThatMatch(aaTranslations[locale], jsonUSEnglishRemoteData);
    if(aMatches.length > 0){
      bUntranslatedStringsFound = true;
      log(`Untranslated strings have been found in the locale "${locale.toLocaleUpperCase()}" with the ids: ${aMatches.join(", ")}.`);
      log(' ');
    }
  }

  if(bUntranslatedStringsFound){
    //Add a prompt asking if the engineer wants to cancel, so he/she can fix the untranslated strings
    const {bUntranslatedCancel} = await prompts({
      type: 'confirm',
      name: 'bUntranslatedCancel',
      message: `Once all of the strings in Crowdin have been translated, you may need to run "gulp downloadTranslations" on a branch cut from master, make a PR to master, and cherry pick the translations into this branch.\n Do you wish to cancel this process so you may do that? (y/n)`,
    });
    
    if (bUntranslatedCancel) {
      return false;
    }
  } else {
    log('COMPARE STEP #2 Complete: There are no untranslated strings in Crowdin');
    log(' ');
  }
  return true;
}


//  Check if the local non-US English languages match with Crowdin.
//  If they do not match, then the translations may not have been downloaded from Crowdin.
//  Report the string keys that do not match.
//  Ask if the developer wishes to continue or stop to download the strings from Crowdin into the master branch and cherry pick that change into this branch
// @aaTranslations, an associative array of the locale and their corresponding remote JSON
// @return Boolean, Were there no errors or did the user choose to ignore the errors? 
async function compareForeignTranslations(aaTranslations) {
    log('COMPARE STEP #3: Now checking to see if all translations have been downloaded from Crowdin...');
    let bNonDownloadedStringsFound = false;

    for(let locale in aaTranslations){
      let localeRemoteData = aaTranslations[locale];

      // Process remote JSON data similarly to local data, then "unprocess" it for comparison.
      // This is necessary because the processing is destructive and we need to compare processed remote 
      // data with processed local data. Also, it is difficult to compare the 2 versions of the translation files before making them into JSON objects,
      // as the processing introduces special characters making it impossible to convert the strings into JSON objects and thus making it 
      // difficult to compare the 2 versions of the translation files.
      // Previously, local data was generated from Crowdin and processed.
      let sLocaleRemoteData = JSON.stringify(localeRemoteData);
      const jsonString = removeEmptyTranslations(sLocaleRemoteData);
      localeRemoteData = processRemoteJSONData(jsonString);
      localeRemoteData = unprocessJSONString(jsonString); 

      let localeLocalData = getJSONFromBRS(locale);

      let aNonMatches = getListOfStringsThatDoNotMatch(localeRemoteData, localeLocalData);
      if(aNonMatches.length > 0){
        bNonDownloadedStringsFound = true;
        log(`Strings have been found NOT to be downloaded from Crowdin in the locale "${locale.toLocaleUpperCase()}" with the ids: ${aNonMatches.join(", ")}.`);
        log(' ');
      }
    }

    if(bNonDownloadedStringsFound){
      //Add a prompt asking if the engineer wants to cancel, so he/she can download the latest strings
      const {bUnDownloadedCancel} = await prompts({
        type: 'confirm',
        name: 'bUnDownloadedCancel',
        message: `You may need to run "gulp downloadTranslations" in a branch cut from master, make a PR to master, and cherry pick the translations into this branch.\n Do you wish to cancel so you may do that? (y/n)`,
      });

      if (bUnDownloadedCancel) {
        return false;
      } 
    } else {
      log('COMPARE STEP #3 Complete: All translations have been downloaded from Crowdin.');
      log(' ');
    }

    return true;
}


//upload the latest version of the US English locale file to crowdin
async function uploadTranslations(done) {
  if(crowdinConfig.crowdinToken !== undefined && crowdinConfig.crowdinToken !== ""){
    try {
      const updateFileResponse = await updateFilesRequest(_sLocalTranslationFilePath);
      log('SUCCESS! FINISHED UPLOADING THE TRANSLATION FILE TO CROWDIN');
      done();
    } catch(error) {
      done(new NoStackError(`ERROR UPLOADING THE TRANSLATION FILE TO CROWDIN: "${error}"`));
    }
  } else {
    log('MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_TOKEN) OR COMMAND LINE PARAMETER');
    done();
  }
}


// Get the translations of all the locales and place it in in an associative array 
// @return Associative Array, an associative array of the locale and their corresponding remote JSON
async function getRemoteTranslations() {
  //an associative array of the locale and their corresponding remote JSON
  let aaTranslations = {};

  //  Download the latest from Crowdin to the next step. Wait up to minute for the download to occur. 
  //  When it does, then instead of saving the download into a file, save it in a variable.
  const translationFiles = await downloadTranslations(30, false);
  if (translationFiles && translationFiles.files) {

    // iterate over each file in the zipped directory
    for (const file of translationFiles.files) {
      let unZippedFilePath = file.path;

      // if the file path contains 'roku' and '.json', we want to process it
      // expect the file path looks like 'es-MX/roku/translations/es-MX.json'
      if (unZippedFilePath.indexOf(crowdinConfig.crowdinBaseDirectory) >= 0 && unZippedFilePath.indexOf('.json') >= 0) {
        //Remove '.json' from the file path to get the locale ID
        let sLocale = path.parse(unZippedFilePath).name;
        sLocale = sLocale.toLowerCase();

        let fileBuffer = await file.buffer();
        if (fileBuffer !== undefined) {
          let fileString = fileBuffer.toString();
          let fileJSON = JSON.parse(fileString);
          if (fileJSON !== undefined) {
            aaTranslations[sLocale] = fileJSON;
          }
        }
        
      }
    }
  }
  return aaTranslations;
}


async function downloadAndProcessTranslations(done) {
  const translationFiles = await downloadTranslations();
  if (translationFiles !== undefined){
    await processTranslationFiles(translationFiles);
    log('DONE PROCESSING TRANSLATIONS.');
  }

  done();
  return;
}


//compare the local version of our source and translated strings with the remote versions to ensure 
//the translations are currently up to date. This function will do 3 comparisons. The developer can bypass
//any failed comparison test.
async function compareTranslations(done) {
  if(crowdinConfig.crowdinToken!== undefined && crowdinConfig.crowdinToken !== ""){
    //The US English JSON that is located remotely on Crowdin
    let jsonUSEnglishRemoteData;

    log('Preparing to compare Crowdin Source file with local US English JSON...');
    try {
      const sourceResponse = await sourceFilesApi.downloadFile(crowdinConfig.projectId, crowdinConfig.fileId);
      const sSourceURL = sourceResponse.data.url;
      
      jsonUSEnglishRemoteData = await fetchJSON(sSourceURL, {});
      
    }  catch(error) {
      done(new NoStackError(`ERROR DOWNLOADING THE ENGLISH SOURCE FILE FROM CROWDIN: "${error}"`));
      return;
    }


    //  COMPARE STEP #1: 
    const bEnglishTranslationComparisonContinue = await compareEnglishTranslations(jsonUSEnglishRemoteData);
    if (!bEnglishTranslationComparisonContinue) {
      //if compareEnglishTranslations() indicates that the script was aborted, then stop function
      return done(new NoStackError('Script aborted'));
    }


    //an associative array of the locale and their corresponding remote JSON
    let aaTranslations = await getRemoteTranslations();

    //  COMPARE STEP #2: 
    const bRemoteUntranslatedTranslationsCheck =  await checkForRemoteUntranslatedTranslations(aaTranslations, jsonUSEnglishRemoteData);
    if (!bRemoteUntranslatedTranslationsCheck) {
      //if checkForRemoteUntranslatedTranslations() indicates that the script was aborted, then stop function
      return done(new NoStackError('Script aborted'));
    }

    //  COMPARE STEP #3:
    const bForeignTranslationComparisonContinue =  await compareForeignTranslations(aaTranslations);
    if (!bForeignTranslationComparisonContinue) {
      //if compareForeignTranslations() indicates that the script was aborted, then stop function
      return done(new NoStackError('Script aborted'));
    }


    log('Translation checks have been completed.');
    done();
    return;
  } else {
    log('MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_TOKEN) OR COMMAND LINE PARAMETER');
    done();
    return;
  }
}


module.exports = {
  updateLocalTranslations,
  uploadTranslations,
  downloadAndProcessTranslations,
  compareTranslations
}