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
      '--tools', '' // Disable tools to speed up response
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
 * Call Claude for element matching analysis
 * @param {string} targetElement - Element name to find
 * @param {Array<Object>} suggestions - List of available elements
 * @param {string} context - Screen context (e.g., "detailScreen", "homeScreen")
 * @returns {Promise<Object|null>}
 */
async function callClaudeForElementMatching(targetElement, suggestions, context = null) {
  // Limit to first 10 suggestions to keep prompt short
  const limitedSuggestions = suggestions.slice(0, 10);
  const elementsDescription = limitedSuggestions.map((s, i) =>
    `${i + 1}.${s.name}(${s.type})${s.text ? `:"${s.text.substring(0, 50)}"` : ''}`
  ).join('\n');

  // Build context-aware instructions
  let contextInstructions = '';
  if (context) {
    if (context.includes('detail')) {
      contextInstructions = `\n⚠️ SCREEN CONTEXT: This element is on DETAIL SCREEN (movie/series details page).
⚠️ Prefer elements with "detail", "info", "panel" in their names.
⚠️ REJECT elements with "tvShows", "homeScreen", "rowList" - those are for home page, not details page.`;
    } else if (context.includes('home')) {
      contextInstructions = `\n⚠️ SCREEN CONTEXT: This element is on HOME SCREEN.
⚠️ Prefer elements with "home", "rowList", "content" in their names.
⚠️ REJECT elements with "detail", "info", "panel" - those are for details page, not home.`;
    } else if (context.includes('tvShows')) {
      contextInstructions = `\n⚠️ SCREEN CONTEXT: This element is on TV SHOWS SCREEN.
⚠️ Prefer elements with "tvShows", "series", "tv" in their names.
⚠️ REJECT elements with "movie", "detail" if not relevant to TV shows.`;
    }
  }

  const prompt = `Find best match for "${targetElement}" from these elements:
${elementsDescription}
${contextInstructions}

Consider: name similarity, text content, type, screen context.

RETURN ONLY THIS JSON FORMAT WITH NO OTHER TEXT:
{"elementName":"match or null","confidence":"high","reasoning":"brief explanation"}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 15000 });
}

/**
 * Call Claude for DOM element path finding
 * @param {string} xmlData - The DOM XML
 * @param {string} targetElement - Element to find
 * @param {string} context - Screen context (e.g., "detailScreen", "homeScreen")
 * @returns {Promise<Object|null>}
 */
async function callClaudeForDOMParsing(xmlData, targetElement, context = null) {
  // Truncate XML if it's extremely large (keep first 150KB)
  // Note: Typical Roku DOM is ~100KB, Claude Haiku can handle 200K tokens (~800KB text)
  const maxXmlSize = 150000;
  let truncatedXml = xmlData;
  if (xmlData.length > maxXmlSize) {
    truncatedXml = xmlData.substring(0, maxXmlSize) + '\n... (truncated)';
  }

  // Build context-aware instructions
  let contextInstructions = '';
  let requiredPathElement = '';

  if (context) {
    if (context.includes('detail')) {
      requiredPathElement = 'detailScreen';
      contextInstructions = `
⚠️ CRITICAL: This element is on DETAIL SCREEN (movie/series details page).
⚠️ The path MUST contain "detailScreen" - paths with "HomeScreen" are WRONG.
⚠️ Expected pattern: ContentController → uiGroup → ContentGroup → ScreenStack → detailScreen → AnimationGroup → DetailInfoPanel
⚠️ REJECT any path containing: HomeScreen, ContentRows, RowList (those are home page, not details page)`;
    } else if (context.includes('home')) {
      requiredPathElement = 'HomeScreen';
      contextInstructions = `
⚠️ CRITICAL: This element is on HOME SCREEN.
⚠️ The path MUST contain "HomeScreen" - paths with "detailScreen" are WRONG.
⚠️ Expected pattern: ContentController → HomeScreen → ContentRows → RowList`;
    }
  }

  const prompt = `Find "${targetElement}" in Roku DOM.
${contextInstructions}

RULES:
1. Start from ContentController
2. ${requiredPathElement ? `PATH MUST INCLUDE: "${requiredPathElement}"` : 'Build complete path'}
3. Match: Line1, FirstLineGroup, TwoLineInfo (case insensitive, partial match)
4. Only visible elements
5. ⚠️ CRITICAL: ALWAYS use the "name" attribute from XML elements, NOT the tag name
   - Example: <RowList name="browseWhileWatchingRowList"> → use "browseWhileWatchingRowList"
   - Example: <Label name="header"> → use "header"
   - If element has no "name" attribute, use the tag name as fallback
6. ⚠️ PATH RULE: Build SIMPLIFIED path with only KEY navigation elements
   - KEEP: ContentController, uiGroup, ContentGroup, ScreenStack, [screen names], [named feature components]
   - SKIP only these generic layout containers: RenderableNode, LayoutGroup, Offset, AnimationGroup
   - ⚠️ NEVER include "RenderableNode" - it's not a valid element ID
   - Example: ContentController → uiGroup → ContentGroup → ScreenStack → videoPlayerScreen → browseWhileWatchingRowList → header
   - Pattern: ContentController → uiGroup → ContentGroup → ScreenStack → [screen] → [feature components] → [target]

XML (search for ${requiredPathElement || 'element'}):
${truncatedXml}

RETURN JSON (xpath MUST use dot notation with # prefix for each element):
{"found":true,"path":["ContentController","uiGroup","ContentGroup","ScreenStack","${requiredPathElement || 'Screen'}","..."],"xpath":"#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#${requiredPathElement || 'Screen'}.#...","matchedElement":"${targetElement}","confidence":"high","reasoning":"brief"}

⚠️ CRITICAL xpath FORMAT:
- Use DOT (.) to separate elements, NOT > or /
- Add # prefix to each element name
- Use element "name" attributes (not tag names)
- Use SIMPLIFIED path (skip generic containers but KEEP ScreenStack)
- Example GOOD: "#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#browseWhileWatchingRowList.#header"
- WRONG formats:
  - Using tag names instead of name attributes
  - "#ContentController>#uiGroup" or "#ContentController/#uiGroup"
  - Including RenderableNode, LayoutGroup, Offset, AnimationGroup

Not found:
{"found":false,"path":[],"xpath":null,"confidence":"none","reasoning":"not in visible ${requiredPathElement || 'DOM'}","suggestions":[]}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 60000 });
}

