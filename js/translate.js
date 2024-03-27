const fs = require('fs');
const path = require('path');
const https = require('https');
const log = require('fancy-log');
const {NoStackError} = require('./utilities');

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
}

const _sLocalTranslationFilename = "translations/en-US.json";
const _sLocalTranslationFilePath = `${process.cwd()}/${_sLocalTranslationFilename}`

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
        let sLocale = unZippedFilePath.slice(unZippedFilePath.lastIndexOf('/') + 1, -5);

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


//Write the translation contents of a locale into the translations BRS file if they don't exist yet or replace them if they do.
function writeLocaleDataToBRS_sync(sLocale, localeData) {
  if(localeData !== undefined && localeData !== "") {
    var fileTranslationCode = 'src/channel/source/lib/TubiLanguageTranslate.brs';
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
    localeData = localDataLinesIndented.join('\n');

    var data = fs.readFileSync(fileTranslationCode, 'utf-8');
    sLocale = sLocale.replace("-", "_");
    var sFunctionName = `getTranslation_${sLocale}`;
    var sStartFunction = `Function ${sFunctionName}()`;
    var sEndFunction = "End Function";

    var newValue = ""
    var sNewString = `${sStartFunction}\n  return ${localeData}\n${sEndFunction}`

    if (data.indexOf(sStartFunction) >= 0) {
      //If the locale function exists, then update the function with the new translations
      log(`Found ${sLocale} locale function. Now replace it within the BRS file: '${fileTranslationCode}'`);
      var re = new RegExp(escapeRegExp(sStartFunction) + "[\\s\\S]*?" + sEndFunction, "i");
      newValue = data.replace(re, sNewString);
    } else {
      //If the locale function does not exist, then create a new function with the new translations
      log(`Could not find ${sLocale} locale function. Appending it to the end of the BRS file: '${fileTranslationCode}'`);
      newValue = `${data}\n\n\n${sNewString}`;
    }

    fs.writeFileSync(fileTranslationCode, newValue, 'utf-8');
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


//update the English strings within the translation BRS file with the latest version of the US English locale file
function updateLocalTranslations(done) {
  //update the BRS file with the American English file before uploading to Crowdin
  log("Updating the BRS file with the latest version found in: ", _sLocalTranslationFilePath)
  const localeData = fs.readFileSync(_sLocalTranslationFilePath, 'utf-8');
  writeLocaleDataToBRS_sync("en-US", localeData);

  log('');
  log('FINISHED UPDATING THE ENGLISH STRINGS IN THE BRS FILE WITH THE LOCAL ENGLISH TRANSLATION FILE');

  done();  //inform gulp that the task has completed.
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

async function downloadTranslations(done) {

  if(crowdinConfig.crowdinToken!== undefined && crowdinConfig.crowdinToken !== ""){
    try{
      const nMaxRetries = 5;
      const nRetryTiming = 2000; //The number of milliseconds to try to check the build status
      let nRetryCount = 0
      const result = await translationsApi.buildProject(crowdinConfig.projectId, {skipUntranslatedStrings: true});
      const buildId = result.data.id;

      while (nRetryCount < nMaxRetries){
        const resultResult = await translationsApi.checkBuildStatus(crowdinConfig.projectId, buildId)

        let sStatus = resultResult.data.status.toLowerCase();
        if (sStatus === 'finished'){
          log('Starting to download the translations.');
          const translations = await translationsApi.downloadTranslations(crowdinConfig.projectId, result.data.id);

          const translationsFileBuffer = await getTranslationsZipFile(translations.data.url);
          const unzipper = require('unzipper');
          const unzippedDirectory = await unzipper.Open.buffer(translationsFileBuffer);
          await processTranslationFiles(unzippedDirectory);
          log('DONE DOWNLOADING TRANSLATIONS.');
          done();
          return;
        } else if(sStatus === 'canceled' || sStatus === 'failed') {
          done(new NoStackError(`FAILED TO BUILD TRANSLATIONS. STATUS = ${sStatus}`));
          return;
        } else {
          nRetryCount++;
          log(`Crowdin is currently building the project. Status = ${resultResult.data.status}`);
          log(`Will attempt to get the translations again in ${nRetryTiming} ms. ${nRetryCount} out of ${nMaxRetries} times.`);
          await new Promise(resolve => setTimeout(resolve, nRetryTiming));
        }
      }

      done(new NoStackError("FAILED TO BUILD TRANSLATIONS. Crowdin is busy creating a build. Please try again later."));

    } catch(error) {
      done(new NoStackError(`FAILED TO BUILD TRANSLATIONS: "${error}"`));
    }
  } else {
    log('COULD NOT DOWNLOAD TRANSLATIONS. MISSING CROWDIN TOKEN EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_KEY) OR COMMAND LINE PARAMETER');
    done();
  }
}


module.exports = {
  updateLocalTranslations,
  uploadTranslations,
  downloadTranslations
}