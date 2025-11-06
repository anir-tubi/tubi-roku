// @ts-check
const fs = require('fs');
const path = require('path');
const config = require('../config');

/**
 * Normalize test case ID to ensure it has 'C' prefix
 * @param {string} testCaseId
 * @returns {string}
 */
function normalizeTestCaseId(testCaseId) {
  if (!testCaseId) return '';
  return testCaseId.startsWith('C') ? testCaseId : 'C' + testCaseId;
}

/**
 * Build prompt for AI test generation
 * @param {Object} testDetails
 * @returns {string}
 */
function buildPrompt(testDetails) {
  const instructionsPath = path.join(config.paths.projectRoot, config.paths.claudeInstructions);
  let instructions = '';

  if (fs.existsSync(instructionsPath)) {
    instructions = fs.readFileSync(instructionsPath, 'utf8');
  }

  const normalizedTestCaseId = normalizeTestCaseId(testDetails.testCaseId);

  return `You are a code generator for Roku Tubi app tests.

TEST REQUIREMENTS:
- Test Case ID: ${normalizedTestCaseId}
- Name: ${testDetails.testName}
- Section: ${testDetails.mainSection}
- User Type: ${testDetails.userType}
- Steps: ${testDetails.testSteps}

INSTRUCTIONS:
${instructions}

OUTPUT FORMAT:
- Return ONLY TypeScript code (no markdown, no explanations, no code blocks)
- Single complete test file ready to save
- Start directly with import statements (no explanatory text before imports)
- Only import modules that are actually used in the code
- IMPORTANT: Use the exact Test Case ID "${normalizedTestCaseId}" in both the comment and the it() block
  Example:
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/${normalizedTestCaseId.replace('C', '')}
    it('${normalizedTestCaseId} - Test Name @tags', async () => {

NOW: Generate the test code following the instructions above.`;
}

/**
 * Build prompt for fixing lint/type errors
 * @param {string} fileContent
 * @param {Object} lintResult
 * @param {string} instructions
 * @returns {string}
 */
function buildLintFixPrompt(fileContent, lintResult, instructions) {
  return `Fix the following ${lintResult.type} errors in this test file:

ERRORS:
${lintResult.errors}

CURRENT FILE CONTENT:
${fileContent}

INSTRUCTIONS:
${instructions}

Return ONLY the complete fixed TypeScript code (no markdown, no explanations).`;
}

/**
 * Build prompt for fixing test errors
 * @param {Object} params
 * @returns {string}
 */
function buildTestFixPrompt({
  fileContent,
  errorOutput,
  errorCategory,
  failingTestName,
  attempt,
  instructions,
  learnedFix
}) {
  let promptContent = `You are fixing a failing Roku test. Analyze the error and fix the test code.

ATTEMPT ${attempt}/3

ERROR TYPE: ${errorCategory.type}
ERROR DESCRIPTION: ${errorCategory.description}
FAILING TEST: ${failingTestName}

ERROR OUTPUT (last 1500 chars):
${errorOutput.slice(-1500)}

CURRENT TEST FILE:
${fileContent}

PROJECT INSTRUCTIONS:
${instructions}
`;

  // Add learned fixes context if available
  if (learnedFix && learnedFix.found) {
    promptContent += `\n\nLEARNED FIXES FOR ${errorCategory.type}:
Review these past solutions for similar errors:
${learnedFix.content}

Apply similar patterns from learned fixes above.
`;
  }

  // Add specific fix guidance based on error type
  const fixGuidance = getFixGuidanceForErrorType(errorCategory.type);
  if (fixGuidance) {
    promptContent += `\n\n${fixGuidance}`;
  }

  promptContent += `\n\nOUTPUT FORMAT:
- Return ONLY the complete fixed TypeScript test file
- No markdown code blocks, no explanations, no comments about changes
- Just the raw TypeScript code ready to save
- Keep all other tests unchanged, only fix the failing one

NOW: Analyze the error and return the fixed test code.`;

  return promptContent;
}

/**
 * Get fix guidance for specific error type
 * @param {string} errorType
 * @returns {string}
 */
function getFixGuidanceForErrorType(errorType) {
  const guidance = {
    EMPTY_STRING: `FIX GUIDANCE:
- Add retryWithTimeOut() before assertions to wait for field to populate
- Example: await testUtils.retryWithTimeOut(async () => { const element = await testUtils.getNodeForElement('name'); expect(element.text).to.equal('expected'); });
- Never assert immediately after getting an element`,

    VISIBILITY: `FIX GUIDANCE:
- Add wait for element visibility before assertions
- Example: await testUtils.retryWithTimeOut(async () => { const element = await testUtils.getNodeForElement('name'); expect(element.visible).to.equal(true); });
- Ensure screen is fully loaded before checking visibility`,

    UNDEFINED: `FIX GUIDANCE:
- Add wait for element or property to exist
- Check if element needs to be loaded first (e.g., waitForGridContentToLoad)
- Use retryWithTimeOut to wait for property to be defined`,

    TIMEOUT: `FIX GUIDANCE:
- Check if prerequisites are met (correct screen, element loaded, etc.)
- Increase timeout if operation legitimately takes longer
- Verify the wait condition is correct
- Ensure proper navigation before waiting`,

    FOCUS: `FIX GUIDANCE:
- Use waitForElementToHaveFocus() before focus assertions
- Verify element is in the focus chain
- Check if navigation completed before focus check`,

    GRID_CONTENT: `FIX GUIDANCE:
- Use waitForGridContentToLoad() before accessing grid items
- Ensure rowList or grid is focused and loaded
- Wait for content field to populate`,

    PLAYER_STATE: `FIX GUIDANCE:
- Use waitForPlayerStateToEqual() to wait for specific player states
- Add waits after playback commands (play, pause)
- Check player state before assertions`
  };

  return guidance[errorType] || '';
}

module.exports = {
  normalizeTestCaseId,
  buildPrompt,
  buildLintFixPrompt,
  buildTestFixPrompt
};
