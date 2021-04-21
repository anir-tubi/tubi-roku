const fs = require('fs');
const FormData = require('form-data');
const unzipper = require('unzipper');
const path = require('path');
const https = require('https');
const log = require('fancy-log');
/* Allow the crowdinKey to be driven from an environment variable or thru command line param.
   Environment variables are set on options, along with any parameters passed in
   to the gulp command line call.
*/
const crowdinConfig = {
  "crowdinKey": (process.env.ROKU_CROWDIN_KEY || ''),
  "crowdinBasePath": "/api/project/tubiapps",
  "crowdinApiBasePath": "api.crowdin.com",
  "crowdinBaseDirectory": "roku"  
}

const _sLocalTranslationFilename = "translations/en-US.json";
const _sLocalTranslationFilePath = `${process.cwd()}/${_sLocalTranslationFilename}`

// fetch command line arguments and replace params in crowdinConfig. Right now it just replaces the "crowdinKey"
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

  if(arg["crowdinKey"] !== undefined){
    crowdinConfig["crowdinKey"] = arg["crowdinKey"]
  }
})(process.argv);

const crowdin_addFilePath = `${crowdinConfig.crowdinBasePath}/add-file?json=1&key=${crowdinConfig.crowdinKey}`;
const crowdin_updateFilePath = `${crowdinConfig.crowdinBasePath}/update-file?update_option=update_as_unapproved&json=1&key=${crowdinConfig.crowdinKey}`;


//Tell Crowdin to zip the translation files. getTranslationsZipFile() will be called to download this zip file.
async function triggerCrowdinBuild() {
  const options = {
    hostname: crowdinConfig.crowdinApiBasePath,
    method: 'GET',
    path: `${crowdinConfig.crowdinBasePath}/export?key=${crowdinConfig.crowdinKey}&json=1`,
  };
  const response = await makeGetRequest(options);
  const parsedResponse = JSON.parse(response);
  return parsedResponse;
}


//Get the already created zip file of the locale translation files from crowdin server
async function getTranslationsZipFile() {
  const options = {
    hostname: crowdinConfig.crowdinApiBasePath,
    method: 'GET',
    path: `${crowdinConfig.crowdinBasePath}/download/all.zip?key=${crowdinConfig.crowdinKey}&json=1'`
  };
  return await makeGetRequest(options);
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
        destinationPath = unZippedFilePath.substring(nDestinationPathIndex);
        destinationPath = path.resolve(destinationPath);

        //Remove '.json' from the file path to get the locale ID
        sLocale = unZippedFilePath.slice(unZippedFilePath.lastIndexOf('/') + 1, -5);

        console.log('Attempting to write downloaded crowdin translation to: ', destinationPath);
        fs.accessSync(destinationPath.substring(0, destinationPath.lastIndexOf('/')), fs.constants.F_OK);
        fileBuffer = await file.buffer();

        // temporarily write the translation json to file
        await writeToFile(destinationPath, fileBuffer);

        if (destinationPath !== '') {
          // read contents of temporarily written json file
          var localeData = fs.readFileSync(destinationPath, 'utf-8');

          // write the contents of the translation json to the appropriate function
          // in the TubiLanguageTranslate.brs file
          writeLocaleDataToBRS_sync(sLocale, localeData);

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
    writeStream = fs.createWriteStream(destinationPath);
    writeStream.write(bufferOrString);
    writeStream.on('finish', () => {
      console.log(destinationPath, 'successfully written to.');
      resolve();
    });
    writeStream.on('error', (err) => {
      console.log('Could not write to: ', destinationPath);
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
      console.log(`Could not find ${sLocale} locale function. Appending it to the end of the BRS file: '${fileTranslationCode}'`);
      newValue = `${data}\n\n\n${sNewString}`;
    }

    fs.writeFileSync(fileTranslationCode, newValue, 'utf-8');
  }
}



//helper function to upload file to crowdin
async function updateFilesRequest(filePath, transformedPath) {
  const filePathKey = `files[${transformedPath}]`;
  const exportPatternsKey = `export_patterns[${transformedPath}]`;

  const formDataObj = new FormData();
  formDataObj.append(filePathKey, fs.createReadStream(filePath));
  formDataObj.append(exportPatternsKey, '%locale%.json');

  const options = {
    hostname: crowdinConfig.crowdinApiBasePath,
    method: 'POST',
    path: crowdin_updateFilePath,
    headers: formDataObj.getHeaders(),
  };
  
  const response = await makePostRequest(options, formDataObj);
  return response;
}



//helper function to make a request to crowdin server
function makePostRequest(options, formData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (resp) => {
      let data = '';
      resp.on('data', (chunk) => {
        data += chunk;
      });

      resp.on('end', () => {
        resolve(JSON.parse(data));
      });
    }).on('error', (err) => {
      reject(err);
    });

    formData.pipe(req);
  });
}


