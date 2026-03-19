# ai-automation

## Purpose

Contains the AI-powered automated test generation system for the Tubi Roku channel. This system uses Claude (via AWS Bedrock) to generate TypeScript UI test files from TestRail test case specifications. It fetches test case details from TestRail, builds prompts with project context, invokes an LLM to generate test code, and then runs lint fixes on the output.

## Structure

- `gulpfile.js` - Gulp task definitions for the AI test generation workflow: prompts for test case IDs, fetches TestRail context, builds LLM prompts, invokes Claude, and writes output test files
- `config.js` - Configuration constants for the AI system: timeouts (15min Claude timeout), retry limits, file paths, regex patterns, LLM feature toggles, and error categories for auto-fixing
- `testrail-case-fetcher.js` - Fetches test case details and surrounding context from the TestRail API (`tubi.testrail.io`), including parent sections and sibling cases for additional context
- `learned-fixes.md` - Accumulated knowledge base of common test generation errors and their fixes, referenced by the LLM during generation
- `tsconfig.json` - TypeScript configuration for the AI automation module
- `.claude/` - Claude agent configuration for the AI automation workspace
- `AUTOMATION_WORKFLOW.md` - Documentation of the automated test generation workflow
- `ENHANCED_ERROR_HANDLING.md` - Documentation of enhanced error handling patterns
- `lib/` - Core library modules
  - `prompt-builder.js` - Builds detailed prompts for Claude including test case info, project context (elements, test helpers, existing tests), and learned fixes
  - `llm-client.js` - LLM client wrapper for Claude invocation via subprocess
  - `file-operations.js` - File read/write operations for test file management
  - `code-cleaner.js` - Post-generation code cleanup and formatting
  - `ast-utils.js` - AST utilities for TypeScript test file parsing and manipulation

## Architecture

- **TestRail → LLM → Test File Pipeline**: The workflow fetches a test case from TestRail, enriches it with project context (existing tests, element definitions, helper functions), constructs a detailed prompt, sends it to Claude, and writes the generated TypeScript test file to `js/automated-tests/tests/`.
- **Context-Aware Generation**: The prompt builder reads actual project files (`automated-tests-config/elements.ts`, `js/automated-tests/test-helpers.ts`, existing test files) to provide Claude with real codebase context, ensuring generated tests use correct element keypaths and helper functions.
- **Iterative Lint Fixing**: After initial generation, the system can invoke Claude again to fix lint errors (up to `MAX_LINT_ATTEMPTS` = 2 retries).
- **Error Auto-Fix Categories**: Defines categories of fixable errors (`EMPTY_STRING`, `VISIBILITY`, `TIMEOUT`, `FOCUS`, `NAVIGATION`, etc.) that the system can attempt to auto-repair.

## Key Concepts

- **`config.CLAUDE_TIMEOUT`** (`config.js`): 15-minute timeout for Claude LLM invocations.
- **`buildPrompt()`** (`lib/prompt-builder.js`): Constructs the full prompt including test case description, project element definitions, helper function signatures, existing similar tests, and learned fixes.
- **`fetchTestCaseWithContext()`** (`testrail-case-fetcher.js`): Fetches a TestRail case plus its parent section and sibling cases for richer context.
- **Learned Fixes** (`learned-fixes.md`): A growing knowledge base of common generation mistakes and corrections that gets included in prompts.

## Dependencies

**Internal:**

- `../automated-tests-config/elements.ts` - Element keypath definitions read during prompt building
- `../js/automated-tests/test-helpers.ts` - Test helper signatures included in prompts
- `../js/automated-tests/tests/` - Existing test files used as examples for generation
- `../.claude/` - Claude agent settings

**External:**

- TestRail API (`tubi.testrail.io`) - Source of test case specifications
- Claude (AWS Bedrock) - LLM for test code generation
- `gulp ^4.0.2` - Task runner for the generation workflow
- `inquirer ^8.2.5` - Interactive CLI prompts for test case ID input

## Working with this Code

### Prerequisites

- `TEST_RAIL_KEY` and `TEST_RAIL_USER_NAME` environment variables for TestRail API access
- AWS SSO authentication for Bedrock (`AWS_PROFILE=tubi-core-dev-bedrock-user`)
- `npm install` from project root

### Build & Run

- `cd ai-automation && npx gulp` - Run the interactive test generation workflow (prompts for test case ID)
- `cd ai-automation && npx gulp --caseId=C12345` - Non-interactive mode with specific test case

### Things to Watch Out For

- The Claude timeout is 15 minutes; complex test cases may approach this limit.
- Generated tests always need manual review — the AI may hallucinate element keypaths or use incorrect helper functions.
- The `learned-fixes.md` file should be updated when recurring generation errors are identified.
- TestRail API credentials are required; the system fails fast with clear error messages if they're missing.
