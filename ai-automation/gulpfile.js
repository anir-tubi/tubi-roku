// @ts-ignore
const gulp = require('gulp');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
// @ts-ignore
const inquirer = require('inquirer');
const { fetchTestCaseWithContext } = require('./testrail-case-fetcher.js');

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

  const answers = await inquirer.prompt(questions);

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
    answers.sectionName = testRailData.sectionName || 'Unknown Section';
    answers.mainSection = testRailData.mainSection;
    answers.subSection = testRailData.subSection;

    // Derive user type from test steps
    const testStepsLower = (answers.testSteps || '').toLowerCase();
    if (testStepsLower.includes('registered') ||
      testStepsLower.includes('signed in')) {
      answers.userType = 'Registered';
    } else {
      answers.userType = 'Guest'; // Default
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

  } catch (error) {
    console.error('❌ Failed to fetch TestRail data:', error.message);
    console.log('📝 Using default values...');

    // Fallback to defaults
    answers.testName = 'Test Case';
    answers.testSteps = 'Test steps not available';
    answers.userType = 'Guest';
    answers.screen = 'Other';
    answers.screenCustom = 'Unknown Screen';
    answers.tags = '@validation';
  }

  return answers;
}

// ============================================================================
// PROMPT GENERATION
// ============================================================================

function buildPrompt(testDetails) {
  // Read instructions from .claude/instructions.md
  const instructionsPath = path.join(projectRoot, '.claude/instructions.md');
  let instructions = '';

  if (fs.existsSync(instructionsPath)) {
    instructions = fs.readFileSync(instructionsPath, 'utf8');
  }

  // Normalize testCaseId to ensure it has the 'C' prefix
  let normalizedTestCaseId = testDetails.testCaseId;
  if (normalizedTestCaseId && !normalizedTestCaseId.startsWith('C')) {
    normalizedTestCaseId = 'C' + normalizedTestCaseId;
  }

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

async function generateTestWithAI(testDetails) {
  console.log('🤖 Calling Claude Code SDK with project context...');

  if (!checkClaudeAvailable()) {
    throw new Error('Claude Code SDK not found. Please install: npm install -g @anthropic-ai/claude-code');
  }

  console.log('✅ Claude Code SDK found');

  return new Promise((resolve, reject) => {
    console.log('📁 Claude will read project files directly...');
    console.log('🤖 Claude will analyze the project and generate test...');
    console.log('⏳ This may take 30-60 seconds...\n');

    const promptContent = buildPrompt(testDetails);

    // Write prompt to a temporary file to avoid shell escaping issues
    const tmpFile = path.join(projectRoot, '.claude-prompt-tmp');
    fs.writeFileSync(tmpFile, promptContent);

    // Use specific files + all test files for learning from existing test patterns
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

      // Validate output
      if (!cleanedOutput.includes('import') || !cleanedOutput.includes('describe')) {
        console.log('⚠️  Generated output may not be valid TypeScript test code');
        console.log('📝 Output preview:', cleanedOutput.substring(0, 200));
      }

      resolve(cleanedOutput);
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
    console.log('⚠️  No describe blocks found in file');
    return -1;
  }

  console.log(`📋 Found ${describeBlocks.length} describe blocks:`, describeBlocks.map(d => `"${d.name}" (lines ${d.startLine + 1}-${d.endLine + 1})`));

  // Sanity check: if we didn't find matching closing braces for all describes, the file might be corrupted
  if (describeStack.length > 0) {
    console.log(`⚠️  WARNING: Found ${describeStack.length} unclosed describe block(s):`, describeStack.map(d => d.name));
    console.log(`⚠️  The file structure may be corrupted. Consider fixing it manually before adding new tests.`);
  }

  // Determine which describe block to use based on test context
  let targetDescribe = null;

  // Check if the test is for a specific context (Movie, Series, etc.)
  const testStepsLower = (testDetails.testSteps || '').toLowerCase();
  const mainSectionLower = (testDetails.mainSection || '').toLowerCase();
  const subSectionLower = (testDetails.subSection || '').toLowerCase();

  console.log(`🔍 Looking for describe matching: mainSection="${testDetails.mainSection}", subSection="${testDetails.subSection}"`);

  // Match patterns like "Movie Details Page", "Series Details Page", etc.
  for (const describe of describeBlocks) {
    const describeNameLower = describe.name.toLowerCase();

    // Prioritize more specific (deeper nested) describe blocks
    if (subSectionLower && describeNameLower.includes(subSectionLower.toLowerCase())) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        console.log(`  ✓ Matched by subSection: "${describe.name}"`);
      }
    } else if (describeNameLower.includes('movie') && (testStepsLower.includes('movie') || mainSectionLower.includes('movie'))) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        console.log(`  ✓ Matched by "movie" keyword: "${describe.name}"`);
      }
    } else if (describeNameLower.includes('series') && (testStepsLower.includes('series') || mainSectionLower.includes('series'))) {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        console.log(`  ✓ Matched by "series" keyword: "${describe.name}"`);
      }
    } else if (describeNameLower.includes(mainSectionLower) && mainSectionLower !== '') {
      if (!targetDescribe || describe.level > targetDescribe.level) {
        targetDescribe = describe;
        console.log(`  ✓ Matched by mainSection: "${describe.name}"`);
      }
    }
  }

  // If no specific match, use the deepest nested describe block (most specific)
  if (!targetDescribe) {
    const sortedByLevel = [...describeBlocks].sort((a, b) => b.level - a.level); // Descending
    targetDescribe = sortedByLevel[0];
    console.log(`ℹ️  No specific describe block matched, using deepest: "${targetDescribe.name}"`);
  } else {
    console.log(`✅ Matched describe block: "${targetDescribe.name}" (lines ${targetDescribe.startLine}-${targetDescribe.endLine})`);
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
      console.log(`  Found it() block starting at line ${i + 1}`);
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
        console.log(`  it() block ends at line ${i + 1}`);
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
    console.log(`✅ Will insert after line ${lastItEndLine + 1} in "${targetDescribe.name}"`);
    return insertPos;
  } else {
    // No it() blocks found, insert before the closing }); of the describe
    console.log(`ℹ️  No it() blocks found in "${targetDescribe.name}", inserting before closing brace at line ${describeEndLine + 1}`);
    // Insert just before the describe's closing });
    let insertPos = 0;
    for (let i = 0; i < describeEndLine; i++) {
      insertPos += lines[i].length + 1; // +1 for the newline character
    }
    return insertPos;
  }
}

