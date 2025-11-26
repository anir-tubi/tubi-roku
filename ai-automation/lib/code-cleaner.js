// @ts-check
const config = require('../config');

/**
 * Clean generated code from Claude (remove markdown, explanations, etc.)
 * @param {string} stdout - Raw output from Claude
 * @returns {string} Cleaned code
 */
function cleanGeneratedCode(stdout) {
  let cleanedOutput = stdout.trim();

  // Remove markdown code block wrappers
  cleanedOutput = cleanedOutput.replace(config.patterns.MARKDOWN_CODE_BLOCK, '');
  cleanedOutput = cleanedOutput.replace(config.patterns.CLOSING_CODE_BLOCK, '');
  cleanedOutput = cleanedOutput.trim();

  // Remove common explanation phrases that Claude adds before code
  const explanationPatterns = [
    /^.*?Here's the fixed code:\s*/is,
    /^.*?Here is the fixed code:\s*/is,
    /^.*?Here's the code:\s*/is,
    /^.*?Here is the code:\s*/is,
    /^.*?Fixed code:\s*/is,
  ];

  for (const pattern of explanationPatterns) {
    if (pattern.test(cleanedOutput)) {
      cleanedOutput = cleanedOutput.replace(pattern, '');
      console.log('ℹ️  ✅ Removed explanation phrase');
      break;
    }
  }

  // Remove any explanatory text before the first import statement
  const importMatch = cleanedOutput.match(/^.*?(import\s+(?:\{|type|[\*\w]))/ms);
  if (importMatch && importMatch.index > 0) {
    cleanedOutput = cleanedOutput.substring(importMatch.index);
    console.log('ℹ️  ✅ Removed explanatory text before imports');
  }

  // Additional cleanup: Remove any remaining text before the first valid import line
  const lines = cleanedOutput.split('\n');
  const firstImportLineIndex = lines.findIndex(line => /^import\s+(?:\{|type|\*|[\w])/.test(line.trim()));
  if (firstImportLineIndex > 0) {
    cleanedOutput = lines.slice(firstImportLineIndex).join('\n');
    console.log('ℹ️  ✅ Removed additional explanatory text before imports');
  }

  // Remove any this.timeout() lines
  cleanedOutput = cleanedOutput.replace(/\s*this\.timeout\(\d+\);\s*/g, '');

  return cleanedOutput;
}

/**
 * Add .only to a specific test case by ID, or to the last test if no ID provided
 * @param {string} code - The test file code
 * @param {string|null} testCaseId - Optional test case ID (e.g., "C535817")
 * @returns {string} Code with .only added to the correct test
 */
function addOnlyToSpecificTest(code, testCaseId = null) {
  if (code.includes('it.only(')) {
    // .only already exists, no need to add
    return code;
  }

  // If testCaseId is provided, find and add .only to that specific test
  if (testCaseId) {
    // Normalize testCaseId (ensure it has C prefix)
    const normalizedId = testCaseId.startsWith('C') ? testCaseId : 'C' + testCaseId;

    // Look for the test with this ID in the it() description
    const testPattern = new RegExp(`(\\s+it)\\(['"](${normalizedId}[^'"]*?)['"]`, 'g');
    const match = testPattern.exec(code);

    if (match) {
      // Found the test with this ID, add .only to it
      const result = code.replace(testPattern, '$1.only(\'$2\'');
      console.log(`ℹ️  ✅ Added .only to test ${normalizedId}`);
      return result;
    } else {
      console.log(`⚠️  Could not find test with ID ${normalizedId}, adding .only to last test`);
    }
  }

  // Fallback: Add .only to the last it() test (most likely the newly added one)
  const itBlocks = code.match(/(\s+it)\([^)]+\)/g);
  if (itBlocks && itBlocks.length > 0) {
    const lastItBlock = itBlocks[itBlocks.length - 1];
    const lastItBlockWithOnly = lastItBlock.replace(/(\s+it)\(/, '$1.only(');
    const lastIndex = code.lastIndexOf(lastItBlock);
    const result = code.substring(0, lastIndex) + lastItBlockWithOnly + code.substring(lastIndex + lastItBlock.length);
    console.log('ℹ️  ✅ Added .only to last test');
    return result;
  }

  console.log('⚠️  Could not add .only - no it() blocks found');
  return code;
}

/**
 * Validate test details have required fields
 * @param {Object} testDetails
 * @throws {Error} if validation fails
 */
function validateTestDetails(testDetails) {
  const required = ['testCaseId', 'testName', 'mainSection'];
  const missing = required.filter(field => !testDetails[field]);

  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`);
  }
}

module.exports = {
  cleanGeneratedCode,
  addOnlyToSpecificTest,
  validateTestDetails
};
