// @ts-check
const fs = require("fs");
const path = require("path");
const config = require("../config");

/**
 * Normalize test case ID to ensure it has 'C' prefix
 * @param {string} testCaseId
 * @returns {string}
 */
function normalizeTestCaseId(testCaseId) {
  if (!testCaseId) return "";
  return testCaseId.startsWith("C") ? testCaseId : "C" + testCaseId;
}


/**
 * Detect keywords in test text and return search patterns
 * @param {string} text - Test text (name + preconditions + steps)
 * @returns {Array<{keyword: string, searchPattern: string}>}
 */
function detectKeywords(text) {
  const patterns = [
    { keywords: ['charles', 'network traffic', 'observe network', 'api', 'intercept'], keyword: 'Network/Proxy', searchPattern: 'import.*proxy' },
    { keywords: ['play video', 'playback', 'player', 'playing', 'pause'], keyword: 'Playback', searchPattern: 'waitForPlayerStateToEqual' },
    { keywords: ['history', 'resume', 'continue watching'], keyword: 'History', searchPattern: 'createHistory' },
    { keywords: ['detail page', 'movie details', 'series details'], keyword: 'Detail Screen', searchPattern: 'detailScreen' },
    { keywords: ['autoplay', 'preview'], keyword: 'Autoplay', searchPattern: 'previewVideoPlayer' },
    { keywords: ['my list', 'watchlist', 'favorites', 'my stuff'], keyword: 'My List', searchPattern: 'addToMyList|removeFromMyList' },
    { keywords: ['parental control', 'kids mode'], keyword: 'Parental Controls', searchPattern: 'setParentalControls' },
  ];

  const detected = [];
  for (const pattern of patterns) {
    if (pattern.keywords.some(kw => text.includes(kw))) {
      detected.push({ keyword: pattern.keyword, searchPattern: pattern.searchPattern });
    }
  }

  return detected.length > 0 ? detected : [{ keyword: 'General', searchPattern: 'it\\(' }];
}

/**
 * Get relevant element IDs from elements.ts based on screen mentions
 * @param {string} text - Test text
 * @returns {Array<string>}
 */