//helper function to make a request to crowdin server
function makeGetRequest(options) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (resp) => {
      if (resp.statusCode >= 300) {
        const url = `${resp.socket.servername}${resp.req.path}`
        const method = resp.socket["_httpMessage"].method
        const errorMessage = `Received ${resp.statusCode} while attempting a ${method} request to ${url}`
        err = new Error(errorMessage);
        reject(err);
      } else {
        let data = [];
        resp.on('data', (chunk) => {
          data.push(chunk);
        });

        resp.on('end', () => {
          buff = Buffer.concat(data)
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
exports.updateLocalTranslations = function(done) {
  //update the BRS file with the American English file before uploading to Crowdin
  log("Updating the BRS file with the latest version found in: ", _sLocalTranslationFilePath)
  const localeData = fs.readFileSync(_sLocalTranslationFilePath, 'utf-8');
  writeLocaleDataToBRS_sync("en-US", localeData);

  log('');
  log('FINISHED UPDATING THE ENGLISH STRINGS IN THE BRS FILE WITH THE LOCAL ENGLISH TRANSLATION FILE');
  
  done();  //inform gulp that the task has completed.
}

//upload the latest version of the US English locale file to crowdin
exports.uploadTranslations = async function() {
  if(crowdinConfig.crowdinKey !== undefined && crowdinConfig.crowdinKey !== ""){
    const crowdinPath = `${crowdinConfig.crowdinBaseDirectory}/${_sLocalTranslationFilename}`;
    const updateFileResponse = await updateFilesRequest(_sLocalTranslationFilePath, crowdinPath);
    if (updateFileResponse.success) {
      console.log('\nSUCCESS! FINISHED UPLOADING THE TRANSLATION FILE TO CROWDIN');
    } else {
      console.log('\nERROR UPLOADING THE TRANSLATION FILE TO CROWDIN \n', updateFileResponse.error)
    }
  } else {
    console.log('MISSING CROWDIN KEY EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_KEY) OR COMMAND LINE PARAMETER');
  }
}


//Main function that initiates the download of any locale translation files from crowdlin
exports.downloadTranslations = async function() {
  if(crowdinConfig.crowdinKey !== undefined && crowdinConfig.crowdinKey !== ""){
    console.log('START DOWNLOADING TRANSLATIONS FROM CROWDIN');
    const buildResponse = await triggerCrowdinBuild();
    if (buildResponse.success) {
      const translationsFileBuffer = await getTranslationsZipFile();

      const unzippedDirectory = await unzipper.Open.buffer(translationsFileBuffer);
      await processTranslationFiles(unzippedDirectory);
    } else {
      console.log('Failed to build translations', buildResponse.error);
    }
    console.log('\nFINISHED DOWNLOAD TRANSLATIONS FROM CROWDIN');
  } else {
    console.log('COULD NOT DOWNLOAD TRANSLATIONS. MISSING CROWDIN KEY EITHER IN ENVIRONMENT VARIABLE (ROKU_CROWDIN_KEY) OR COMMAND LINE PARAMETER');
  }
}
