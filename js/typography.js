'use strict';
const fs = require('fs');
const log = require('fancy-log');
const glob = require('glob');


//  Find and replace the typography style associative arrays with the param/value pairs contained in the passed AA in the provided list of files.
//  @aaListOfStyles: Associative Array, the flat AA that contains the key/value combo of the styles: i.e. {"TYPOGRAPHY_headerLarge_TYPOGRAPHY": {fontSize: 86, fontSize: 900}}
//  @files: Array, An array of files that the function should look thru to find the style associative arrays
function findAndReplaceStylesInFiles(aaListOfStyles, files) {
  if (aaListOfStyles) {
    files.forEach(file => {
      let data = fs.readFileSync(file, 'utf-8');
      let originalData = data;
      Object.keys(aaListOfStyles).forEach(styleKey => {
        const styleValue =  aaListOfStyles[styleKey];

        data = findAndReplaceStringWithAAInData(styleKey, styleValue, data);
      });

      if (data !== originalData){
        //if the data has changed, then replace the file with the new data
        log(`Typography Associative Arrays have been changed in the file: ${file}`);
        fs.writeFileSync(file, data, 'utf-8');
      }

    });
  }
}


//  @findString: string, the string that will be searched for
//  @replacementAA: Associative Array, the AA that will be stringified and replace the findString parameter within the data string.
//  @data: string, The string to search thru to find the findString
//  return: string, return the altered or unaltered string if the style constant was found or not.
function findAndReplaceStringWithAAInData(findString, replacementAA, data) {
  const regExpFind = new RegExp(findString, "gi");
  if (!replacementAA){
    replacementAA = {}
  }
  let replacementString = JSON.stringify(replacementAA)
  data = data.replace(regExpFind, replacementString);
  return data;
}


// getTypographyThemeKeyValue()
// Recursively process a JSON Node to flatten it into an associative array of style key/value combos
// @sStyle: string, the current processed style key path: "header" or "headerLarge"
// @node: object, the JSON object that needs to be processed for styles
// @styleAA: Associative Array, The AA with the current style key/value combos
// returns: Associative Array, this is either the same AA as styleAA or it contains additional style key/value combos
function getTypographyThemeKeyValue(sStyle, node, styleAA){
  const sStyleConstantPrefix = `"TYPOGRAPHY_`;
  const sStyleConstantSuffix = `_TYPOGRAPHY"`;
  Object.entries(node).forEach(([styleName, styleNode]) => {
    if (styleName[0] !== `$`) {

      //get rid of "-" as that cannot be used in a constant name in the Roku app
      sStyle = sStyle.replace(/\-/gi, "");
      styleName = styleName.replace(/\-/gi, "");
      const sStyleNew = sStyle + styleName;

      if(styleNode.$value){
        //Add property to AA: i.e. fontWeight, lineHeight, fontSize'
        const sStyleValue = styleNode.$value;

        let styleId = sStyleConstantPrefix + sStyle + sStyleConstantSuffix;
        let aaStyle = styleAA[styleId];
        if (aaStyle == undefined) {
          aaStyle = {};
        }
        
        aaStyle[styleName] = sStyleValue;
        styleAA[styleId] = aaStyle;
      } else {
        styleAA = getTypographyThemeKeyValue(sStyleNew, styleNode, styleAA);
      }
    }

  });
  return styleAA;
}


// Within the roku code, there are associative arrays with ID that will dictate the font styles of the Roku app. 
// This function will replace populate these associative arrays with the styles within a JSON file.
// @dest: String, The relative path/destination where the files are located.
function replaceTypographyConstants(dest) {
  const relativeTypographyPath = `themes/typography.tokens.json`;
  const stylesTypography = require(`${process.cwd()}/${relativeTypographyPath}`);
  const files = glob.sync( `${dest}/components/lib/TypographyMixin.brs` );  //Only look at one file
  const styles = stylesTypography.typography.ott;
  let aaListOfStyles = {};
  
  log(`Replacing typography styles for filepath: ${dest}`);

  //parse the style theme JSON in a flat AA
  Object.entries(styles).forEach(([themeName, themeNode])  => {
    Object.entries(themeNode).forEach(([subThemeName, subThemeNode]) => {
      const sStyle = themeName + subThemeName;
      aaListOfStyles = getTypographyThemeKeyValue(sStyle, subThemeNode, aaListOfStyles);
    });
  });

  //Go thru all the files and find all references to the style associative arrays
  findAndReplaceStylesInFiles(aaListOfStyles, files);
}


module.exports = {
  replaceTypographyConstants
}