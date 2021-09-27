'use strict';
const fs = require('fs');
const log = require('fancy-log');
const glob = require('glob');
const path = require('path');


function listUnusedImages(done) {
    const globOptions = {
        root: path.resolve(process.cwd(), 'src/channel'),
        nomount: true
    };
    const images = glob.sync('/images/**/*.*', globOptions);
    const files = glob.sync('{src/channel/{components,source}/**/*.*,config/*.yml}', {ignore: ['src/channel/source/tests/**/*.*'] });

    log('====================================================')
    log('LIST OF UNUSED IMAGES:')
    log('These are the potential list of unused images. Please make sure they are indeed not used and then delete it.')
    log('====================================================')
    const imageSet = new Set(images)
    imageSet.forEach(image => {
        if (!searchforStringInFiles(image, files)){
            log(image);
        }
    });
    log('====================================================')
    done();
};


// @stringName: string, the string that will be searched for
// @files: array, each item in the array is the file path
// returns: boolean, true if the string exists in at least one of the files,
//                   false if the string exists in none of the files
function searchforStringInFiles(stringName, files) {
    return files.some(file => {
        const match = fs.readFileSync(file, 'UTF8').indexOf(stringName);
        return match !== -1;
    });
}


function listUnusedTranslations(done) {
    const _sLocalTranslationFilename = "translations/en-US.json";
    const _sLocalTranslationFilePath = `${process.cwd()}/${_sLocalTranslationFilename}`
    const translations = JSON.parse(fs.readFileSync(_sLocalTranslationFilePath))
    const files = glob.sync('src/channel/{components,source}/**/*.*', {ignore: ['src/channel/source/lib/TubiLanguageTranslate.brs','src/channel/source/tests/**/*.*'] } );
   
    log('====================================================')
    log('LIST OF UNUSED TRANSLATIONS :')
    log('These are the potential list of unused translations. Please make sure they are indeed not used and then delete the scripts from all languages that are not being used.');
    log('====================================================') 
    Object.keys(translations).forEach(tr => {
        if (!searchforStringInFiles(tr, files)){
            log(tr);
        }
    });
    log('====================================================')
    done();
};

module.exports = {
    listUnusedImages,
    listUnusedTranslations
}