function getRelevantElements(text) {
  const elementsPath = path.join(config.paths.projectRoot, config.paths.configDir, 'elements.ts');

  if (!fs.existsSync(elementsPath)) {
    return [];
  }

  // Read elements.ts and extract element names
  // Match both quoted ('key': {) and unquoted (key: {) TypeScript object keys
  const elementsContent = fs.readFileSync(elementsPath, 'utf8');
  const elementMatches = elementsContent.matchAll(/(?:['"](\w+)['"]|(\w+))\s*:\s*\{/g);
  const allElements = Array.from(elementMatches, m => m[1] || m[2]);

  // Filter elements based on screen keywords in test
  const screenKeywords = {
    search: ['search', 'trending'],
    detail: ['detail', 'movie', 'series', 'vod'],
    player: ['player', 'video', 'playback'],
    home: ['home', 'grid', 'row'],
    mystuff: ['mystuff', 'myStuff', 'watchlist'],
  };

  const relevantElements = [];
  for (const [screen, keywords] of Object.entries(screenKeywords)) {
    if (keywords.some(kw => text.includes(kw))) {
      // Add elements that contain screen-related keywords
      relevantElements.push(...allElements.filter(el =>
        keywords.some(kw => el.toLowerCase().includes(kw))
      ));
    }
  }

  // Remove duplicates and limit to 10 most relevant
  return [...new Set(relevantElements)].slice(0, 10);
}

/**
 * Build prompt for AI test generation
 * @param {Object} testDetails
 * @param {Array<string>} existingTestIds - List of existing test case IDs to avoid
 * @param {string} wrongIdFromPreviousAttempt - ID that AI used incorrectly in previous attempt
 * @returns {string}
 */
function buildPrompt(
  testDetails,
  existingTestIds = [],
  wrongIdFromPreviousAttempt = null,
) {
  const normalizedTestCaseId = normalizeTestCaseId(testDetails.testCaseId);
  const hasPreConditions =
    testDetails.preConditions &&
    testDetails.preConditions !== "No pre-conditions specified";
  const hasExpectedResult =
    testDetails.expectedResult &&
    testDetails.expectedResult !== "No expected result specified";

  // If this is a retry, add explicit correction feedback AT THE VERY TOP
  let retryFeedback = "";
  if (wrongIdFromPreviousAttempt) {
    retryFeedback = `
🚨 CRITICAL ERROR IN PREVIOUS ATTEMPT 🚨

YOU USED THE WRONG TEST CASE ID: ${wrongIdFromPreviousAttempt}
The CORRECT test case ID is: ${normalizedTestCaseId}

DO NOT REPEAT THIS MISTAKE!

`;
  }

  // Detect keywords for targeted instruction injection
  const testText = `${testDetails.testName} ${testDetails.preConditions} ${testDetails.testSteps} ${testDetails.expectedResult || ''}`.toLowerCase();
  const detectedKeywords = detectKeywords(testText);

  // Get relevant elements if screen is mentioned
  const relevantElements = getRelevantElements(testText);

  return `${retryFeedback}<test_requirement>
TEST CASE: ${normalizedTestCaseId} (use this ID only)

Test Name: ${testDetails.testName}
Section: ${testDetails.mainSection}
User Type: ${testDetails.userType}
${hasPreConditions ? `Pre-conditions: ${testDetails.preConditions}` : ""}
Test Steps:
${testDetails.testSteps}

${hasExpectedResult ? `Expected Result:
${testDetails.expectedResult}

` : ""}${existingTestIds.length > 0 ? `${existingTestIds.length} existing tests - do not copy IDs` : ""}
</test_requirement>

${relevantElements.length > 0 ? `<relevant_elements>
These element IDs exist in automated-tests-config/elements.ts:
${relevantElements.join('\n')}
Use EXACT names from this list.
</relevant_elements>

` : ""}<guidelines>

SEARCH PATTERNS: Grep for '${detectedKeywords.map(kw => kw.searchPattern).join("' OR '")}'. Read 2-3 examples. Copy exact patterns.

SETUP:
- User: ${testDetails.userType}
- Start: testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true${detectedKeywords.some(kw => kw.keyword === 'Network/Proxy') ? ', clearRegistry: false' : ''} })

CONSTRAINTS:
- No utils.sleep() > 2000ms (use waitForElementToShowOnScreen, waitForPlayerStateToEqual)
- No 'message' param in waitForCurrentScreenToEqual/retryWithTimeOut
- Use exact element names from elements.ts${detectedKeywords.some(kw => kw.keyword === 'Network/Proxy') ? '\n- PROXY: When using proxy.start(), add clearRegistry:false to startApplicationAtPage' : ''}

FORMAT (REQUIRED):
it('${normalizedTestCaseId} - Test name @tags', async () => {
  /**
   * Pre-conditions:
${hasPreConditions ? testDetails.preConditions.split('\n').map(line => `   * ${line.trim()}`).join('\n') : '   * No pre-conditions'}
   *
   * Test Steps:
${testDetails.testSteps.split('\n').map((line, idx) => `   * ${idx + 1}. ${line.trim()}`).join('\n')}
   */

  // test code here
});

OUTPUT: TypeScript code only. Start with 'import'. No explanations/markdown/html/css.
</guidelines>`;
}

/**
 * Extract type names from TypeScript error messages
 * @param {string} errorText
 * @returns {string[]}
 */
function extractTypeNamesFromErrors(errorText) {
  const typeNames = new Set();

  // Pattern 1: "Property 'X' does not exist on type 'TypeName'"
  const pattern1 = /does not exist on type '([^']+)'/g;
  let match;
  while ((match = pattern1.exec(errorText)) !== null) {
    typeNames.add(match[1]);
  }

  // Pattern 2: "Property 'X' is private and only accessible within class 'ClassName'"
  const pattern2 = /only accessible within class '([^']+)'/g;
  while ((match = pattern2.exec(errorText)) !== null) {
    typeNames.add(match[1]);
  }

  // Pattern 3: "Type 'TypeName' is missing the following properties"
  const pattern3 = /Type '([^']+)' is missing/g;
  while ((match = pattern3.exec(errorText)) !== null) {
    typeNames.add(match[1]);
  }

  return Array.from(typeNames);
}

/**
 * Find and read type definition files for the given type names
 * @param {string[]} typeNames
 * @returns {Object[]} Array of {typeName, filePath, content}
 */
function findTypeDefinitions(typeNames) {
  const results = [];
  const projectRoot = path.resolve(__dirname, '../../');
  const nodeModulesPath = path.join(projectRoot, 'node_modules');

  for (const typeName of typeNames) {
    try {
      // Search in node_modules for .d.ts files containing the type
      const { execSync } = require('child_process');

      // Use grep to find type definitions (faster than reading all files)
      const grepCommand = `grep -r "interface ${typeName}\\|class ${typeName}\\|type ${typeName}" "${nodeModulesPath}" --include="*.d.ts" -l 2>/dev/null | head -1`;
      const foundFile = execSync(grepCommand, { encoding: 'utf8' }).trim();

      if (foundFile) {
        const content = fs.readFileSync(foundFile, 'utf8');
        results.push({
          typeName,
          filePath: foundFile.replace(projectRoot, ''),
          content
        });
      }
    } catch (error) {
      // File not found or grep error - continue
    }
  }

  return results;
}

