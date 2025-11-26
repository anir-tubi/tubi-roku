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
  const hasPreConditions = testDetails.preConditions && testDetails.preConditions !== 'No pre-conditions specified';

  return `You are a code generator for Roku Tubi app tests.

TEST REQUIREMENTS:
- Test Case ID: ${normalizedTestCaseId}
- Name: ${testDetails.testName}
- Section: ${testDetails.mainSection}
- User Type: ${testDetails.userType}${hasPreConditions ? `\n- Pre-conditions: ${testDetails.preConditions}` : ''}
- Steps: ${testDetails.testSteps}

⚠️ **CRITICAL - DO NOT COPY EXISTING TESTS:**
- You MUST generate a NEW test for Test Case ID: ${normalizedTestCaseId}
- DO NOT copy any existing test from the codebase
- DO NOT reuse code from other test case IDs
- You may REFERENCE existing tests to learn patterns, but you MUST write NEW test code
- The test MUST use Test Case ID: ${normalizedTestCaseId} (not any other ID)

CRITICAL ANALYSIS STEP - READ BEFORE WRITING ANY CODE:
1. **⚠️ FIRST: Carefully read and analyze the Test Name**
   - The test name contains the EXPECTED BEHAVIOR that you must verify
   - Examples:
     * "Year displayed and runtime not displayed" → Verify year IS visible AND runtime IS NOT visible
     * "Button is visible" → Verify button IS visible
     * "Button is not visible" → Verify button IS NOT visible
   - Pay attention to "not", "displayed", "hidden", "visible", "enabled", "disabled"
   - Your assertions MUST match what the test name describes

2. **Carefully read and analyze the Pre-conditions** (if provided above)
   - Determine what setup is required (e.g., "be a signed in user", "movie has history")
   - Identify the correct user type based on pre-conditions
   - Note any state requirements (history, queue, favorites, etc.)

   ⚠️ **CRITICAL: "Movie has history" or "Movie with history" means YOU MUST CREATE HISTORY IN THE TEST**
   - If test mentions "movie has history", "movie with history", "title with history" → YOU must create the history
   - Look for pattern in existing tests: Play movie → Wait → Create history → Back to details
   - DO NOT assume history already exists - YOU must create it using:
     Example pattern: ecp.sendKeypress(ecp.Key.Play) then call createHistory() helper function

3. **Carefully read and analyze the Test Steps**
   - Understand the complete test flow from start to finish
   - Identify all required user actions
   - Note expected outcomes at each step
   - If steps mention "Select Movie title with history" → This means CREATE history first, THEN test the behavior

4. **Derive Test Requirements from Analysis**
   - Combine Test Name + Pre-conditions + Test Steps to understand what to test
   - Test Name = WHAT to verify (expected behavior)
   - Steps = HOW to get there (navigation and actions)
   - Pre-conditions = SETUP required before test
   - User authentication needs (Guest vs Registered user)
   - Screen navigation path
   - Required helper functions (createHistory, etc.)
   - Assertions needed to verify behavior

   ⚠️ **For "Remove from History" or "Delete from Continue Watching" tests:**
   - ALWAYS create history first by playing content
   - Use the exact pattern from existing tests in details-page.ts
   - Pattern: Launch → Play → createHistory() → Back → Remove from history → Verify

5. **⚠️ CRITICAL: Study Existing Tests in the Same File**
   - Look at other tests in the file to see what helper functions they use
   - Copy the exact patterns, element names, and function calls from existing tests
   - DO NOT invent or assume functions exist (e.g., loginRegisteredUser(), navigateToDetailsPage(), getButtonLabels())
   - ONLY use functions that you see in existing tests
   - Use raw ecp.sendKeypress(), odc, utils.sleep() for actions not covered by helpers

INSTRUCTIONS:
${instructions}

OUTPUT FORMAT - CRITICAL RULES:
⚠️  NEVER return explanatory text, descriptions, or summaries
⚠️  NEVER say "the test already exists" or explain existing code
⚠️  NEVER return markdown, comments about what you're doing, or analysis

REQUIRED OUTPUT:
- Return ONLY TypeScript code (no markdown, no explanations, no code blocks)
- Single complete test file ready to save
- Start directly with import statements (no explanatory text before imports)
- Only import modules that are actually used in the code
- **CRITICAL: Use the correct import pattern:**
  ✅ CORRECT: import { ecp, odc, utils } from 'roku-test-automation';
  ❌ WRONG: import { ecp } from '../src/ecp'; import { odc } from '../src/odc';
  Always use: import { ecp, odc, utils } from 'roku-test-automation';
  And: import { testUtils } from '../test-utils';
- ⚠️ CRITICAL: Use the exact Test Case ID "${normalizedTestCaseId}" in both the comment and the it() block
- DO NOT use any other test case ID (like C537369, C535838, etc.) - only use ${normalizedTestCaseId}
  Example:
    // Test Rail Link: https://tubi.testrail.io/index.php?/cases/view/${normalizedTestCaseId.replace('C', '')}
    it('${normalizedTestCaseId} - Test Name @tags', async () => {

  ❌ WRONG EXAMPLES (DO NOT DO THIS):
    it('C537369 - Some other test @tags', async () => {  // ❌ Wrong ID!
    it('C535838 - Different test @tags', async () => {   // ❌ Wrong ID!

YOUR FIRST CHARACTER MUST BE: i (from "import")
YOUR RESPONSE MUST BE: Valid TypeScript code that can be saved directly to a .ts file

⚠️ **UNDERSTANDING ELEMENT BEHAVIOR - CRITICAL:**

**FIRST: Analyze the element name to understand what it contains:**
- Element names like "titleAndGenre", "yearAndDuration", "nameAndRole" indicate COMBINED INFO in one element
- These elements show different pieces of info in their .text property based on app state
- The test verifies WHAT INFO IS SHOWN, not just if element is visible

**PATTERN 1: Testing content within a combined-info element**
When test says "X displayed and Y not displayed" AND element name is like "xAndY":

  // The element exists and is visible, but shows only some info
  const element = await testUtils.getNodeForElement('combinedInfoElement');

  // Check for presence of X (use appropriate pattern for what X is)
  expect(element.text).to.match(/pattern-for-X/);

  // Check for absence of Y (use appropriate pattern for what Y is)
  expect(element.text).to.not.match(/pattern-for-Y/);

Examples of regex patterns:
- Year (4-digit number): /\\d{4}/
- Duration/Runtime (time format): /\\d+\\s*(h|hr|hour|min|m)/i
- Genre (words): /comedy|drama|action/i
- Rating (like PG-13, R): /\\b(G|PG|PG-13|R|NC-17)\\b/i

**PATTERN 2: Testing visibility of separate elements**
When test says "X visible and Y not visible" AND elements are separate:

  const xElement = await testUtils.getNodeForElement('xElement');
  expect(xElement.visible).to.equal(true);

  const yElement = await testUtils.getNodeForElement('yElement');
  expect(yElement.visible).to.equal(false);

**HOW TO DECIDE which pattern to use:**
1. Look at element names in the test steps or error messages
2. If element name combines multiple concepts (e.g., "titleAndYear") → Use PATTERN 1 (text matching)
3. If there are separate elements → Use PATTERN 2 (visibility checks)
4. Check existing tests in the same file for similar scenarios

NOW:
1. First, analyze the TEST NAME to understand expected behavior
2. Then analyze pre-conditions and steps
3. Then generate ONLY the test code - no explanations, no summaries, just code`;
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
