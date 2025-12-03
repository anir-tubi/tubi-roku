// @ts-ignore
const gulp = require('gulp');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
// @ts-ignore
const inquirer = require('inquirer');
const { fetchTestCaseWithContext } = require('./testrail-case-fetcher.js');
const { buildPrompt, buildLintFixPrompt } = require('./lib/prompt-builder.js');

// Suppress regex flag warnings
process.on('warning', (warning) => {
  if (warning.name === 'ExperimentalWarning' && warning.message.includes('regex flag')) {
    // Ignore regex flag warnings
    return;
  }
  console.warn(warning.message);
});

const projectRoot = path.resolve(__dirname, '..');
const CLAUDE_TIMEOUT = 600000; // 10 minutes (increased from 2 to handle large codebases)

// ============================================================================
// USER INPUT
// ============================================================================

async function promptUser() {
  // Check for command-line arguments
  const caseIdArg = process.argv.find(arg => arg.startsWith('--caseId='));
  const caseIdFromCli = caseIdArg ? caseIdArg.split('=')[1] : null;

  let answers = {};

  if (caseIdFromCli) {
    // Non-interactive mode
    console.log('🎯 Test Generation (Non-Interactive Mode)');
    console.log('==========================================\n');
    console.log(`📋 Using Test Case ID: ${caseIdFromCli}\n`);
    answers.testCaseId = caseIdFromCli;
  } else {
    // Interactive mode
    console.log('🎯 Test Generation Wizard');
    console.log('========================\n');

    const questions = [
      {
        type: 'input',
        name: 'testCaseId',
        message: 'TestRail Case ID (e.g., "C535841" or "535841"):',
        validate: (input) => input.length > 0 || 'Test case ID is required'
      }
    ];

    answers = await inquirer.prompt(questions);
  }

  // Set default values
  answers.runLinter = true;
  answers.runTest = true;

  // Fetch TestRail case data
  console.log('\n🔍 Fetching TestRail case data...');
  try {
    const testRailData = await fetchTestCaseWithContext(answers.testCaseId);

    // Map TestRail data to our expected format
    answers.testName = testRailData.title;
    answers.testSteps = testRailData.testSteps || 'Test steps not available';
    answers.preConditions = testRailData.preConditions || 'No pre-conditions specified';
    answers.sectionName = testRailData.sectionName || 'Unknown Section';
    answers.mainSection = testRailData.mainSection;
    answers.subSection = testRailData.subSection;

    // Derive user type using LLM (replaces brittle keyword matching)
    console.log('🤖 Using LLM to determine user type...');
    const { callClaudeForUserTypeDetermination } = require('./lib/llm-client');

    try {
      const userTypeResult = await callClaudeForUserTypeDetermination(
        answers.testSteps,
        answers.preConditions
      );

      if (userTypeResult && userTypeResult.userType) {
        answers.userType = userTypeResult.userType;
        console.log(`   Determined: ${userTypeResult.userType}`);
        console.log(`   Confidence: ${userTypeResult.confidence}`);
        console.log(`   Reasoning: ${userTypeResult.reasoning}`);
      } else {
        // Fallback to legacy keyword matching
        console.log('   LLM determination failed, using keyword matching...');
        answers.userType = deriveUserTypeLegacy(answers.testSteps, answers.preConditions);
      }
    } catch (error) {
      console.error(`   LLM error: ${error.message}`);
      console.log('   Using keyword matching fallback...');
      answers.userType = deriveUserTypeLegacy(answers.testSteps, answers.preConditions);
    }

    // Use main section as screen context (already parsed from TestRail)
    console.log(`🔍 Main Section: ${answers.mainSection}`);
    console.log(`🔍 Sub Section: ${answers.subSection || 'None'}`);

    // Use main section as screen context
    answers.screen = 'Other';
    answers.screenCustom = answers.mainSection;
    answers.tags = '@validation';

    console.log(`✅ Fetched: ${testRailData.title}`);
    console.log(`📋 Section: ${testRailData.sectionName}`);
    console.log(`👤 User Type: ${answers.userType}`);
    if (testRailData.preConditions) {
      console.log(`📌 Pre-conditions: ${testRailData.preConditions.substring(0, 100)}${testRailData.preConditions.length > 100 ? '...' : ''}`);
    }

  } catch (error) {
    console.error('❌ Failed to fetch TestRail data:', error.message);
    console.log('📝 Using default values...');

    // Fallback to defaults
    answers.testName = 'Test Case';
    answers.testSteps = 'Test steps not available';
    answers.preConditions = 'No pre-conditions specified';
    answers.userType = 'Guest';
    answers.screen = 'Other';
    answers.screenCustom = 'Unknown Screen';
    answers.tags = '@validation';
  }

  return answers;
}

/**
 * Legacy keyword-based user type derivation (fallback)
 */
function deriveUserTypeLegacy(testSteps, preConditions) {
  const testStepsLower = (testSteps || '').toLowerCase();
  const preConditionsLower = (preConditions || '').toLowerCase();
  const combinedText = testStepsLower + ' ' + preConditionsLower;

  // Check for registered user indicators
  const registeredKeywords = ['registered', 'signed in', 'sign in', 'logged in', 'login', 'authenticated'];
  const hasRegisteredIndicator = registeredKeywords.some(keyword => combinedText.includes(keyword));

  // Check for guest user indicators (explicit guest mentions override registered keywords)
  const guestKeywords = ['guest', 'unauthenticated', 'not signed in', 'no account'];
  const hasGuestIndicator = guestKeywords.some(keyword => combinedText.includes(keyword));

  // Determine user type
  if (hasGuestIndicator && !combinedText.includes('be a signed in user')) {
    return 'Guest';
  } else if (hasRegisteredIndicator || combinedText.includes('history')) {
    // History functionality typically requires a registered user
    return 'Registered';
  } else {
    return 'Guest'; // Default
  }
}

// ============================================================================
// CODE GENERATION
// ============================================================================

