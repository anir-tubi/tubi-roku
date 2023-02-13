'use strict';
const fs = require('fs');
const log = require('fancy-log');
const glob = require('glob');


//  Find and replace the color constants with the hexadecimal values contained in the passed AA in the provided list of files.
//  @aaListOfColors: Associative Array, the flat AA that contains the key/value combo of the colors: i.e. {"THEME_defaultDarkPrimaryAccent": "0xE13100FF"}
//  @files: string, The List of files that the function should look thru to find the color constants
function findAndReplaceColorConstantsInFiles(aaListOfColors, files) {
  if (aaListOfColors) {
    files.forEach(file => {
      var data = fs.readFileSync(file, 'utf-8');
      var originalData = data;

      Object.keys(aaListOfColors).forEach(colorKey => {
        const colorValue =  aaListOfColors[colorKey];
        data = findAndReplaceForStringInData(colorKey, colorValue, data);
      });

      if (data !== originalData){
        //if the data has changed, then replace the file with the new data
        log(`Color constants have been changed in the file: $(file}`);
        fs.writeFileSync(file, data, 'utf-8');
      }

    });
  }
}


//  @findString: string, the string that will be searched for
//  @replacementString: string, the string that should replace the findString
//  @data: string, The string to search thru to find the findString
//  return: string, return the altered or unaltered string if the color constant was found or not.
function findAndReplaceForStringInData(findString, replacementString, data) {
  const regExpFind = new RegExp(findString, "gi");
  data = data.replace(regExpFind, replacementString);
  log(`Replacing "${findString}" with the color string = ${replacementString}`);
  return data;
}


// getColorKeyValue()
// Recursively process a JSON Node to flatten it into an associative array of color key/value combos
// @sColor: string, the current processed color key path: "default" or "defaultDark" or "defaultDarkPrimary" 
// @node: object, the JSON object that needs to be processed for colors
// @colorAA: Associative Array, The AA with the current color key/value combos
// returns: Associative Array, this is either the same AA as colorAA or it contains additional color key/value combos
function getColorKeyValue(sColor, node, colorAA){
  const sColorConstantPrefix = `THEME_`
  Object.entries(node).forEach(([colorName, colorNode]) => {
    if (colorName[0] !== `$`) {
      colorName = colorName.replace(/\-/gi, ""); //get rid of "-" as that cannot be used in a constant name in the Roku app
      const sColorNew = sColor + colorName;

      if(colorNode.$value){
        const sColorValue = colorNode.$value;

        if (sColorValue && sColorValue.length > 0) {

          //switch from using the "#" to "0x" to proceed color values, and ensure there is a transparency value at the end of the string
          const formattedColorValue = sColorValue.replace("#", "0x").padEnd(10, "FF");
          colorAA[sColorConstantPrefix + sColorNew] = formattedColorValue;
        }        
      } else {
        colorAA = getColorKeyValue(sColorNew, colorNode, colorAA);
      }
    }

  });
  return colorAA;
}


// Throughout the code, color enums are used instead of actual color hexadecimal strings. Replace the colors constants with the 
// hexadecimal color codes using the color pallette file
// @dest: String, The relative path/destination where the files are located.
function replaceColorConstants(dest) {    
  const themeFilename = `themes/theme.json`;
  const themeColors = require(`${process.cwd()}/${themeFilename}`);
  const files = glob.sync( `${dest}/source/Constants.brs` );  //Only look at one file
  const themes = themeColors.themes;
  let aaListOfColors = {};
  
  log(`Replacing theme colors for filepath: ${dest}`);

  //parse the color theme JSON in a flat AA
  Object.entries(themes).forEach(([themeName, themeNode])  => {
    Object.entries(themeNode).forEach(([subThemeName, subThemeNode]) => {
      const sColor = themeName + subThemeName;
      if (subThemeNode.tokens && subThemeNode.tokens.colors){
        aaListOfColors = getColorKeyValue(sColor, subThemeNode.tokens.colors, aaListOfColors);
      }
    });
  });

  //Go thru all the files and find all references to any color constants
  findAndReplaceColorConstantsInFiles(aaListOfColors, files);
}


module.exports = {
  replaceColorConstants
}