function saveTest(generatedTest, testDetails) {
  // Use the last part of subSection (after last ›) for filename
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

  const fileName = sectionName
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '-');

  const filePath = path.join(projectRoot, 'js/automated-tests/tests', `${fileName}.ts`);

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
      console.log('⚠️  Could not find it() block in generated test. Creating new file instead.');
      fs.writeFileSync(filePath, generatedTest);
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
        console.log('⚠️  Could not find closing of it() block. Creating new file instead.');
        fs.writeFileSync(filePath, generatedTest);
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
        console.log('⚠️  Could not find appropriate describe block in existing file. Creating new file instead.');
        fs.writeFileSync(filePath, generatedTest);
      } else {
        // Insert new test case before the closing });
        const updatedContent =
          existingContent.substring(0, insertPosition) +
          '\n  ' + newTestCase + '\n' +
          existingContent.substring(insertPosition);

        fs.writeFileSync(filePath, updatedContent);
        console.log(`✅ Added new test case to existing file with .only`);
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

      // Run TypeScript check
      // @ts-ignore
      exec(`npx tsc --noEmit ${filePath}`, (tscError, tscStdout, tscStderr) => {
        if (tscError) {
          console.log('\n⚠️  TypeScript found issues:\n');
          console.log('━'.repeat(60));
          // TypeScript errors usually go to stdout
          const tscOutput = (tscStdout + '\n' + tscStderr).trim();
          console.log(tscOutput);
          console.log('━'.repeat(60));
          console.log('');
          resolve({ hasErrors: true, errors: tscOutput, type: 'typescript' });
          return;
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

  const promptContent = `Fix the following ${lintResult.type} errors in this test file:

ERRORS:
${lintResult.errors}

CURRENT FILE CONTENT:
${fileContent}

INSTRUCTIONS:
${instructions}

Return ONLY the complete fixed TypeScript code (no markdown, no explanations).`;

  // @ts-ignore
  return new Promise((resolve, reject) => {
    // Write prompt to a temporary file to avoid shell escaping issues
    const tmpFile = path.join(projectRoot, '.claude-lint-fix-tmp');
    fs.writeFileSync(tmpFile, promptContent);

    // Use specific files + all test files for learning from existing test patterns
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

      // Validate output
      if (!fixedCode.includes('import') || !fixedCode.includes('describe')) {
        console.log('⚠️  Generated output may not be valid TypeScript test code');
        resolve(false);
        return;
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

    // Run only the specific test file, not the entire suite
    const testCommand = `cd ${projectRoot} && RERUN_AUTOMATED_TESTS=true npx mocha ${filePath}`;

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

function categorizeError(errorOutput) {
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
      promptContent += `\n\nFIX GUIDANCE:
- Add wait for element visibility before assertions
- Example: await testUtils.retryWithTimeOut(async () => { const element = await testUtils.getNodeForElement('name'); expect(element.visible).to.equal(true); });
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
- Use waitForPlayerStateToEqual() to wait for specific player states
- Add waits after playback commands (play, pause)
- Check player state before assertions
`;
      break;
  }

  promptContent += `\n\nOUTPUT FORMAT:
- Return ONLY the complete fixed TypeScript test file
- No markdown code blocks, no explanations, no comments about changes
- Just the raw TypeScript code ready to save
- Keep all other tests unchanged, only fix the failing one

NOW: Analyze the error and return the fixed test code.`;

  // @ts-ignore
  return new Promise((resolve, reject) => {
    const tmpFile = path.join(projectRoot, '.claude-error-fix-tmp');
    fs.writeFileSync(tmpFile, promptContent);

    // Use specific files + all test files for learning from existing test patterns
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

    // Find the element using hierarchy finder
    console.log(`🔍 Searching for: ${baseElementName}`);
    const result = await findElementHierarchy(baseElementName);

    if (!result.found) {
      console.log(`❌ Element '${baseElementName}' not found on current screen`);
      console.log('💡 Tip: Make sure the test navigated to the correct screen before failing');
      return false;
    }

    // Check if element already exists
    const elementsFilePath = path.join(projectRoot, 'automated-tests-config', 'elements.ts');
    const elementsContent = fs.readFileSync(elementsFilePath, 'utf8');
    const elementExistsRegex = new RegExp(`^\\s*${elementName}:\\s*{`, 'm');

    if (elementExistsRegex.test(elementsContent)) {
      console.log(`ℹ️  Element '${elementName}' already exists in elements.ts`);
      return false;
    }

    // Add to elements.ts
    const entry = `  /** ${elementName} */\n  ${elementName}: {\n    keyPath: '${result.xpath}',\n  },`;
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

    // Show a snippet of the output for debugging
    if (result.output) {
      const outputLines = result.output.split('\n');
      const relevantLines = outputLines.filter(line =>
        line.includes('passing') ||
        line.includes('failing') ||
        line.includes('Error:') ||
        line.includes('expected') ||
        line.includes('Could not find')
      );
      if (relevantLines.length > 0) {
        console.log('\n📝 Test output highlights:');
        relevantLines.slice(-10).forEach(line => console.log('  ' + line));
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
          console.log(`⏳ Waiting 3 seconds before retry...`);
          await new Promise(resolve => setTimeout(resolve, 3000));
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
    } else if (attempt < maxAttempts) {
      // STRATEGY 2: Categorize error and use AI to fix
      console.log(`\n🔍 STRATEGY 2: AI-Powered Error Analysis`);

      const errorCategory = categorizeError(result.output);
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
        console.log(`⏳ Waiting 3 seconds before retry...`);
        await new Promise(resolve => setTimeout(resolve, 3000));
        console.log(`🔄 Retrying test with AI-fixed code...`);
        continue;
      } else {
        console.log(`\n⚠️  AI fix failed or was not applicable`);
        console.log(`⏳ Will retry test anyway (attempt ${attempt + 1}/${maxAttempts})...`);
        await new Promise(resolve => setTimeout(resolve, 2000));
        continue;
      }
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
    console.log(`  Steps: ${testDetails.testSteps}`);
    console.log(`  Tags: ${testDetails.tags}\n`);

    // Generate test with Claude
    const generatedTest = await generateTestWithAI(testDetails);

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
