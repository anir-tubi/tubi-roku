// @ts-check
const { spawn } = require('child_process');
const config = require('../config');

/**
 * Call Claude LLM with a prompt
 * @param {string} prompt - The prompt to send to Claude
 * @param {Object} [options] - Configuration options
 * @param {string} [options.model='haiku'] - Model to use (haiku, sonnet, opus)
 * @param {number} [options.temperature=0] - Temperature (0-1)
 * @param {number} [options.timeout=30000] - Timeout in ms
 * @param {boolean} [options.expectJson=true] - Whether to expect JSON response
 * @returns {Promise<string|Object>} Claude's response
 */
async function callClaude(prompt, options = {}) {
  const {
    model = 'haiku',
    temperature = 0,
    timeout = 30000,
    expectJson = true
  } = options;

  return new Promise((resolve, reject) => {
    // Use stdin for prompt to avoid command-line length limits and escaping issues
    const args = [
      '--print',
      '--model', model,
      '--output-format', 'text',
      '--tools', '' // Disable all tools to prevent conversational responses
    ];

    // Add permission bypass if configured (recommended for automation)
    if (config.llm && config.llm.skipPermissions) {
      args.push('--dangerously-skip-permissions');
    }

    const claude = spawn('claude', args, {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';
    let timeoutHandle;
    let isResolved = false;

    // Set up timeout handler
    if (timeout > 0) {
      timeoutHandle = setTimeout(() => {
        if (!isResolved) {
          isResolved = true;
          claude.kill('SIGTERM');
          console.error(`❌ Claude call timed out after ${timeout}ms`);
          resolve(null);
        }
      }, timeout);
    }

    claude.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    claude.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    claude.on('close', (code) => {
      if (isResolved) return;
      isResolved = true;

      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }

      if (code !== 0 && code !== null) {
        console.error(`❌ Claude call failed with code ${code}: ${stderr}`);
        resolve(null);
        return;
      }

      try {
        if (expectJson) {
          // Extract JSON from the response - find first complete JSON object
          // Use a more robust approach that handles extra text before/after JSON
          let jsonStr = null;

          // Try to find JSON between curly braces
          const firstBrace = stdout.indexOf('{');
          if (firstBrace !== -1) {
            // Find matching closing brace
            let depth = 0;
            let lastBrace = -1;
            for (let i = firstBrace; i < stdout.length; i++) {
              if (stdout[i] === '{') depth++;
              else if (stdout[i] === '}') {
                depth--;
                if (depth === 0) {
                  lastBrace = i;
                  break;
                }
              }
            }

            if (lastBrace !== -1) {
              jsonStr = stdout.substring(firstBrace, lastBrace + 1);
            }
          }

          if (jsonStr) {
            const response = JSON.parse(jsonStr);
            resolve(response);
          } else {
            console.error(`❌ Could not find valid JSON in Claude response`);
            console.error(`   Response: ${stdout.substring(0, 200)}`);
            resolve(null);
          }
        } else {
          // Return raw text response
          resolve(stdout.trim());
        }
      } catch (parseError) {
        console.error(`❌ Failed to parse Claude response: ${parseError.message}`);
        console.error(`   Raw output: ${stdout.substring(0, 300)}`);
        resolve(null);
      }
    });

    claude.on('error', (error) => {
      if (isResolved) return;
      isResolved = true;

      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
      console.error(`❌ Claude process error: ${error.message}`);
      resolve(null);
    });

    // Write prompt to stdin (handles newlines and special chars properly)
    try {
      claude.stdin.write(prompt);
      claude.stdin.end();
    } catch (writeError) {
      if (isResolved) return;
      isResolved = true;

      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
      console.error(`❌ Failed to write prompt to Claude: ${writeError.message}`);
      resolve(null);
    }
  });
}

/**
 * Call Claude for error categorization
 * @param {string} errorOutput - The test error output
 * @returns {Promise<Object|null>}
 */
async function callClaudeForErrorCategorization(errorOutput) {
  // Keep only last 1500 chars
  const truncatedError = errorOutput.slice(-1500);

  const prompt = `You are a JSON-only analysis tool. Do NOT ask questions. Do NOT use tools. Do NOT be conversational.

TASK: Categorize this test error.

Error Types:
- EMPTY_STRING: Field is empty string (timing issue, fixable)
- VISIBILITY: Element not visible (fixable)
- UNDEFINED: Property/element undefined (fixable)
- TIMEOUT: Operation timed out (fixable)
- FOCUS: Focus issue (fixable)
- GRID_CONTENT: Grid/list content issue (fixable)
- PLAYER_STATE: Player state issue (fixable)
- NAVIGATION: Navigation issue (fixable)
- WRONG_VALUE: Wrong value (NOT fixable)
- HOOK_FAILURE: Hook failed
- UNKNOWN: Unknown error

Error:
${truncatedError}

OUTPUT REQUIREMENT: Reply with ONLY valid JSON, nothing else.
{"type":"EMPTY_STRING","description":"brief description","shouldFix":true,"confidence":"high","reasoning":"brief explanation"}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 15000 });
}

/**
 * Call Claude for user type derivation
 * @param {string} testSteps - Test steps from TestRail
 * @param {string} preConditions - Pre-conditions from TestRail
 * @returns {Promise<Object|null>}
 */
async function callClaudeForUserTypeDetermination(testSteps, preConditions) {
  const prompt = `You are a JSON-only analysis tool. Do NOT ask questions. Do NOT use tools. Do NOT be conversational.

TASK: Determine user type from these test details.

Rules:
- "Guest" = no account needed (browsing, search, viewing content)
- "Registered" = requires account (history, queue, favorites, watchlist)
- Default to "Guest" if unclear

Pre-conditions: ${preConditions}
Test steps: ${testSteps}

OUTPUT REQUIREMENT: Reply with ONLY valid JSON, nothing else.
{"userType":"Guest","confidence":"high","reasoning":"brief explanation"}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 15000 });
}

