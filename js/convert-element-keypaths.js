// Temporary script to convert over keypaths from json to ts file. Will be removed after we remove the json version of elements after any existing branches are converted over to the element.ts file
const fs = require('fs');
const elementsJson = require('../automated-tests-config/element-keypaths.json');

const filePath = 'automated-tests-config/elements.ts';

let elementsFileContents = '';

for (const key in elementsJson) {
  const element = elementsJson[key];
  if (element.description) {
    elementsFileContents += `
  /** ${element.description} */`;
  }
  elementsFileContents += `
  ${key}: {
    keyPath: '${element.keyPath}',`;

  if (element.xpath) {
    elementsFileContents += `
    xpath: '${element.xpath}',`;
  }
  elementsFileContents += `
  },\n`;
}

let fileContents = fs.readFileSync(filePath, 'utf8');
const startInjectString = '// START ELEMENTS INJECT';
const endInjectString = '// END ELEMENTS INJECT';

// Now we inject our elementsFileContents at the right spot
const r = new RegExp(`${startInjectString}.*${endInjectString}`, 'gms');
fileContents = fileContents.replace(r, `${startInjectString}\n${elementsFileContents}\n${endInjectString}`);

fs.writeFileSync(filePath, fileContents);