/**
 * Call Claude for error categorization
 * @param {string} errorOutput - The test error output
 * @returns {Promise<Object|null>}
 */
async function callClaudeForErrorCategorization(errorOutput) {
  // Keep only last 1500 chars
  const truncatedError = errorOutput.slice(-1500);

  const prompt = `Categorize this test error into one of these types:
EMPTY_STRING(timing,fixable), VISIBILITY(fixable), UNDEFINED(fixable), TIMEOUT(fixable), FOCUS(fixable), GRID_CONTENT(fixable), PLAYER_STATE(fixable), NAVIGATION(fixable), WRONG_VALUE(NOT fixable), HOOK_FAILURE, UNKNOWN.

Error:
${truncatedError}

RETURN ONLY THIS JSON FORMAT WITH NO OTHER TEXT:
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
  const prompt = `Determine user type: Guest (no account) or Registered (signed in).
Features requiring account: history, queue, favorites. Default to Guest if unclear.

Pre-conditions: ${preConditions}
Test steps: ${testSteps}

RETURN ONLY THIS JSON FORMAT WITH NO OTHER TEXT:
{"userType":"Guest","confidence":"high","reasoning":"brief explanation"}`;

  return callClaude(prompt, { model: 'haiku', expectJson: true, timeout: 15000 });
}

module.exports = {
  callClaude,
  callClaudeForElementMatching,
  callClaudeForDOMParsing,
  callClaudeForErrorCategorization,
  callClaudeForUserTypeDetermination
};