/**
 * Call Claude to determine screen/page from test steps
 * @param {string} testSteps - Test steps from TestRail
 * @param {string} testName - Test name
 * @param {string} section - Section name
 * @returns {Promise<Object|null>}
 */
async function callClaudeForScreenDetermination(testSteps, testName, section) {
  const prompt = `You are a JSON-only analysis tool. Do NOT ask questions. Do NOT use tools. Do NOT be conversational.

TASK: Determine which screen/page this test covers.

Test Name: ${testName}
Section: ${section}
Test Steps: ${testSteps}

Common screens: Home, Search, Detail, Player, Settings, My Stuff, Kids Mode, Other

OUTPUT REQUIREMENT: Reply with ONLY valid JSON, nothing else.
{"screen":"Home","confidence":"high","reasoning":"brief explanation"}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 15000 });
}

/**
 * Call Claude to generate appropriate test tags
 * @param {string} testName - Test name
 * @param {string} section - Section name
 * @param {string} testSteps - Test steps
 * @returns {Promise<Object|null>}
 */
async function callClaudeForTagGeneration(testName, section, testSteps) {
  const prompt = `You are a JSON-only analysis tool. Do NOT ask questions. Do NOT use tools. Do NOT be conversational.

TASK: Generate appropriate test tags.

Test Name: ${testName}
Section: ${section}
Test Steps: ${testSteps}

Common tags: @smoke, @search, @playback, @navigation, @detail, @player, @manual_regression, @validation

OUTPUT REQUIREMENT: Reply with ONLY valid JSON, nothing else.
{"tags":"@search @manual_regression","confidence":"high","reasoning":"brief explanation"}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 15000 });
}


module.exports = {
  callClaude,
  callClaudeForErrorCategorization,
  callClaudeForUserTypeDetermination,
  callClaudeForScreenDetermination,
  callClaudeForTagGeneration
};
