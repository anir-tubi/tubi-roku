'use strict';
const fs = require('fs');
const log = require('fancy-log');
const glob = require('glob');
const {fetchJSONFromGithub} = require('./network.js');
const {NoStackError, writeJSONToFile} = require('./utilities');
const sLocalRelativePath = 'themes/theme.json';


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
        log(`Color constants have been changed in the file: ${file}`);
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
  try {
    //The replacement string is a stringified json string of an array of gradient objects
    const aParsed = JSON.parse(replacementString);
    if (Array.isArray(aParsed)) {
      replacementString = JSON.stringify(aParsed);
    }
  } catch (e) {
    //The replacement string is a hexadecimal color string
  }
  const regExpFind = new RegExp(findString, "gi");
  data = data.replace(regExpFind, replacementString);
  log(`Replacing "${findString}" with the color string = ${replacementString}`);
  return data;
}


// getColorKeyValue()
// Recursively process a JSON Node to flatten it into an associative array of color key/value combos.
// In the case of a simple color string, the key/value combo may look like: "defaultDarkPrimaryAccent": "0X000000FF"
// In the case of a gradient, the key/value combo may look like: "defaultDarkGradientBrand": [{color: "0xFF0000FF", position: "0"}, {color: "0x000000FF", position: "1"}]
// @sColor: string, the current processed color key path: "default" or "defaultDark" or "defaultDarkPrimary" 
// @node: object, the JSON object that needs to be processed for colors
// @colorAA: Associative Array, The AA with the current color key/value combos
// returns: Associative Array, this is either the same AA as colorAA or it contains additional color key/value combos
function getColorKeyValue(sColor, node, colorAA){
  const sColorConstantPrefix = `THEME_`
  const sColorConstantSuffix = `_THEME`
  
  Object.entries(node).forEach(([colorName, colorNode]) => {
    if (colorName[0] !== `$`) {
      colorName = colorName.replace(/\-/gi, ""); //get rid of "-" as that cannot be used in a constant name in the Roku app
      const sColorNew = sColor + colorName;

      if(colorNode.$value){
        const sColorValue = colorNode.$value;
      
        let sKeyToBeReplaced = sColorConstantPrefix + sColorNew + sColorConstantSuffix
        if (typeof sColorValue === 'string' && sColorValue.length > 0) {

          //switch from using the "#" to "0x" to proceed color values, and ensure there is a transparency value at the end of the string
          const formattedColorValue = sColorValue.replace("#", "0x").padEnd(10, "FF");
          colorAA[sKeyToBeReplaced] = formattedColorValue;

        } else if (sColorValue.stops && Array.isArray(sColorValue.stops)){
          //This may be a gradient value
            
          const aGradientSource = sColorValue.stops;
          let aGradientNew = [];
          const length = aGradientSource.length;
          for(let i = 0; i < length; i++){
            const gradientObjectSource = aGradientSource[i];
            let gradientObjectNew = {};
            
            if (gradientObjectSource.position >= 0 && gradientObjectSource.color && gradientObjectSource.color.length > 0) {
              const formattedColorValue = gradientObjectSource.color.replace("#", "0x").padEnd(10, "FF");
              
              //Create new version of the gradient object with formatted color value
              gradientObjectNew = {
                color: formattedColorValue,
                position: gradientObjectSource.position
              };
              aGradientNew.push(gradientObjectNew);
            }
          }

          if (aGradientNew.length > 0) {
            const sGradientNew = JSON.stringify(aGradientNew)

            // Ensure to encapsulate the array index value (sKeyToBeReplaced) of colorAA with double quotes
            // when the value represents a gradient array. The BRS file, which contains the key 
            // to be replaced, expects a string value enclosed in quotes. Therefore, for non-string 
            // values (like arrays), remove these quotes from the BRS when performing the key-value substitution.

            // Example in context:
            // If replacing "THEME_defaultDarkStatusOnNow_THEME" in BRS:
            //   Original: "THEME_defaultDarkStatusOnNow_THEME"
            //   Replacement for a hex color: "0x2948FFFF"
            //   Replacement for an array: [{color: "0x2948FFFF", position:0}, {color: "0xA345DD00", position: 1}]
            sKeyToBeReplaced = '"' + sKeyToBeReplaced + '"'
            colorAA[sKeyToBeReplaced] = sGradientNew;
          }
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
  const themeColors = require(`${process.cwd()}/${sLocalRelativePath}`);
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


//This will update the locally stored color JSON file with the Design version stored on the web.
//The Design-authored JSON is located at: https://github.com/adRise/design-tokens/blob/main/src/tokens/themes.tokens.json
async function updateColorJSON(done) {
  const sDesignURL = 'https://raw.githubusercontent.com/adRise/design-tokens/main/src/tokens/themes.tokens.json';

  // Get the contents of the sDesignURL
  try {
    const designContent = await fetchJSONFromGithub(sDesignURL);
    if (designContent) {
      // Write the contents to the sLocalRelativePath
      writeJSONToFile(designContent, sLocalRelativePath);
      done();
    }
  } catch (error) {
    done(new NoStackError(`updateColorJSON(): An error occurred while fetching or writing the JSON file: ${error}`));
  }
}


module.exports = {
  replaceColorConstants,
  updateColorJSON
}