function checkClaudeAvailable() {
  try {
    const { execSync } = require('child_process');
    execSync('claude --version', { encoding: 'utf8', stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

/**
 * Call Claude AI to analyze and match elements
 * Now uses the centralized LLM client
 * @param {string} targetElement - Element name to find
 * @param {Array<Object>} suggestions - List of available elements
 * @param {string} context - Screen context (e.g., "detailScreen", "homeScreen")
 * @returns {Promise<Object>}
 */
async function callClaudeForElementMatching(targetElement, suggestions, context = null) {
  const { callClaudeForElementMatching: claudeClient } = require('./lib/llm-client');
  return claudeClient(targetElement, suggestions, context);
}

/**
 * Adds .only to a specific test case by ID, or to the last test if no ID provided
 * @param {string} code - The test file code
 * @param {string} testCaseId - Optional test case ID (e.g., "C535817")
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
    // Pattern: it('C535817 - or it("C535817 -
    const testPattern = new RegExp(`(\\s+it)\\(['"](${normalizedId}[^'"]*?)['"]`, 'g');
    const match = testPattern.exec(code);

    if (match) {
      // Found the test with this ID, add .only to it
      const result = code.replace(testPattern, '$1.only(\'$2\'');
      console.log(`✅ Added .only to test ${normalizedId}`);
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
    console.log('✅ Added .only to last test');
    return result;
  }

  console.log('⚠️  Could not add .only - no it() blocks found');
  return code;
}

/**
 * Removes .only from all test cases in a file
 * @param {string} filePath - Path to the test file
 */
function removeTestOnlyFromFile(filePath) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;

    // Replace all it.only( with it(
    content = content.replace(/(\s+it)\.only\(/g, '$1(');

    if (content !== originalContent) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log('✅ Removed .only from test file');
      return true;
    } else {
      console.log('ℹ️  No .only found in test file');
      return false;
    }
  } catch (error) {
    console.error(`❌ Error removing .only: ${error.message}`);
    return false;
  }
}

function cleanGeneratedCode(stdout) {
  let cleanedOutput = stdout.trim();

  // Remove markdown code block wrappers
  cleanedOutput = cleanedOutput.replace(/^```typescript\n?/gm, '');
  cleanedOutput = cleanedOutput.replace(/^```ts\n?/gm, '');
  cleanedOutput = cleanedOutput.replace(/\n?```$/gm, '');
  cleanedOutput = cleanedOutput.trim();

  // Remove common explanation phrases that Claude adds before code
  const explanationPatterns = [
    // @ts-ignore
    /^.*?Here's the fixed code:\s*/is,
    // @ts-ignore
    /^.*?Here is the fixed code:\s*/is,
    // @ts-ignore
    /^.*?Here's the code:\s*/is,
    // @ts-ignore
    /^.*?Here is the code:\s*/is,
    // @ts-ignore
    /^.*?Fixed code:\s*/is,
  ];

  for (const pattern of explanationPatterns) {
    if (pattern.test(cleanedOutput)) {
      cleanedOutput = cleanedOutput.replace(pattern, '');
      console.log('✅ Removed explanation phrase');
      break;
    }
  }

  // Remove any explanatory text before the first import statement
  // Look for actual import statement patterns (import {, import *, import type, etc.)
  // @ts-ignore
  const importMatch = cleanedOutput.match(/^.*?(import\s+(?:\{|type|[\*\w]))/ms);
  if (importMatch && importMatch.index > 0) {
    cleanedOutput = cleanedOutput.substring(importMatch.index);
    console.log('✅ Removed explanatory text before imports');
  }

  // Additional cleanup: Remove any remaining text before the first valid import line
  // This catches cases where Claude's explanation contains the word "import"
  const lines = cleanedOutput.split('\n');
  const firstImportLineIndex = lines.findIndex(line => /^import\s+(?:\{|type|\*|[\w])/.test(line.trim()));
  if (firstImportLineIndex > 0) {
    cleanedOutput = lines.slice(firstImportLineIndex).join('\n');
    console.log('✅ Removed additional explanatory text before imports');
  }

  // Note: We no longer remove .only since it's used for test isolation during development
  // cleanedOutput = cleanedOutput.replace(/(\s+it)\.only\(/g, '$1(');

  // Remove any this.timeout() lines
  cleanedOutput = cleanedOutput.replace(/\s*this\.timeout\(\d+\);\s*/g, '');

  return cleanedOutput;
}

/**
 * Scan all test files and extract existing test case IDs
 * @returns {Array<string>} List of existing test case IDs
 */
function getAllExistingTestCaseIds() {
  const testsDir = path.join(projectRoot, 'js/automated-tests/tests');
  const existingIds = new Set();

  try {
    const testFiles = fs.readdirSync(testsDir).filter(f => f.endsWith('.ts'));

    for (const file of testFiles) {
      const filePath = path.join(testsDir, file);
      const content = fs.readFileSync(filePath, 'utf8');

      // Find all test case IDs in it() or it.only() blocks
      const matches = content.matchAll(/it(?:\.only)?\s*\(['"]C(\d+)[^'"]*['"]/g);
      for (const match of matches) {
        existingIds.add('C' + match[1]);
      }
    }

    return Array.from(existingIds).sort();
  } catch (error) {
    console.warn('⚠️  Could not scan existing test IDs:', error.message);
    return [];
  }
}

/**
 * Generate test with automatic retry if wrong test case ID is used
 * @param {Object} testDetails
 * @param {number} maxAttempts
 * @returns {Promise<string>} Generated test code
 */
async function generateTestWithRetry(testDetails, maxAttempts = 3) {
  const existingTestIds = getAllExistingTestCaseIds();
  let lastWrongId = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`📍 Generation Attempt ${attempt}/${maxAttempts}`);
    console.log(`${'='.repeat(60)}\n`);

    const result = await generateTestWithAI(testDetails, existingTestIds, lastWrongId, attempt);

    if (result.isValid) {
      console.log(`\n✅ Test generated successfully with correct ID: ${testDetails.testCaseId}`);
      return result.code;
    }

    // Wrong ID detected
    console.error('\n' + '━'.repeat(60));
    console.error('❌ WRONG TEST CASE ID DETECTED');
    console.error('━'.repeat(60));
    console.error(`\n🎯 Expected: ${result.expectedId}`);
    console.error(`❌ Got: ${result.wrongId || 'unknown'}`);

    if (result.wrongId && existingTestIds.includes(result.wrongId)) {
      console.error(`⚠️  ${result.wrongId} ALREADY EXISTS in codebase - AI copied an existing test!`);
    }

    lastWrongId = result.wrongId;

    if (attempt < maxAttempts) {
      console.error(`\n🔄 Retrying with explicit feedback about the mistake...\n`);
    } else {
      console.error('\n❌ Failed to generate test with correct ID after all attempts');
      throw new Error(`AI failed to use correct test case ID after ${maxAttempts} attempts. Expected: ${result.expectedId}, Got: ${result.wrongId}`);
    }
  }
}

async function generateTestWithAI(testDetails, existingTestIds, wrongIdFromPreviousAttempt = null, attempt = 1) {
  if (attempt === 1) {
    console.log('🤖 Calling Claude Code SDK with project context...');

    if (!checkClaudeAvailable()) {
      throw new Error('Claude Code SDK not found. Please install: npm install -g @anthropic-ai/claude-code');
    }

    console.log('✅ Claude Code SDK found');

    // Get all existing test case IDs to prevent copying (only on first attempt)
    if (!existingTestIds) {
      console.log('🔍 Scanning for existing test case IDs...');
      existingTestIds = getAllExistingTestCaseIds();
      console.log(`📋 Found ${existingTestIds.length} existing test cases`);
    }
  } else {
    console.log(`🔄 Regenerating with correction feedback (attempt ${attempt})...`);
  }

  return new Promise((resolve, reject) => {
    console.log('📁 Claude will read project files directly...');
    console.log('🤖 Claude will analyze the project and generate test...');
    console.log('⏳ This may take 30-60 seconds...\n');

    const promptContent = buildPrompt(testDetails, existingTestIds, wrongIdFromPreviousAttempt);

    // Write prompt to a temporary file to avoid shell escaping issues
    const tmpFile = path.join(projectRoot, '.claude-prompt-tmp');
    fs.writeFileSync(tmpFile, promptContent);

    // Add test files for pattern learning, but AI must NOT copy test case IDs
    const claudeCommand = `cat ${tmpFile} | claude --print --add-dir js/automated-tests --add-dir automated-tests-config --add-dir .claude`;

    // Progress indicators
    const progressInterval = setInterval(() => process.stdout.write('.'), 2000);
    const timeout = setTimeout(() => {
      console.log('\n⏰ Claude is taking longer than expected...');
      console.log('💡 This is normal for large projects. Claude is analyzing your codebase.');
    }, 10000);

    // @ts-ignore
    exec(claudeCommand, { cwd: projectRoot, timeout: CLAUDE_TIMEOUT }, (error, stdout, stderr) => {
      // Clean up temp file
      try {
        fs.unlinkSync(tmpFile);
      } catch (e) {
        // Ignore cleanup errors
      }
      clearTimeout(timeout);
      clearInterval(progressInterval);

      if (error) {
        console.error('\n❌ Claude execution failed:', error.message);
        if (error.signal === 'SIGTERM' || error.message.includes('timeout')) {
          console.error('⏰ Claude timed out after 10 minutes');
          console.error('💡 This is unusual - the codebase may be very large or Claude API may be slow');
        }
        reject(error);
        return;
      }

      console.log('\n✅ Claude generated test successfully');

      const cleanedOutput = cleanGeneratedCode(stdout);

      // STRICT VALIDATION: Ensure output is actual code, not explanatory text
      const validationErrors = [];
      let errorType = 'unknown';

      // Check 1: Must start with 'import'
      const startsWithImport = cleanedOutput.trim().startsWith('import');
      if (!startsWithImport) {
        validationErrors.push('Output must start with import statement');
        errorType = 'wrong_format';
      }

      // Check 2: Must contain 'describe' and 'it('
      const hasDescribe = cleanedOutput.includes('describe');
      const hasIt = cleanedOutput.includes('it(') || cleanedOutput.includes('it.only(');

      // Note: We don't add errors here yet - we'll check if it's a valid standalone block first
      if (!hasIt) {
        validationErrors.push('Missing it() test block');
      }

      // Check 3: Must NOT contain common explanation phrases at the beginning (before code starts)
      // Only check the first 500 characters to avoid false positives from comments/strings in code
      const outputStart = cleanedOutput.substring(0, 500);
      const explanationIndicators = [
        'I can see that',
        'Looking at',
        'The test already exists',
        'Since this test',
        'already implements',
        'File:**',
        '**File:**',
        'Located at:',
        'there\'s no need',
      ];

      let hasExplanation = false;
      for (const phrase of explanationIndicators) {
        if (outputStart.includes(phrase)) {
          validationErrors.push(`Contains explanatory text at start: "${phrase}"`);
          hasExplanation = true;
          errorType = 'explanation_text';
          break;
        }
      }

      // Check 4: Verify TypeScript code structure
      const hasImports = cleanedOutput.match(/^import\s+/m);
      const hasDescribeBlock = cleanedOutput.match(/describe\s*\(/);
      const hasItBlock = cleanedOutput.match(/it(?:\.only)?\s*\(/);

      // Check 5: Detect truly truncated/incomplete output
      const lines = cleanedOutput.split('\n');
      const lastLine = lines[lines.length - 1].trim();

      // More sophisticated truncation detection
      const hasProperClosing = cleanedOutput.match(/\}\s*\)\s*;\s*$/m) || cleanedOutput.match(/\}\s*;?\s*$/m);
      const endsAbruptly = lastLine && !lastLine.endsWith(';') && !lastLine.endsWith('}') &&
        !lastLine.endsWith(')') && !lastLine.endsWith(',') && lastLine.length > 10;

      // SPECIAL CASE: Standalone it() block without describe (valid for appending to existing files)
      const isStandaloneItBlock = startsWithImport && hasItBlock && !hasDescribe && hasProperClosing;

      // Only flag as truncated if it's clearly incomplete
      const isTruncated = startsWithImport && hasItBlock && !hasDescribe && !hasProperClosing;
      const seemsIncomplete = endsAbruptly && hasItBlock && !hasDescribe && !hasProperClosing;

      // LENIENT: Accept if has either:
      // 1. Full structure (imports, describe, it) OR
      // 2. Standalone it() block that will be appended to existing file
      const hasMinimalStructure = (startsWithImport && hasDescribeBlock && hasItBlock) || isStandaloneItBlock;

      if (!hasMinimalStructure) {
        // Only add "missing describe" error if it's NOT a valid standalone block
        if (!hasDescribe && !isStandaloneItBlock) {
          validationErrors.push('Missing describe block');
        }

        if (isTruncated || seemsIncomplete) {
          validationErrors.push('Output appears to be truncated or incomplete');
          errorType = 'truncated';
        }

        if (!hasImports || !hasItBlock) {
          if (startsWithImport && !hasExplanation) {
            // Has imports but missing structure - likely truncated
            errorType = 'truncated';
          }
          validationErrors.push('Missing required TypeScript test structure (imports, it block)');
        }
      } else {
        // Has minimal structure - log info about what we got
        if (isStandaloneItBlock) {
          console.log('ℹ️  Generated standalone it() block (will be added to existing describe block)');
          console.log('💡 This is valid for appending to existing test files');
        }
        if (endsAbruptly || !hasProperClosing) {
          console.log('⚠️  Output may be slightly incomplete but has valid structure');
          console.log('💡 Will save and let linter/tests validate further');
        }
      }

      // If validation fails, reject and show error
      if (validationErrors.length > 0) {
        console.error('\n' + '━'.repeat(60));
        console.error('❌ AI OUTPUT VALIDATION FAILED');
        console.error('━'.repeat(60));

        // Provide specific error message based on error type
        if (errorType === 'truncated') {
          console.error('\n🔍 Issue Type: TRUNCATED OR INCOMPLETE OUTPUT');
          console.error('\nThe AI started generating code correctly but the output was cut off.');
          console.error('\nPossible causes:');
          console.error('  1. Claude API response was truncated');
          console.error('  2. Output buffer limit reached');
          console.error('  3. Claude timed out mid-generation');
          console.error('  4. Code was too long and got cut off');
          console.error('\n💡 Solutions:');
          console.error('  - Retry the generation (may work on second try)');
          console.error('  - Simplify the test case if possible');
          console.error('  - Check Claude API status');

        } else if (errorType === 'explanation_text') {
          console.error('\n🔍 Issue Type: EXPLANATORY TEXT INSTEAD OF CODE');
          console.error('\nThe AI returned explanatory text instead of TypeScript code.');
          console.error('\n💡 Solutions:');
          console.error('  - The AI found an existing test and explained it instead of generating code');
          console.error('  - Retry with a different test case');
          console.error('  - Check if the test already exists in the codebase');

        } else if (errorType === 'wrong_format') {
          console.error('\n🔍 Issue Type: WRONG OUTPUT FORMAT');
          console.error('\nThe AI did not start with an import statement.');
          console.error('\n💡 Solutions:');
          console.error('  - Retry the generation');
          console.error('  - Check the prompt instructions');
        }

        console.error('\n📋 Validation errors:');
        validationErrors.forEach(err => console.error(`  • ${err}`));

        console.error('\n📝 Output preview (first 800 characters):');
        console.error('─'.repeat(60));
        console.error(cleanedOutput.substring(0, 800));
        if (cleanedOutput.length > 800) {
          console.error('\n... (truncated, total length: ' + cleanedOutput.length + ' characters)');
        }
        console.error('─'.repeat(60));

        console.error('\n📝 Output preview (last 200 characters):');
        console.error('─'.repeat(60));
        console.error(cleanedOutput.substring(Math.max(0, cleanedOutput.length - 200)));
        console.error('─'.repeat(60));

        // Create specific error message
        let errorMsg = 'AI output validation failed: ';
        if (errorType === 'truncated') {
          errorMsg = 'AI output was truncated or incomplete. Try running the generation again.';
        } else if (errorType === 'explanation_text') {
          errorMsg = 'AI generated explanatory text instead of code. Check if test already exists.';
        } else if (errorType === 'wrong_format') {
          errorMsg = 'AI output is not in the correct format. Should start with import statement.';
        } else {
          errorMsg = 'AI output is missing required TypeScript test structure.';
        }

        reject(new Error(errorMsg));
        return;
      }

      // Success - output is valid
      if (endsAbruptly || !hasProperClosing) {
        console.log('✅ Output validation passed with minor warnings');
        console.log('   Code has imports, describe, and it blocks');
        console.log('   Linter and tests will validate further');
      } else {
        console.log('✅ Output validation passed - code structure looks good');
      }

      // CRITICAL: Verify the generated test uses the CORRECT test case ID
      // This prevents AI from copying existing tests with different IDs
      const expectedTestCaseId = testDetails.testCaseId.startsWith('C')
        ? testDetails.testCaseId
        : 'C' + testDetails.testCaseId;

      // Find ALL test case IDs in the generated code
      const allTestCaseIds = [];
      const itBlockMatches = cleanedOutput.matchAll(/it(?:\.only)?\s*\(['"]([^'"]+)['"]/g);
      for (const match of itBlockMatches) {
        const testDescription = match[1];
        const idMatch = testDescription.match(/C\d+/);
        if (idMatch) {
          allTestCaseIds.push(idMatch[0]);
        }
      }

      // Check if there are ANY test case IDs other than the expected one
      const wrongIds = allTestCaseIds.filter(id => id !== expectedTestCaseId);
      if (wrongIds.length > 0) {
        console.error(`\n⚠️  Generated code contains MULTIPLE test case IDs!`);
        console.error(`   Expected only: ${expectedTestCaseId}`);
        console.error(`   But found: ${allTestCaseIds.join(', ')}`);
        console.error(`   Wrong IDs: ${wrongIds.join(', ')}`);

        // Return validation error with details for retry
        resolve({
          isValid: false,
          expectedId: expectedTestCaseId,
          wrongId: wrongIds[0], // Report first wrong ID
          code: cleanedOutput
        });
        return;
      }

      // Check if the expected test case ID appears in the generated code
      if (!allTestCaseIds.includes(expectedTestCaseId)) {
        console.error(`\n⚠️  Expected test case ID ${expectedTestCaseId} not found!`);
        console.error(`   Found IDs: ${allTestCaseIds.join(', ') || 'none'}`);

        // Return validation error with details for retry
        resolve({
          isValid: false,
          expectedId: expectedTestCaseId,
          wrongId: allTestCaseIds[0] || null,
          code: cleanedOutput
        });
        return;
      }

      console.log(`✅ Test case ID verified: ${expectedTestCaseId} (only ID in output)`);
      resolve({ isValid: true, code: cleanedOutput });
    });
  });
}

// ============================================================================
// FILE OPERATIONS
// ============================================================================

/**
 * Finds the correct position to insert a new test case in an existing file
 * Handles files with nested describe blocks by finding the appropriate describe block
 * and the last it() block within that describe to insert after.
 */
function findCorrectInsertPosition(fileContent, testDetails) {
  // Strategy:
  // 1. Find all describe blocks and their ranges (using proper brace counting)
  // 2. Determine which describe block the test belongs to based on testDetails
  // 3. Find the last it() block within that describe block
  // 4. Return the position after that it() block (before the describe's closing })

  const lines = fileContent.split('\n');
  const describeBlocks = [];
  const describeStack = [];

  // Track brace depth to properly match describe blocks
  let globalBraceDepth = 0;

  // Parse the file to find describe blocks with their positions
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    // Match describe declarations
    const describeMatch = trimmedLine.match(/describe\(['"]([^'"]+)['"]/);
    if (describeMatch) {
      describeStack.push({
        name: describeMatch[1],
        startLine: i,
        level: describeStack.length,
        braceDepthAtStart: globalBraceDepth
      });
    }

    // Count braces in this line
    for (const char of line) {
      if (char === '{') globalBraceDepth++;
      if (char === '}') globalBraceDepth--;
    }

    // Check if we've closed a describe block
    // A describe closes when we hit a }); and our brace depth matches what it was when describe started
    if (trimmedLine.match(/^\}\);?\s*(\/\/.*)?$/) && describeStack.length > 0) {
      const topDescribe = describeStack[describeStack.length - 1];
      // Check if this closing brace matches the describe's opening depth
      // After processing this line, globalBraceDepth should equal braceDepthAtStart
      if (globalBraceDepth === topDescribe.braceDepthAtStart) {
        const describe = { ...describeStack.pop(), endLine: i };
        describeBlocks.push(describe);
      }
    }
  }

  if (describeBlocks.length === 0) {
    return -1;
  }

  // Determine which describe block to use based on test context
  let targetDescribe = null;

  // Check if the test is for a specific context (Movie, Series, etc.)
  const testStepsLower = (testDetails.testSteps || '').toLowerCase();
  const mainSectionLower = (testDetails.mainSection || '').toLowerCase();
  const subSectionLower = (testDetails.subSection || '').toLowerCase();

  // Match patterns like "Movie Details Page", "Series Details Page", etc.
  for (const describe of describeBlocks) {
    const describeNameLower = describe.name.toLowerCase();

    // Prioritize more specific (deeper nested) describe blocks
    if (subSectionLower && describeNameLower.includes(subSectionLower.toLowerCase())) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
      }
    } else if (describeNameLower.includes('movie') && (testStepsLower.includes('movie') || mainSectionLower.includes('movie'))) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
      }
    } else if (describeNameLower.includes('series') && (testStepsLower.includes('series') || mainSectionLower.includes('series'))) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
      }
    } else if (describeNameLower.includes(mainSectionLower) && mainSectionLower !== '') {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
      }
    }
  }

  // If no specific match, use the deepest nested describe block (most specific)
  if (!targetDescribe) {
    const sortedByLevel = [...describeBlocks].sort((a, b) => b.level - a.level); // Descending
    targetDescribe = sortedByLevel[0];
  }

  // Find the last it() block within the target describe block
  // Use a more robust approach: scan line by line to find it() blocks
  const describeStartLine = targetDescribe.startLine;
  const describeEndLine = targetDescribe.endLine;

  let lastItEndLine = -1;
  let braceCount = 0;
  let inItBlock = false;

  for (let i = describeStartLine + 1; i < describeEndLine; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    // Detect start of an it() block
    if (trimmedLine.match(/^it(?:\.only)?\s*\(/)) {
      inItBlock = true;
      braceCount = 0;
    }

    if (inItBlock) {
      // Count braces to find the end of the it() block
      for (const char of line) {
        if (char === '{') braceCount++;
        if (char === '}') braceCount--;
      }

      // Check if this line ends the it() block (ends with });)
      if (braceCount === 0 && trimmedLine.match(/\}\);?\s*(\/\/.*)?$/)) {
        lastItEndLine = i;
        inItBlock = false;
      }
    }
  }

  if (lastItEndLine !== -1) {
    // Insert after the last it() block (after its closing });)
    // Calculate the position at the end of that line INCLUDING the newline
    let insertPos = 0;
    for (let i = 0; i <= lastItEndLine; i++) {
      insertPos += lines[i].length + 1; // +1 for the newline character
    }
    return insertPos;
  } else {
    // No it() blocks found, insert before the closing }); of the describe
    // Insert just before the describe's closing });
    let insertPos = 0;
    for (let i = 0; i < describeEndLine; i++) {
      insertPos += lines[i].length + 1; // +1 for the newline character
    }
    return insertPos;
  }
}

function saveTest(generatedTest, testDetails) {
  // Use the second part of subSection (after first ›) for filename, or last part if only 2 parts
  let sectionName;
  if (testDetails.subSection && testDetails.subSection.includes('›')) {
    const parts = testDetails.subSection.split('›').map(p => p.trim());
    // If we have 3+ parts, use the second one (index 1)
    // Example: "Playback › Browse While Watching › V4 › Control" → "Browse While Watching"
    // If we have exactly 2 parts, use the last one (index 1)
    // Example: "Details Page › Series Details Page" → "Series Details Page"
    sectionName = parts.length >= 2 ? parts[1] : parts[parts.length - 1];
  } else if (testDetails.subSection) {
    sectionName = testDetails.subSection;
  } else {
    // Fallback to mainSection
    sectionName = testDetails.mainSection || testDetails.testName;
  }

  const fileName = sectionName
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '-');

  // Try to find an existing file that might match
  const testsDir = path.join(projectRoot, 'js/automated-tests/tests');
  let filePath = path.join(testsDir, `${fileName}.ts`);

  // If exact file doesn't exist, search for similar files
  if (!fs.existsSync(filePath)) {
    const allTestFiles = fs.readdirSync(testsDir).filter(f => f.endsWith('.ts'));

    // Extract key words from section name (remove version numbers, parentheses content, etc.)
    const keyWords = sectionName
      .toLowerCase()
      .replace(/\(.*?\)/g, '') // Remove parentheses content
      .replace(/v\d+/g, '')     // Remove version numbers
      .replace(/aka.*?$/i, '')  // Remove "aka XXX"
      .trim()
      .split(/\s+/)
      .filter(w => w.length > 3); // Only keep words longer than 3 chars

    // Find best matching file
    let bestMatch = null;
    let maxMatches = 0;

    for (const existingFile of allTestFiles) {
      const existingFileName = existingFile.replace('.ts', '');
      let matchCount = 0;

      // Count how many key words are in the existing filename
      for (const word of keyWords) {
        if (existingFileName.includes(word)) {
          matchCount++;
        }
      }

      // If we found a better match, update
      if (matchCount > maxMatches && matchCount >= Math.min(2, keyWords.length)) {
        maxMatches = matchCount;
        bestMatch = existingFile;
      }
    }

    if (bestMatch) {
      console.log(`📁 Found similar existing file: ${bestMatch}`);
      console.log(`   Original section: "${sectionName}"`);
      console.log(`   Matched ${maxMatches} key words`);
      filePath = path.join(testsDir, bestMatch);
    } else {
      console.log(`📝 No matching file found, will create: ${fileName}.ts`);
    }
  }

  // Ensure directory exists
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  // Check if file already exists
  if (fs.existsSync(filePath)) {
    console.log(`📄 File exists: ${fileName}.ts - appending new test case`);

    // Read existing file
    const existingContent = fs.readFileSync(filePath, 'utf8');

    // Extract the new test case (just the it() block, not any surrounding describe blocks)
    // Look for the it() block within the generated test
    // Handle both cases: full file with describe OR just an it() block

    const generatedLines = generatedTest.split('\n');

    // Find the first it() line
    let itStartLine = -1;
    for (let i = 0; i < generatedLines.length; i++) {
      if (generatedLines[i].trim().match(/^it(?:\.only)?\s*\(/)) {
        itStartLine = i;
        break;
      }
    }

    if (itStartLine === -1) {
      console.error('⚠️  Could not find it() block in generated test.');
      console.error('🛑 SAFETY: Refusing to overwrite existing file with tests');
      console.error('💡 Please check the generated test structure');
      // Don't overwrite - keep existing file intact
      return filePath;
    } else {
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
        if (foundOpeningBrace && braceCount === 0 && line.trim().match(/\}\);?\s*(\/\/.*)?$/)) {
          itEndLine = i;
          break;
        }
      }

      if (itEndLine === -1) {
        console.error('⚠️  Could not find closing of it() block.');
        console.error('🛑 SAFETY: Refusing to overwrite existing file with tests');
        console.error('💡 Please check the generated test structure');
        // Don't overwrite - keep existing file intact
        return filePath;
      }

      // Extract just the it() block (include any comment lines immediately before it)
      let extractStartLine = itStartLine;

      // Check if there's a comment line (Test Rail Link) immediately before the it()
      if (itStartLine > 0 && generatedLines[itStartLine - 1].trim().startsWith('//')) {
        extractStartLine = itStartLine - 1;
      }

      const itBlockLines = generatedLines.slice(extractStartLine, itEndLine + 1);
      let newTestCase = itBlockLines.join('\n');

      console.log(`📝 Extracted it() block (lines ${extractStartLine + 1} to ${itEndLine + 1}, ${itBlockLines.length} lines total):`);
      console.log('   First line:', itBlockLines[0].trim().substring(0, 80));
      console.log('   Last line:', itBlockLines[itBlockLines.length - 1].trim().substring(0, 80));

      // Add .only to the test case so it can be run in isolation
      newTestCase = newTestCase.replace(/(\s+it)\(/, '$1.only(');
      console.log(`✅ Added .only to new test case for isolated execution`);

      // Find the correct describe block to insert the test
      // Strategy: Find describe blocks and their closing positions, then pick the appropriate one
      const insertPosition = findCorrectInsertPosition(existingContent, testDetails);

      if (insertPosition === -1) {
        console.error('⚠️  Could not find appropriate describe block in existing file.');
        console.error('🛑 SAFETY: Refusing to overwrite existing file with tests');
        console.error('💡 File may have unusual structure or no describe blocks');
        // Don't overwrite - keep existing file intact
      } else {
        // Insert new test case before the closing });
        const updatedContent =
          existingContent.substring(0, insertPosition) +
          '\n  ' + newTestCase + '\n' +
          existingContent.substring(insertPosition);

        fs.writeFileSync(filePath, updatedContent);
        console.log(`✅ Added new test case to existing file with .only`);

        // Verify tests weren't lost
        const afterTestCount = (updatedContent.match(/\sit\(/g) || []).length + (updatedContent.match(/\sit\.only\(/g) || []).length;
        const beforeTestCount = (existingContent.match(/\sit\(/g) || []).length + (existingContent.match(/\sit\.only\(/g) || []).length;
        console.log(`📊 Test count: ${beforeTestCount} → ${afterTestCount} (expected: ${beforeTestCount + 1})`);

        if (afterTestCount < beforeTestCount) {
          console.error('🚨 ERROR: Tests were lost during save! Rolling back...');
          fs.writeFileSync(filePath, existingContent); // Restore original
          console.error('✅ Restored original file');
        }
      }
    }
  } else {
    console.log(`📝 Creating new file: ${fileName}.ts`);
    fs.writeFileSync(filePath, generatedTest);
  }

  console.log(`💾 Test saved: ${filePath}`);
  return filePath;
}

// ============================================================================
// LINTING
// ============================================================================

async function runLinter(filePath) {
  return new Promise((resolve) => {
    console.log('🔍 Running linter and TypeScript checks...');

    if (!fs.existsSync(filePath)) {
      console.log('❌ File does not exist:', filePath);
      resolve();
      return;
    }

    const fileContent = fs.readFileSync(filePath, 'utf8');
    if (fileContent.trim().length === 0) {
      console.log('❌ File is empty');
      resolve();
      return;
    }

    // Run ESLint with auto-fix
    // @ts-ignore
    exec(`npx eslint ${filePath} --fix`, (eslintError, eslintStdout, eslintStderr) => {
      if (eslintError) {
        console.log('\n⚠️  ESLint found issues:\n');
        console.log('━'.repeat(60));
        // Both stdout and stderr can contain error info
        const eslintOutput = (eslintStdout + '\n' + eslintStderr).trim();
        console.log(eslintOutput);
        console.log('━'.repeat(60));
        console.log('');
        resolve({ hasErrors: true, errors: eslintOutput, type: 'eslint' });
        return;
      }

      console.log('✅ ESLint passed');

      // Run TypeScript check with project config
      // @ts-ignore
      exec(`npx tsc --noEmit --project ${projectRoot}/tsconfig.json`, (tscError, tscStdout, tscStderr) => {
        if (tscError) {
          // TypeScript errors usually go to stdout
          const tscOutput = (tscStdout + '\n' + tscStderr).trim();

          // First, check if the generated file is mentioned in the output
          const lines = tscOutput.split('\n');
          const fileErrorLines = [];

          // Find all lines that reference the generated file
          for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.includes(filePath)) {
              // Found an error in our file - capture this line and the next few lines for context
              fileErrorLines.push(line);
              // Capture up to 3 following lines that might be part of the error message
              for (let j = 1; j <= 3 && i + j < lines.length; j++) {
                const nextLine = lines[i + j];
                // Stop if we hit another file path or empty line
                if (nextLine.trim().match(/^[a-zA-Z\/\.].*\(\d+,\d+\):/) || nextLine.trim() === '') {
                  break;
                }
                fileErrorLines.push(nextLine);
              }
            }
          }

          // If there are file-specific errors, report them
          if (fileErrorLines.length > 0) {
            console.log('\n⚠️  TypeScript found issues in generated test:\n');
            console.log('━'.repeat(60));
            console.log(fileErrorLines.join('\n'));
            console.log('━'.repeat(60));
            console.log('');
            resolve({ hasErrors: true, errors: fileErrorLines.join('\n'), type: 'typescript' });
            return;
          }

          // If no file-specific errors, check if there are project-level errors
          const hasProjectErrors = tscOutput.includes('error TS');
          if (hasProjectErrors) {
            console.log('\n⚠️  TypeScript found project-level issues (not in generated test)');
            console.log('💡 Generated test is OK, but project has configuration issues');
            console.log('✅ Skipping TypeScript errors - they are not in the generated test');
            resolve({ hasErrors: false });
            return;
          }
        }

        console.log('✅ TypeScript check passed');
        console.log('🎉 All checks passed!');
        resolve({ hasErrors: false });
      });
    });
  });
}

async function fixLintErrors(filePath, lintResult) {
  console.log('\n🤖 Using AI to fix lint/type errors...');

  const fileContent = fs.readFileSync(filePath, 'utf8');
  const instructions = fs.readFileSync(path.join(projectRoot, '.claude/instructions.md'), 'utf8');

  const promptContent = buildLintFixPrompt(fileContent, lintResult, instructions);

  // @ts-ignore
  return new Promise((resolve, reject) => {
    // Write prompt to a temporary file to avoid shell escaping issues
    const tmpFile = path.join(projectRoot, '.claude-lint-fix-tmp');
    fs.writeFileSync(tmpFile, promptContent);

    // Add test files for pattern learning, but AI must NOT copy test case IDs
    const claudeCommand = `cat ${tmpFile} | claude --print --add-dir js/automated-tests --add-dir automated-tests-config --add-dir .claude`;

    console.log('⏳ Calling Claude to fix errors...');

    // @ts-ignore
    exec(claudeCommand, { cwd: projectRoot, timeout: CLAUDE_TIMEOUT }, (error, stdout, stderr) => {
      // Clean up temp file
      try {
        fs.unlinkSync(tmpFile);
      } catch (e) {
        // Ignore cleanup errors
      }
      if (error) {
        console.error('\n❌ Claude execution failed:', error.message);
        resolve(false);
        return;
      }

      console.log('✅ Claude generated fixes');

      const fixedCode = cleanGeneratedCode(stdout);

      // STRICT VALIDATION: Ensure output is actual code
      if (!fixedCode.trim().startsWith('import')) {
        console.error('⚠️  Fixed code does not start with import statement');
        console.error('Output preview:', fixedCode.substring(0, 200));
        resolve(false);
        return;
      }

      if (!fixedCode.includes('import') || !fixedCode.includes('describe')) {
        console.log('⚠️  Generated output may not be valid TypeScript test code');
        resolve(false);
        return;
      }

      // Check for explanatory text
      const explanationIndicators = ['I can see that', 'Looking at', 'The test already exists', 'I\'ve fixed'];
      for (const phrase of explanationIndicators) {
        if (fixedCode.includes(phrase)) {
          console.error('⚠️  Fixed code contains explanatory text instead of pure code');
          console.error(`Found phrase: "${phrase}"`);
          resolve(false);
          return;
        }
      }

      // Ensure .only is added to the correct test for isolation
      const finalCode = addOnlyToSpecificTest(fixedCode);

      fs.writeFileSync(filePath, finalCode);
      console.log('✅ AI applied fixes to file');
      resolve(true);
    });
  });
}

// ============================================================================
// TEST EXECUTION & RETRY
// ============================================================================

// @ts-ignore
function addOnlyToTest(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');

  // Add .only to the first it() statement
  const updatedContent = content.replace(
    /(\s+it)\(/,
    '$1.only('
  );

  // Check if .only was added
  if (updatedContent === content) {
    console.log('⚠️  Could not add .only to test - pattern not found');
    return false;
  }

  fs.writeFileSync(filePath, updatedContent);
  console.log('✅ Added .only to test');
  return true;
}

// @ts-ignore
function removeOnlyFromTest(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');

  // Remove .only from it.only()
  const updatedContent = content.replace(
    /(\s+it)\.only\(/g,
    '$1('
  );

  fs.writeFileSync(filePath, updatedContent);
  console.log('✅ Removed .only from test');
}

async function runGeneratedTest(filePath) {
  // @ts-ignore
  return new Promise((resolve, reject) => {
    console.log('\n🧪 Running generated test...');

    // Run test with proper mocha configuration (ts-node and include.ts)
    // This matches the mocha config in package.json
    const testCommand = `cd ${projectRoot} && RERUN_AUTOMATED_TESTS=true npx mocha --require ts-node/register --require ./js/automated-tests/include.ts --timeout 120000 ${filePath}`;

    exec(testCommand, {
      timeout: 300000,
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer for large output
      env: { ...process.env, RERUN_AUTOMATED_TESTS: 'true' }
    }, (error, stdout, stderr) => {
      const output = stdout + stderr;

      // Check if tests actually ran by looking for mocha output
      const testsRanSuccessfully = output.includes('passing') || output.includes('failing');

      if (!testsRanSuccessfully && !error) {
        console.log('⚠️  Tests may not have run properly');
        resolve({ success: false, output: output, error: 'Tests did not execute' });
        return;
      }

      if (error) {
        // Check if it's a test failure vs a command failure
        const isTestFailure = output.includes('failing') || output.includes('Error:');
        resolve({
          success: false,
          output: output,
          error: error.message,
          isTestFailure: isTestFailure
        });
      } else {
        resolve({ success: true, output: output });
      }
    });
  });
}

// ============================================================================
// ERROR CATEGORIZATION
// ============================================================================

/**
 * LLM-based error categorization (NEW - replaces 100+ lines of regex)
 * Uses Claude to intelligently categorize test errors
 */
async function categorizeErrorWithLLM(errorOutput) {
  const { callClaudeForErrorCategorization } = require('./lib/llm-client');

  console.log('🤖 Using LLM for error categorization...');

  try {
    const result = await callClaudeForErrorCategorization(errorOutput);

    if (result) {
      console.log(`   Category: ${result.type}`);
      console.log(`   Confidence: ${result.confidence}`);
      console.log(`   Reasoning: ${result.reasoning}`);

      return {
        type: result.type,
        description: result.description,
        pattern: result.reasoning,
        shouldFix: result.shouldFix
      };
    } else {
      console.log('   LLM categorization failed, falling back to regex...');
      return categorizeErrorLegacy(errorOutput);
    }
  } catch (error) {
    console.error(`   LLM categorization error: ${error.message}`);
    console.log('   Falling back to regex-based categorization...');
    return categorizeErrorLegacy(errorOutput);
  }
}

/**
 * Legacy regex-based error categorization (fallback)
 */
function categorizeErrorLegacy(errorOutput) {
  const categories = [];

  // Empty string assertion errors (fixable - timing issue)
  if (errorOutput.match(/expected\s+['"]['"]?\s+to\s+(equal|match|contain)/i) ||
    errorOutput.match(/expected\s+['"]['"]?\s+to\s+be/i)) {
    categories.push({
      type: 'EMPTY_STRING',
      description: 'Field not populated yet - needs wait before assertion',
      pattern: 'Empty string assertion',
      shouldFix: true
    });
  }

  // Wrong value errors (NOT fixable - requires manual review)
  // Example: expected 'Add to My List' to equal 'Add to Queue'
  if (errorOutput.match(/expected\s+['"](?!['"])[^'"]+['"]\s+to\s+(equal|match|contain)\s+['"]/i)) {
    categories.push({
      type: 'WRONG_VALUE',
      description: 'Element has unexpected value - could be outdated test case, app bug, or intentional change',
      pattern: 'Value mismatch',
      shouldFix: false
    });
  }

  // Visibility errors (fixable - timing issue)
  if (errorOutput.match(/expected\s+false\s+to\s+equal\s+true/i) &&
    errorOutput.match(/visible/i)) {
    categories.push({
      type: 'VISIBILITY',
      description: 'Element not visible yet - needs visibility wait',
      pattern: 'Visibility assertion failed',
      shouldFix: true
    });
  }

  // Undefined/null errors (fixable - timing issue)
  if (errorOutput.match(/expected\s+undefined\s+to\s+(exist|equal|not\.be\.undefined)/i) ||
    errorOutput.match(/Cannot read propert(y|ies) of undefined/i)) {
    categories.push({
      type: 'UNDEFINED',
      description: 'Element or property not loaded yet - needs wait',
      pattern: 'Undefined value',
      shouldFix: true
    });
  }

  // Timeout errors (fixable - may need longer wait or prerequisites)
  if (errorOutput.match(/Timed out waiting/i) ||
    errorOutput.match(/timeout of \d+ms exceeded/i)) {
    categories.push({
      type: 'TIMEOUT',
      description: 'Wait condition not met in time - check prerequisites',
      pattern: 'Timeout error',
      shouldFix: true
    });
  }

  // Focus errors (fixable - timing issue)
  if (errorOutput.match(/focus/i) && errorOutput.match(/expected/i)) {
    categories.push({
      type: 'FOCUS',
      description: 'Element focus issue - verify focus chain',
      pattern: 'Focus assertion failed',
      shouldFix: true
    });
  }

  // Grid/list content errors (fixable - timing issue)
  if (errorOutput.match(/grid|rowlist|list/i) &&
    (errorOutput.match(/content|items|children/i))) {
    categories.push({
      type: 'GRID_CONTENT',
      description: 'Grid content not loaded yet - needs content wait',
      pattern: 'Grid/List content not loaded',
      shouldFix: true
    });
  }

  // Player state errors (fixable - timing issue)
  if (errorOutput.match(/player|playback|playing|paused|buffering/i)) {
    categories.push({
      type: 'PLAYER_STATE',
      description: 'Video player state issue - needs state wait',
      pattern: 'Player state error',
      shouldFix: true
    });
  }

  // Navigation errors (fixable - timing issue)
  if (errorOutput.match(/navigation|navigate|page|screen/i) &&
    errorOutput.match(/not found|failed/i)) {
    categories.push({
      type: 'NAVIGATION',
      description: 'Navigation failed or screen not loaded',
      pattern: 'Navigation error',
      shouldFix: true
    });
  }

  // Return primary category or unknown
  return categories.length > 0 ? categories[0] : {
    type: 'UNKNOWN',
    description: 'Unrecognized error pattern',
    pattern: 'Unknown error',
    shouldFix: false
  };
}

/**
 * Main categorizeError function - uses LLM by default
 */
async function categorizeError(errorOutput, useLLM = true) {
  if (useLLM) {
    return await categorizeErrorWithLLM(errorOutput);
  } else {
    return categorizeErrorLegacy(errorOutput);
  }
}

// ============================================================================
// LEARNED FIXES LOOKUP
// ============================================================================

// @ts-ignore
async function searchLearnedFixes(errorCategory, errorOutput) {
  const learnedFixesPath = path.join(projectRoot, 'ai-automation/learned-fixes.md');

  if (!fs.existsSync(learnedFixesPath)) {
    return null;
  }

  const learnedFixesContent = fs.readFileSync(learnedFixesPath, 'utf8');

  // Check if there are any recorded fixes (not just template)
  if (!learnedFixesContent.includes('### Fix #')) {
    return null;
  }

  // Look for fixes matching the error category
  const categoryPattern = new RegExp(`\\*\\*Error Type:\\*\\*[^\\n]*${errorCategory.type}`, 'i');

  if (categoryPattern.test(learnedFixesContent)) {
    console.log(`✅ Found similar fix pattern in learned-fixes.md for ${errorCategory.type}`);
    return {
      found: true,
      category: errorCategory.type,
      content: learnedFixesContent
    };
  }

  return null;
}

// ============================================================================
// AI-POWERED ERROR FIXING
// ============================================================================

async function fixTestWithAI(filePath, errorOutput, errorCategory, learnedFix, attempt) {
  console.log(`\n🤖 Using AI to analyze and fix ${errorCategory.type} error...`);
  console.log(`📋 Error: ${errorCategory.description}`);

  const fileContent = fs.readFileSync(filePath, 'utf8');
  const instructions = fs.readFileSync(path.join(projectRoot, '.claude/instructions.md'), 'utf8');

  // Extract the relevant test case that's failing
  const failingTestMatch = errorOutput.match(/\d+\)\s+(.+?):/);
  const failingTestName = failingTestMatch ? failingTestMatch[1] : 'unknown test';

  // Extract test case ID from the failing test name (e.g., "C535817 - Test Name")
  const testCaseIdMatch = failingTestName.match(/^(C\d+)/);
  const testCaseId = testCaseIdMatch ? testCaseIdMatch[1] : null;

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
  switch (errorCategory.type) {
    case 'EMPTY_STRING':
      promptContent += `\n\nFIX GUIDANCE:
- Add retryWithTimeOut() before assertions to wait for field to populate
- Example: await testUtils.retryWithTimeOut(async () => { const element = await testUtils.getNodeForElement('name'); expect(element.text).to.equal('expected'); });
- Never assert immediately after getting an element
`;
      break;
    case 'VISIBILITY':
      promptContent += `\n\nFIX GUIDANCE FOR VISIBILITY ERRORS:

⛔ WRONG PATTERN - DO NOT USE:
await testUtils.retryWithTimeOut(async () => {
  const element = await testUtils.getNodeForElement('elementName');
  expect(element.visible).to.equal(true);
}, 10000, 'Error message');

✅ CORRECT PATTERN - USE THIS:
await testUtils.waitForElementToShowOnScreen('elementName', 'Element not visible', 10000);

More examples:
- await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown', 10000);
- await testUtils.waitForElementToShowOnScreen('transportButtons', 'Transport not shown', 10000);
- Ensure screen is fully loaded before checking visibility
`;
      break;
    case 'UNDEFINED':
      promptContent += `\n\nFIX GUIDANCE:
- Add wait for element or property to exist
- Check if element needs to be loaded first (e.g., waitForGridContentToLoad)
- Use retryWithTimeOut to wait for property to be defined
`;
      break;
    case 'TIMEOUT':
      promptContent += `\n\nFIX GUIDANCE:
- Check if prerequisites are met (correct screen, element loaded, etc.)
- Increase timeout if operation legitimately takes longer
- Verify the wait condition is correct
- Ensure proper navigation before waiting
`;
      break;
    case 'FOCUS':
      promptContent += `\n\nFIX GUIDANCE:
- Use waitForElementToHaveFocus() before focus assertions
- Verify element is in the focus chain
- Check if navigation completed before focus check
`;
      break;
    case 'GRID_CONTENT':
      promptContent += `\n\nFIX GUIDANCE:
- Use waitForGridContentToLoad() before accessing grid items
- Ensure rowList or grid is focused and loaded
- Wait for content field to populate
`;
      break;
    case 'PLAYER_STATE':
      promptContent += `\n\nFIX GUIDANCE:
- Use waitForPlayerStateToEqual(elementId, state, timeout) to wait for specific player states
- IMPORTANT: Player states ('playing', 'paused', 'buffering') are NOT elements!
- CORRECT: await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
  - First param: element ID like 'videoPlayerScreen'
  - Second param: state like 'playing', 'paused', 'buffering'
- WRONG: Do NOT try to find an element named 'playing'
- Add waits after playback commands (play, pause)
- Common states: 'playing', 'paused', 'buffering', 'stopped'
`;
      break;
  }

  promptContent += `

<critical_note>
IMPORTANT: Player states are NOT elements!
- 'playing', 'paused', 'buffering', 'stopped' are PLAYER STATES, not DOM elements
- waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000) is CORRECT
  - First param: element ID (e.g., 'videoPlayerScreen')
  - Second param: state (e.g., 'playing')
- DO NOT try to find an element named 'playing' - it doesn't exist!
</critical_note>

<output_requirements>
CRITICAL FORMAT RULES - YOUR RESPONSE MUST FOLLOW THESE EXACTLY:

1. Return the COMPLETE FIXED FILE with ALL tests (not just the failing one)
2. Your ENTIRE response must be ONLY valid TypeScript code
3. NO markdown code fences (no \`\`\`typescript or \`\`\`)
4. NO explanatory text before, after, or within the code
5. NO comments like "I've fixed:" or "The issue was:"
6. Start IMMEDIATELY with the first import statement
7. Include ALL existing tests in the file - only fix the one that's failing
8. Preserve all other tests exactly as they are

CORRECT OUTPUT (full file with all tests):
import { expect } from 'chai';
import { ecp, utils } from 'roku-test-automation';
import { testUtils } from '../test-utils';

describe('Test Suite', function () {
  // Test 1 (existing - keep as is)
  it('existing test 1', async () => { ... });

  // Test 2 (FIXED - this is the failing one)
  it('failing test', async () => {
    // Your fixes here
  });

  // Test 3 (existing - keep as is)
  it('existing test 3', async () => { ... });
});

INCORRECT OUTPUT (DO NOT DO THIS):
Here's the fixed test:
\`\`\`typescript
it('failing test', async () => { ... });
\`\`\`

YOUR FIRST LINE MUST BE: import
</output_requirements>`;

  // @ts-ignore
  return new Promise((resolve, reject) => {
    const tmpFile = path.join(projectRoot, '.claude-error-fix-tmp');
    fs.writeFileSync(tmpFile, promptContent);

    // Add test files for pattern learning, but AI must NOT copy test case IDs
    const claudeCommand = `cat ${tmpFile} | claude --print --add-dir js/automated-tests --add-dir automated-tests-config --add-dir .claude`;

    console.log('⏳ Claude is analyzing the error and generating fix...');

    // @ts-ignore
    exec(claudeCommand, { cwd: projectRoot, timeout: CLAUDE_TIMEOUT }, (error, stdout, stderr) => {
      try {
        fs.unlinkSync(tmpFile);
      } catch (e) {
        // Ignore cleanup errors
      }

      if (error) {
        console.error('\n❌ Claude execution failed:', error.message);
        resolve(false);
        return;
      }

      console.log('✅ Claude generated fix');

      const fixedCode = cleanGeneratedCode(stdout);

      if (!fixedCode.includes('import') || !fixedCode.includes('describe')) {
        console.log('⚠️  Generated output may not be valid TypeScript test code');
        resolve(false);
        return;
      }

      // SAFETY CHECK: Ensure we're not losing tests
      // Count it() blocks in original vs fixed code
      const originalContent = fs.readFileSync(filePath, 'utf8');
      const originalTestCount = (originalContent.match(/\sit\(/g) || []).length + (originalContent.match(/\sit\.only\(/g) || []).length;
      const fixedTestCount = (fixedCode.match(/\sit\(/g) || []).length + (fixedCode.match(/\sit\.only\(/g) || []).length;

      if (fixedTestCount < originalTestCount) {
        console.error(`\n⚠️  SAFETY CHECK FAILED: AI fix would delete tests!`);
        console.error(`   Original file has ${originalTestCount} test(s)`);
        console.error(`   Fixed code has ${fixedTestCount} test(s)`);
        console.error(`   🛑 Refusing to overwrite file to prevent data loss`);
        console.error(`   💡 The AI may have returned only the failing test instead of the full file`);
        resolve(false);
        return;
      }

      console.log(`✅ Safety check passed: ${fixedTestCount} test(s) preserved`);

      // Ensure .only is added to the correct test for isolation
      // Use the test case ID to target the specific test that's being fixed
      const finalCode = addOnlyToSpecificTest(fixedCode, testCaseId);

      fs.writeFileSync(filePath, finalCode);
      console.log(`✅ Applied AI fix for ${errorCategory.type} error`);
      resolve(true);
    });
  });
}

function extractMissingElement(errorOutput) {
  // Look for "Could not find element named xxx" pattern (most common)
  const couldNotFindMatch = errorOutput.match(/Could not find element named (\w+)/i);
  if (couldNotFindMatch) {
    return couldNotFindMatch[1];
  }

  // Look for "Could not get node for element 'xxx'" pattern
  const couldNotGetNodeMatch = errorOutput.match(/Could not get node for element ['"]([^'"]+)['"]/i);
  if (couldNotGetNodeMatch) {
    return couldNotGetNodeMatch[1];
  }

  // Look for "Element 'xxx' not found" pattern
  const elementNotFoundMatch = errorOutput.match(/Element '([^']+)' not found/);
  if (elementNotFoundMatch) {
    return elementNotFoundMatch[1];
  }

  // Look for getNodeForElement errors
  const getNodeMatch = errorOutput.match(/getNodeForElement\('([^']+)'\)/);
  if (getNodeMatch) {
    return getNodeMatch[1];
  }

  return null;
}

function extractElementFromVisibilityError(errorOutput) {
  // Look for visibility error patterns that include element names

  // Pattern 1: "Could not get node for element 'elementName'" - most direct
  const couldNotGetNodeMatch = errorOutput.match(/Could not get node for element ['"]([^'"]+)['"]/i);
  if (couldNotGetNodeMatch) {
    return couldNotGetNodeMatch[1];
  }

  // Pattern 2: "getNodeForElement('elementName').visible" in stack trace
  const getNodeMatch = errorOutput.match(/getNodeForElement\(['"]([^'"]+)['"]\)[^\n]*\.visible/i);
  if (getNodeMatch) {
    return getNodeMatch[1];
  }

  // Pattern 3: Any "getNodeForElement('elementName')" call in the error
  const anyGetNodeMatch = errorOutput.match(/getNodeForElement\(['"]([^'"]+)['"]\)/);
  if (anyGetNodeMatch) {
    return anyGetNodeMatch[1];
  }

  // Pattern 4: "waitForElementToShowOnScreen('elementName'," in stack trace
  const waitForElementMatch = errorOutput.match(/waitForElementToShowOnScreen\(['"]([^'"]+)['"]/i);
  if (waitForElementMatch) {
    return waitForElementMatch[1];
  }

  // Pattern 5: "waitForElementToFullyShowOnScreen('elementName'," in stack trace
  const waitForFullyMatch = errorOutput.match(/waitForElementToFullyShowOnScreen\(['"]([^'"]+)['"]/i);
  if (waitForFullyMatch) {
    return waitForFullyMatch[1];
  }

  // Pattern 6: Look for element name in test context (test name or description)
  // Example: "1) C535817 - Verify detailScreenTitle is visible:"
  const testNameMatch = errorOutput.match(/\d+\)\s+C?\d+\s*-\s*[^:]*?(\w+)\s+is\s+visible/i);
  if (testNameMatch) {
    return testNameMatch[1];
  }

  // Pattern 7: Look in the actual error lines for element references
  // This catches cases where element is mentioned in surrounding context
  const lines = errorOutput.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // If this line has visibility error
    if (line.match(/expected\s+false\s+to\s+equal\s+true/i) && line.match(/visible/i)) {
      // Look at previous lines for getNodeForElement
      for (let j = Math.max(0, i - 5); j < i; j++) {
        const prevLine = lines[j];
        const elementMatch = prevLine.match(/getNodeForElement\(['"]([^'"]+)['"]\)/);
        if (elementMatch) {
          return elementMatch[1];
        }
      }
    }
  }

  return null;
}

async function findAndAddMissingElement(elementName) {
  console.log(`\n🔍 Attempting to find and add missing element: ${elementName}`);
  console.log('💡 Note: The test has already navigated to the screen where this element should exist');
  console.log('⏳ Waiting 2 seconds for screen to fully render...');

  // Wait a bit to ensure screen is fully rendered after test failure
  await new Promise(resolve => setTimeout(resolve, 2000));

  try {
    const { findElementHierarchy } = require('./dynamic-hierarchy-finder.js');
    const fs = require('fs');
    const path = require('path');

    // Try to extract context and base element name
    // Example: "detailScreenTitle" -> context="detailScreen", baseName="Title"
    let context = null;
    let baseElementName = elementName;

    // Common screen contexts
    const screenContexts = ['detailScreen', 'homeScreen', 'tvShowsScreen', 'espanolScreen', 'myStuffScreen', 'settingsScreen'];
    for (const screenContext of screenContexts) {
      if (elementName.startsWith(screenContext)) {
        context = screenContext;
        baseElementName = elementName.substring(screenContext.length);
        console.log(`📍 Detected context: ${context}`);
        console.log(`📍 Base element name: ${baseElementName}`);
        break;
      }
    }

    // Find the element using hierarchy finder with context
    console.log(`🔍 Searching for: ${baseElementName}`);
    console.log(`📍 Context: ${context || 'none detected'}`);
    const result = await findElementHierarchy(baseElementName, true, context);

    if (!result.found) {
      console.log(`❌ Element '${baseElementName}' not found on current screen`);

      // Show suggestions if available and ask AI to choose
      if (result.suggestions && result.suggestions.length > 0) {
        console.log(`\n🤖 Asking AI to analyze ${result.suggestions.length} visible elements...`);
        if (context) {
          console.log(`📍 Using screen context: ${context}`);
        }

        // Call Claude API to analyze (now using centralized LLM client with context)
        const aiResponse = await callClaudeForElementMatching(baseElementName, result.suggestions, context);

        if (aiResponse && aiResponse.elementName) {
          console.log(`\n🎯 AI selected: ${aiResponse.elementName}`);
          console.log(`   Confidence: ${aiResponse.confidence}`);
          console.log(`   Reasoning: ${aiResponse.reasoning}`);

          console.log(`\n🔄 Attempting to use AI-suggested element: ${aiResponse.elementName}`);
          const suggestionResult = await findElementHierarchy(aiResponse.elementName, true, context);

          if (suggestionResult.found) {
            console.log(`✅ Successfully found AI-suggested element!`);
            result.found = true;
            result.path = suggestionResult.path;
            result.xpath = suggestionResult.xpath;
            result.usedSuggestion = aiResponse.elementName;
            result.aiReasoning = aiResponse.reasoning;
          } else {
            console.log(`❌ Could not find hierarchy for suggested element`);
            return false;
          }
        } else {
          console.log(`\n❌ AI could not find a suitable match`);
          console.log(`   Reasoning: ${aiResponse?.reasoning || 'Unknown'}`);
          return false;
        }
      } else {
        console.log('💡 Tip: Make sure the test navigated to the correct screen before failing');
        return false;
      }
    }

    // Check if element already exists and update it, or add new
    const elementsFilePath = path.join(projectRoot, 'automated-tests-config', 'elements.ts');
    const elementsContent = fs.readFileSync(elementsFilePath, 'utf8');
    // Match element definition including optional trailing comma
    const elementExistsRegex = new RegExp(`^(\\s*)${elementName}:\\s*\\{[^}]*\\},?`, 'm');
    const elementExistsMatch = elementsContent.match(elementExistsRegex);

    if (elementExistsMatch) {
      console.log(`ℹ️  Element '${elementName}' already exists in elements.ts - updating xpath...`);

      // Update the existing element's keyPath
      const indent = elementExistsMatch[1].replace(/\n/g, ''); // Remove newlines from indent
      let comment = `/** ${elementName} (auto-updated) */`;
      if (result.usedSuggestion) {
        comment = `/** ${elementName} (auto-updated from ${result.usedSuggestion}) */`;
        console.log(`\nℹ️  Note: Element was automatically mapped from suggested element: ${result.usedSuggestion}`);
        console.log(`   Original: ${elementName} (not found in DOM)`);
        console.log(`   Mapped to: ${result.usedSuggestion} (found in DOM)`);
      }

      const updatedEntry = `${indent}${comment}\n${indent}${elementName}: {\n${indent}  keyPath: '${result.xpath}',\n${indent}},`;

      // Replace the old element definition with the updated one
      const updatedContent = elementsContent.replace(elementExistsRegex, updatedEntry);
      fs.writeFileSync(elementsFilePath, updatedContent);

      console.log(`✅ Successfully updated '${elementName}' in elements.ts with new xpath`);
      return true;
    }

    // Add to elements.ts with note if we used a suggestion (new element)
    let comment = `/** ${elementName} */`;
    if (result.usedSuggestion) {
      comment = `/** ${elementName} (auto-mapped from ${result.usedSuggestion}) */`;
      console.log(`\nℹ️  Note: Element was automatically mapped from suggested element: ${result.usedSuggestion}`);
      console.log(`   Original: ${elementName} (not found in DOM)`);
      console.log(`   Mapped to: ${result.usedSuggestion} (found in DOM)`);
    }
    const entry = `  ${comment}\n  ${elementName}: {\n    keyPath: '${result.xpath}',\n  },`;
    const insertionRegex = /(\n\}\);?\s*\n\s*export\s+\{)/;

    if (!insertionRegex.test(elementsContent)) {
      console.log('❌ Could not find insertion point in elements.ts');
      return false;
    }

    // Ensure the last element has a trailing comma before we insert
    // Find the last closing brace before the export and make sure there's a comma after it
    let updatedContent = elementsContent.replace(
      /(\n\s*\},?)(\s*\n\}\);?\s*\n\s*export\s+\{)/,
      (match, lastElement, closing) => {
        // If lastElement doesn't end with comma, add it
        if (!lastElement.trim().endsWith(',')) {
          return lastElement + ',' + closing;
        }
        return match;
      }
    );

    // Now insert the new element
    updatedContent = updatedContent.replace(insertionRegex, `\n${entry}\n$1`);
    fs.writeFileSync(elementsFilePath, updatedContent);

    console.log(`✅ Successfully added '${elementName}' to elements.ts`);
    return true;
  } catch (err) {
    console.log(`❌ Failed to add element: ${err.message}`);
    console.log('💡 Tip: Make sure the test navigated to the correct screen before failing');
    return false;
  }
}

async function runTestWithRetry(filePath, maxAttempts = 3) {
  console.log(`\n🔄 Enhanced Test Execution with Multi-Strategy Retry (max ${maxAttempts} attempts)`);
  console.log('='.repeat(60));
  console.log('🎯 Strategy: Missing Element Fix → AI Error Analysis → Final Attempt');
  console.log('='.repeat(60));

  let lastErrorCategory = null;
  // @ts-ignore
  let lastLearnedFix = null;
  let lastErrorOutput = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`📍 Attempt ${attempt}/${maxAttempts}`);
    console.log(`${'='.repeat(60)}`);

    const startTime = Date.now();
    const result = await runGeneratedTest(filePath);
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);

    console.log(`\n⏱️  Test execution took ${duration} seconds`);

    // Show test output summary and error details
    if (result.output) {
      const outputLines = result.output.split('\n');

      // Find summary lines (passing/failing)
      const summaryLines = outputLines.filter(line =>
        line.includes('passing') || line.includes('failing')
      );

      // Find error details - be more comprehensive
      const errorLines = [];
      let captureError = false;
      let emptyLineCount = 0;
      for (let i = 0; i < outputLines.length; i++) {
        const line = outputLines[i];

        // Start capturing when we hit a failing test
        if (line.match(/^\s*\d+\)\s+/) || line.includes('Error:') || line.includes('AssertionError')) {
          captureError = true;
        }

        // Capture error context
        if (captureError) {
          errorLines.push(line);

          // Count consecutive empty lines
          if (line.trim() === '') {
            emptyLineCount++;
          } else {
            emptyLineCount = 0;
          }

          // Stop after capturing enough context or multiple empty lines
          // Allow single empty lines (between test name and error message)
          if (errorLines.length > 50 || emptyLineCount > 2) {
            break;
          }
        }
      }

      // Display summary
      if (summaryLines.length > 0) {
        console.log('\n📝 Test output:');
        summaryLines.forEach(line => console.log('  ' + line));
      }

      // Display error details if test failed
      if (!result.success && errorLines.length > 0) {
        console.log('\n❌ Error details:');
        errorLines.slice(0, 30).forEach(line => console.log('  ' + line));
      }
    }

    if (result.success) {
      console.log('\n✅ Test passed successfully!');

      // If we had to fix errors, offer to record the fix
      if (attempt > 1 && lastErrorCategory) {
        console.log('\n💡 Test passed after fixing errors!');
        console.log(`📝 Consider recording this fix to learned-fixes.md for future reference`);
        console.log(`   Error type: ${lastErrorCategory.type}`);
      }

      return {
        success: true,
        attempts: attempt,
        fixedErrorType: lastErrorCategory?.type,
        errorCategory: lastErrorCategory,
        errorOutput: lastErrorOutput
      };
    }

    console.log(`\n❌ Test failed on attempt ${attempt}`);

    // DETECT: Check for "before all" or "before each" hook failures
    const hasBeforeHookFailure = result.output.includes('"before all" hook') ||
      result.output.includes('"before each" hook') ||
      result.output.includes('"beforeAll" hook');

    if (hasBeforeHookFailure) {
      console.error('\n⚠️  DETECTED: Test failed in before/beforeAll hook');
      console.error('💡 This means the test never actually ran - it failed during setup.');
      console.error('');
      console.error('Common causes:');
      console.error('  1. Test is in a describe block with a failing before() hook');
      console.error('  2. Shared setup (before hook) is incompatible with this test');
      console.error('  3. Test needs its own setup but is using shared hooks');
      console.error('');
      console.error('Solutions:');
      console.error('  1. Move test to separate describe block without the problematic hook');
      console.error('  2. Ensure test has its own complete setup (call startApplicationAtPage)');
      console.error('  3. Remove or fix the failing before() hook');
      console.error('');
      console.error('⚠️  Skipping AI retry - this is a structural issue, not a test code issue');

      // Don't retry for hook failures - it's a structural problem
      return {
        success: false,
        attempts: attempt,
        error: 'Test failed in before/beforeAll hook - structural issue',
        errorCategory: { type: 'HOOK_FAILURE', description: 'before/beforeAll hook failed' }
      };
    }

    // STRATEGY 1: Check for missing element (HIGHEST PRIORITY - preserve existing logic)
    const missingElement = extractMissingElement(result.output);

    if (missingElement) {
      console.log(`\n💡 Detected missing element: "${missingElement}"`);
      console.log(`🔧 STRATEGY 1: Missing Element Fix`);

      if (attempt < maxAttempts) {
        console.log('📍 Will search for element and add to elements.ts');

        const fixed = await findAndAddMissingElement(missingElement);

        if (fixed) {
          console.log(`\n✅ Successfully added "${missingElement}" to elements.ts`);
          console.log(`⏳ Waiting 1 second before retry...`);
          await new Promise(resolve => setTimeout(resolve, 1000));
          console.log(`🔄 Retrying test now...`);
          continue;
        } else {
          console.log(`\n❌ Failed to add element "${missingElement}"`);
          console.log('💡 Possible reasons:');
          console.log('  - Element not visible on current screen');
          console.log('  - Element name does not match actual DOM element');
          console.log('  - Device not connected or screen changed');

          if (attempt < maxAttempts) {
            console.log(`\n⚠️  Will retry test anyway (attempt ${attempt + 1}/${maxAttempts})...`);
            await new Promise(resolve => setTimeout(resolve, 2000));
            continue;
          }
        }
      }
    }

    // STRATEGY 1.5: Check for visibility errors that might indicate design change
    // This runs BEFORE general AI error analysis to catch element hierarchy changes
    // Note: Run this on ALL attempts, including the last one
    if (!result.success && attempt <= maxAttempts) {
      let errorCategory = await categorizeError(result.output);

      if (errorCategory.type === 'VISIBILITY') {
        console.log(`\n🔍 STRATEGY 1.5: Visibility Error - Checking for Design Change`);

        // Debug: show a snippet of the error to understand what we're working with
        const errorSnippet = result.output.substring(0, 500);
        console.log(`🔍 Error snippet (first 500 chars):`);
        console.log(errorSnippet.split('\n').slice(0, 10).join('\n'));
        console.log('...');

        const visibilityElement = extractElementFromVisibilityError(result.output);
        console.log(`🔍 Extracted element name: ${visibilityElement || 'null'}`);

        if (visibilityElement) {
          console.log(`💡 Detected visibility error for element: "${visibilityElement}"`);

          // Check if this is actually a "Could not get node" error (element doesn't exist)
          const isCouldNotGetNodeError = result.output.includes('Could not get node for element');

          if (isCouldNotGetNodeError) {
            console.log(`🔧 This is actually a missing element error (element not found in DOM)`);
            console.log(`📍 Will search for element and add/update in elements.ts`);
          } else {
            console.log(`🔧 This could be due to design changes - attempting to re-generate element...`);
            console.log('📍 Will search for element and update elements.ts');
          }

          const fixed = await findAndAddMissingElement(visibilityElement);

          if (fixed) {
            console.log(`\n✅ Successfully updated "${visibilityElement}" in elements.ts`);
            console.log(`💡 Element hierarchy may have changed - new path should fix visibility issue`);
            console.log(`⏳ Waiting 1 second before retry...`);
            await new Promise(resolve => setTimeout(resolve, 1000));
            console.log(`🔄 Retrying test now...`);
            continue;
          } else {
            console.log(`\n⚠️  Could not re-generate element "${visibilityElement}"`);
            console.log('💡 Will proceed with standard AI error analysis...');
          }
        } else {
          console.log(`⚠️  Could not extract element name from visibility error`);
          console.log('💡 Will proceed with standard AI error analysis...');
        }
      }

      // STRATEGY 2: Categorize error and use AI to fix (only if not last attempt)
      if (attempt < maxAttempts) {
        console.log(`\n🔍 STRATEGY 2: AI-Powered Error Analysis`);
        lastErrorCategory = errorCategory;
        lastErrorOutput = result.output;

        console.log(`📊 Error Category: ${errorCategory.type}`);
        console.log(`📋 Description: ${errorCategory.description}`);

        // Check if this error type should be fixed by AI
        if (!errorCategory.shouldFix) {
          console.log(`\n⚠️  Error type "${errorCategory.type}" should NOT be auto-fixed`);
          console.log(`💡 Reason: ${errorCategory.description}`);
          console.log(`👤 This requires manual review - could be:`);
          console.log(`   - Outdated test case in TestRail`);
          console.log(`   - Real application bug`);
          console.log(`   - Intentional app change not reflected in test`);
          console.log(`\n🛑 Skipping AI fix to avoid masking real issues`);

          // Don't retry - just fail fast for manual review
          break;
        }

        // Search for learned fixes
        const learnedFix = await searchLearnedFixes(errorCategory, result.output);
        lastLearnedFix = learnedFix;

        if (learnedFix) {
          console.log(`📚 Found similar fixes in learned-fixes.md`);
        } else {
          console.log(`📚 No similar fixes found in learned-fixes.md`);
        }

        // Use AI to fix the test
        console.log(`\n🤖 Attempting AI-powered fix for ${errorCategory.type} error...`);
        const aiFixed = await fixTestWithAI(filePath, result.output, errorCategory, learnedFix, attempt);

        if (aiFixed) {
          console.log(`\n✅ AI applied fix to test file`);
          console.log(`⏳ Waiting 1 second before retry...`);
          await new Promise(resolve => setTimeout(resolve, 1000));
          console.log(`🔄 Retrying test with AI-fixed code...`);
          continue;
        } else {
          console.log(`\n⚠️  AI fix failed or was not applicable`);
          console.log(`⏳ Will retry test anyway (attempt ${attempt + 1}/${maxAttempts})...`);
          await new Promise(resolve => setTimeout(resolve, 2000));
          continue;
        }
      } // End of STRATEGY 2 (attempt < maxAttempts)
    }

    // If this is the last attempt, return the failure
    if (attempt === maxAttempts) {
      console.log(`\n❌ Test failed after ${maxAttempts} attempts`);
      console.log('\n📋 Full Error Output:');
      console.log('-'.repeat(60));
      const outputToShow = result.output.slice(-2000);
      console.log(outputToShow);
      console.log('-'.repeat(60));

      if (lastErrorCategory) {
        console.log(`\n📊 Final Error Category: ${lastErrorCategory.type}`);
        console.log(`💡 ${lastErrorCategory.description}`);
      }

      return {
        success: false,
        attempts: attempt,
        error: result.output,
        errorCategory: lastErrorCategory
      };
    }
  }

  // Fallback: if we somehow exit the loop without returning, return a failure
  console.log('\n⚠️  Unexpected: Loop exited without explicit return');
  return {
    success: false,
    attempts: maxAttempts,
    error: 'Loop completed without result',
    errorCategory: lastErrorCategory
  };
}