/**
 * Find example usage patterns from existing tests
 * @param {string} errorText
 * @param {string} fileContent
 * @returns {string[]} Array of example code snippets
 */
function findExamplePatterns(errorText, fileContent) {
  const examples = [];
  const { execSync } = require('child_process');
  const projectRoot = path.resolve(__dirname, '../../');
  const testDirectories = ['js/automated-tests/tests', 'js/automated-tests'];

  try {
    // Detect patterns to search for based on error and file content
    const searchPatterns = [];

    // If error involves proxy callbacks
    if (errorText.includes('NetworkProxy') || errorText.includes('proxy') || fileContent.includes('proxy.addCallback')) {
      searchPatterns.push('proxy.addCallback');
    }

    // If error involves removeCallback
    if (errorText.includes('removeCallback') || fileContent.includes('removeCallback')) {
      searchPatterns.push('args.removeCallback');
    }

    // If error involves element operations
    if (errorText.includes('element') && (fileContent.includes('getNodeForElement') || fileContent.includes('waitForElement'))) {
      searchPatterns.push('waitForElementToShowOnScreen');
      searchPatterns.push('getNodeForElement');
    }

    // Search for each pattern and extract examples
    for (const pattern of searchPatterns) {
      for (const testDir of testDirectories) {
        const searchPath = path.join(projectRoot, testDir);
        if (!fs.existsSync(searchPath)) continue;

        try {
          // Use grep to find files with the pattern, then extract context
          const grepCommand = `grep -r "${pattern}" "${searchPath}" --include="*.ts" -A 15 -B 2 2>/dev/null | head -80`;
          const result = execSync(grepCommand, { encoding: 'utf8', timeout: 3000 }).trim();

          if (result) {
            examples.push(`Example usage of "${pattern}":\n${result}`);
            break; // Found an example for this pattern, move to next
          }
        } catch (error) {
          // Continue to next directory
        }
      }
    }
  } catch (error) {
    // If example search fails, just continue without examples
  }

  return examples;
}

/**
 * Build prompt for fixing lint/type errors
 * @param {string} filePath
 * @param {Object} lintResult
 * @returns {string}
 */
function buildLintFixPrompt(filePath, lintResult) {
  const fs = require('fs');
  const fileContent = fs.readFileSync(filePath, 'utf8');

  let promptContent = `Fix these ${lintResult.type} errors in the file by using the Edit tool to make the necessary changes.

FILE PATH: ${filePath}

ERRORS TO FIX:
${lintResult.errors}`;

  // If TypeScript errors, try to include relevant type definitions
  if (lintResult.type === 'typescript') {
    const typeNames = extractTypeNamesFromErrors(lintResult.errors);

    if (typeNames.length > 0) {
      const typeDefinitions = findTypeDefinitions(typeNames);

      if (typeDefinitions.length > 0) {
        promptContent += '\n\nRELEVANT TYPE DEFINITIONS:\n';
        for (const typeDef of typeDefinitions) {
          promptContent += `\n--- ${typeDef.typeName} (from ${typeDef.filePath}) ---\n${typeDef.content}\n`;
        }
      }
    }

    // Find and include example patterns from existing tests
    const examples = findExamplePatterns(lintResult.errors, fileContent);
    if (examples.length > 0) {
      promptContent += '\n\nEXAMPLE PATTERNS FROM EXISTING TESTS:\n';
      promptContent += 'These show correct usage patterns from working tests in the codebase:\n\n';
      for (const example of examples) {
        promptContent += `${example}\n\n`;
      }
    }
  }

  promptContent += `

INSTRUCTIONS:
1. Read the file to understand the current code
2. Use the Edit tool to fix each error
3. Preserve all .only() modifiers exactly as they appear
4. If there are syntax errors from invalid text (like plain English descriptions in the code), use Edit to remove those lines
5. DO NOT output code as text - use the Edit tool to modify the file directly
6. After fixing all errors, respond with "Fixed all errors" or list any errors you could not fix`;

  return promptContent;
}

module.exports = {
  normalizeTestCaseId,
  buildPrompt,
  buildLintFixPrompt,
};
