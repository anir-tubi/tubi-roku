// @ts-check
const fs = require('fs');
const path = require('path');
const config = require('../config');
const logger = require('./logger');
const { parseDescribeBlocks, findItBlocks, calculateBytePosition } = require('./ast-utils');

/**
 * Extract the it() block from generated test code
 * @param {string} generatedTest - Full generated test code
 * @returns {{testCase: string, success: boolean, error?: string}}
 */
function extractItBlock(generatedTest) {
  const generatedLines = generatedTest.split('\n');

  // Find the first it() line
  let itStartLine = -1;
  for (let i = 0; i < generatedLines.length; i++) {
    if (generatedLines[i].trim().match(config.patterns.IT_BLOCK_START)) {
      itStartLine = i;
      break;
    }
  }

  if (itStartLine === -1) {
    return {
      success: false,
      error: 'Could not find it() block in generated test',
      testCase: ''
    };
  }

  // Extract from it() to its closing }); using brace counting
  let braceCount = 0;
  let foundOpeningBrace = false;
  let itEndLine = -1;

  for (let i = itStartLine; i < generatedLines.length; i++) {
    const line = generatedLines[i];

    // Count braces
    for (const char of line) {
      if (char === '{') {
        braceCount++;
        foundOpeningBrace = true;
      }
      if (char === '}') braceCount--;
    }

    // Check if this line closes the it() block
    if (foundOpeningBrace && braceCount === 0 && line.trim().match(config.patterns.CLOSING_BRACE)) {
      itEndLine = i;
      break;
    }
  }

  if (itEndLine === -1) {
    return {
      success: false,
      error: 'Could not find closing of it() block',
      testCase: ''
    };
  }

  // Extract just the it() block (include any comment lines immediately before it)
  let extractStartLine = itStartLine;

  // Check if there's a comment line (Test Rail Link) immediately before the it()
  if (itStartLine > 0 && generatedLines[itStartLine - 1].trim().startsWith('//')) {
    extractStartLine = itStartLine - 1;
  }

  const itBlockLines = generatedLines.slice(extractStartLine, itEndLine + 1);
  const testCase = itBlockLines.join('\n');

  logger.extraction(
    itBlockLines.length,
    itBlockLines[0].trim(),
    itBlockLines[itBlockLines.length - 1].trim()
  );

  return {
    success: true,
    testCase
  };
}

/**
 * Select target describe block based on test context
 * @param {Array} describeBlocks
 * @param {Object} testDetails
 * @returns {Object|null}
 */
function selectTargetDescribe(describeBlocks, testDetails) {
  let targetDescribe = null;

  const testStepsLower = (testDetails.testSteps || '').toLowerCase();
  const mainSectionLower = (testDetails.mainSection || '').toLowerCase();
  const subSectionLower = (testDetails.subSection || '').toLowerCase();

  logger.search(`Looking for describe matching: mainSection="${testDetails.mainSection}", subSection="${testDetails.subSection}"`);

  // Match patterns like "Movie Details Page", "Series Details Page", etc.
  for (const describe of describeBlocks) {
    const describeNameLower = describe.name.toLowerCase();

    // Prioritize more specific (deeper nested) describe blocks
    if (subSectionLower && describeNameLower.includes(subSectionLower.toLowerCase())) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        logger.checkmark(`Matched by subSection: "${describe.name}"`);
      }
    } else if (describeNameLower.includes('movie') && (testStepsLower.includes('movie') || mainSectionLower.includes('movie'))) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        logger.checkmark(`Matched by "movie" keyword: "${describe.name}"`);
      }
    } else if (describeNameLower.includes('series') && (testStepsLower.includes('series') || mainSectionLower.includes('series'))) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        logger.checkmark(`Matched by "series" keyword: "${describe.name}"`);
      }
    } else if (describeNameLower.includes(mainSectionLower) && mainSectionLower !== '') {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        logger.checkmark(`Matched by mainSection: "${describe.name}"`);
      }
    }
  }

  // If no specific match, use the deepest nested describe block (most specific)
  if (!targetDescribe) {
    const sortedByLevel = [...describeBlocks].sort((a, b) => b.level - a.level);
    targetDescribe = sortedByLevel[0];
    logger.info(`No specific describe block matched, using deepest: "${targetDescribe.name}"`);
  } else {
    logger.success(`Matched describe block: "${targetDescribe.name}" (lines ${targetDescribe.startLine + 1}-${targetDescribe.endLine + 1})`);
  }

  return targetDescribe;
}

/**
 * Find correct position to insert test in existing file
 * @param {string} fileContent
 * @param {Object} testDetails
 * @returns {number} Position to insert, or -1 if failed
 */