// ============================================================================
// AUTOMATIC LEARNING SYSTEM
// ============================================================================

async function recordFixToLearnedFixes(filePath, errorCategory, errorOutput, testResult) {
  const learnedFixesPath = path.join(projectRoot, 'ai-automation/learned-fixes.md');

  if (!fs.existsSync(learnedFixesPath)) {
    console.log('⚠️  learned-fixes.md not found, skipping recording');
    return false;
  }

  try {
    const learnedFixesContent = fs.readFileSync(learnedFixesPath, 'utf8');

    // Count existing fixes to generate the next fix number
    const fixMatches = learnedFixesContent.match(/### Fix #(\d+)/g) || [];
    const nextFixNumber = fixMatches.length + 1;

    // Extract the failing test name
    const failingTestMatch = errorOutput.match(/\d+\)\s+(.+?):/);
    const failingTestName = failingTestMatch ? failingTestMatch[1] : 'Unknown test';

    // Extract a snippet of the error message
    const errorLines = errorOutput.split('\n').filter(line =>
      line.includes('Error:') || line.includes('expected') || line.includes('AssertionError')
    );
    const errorSnippet = errorLines.slice(0, 3).join('\n').substring(0, 300);

    // Get current date
    const today = new Date().toISOString().split('T')[0];

    // Create the fix entry
    const fixEntry = `
### Fix #${nextFixNumber}: ${errorCategory.type} - ${failingTestName}
**Date:** ${today}
**Test File:** \`${filePath}\`
**Error Type:** ${errorCategory.type}

**Error Message:**
\`\`\`
${errorSnippet}
\`\`\`

**Root Cause:**
${errorCategory.description}

**Solution Applied:**
AI automatically applied fix for ${errorCategory.type} error after ${testResult.attempts} attempt(s).
Common fixes for this error type:
- Added proper wait conditions before assertions
- Used retryWithTimeOut() to wait for element state
- Ensured screen/element is loaded before checking properties

**Pattern Matched:** ${errorCategory.pattern}
**Lessons Learned:**
- Always wait for element state before assertions
- ${errorCategory.type} errors typically require wait conditions
- AI successfully identified and fixed this pattern

---
`;

    // Find the insertion point (after "## Recorded Fixes" section)
    const insertionPoint = learnedFixesContent.indexOf('## Recorded Fixes');

    if (insertionPoint === -1) {
      console.log('⚠️  Could not find insertion point in learned-fixes.md');
      return false;
    }

    // Find the end of the "Recorded Fixes" heading (after the next line)
    const nextSectionStart = learnedFixesContent.indexOf('\n\n', insertionPoint + 20);
    const insertPosition = nextSectionStart !== -1 ? nextSectionStart + 2 : learnedFixesContent.length;

    // Insert the fix entry
    const updatedContent =
      learnedFixesContent.substring(0, insertPosition) +
      fixEntry +
      learnedFixesContent.substring(insertPosition);

    fs.writeFileSync(learnedFixesPath, updatedContent);

    console.log(`\n✅ Recorded Fix #${nextFixNumber} to learned-fixes.md`);
    console.log(`📝 File: ai-automation/learned-fixes.md`);
    console.log(`📊 Total fixes recorded: ${nextFixNumber}`);

    return true;
  } catch (err) {
    console.log(`⚠️  Failed to record fix: ${err.message}`);
    return false;
  }
}

