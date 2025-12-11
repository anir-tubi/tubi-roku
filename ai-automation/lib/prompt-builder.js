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
 * @param {Array<string>} existingTestIds - List of existing test case IDs to avoid
 * @param {string} wrongIdFromPreviousAttempt - ID that AI used incorrectly in previous attempt
 * @returns {string}
 */
function buildPrompt(testDetails, existingTestIds = [], wrongIdFromPreviousAttempt = null) {
  const instructionsPath = path.join(config.paths.projectRoot, config.paths.claudeInstructions);
  let instructions = '';

  if (fs.existsSync(instructionsPath)) {
    instructions = fs.readFileSync(instructionsPath, 'utf8');
  }

  const normalizedTestCaseId = normalizeTestCaseId(testDetails.testCaseId);
  const hasPreConditions = testDetails.preConditions && testDetails.preConditions !== 'No pre-conditions specified';

  // Build list of forbidden IDs (show first 20 as examples)
  const forbiddenIdsPreview = existingTestIds.slice(0, 20).join(', ');
  const totalExistingTests = existingTestIds.length;

  // If this is a retry, add explicit correction feedback AT THE VERY TOP
  let retryFeedback = '';
  if (wrongIdFromPreviousAttempt) {
    retryFeedback = `
🚨 CRITICAL ERROR IN PREVIOUS ATTEMPT 🚨

YOU USED THE WRONG TEST CASE ID: ${wrongIdFromPreviousAttempt}
The CORRECT test case ID is: ${normalizedTestCaseId}

DO NOT REPEAT THIS MISTAKE!
You MUST use: ${normalizedTestCaseId}

`;
  }

  return `${retryFeedback}You are a code generator for Roku Tubi app tests.

🚨 **CRITICAL - TEST CASE ID YOU MUST USE** 🚨

THE ONLY TEST CASE ID YOU ARE ALLOWED TO USE IS: ${normalizedTestCaseId}

TEST REQUIREMENTS:
- Test Case ID: ${normalizedTestCaseId} ← THIS IS THE ONLY CORRECT ID!
- Name: ${testDetails.testName}
- Section: ${testDetails.mainSection}
- User Type: ${testDetails.userType}${hasPreConditions ? `\n- Pre-conditions: ${testDetails.preConditions}` : ''}
- Steps: ${testDetails.testSteps}

⛔ FORBIDDEN TEST IDs (${totalExistingTests} tests already exist):
${forbiddenIdsPreview}${totalExistingTests > 20 ? `... and ${totalExistingTests - 20} more` : ''}

🚨 **CRITICAL RULES:**
1. ✅ USE ONLY: ${normalizedTestCaseId}
2. ❌ NEVER copy test case IDs from existing tests
3. ❌ NEVER generate multiple tests - ONLY ONE it() block
4. ✅ Learn code patterns from existing tests, but generate NEW test with ${normalizedTestCaseId}
5. ✅ Read test-helpers.ts and test-utils.ts to find existing helpers (DO NOT write custom logic if helper exists)
6. ❌ NEVER use findNode() or property chaining (node.child?.grandchild) - add nested elements to elements.ts instead
7. ✅ Follow the 5-STEP PROCESS documented in instructions.md
8. ✅ Refer to node_modules/roku-test-automation/README.md for roku-test-automation framework patterns (ArrayGrid/RowList element access, odc.getValue() syntax, grid navigation)
9. ✅ Use startApplicationAtPage('home') for general tests - ONLY use 'movies', 'series', etc. if test specifically requires that mode

🚨 **BEFORE RETURNING CODE - FINAL VERIFICATION:**
1. Does the it() block contain "${normalizedTestCaseId}"? If NO → FIX IT
2. Does the TestRail link contain "${normalizedTestCaseId.replace('C', '')}"? If NO → FIX IT
3. Did you use any forbidden test IDs? If YES → START OVER

INSTRUCTIONS:
${instructions}

OUTPUT FORMAT:
- Return ONLY TypeScript code (no markdown, no explanations)
- Generate ONLY ONE it() block for ${normalizedTestCaseId}
- Start with import statements (first character must be 'i')
- Use correct imports: import { ecp, odc, utils } from 'roku-test-automation';
- CRITICAL: You MUST include the TestRail link comment AFTER imports and BEFORE the it() block

REQUIRED STRUCTURE (follow this EXACT format):
import { expect } from 'chai';
import { ecp, odc, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

// Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/${normalizedTestCaseId.replace('C', '')}
it('${normalizedTestCaseId} - ${testDetails.testName} @tags', async () => {
  // Your test code here
});

🚨 The TestRail link comment is MANDATORY and must appear AFTER imports, BEFORE the it() block
🚨 The format is: // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/${normalizedTestCaseId.replace('C', '')}

Generate ONLY the TypeScript test code now - no explanations, no markdown, no summaries.`;
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

OUTPUT FORMAT - CRITICAL RULES:
⚠️  NEVER return explanatory text like "I've fixed the errors" or "Here's the fixed code"
⚠️  NEVER add comments explaining what you fixed
⚠️  NEVER return markdown code blocks

REQUIRED OUTPUT:
- Return ONLY the complete fixed TypeScript code
- Start with import statement (first character must be 'i')
- No markdown, no explanations, no comments about changes
- Just the raw TypeScript code ready to save

YOUR FIRST CHARACTER MUST BE: i (from "import")`;
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