function findCorrectInsertPosition(fileContent, testDetails) {
  const lines = fileContent.split('\n');

  // Parse describe blocks
  const { describeBlocks, unclosedDescribes } = parseDescribeBlocks(
    fileContent,
    config.patterns.DESCRIBE_DECLARATION
  );

  if (describeBlocks.length === 0) {
    logger.warning('No describe blocks found in file');
    return -1;
  }

  logger.info(`Found ${describeBlocks.length} describe blocks: ${describeBlocks.map(d => `"${d.name}" (lines ${d.startLine + 1}-${d.endLine + 1})`).join(', ')}`);

  // Sanity check for unclosed describe blocks
  if (unclosedDescribes.length > 0) {
    logger.warning(`Found ${unclosedDescribes.length} unclosed describe block(s): ${unclosedDescribes.map(d => d.name).join(', ')}`);
    logger.warning('The file structure may be corrupted. Consider fixing it manually before adding new tests.');
  }

  // Select target describe block
  const targetDescribe = selectTargetDescribe(describeBlocks, testDetails);
  if (!targetDescribe) {
    return -1;
  }

  // Find it() blocks within target describe
  const itBlocks = findItBlocks(
    lines,
    targetDescribe.startLine,
    targetDescribe.endLine,
    config.patterns.IT_BLOCK_START
  );

  if (itBlocks.length > 0) {
    const lastIt = itBlocks[itBlocks.length - 1];
    logger.debug(`Found it() blocks: ${itBlocks.length}, last one ends at line ${lastIt.endLine + 1}`);

    const insertPos = calculateBytePosition(lines, lastIt.endLine);
    logger.success(`Will insert after line ${lastIt.endLine + 1} in "${targetDescribe.name}"`);
    return insertPos;
  } else {
    logger.info(`No it() blocks found in "${targetDescribe.name}", inserting before closing brace at line ${targetDescribe.endLine + 1}`);
    const insertPos = calculateBytePosition(lines, targetDescribe.endLine - 1);
    return insertPos;
  }
}

/**
 * Determine filename from test section
 * @param {Object} testDetails
 * @returns {string}
 */
function determineFileName(testDetails) {
  let sectionName;

  if (testDetails.subSection && testDetails.subSection.includes('›')) {
    // Get the last part after the last ›
    const parts = testDetails.subSection.split('›');
    sectionName = parts[parts.length - 1].trim();
  } else if (testDetails.subSection) {
    sectionName = testDetails.subSection;
  } else {
    // Fallback to mainSection
    sectionName = testDetails.mainSection || testDetails.testName;
  }

  return sectionName
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '-');
}

/**
 * Save test to file (create new or append to existing)
 * @param {string} generatedTest
 * @param {Object} testDetails
 * @returns {string} File path
 */
function saveTest(generatedTest, testDetails) {
  const fileName = determineFileName(testDetails);
  const filePath = path.join(config.paths.projectRoot, config.paths.testsDir, `${fileName}.ts`);

  // Ensure directory exists
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  // Check if file already exists
  if (fs.existsSync(filePath)) {
    logger.info(`File exists: ${fileName}.ts - appending new test case`);

    const existingContent = fs.readFileSync(filePath, 'utf8');
    const extraction = extractItBlock(generatedTest);

    if (!extraction.success) {
      logger.warning(`${extraction.error}. Creating new file instead.`);
      fs.writeFileSync(filePath, generatedTest);
      return filePath;
    }

    let newTestCase = extraction.testCase;

    // Add .only to the test case so it can be run in isolation
    newTestCase = newTestCase.replace(/(\s+it)\(/, '$1.only(');
    logger.success('Added .only to new test case for isolated execution');

    // Find the correct describe block to insert the test
    const insertPosition = findCorrectInsertPosition(existingContent, testDetails);

    if (insertPosition === -1) {
      logger.warning('Could not find appropriate describe block in existing file. Creating new file instead.');
      fs.writeFileSync(filePath, generatedTest);
    } else {
      // Insert new test case
      const updatedContent =
        existingContent.substring(0, insertPosition) +
        '\n  ' + newTestCase + '\n' +
        existingContent.substring(insertPosition);

      fs.writeFileSync(filePath, updatedContent);
      logger.success('Added new test case to existing file with .only');
    }
  } else {
    logger.info(`Creating new file: ${fileName}.ts`);
    fs.writeFileSync(filePath, generatedTest);
  }

  logger.file(`Test saved: ${filePath}`);
  return filePath;
}

module.exports = {
  extractItBlock,
  findCorrectInsertPosition,
  saveTest,
  determineFileName
};