// ============================================================================
// MAIN TASK
// ============================================================================

// ============================================================================
// TEST RETRY ON EXISTING FILE
// ============================================================================

gulp.task('test-retry-workflow', async (done) => {
  try {
    console.log('🧪 Testing Retry Workflow on Existing Test\n');

    // Use the existing tv-shows-validation-test.ts
    const filePath = path.join(projectRoot, 'js/automated-tests/tests/tv-shows-validation-test.ts');

    if (!fs.existsSync(filePath)) {
      console.error('❌ Test file not found:', filePath);
      done(new Error('Test file not found'));
      return;
    }

    console.log(`📁 Testing with file: ${filePath}\n`);

    // Run the test with retry logic
    const testResult = await runTestWithRetry(filePath, 3);

    if (testResult.success) {
      console.log('\n🎉 Test passed successfully!');
      console.log(`✅ Test passed after ${testResult.attempts} attempt(s)`);
    } else {
      console.log('\n⚠️  Test did not pass after all retries');
      console.log('📋 Check the output above for details');
    }

    done();
  } catch (error) {
    console.error('❌ Error:', error.message);
    done(error);
  }
});

gulp.task('generate-test', async (done) => {
  try {
    console.log('🚀 Starting Test Generation...\n');

    // Get test details from user
    const testDetails = await promptUser();

    console.log('\n📝 Test Details:');
    console.log(`  Name: ${testDetails.testName}`);
    console.log(`  User Type: ${testDetails.userType}`);
    console.log(`  Screen: ${testDetails.screen}`);
    if (testDetails.preConditions && testDetails.preConditions !== 'No pre-conditions specified') {
      console.log(`  Pre-conditions: ${testDetails.preConditions.substring(0, 80)}${testDetails.preConditions.length > 80 ? '...' : ''}`);
    }
    console.log(`  Steps: ${testDetails.testSteps.substring(0, 80)}${testDetails.testSteps.length > 80 ? '...' : ''}`);
    console.log(`  Tags: ${testDetails.tags}\n`);

    // Generate test with Claude (with automatic retry if wrong ID is used)
    const generatedTest = await generateTestWithRetry(testDetails);

    // Save test file
    const filePath = saveTest(generatedTest, testDetails);

    // Run linter and fix errors with AI if needed
    if (testDetails.runLinter) {
      let lintAttempts = 0;
      const maxLintAttempts = 2;

      while (lintAttempts < maxLintAttempts) {
        const lintResult = await runLinter(filePath);

        if (!lintResult || !lintResult.hasErrors) {
          break; // No errors, we're good
        }

        lintAttempts++;
        console.log(`\n🔧 Lint attempt ${lintAttempts}/${maxLintAttempts} - Found ${lintResult.type} errors`);

        if (lintAttempts < maxLintAttempts) {
          const fixed = await fixLintErrors(filePath, lintResult);
          if (!fixed) {
            console.log('⚠️  AI could not fix errors automatically');
            break;
          }
        } else {
          console.log('⚠️  Max lint fix attempts reached');
          console.log('💡 Some errors remain - will try to run test anyway');
        }
      }
    }

    console.log('\n✅ Test generation complete!');
    console.log(`📁 File: ${filePath}`);

    // Automatically run test with retry logic (if requested)
    if (testDetails.runTest) {
      const testResult = await runTestWithRetry(filePath, 3);

      if (testResult.success) {
        console.log('\n🎉 Test generated and verified successfully!');
        console.log(`✅ Test passed after ${testResult.attempts} attempt(s)`);

        // Remove .only from test file after successful execution
        removeTestOnlyFromFile(filePath);

        // Auto-record fix if errors were resolved
        if (testResult.attempts > 1 && testResult.fixedErrorType && testResult.errorCategory && testResult.errorOutput) {
          console.log('\n📚 Auto-recording successful fix to learned-fixes.md...');
          await recordFixToLearnedFixes(filePath, testResult.errorCategory, testResult.errorOutput, testResult);
        }
      } else {
        console.log('\n⚠️  Test generated but not passing');
        console.log('\n📋 Developer Action Required:');
        console.log('  1. Review the generated test code');
        console.log('  2. Check the error output above');
        console.log('  3. Manually debug and fix remaining issues');
        console.log(`  4. File location: ${filePath}`);

        // Offer to record the failed attempt for learning
        if (testResult.errorCategory) {
          console.log('\n💡 This failure could be recorded for future learning');
          console.log(`   Error type: ${testResult.errorCategory.type}`);
          console.log('   Once manually fixed, consider adding to learned-fixes.md');
        }
      }
    } else {
      console.log('\n📋 Next steps:');
      console.log('  1. Review the generated test');
      console.log('  2. Run: RERUN_AUTOMATED_TESTS=true npx gulp runAutomatedTests');
    }

    done();
  } catch (error) {
    console.error('❌ Error:', error.message);
    done(error);
  }
});


gulp.task('default', gulp.series('generate-test'));

// Export for external use
module.exports = {
  'test-retry-workflow': gulp.task('test-retry-workflow')
};
