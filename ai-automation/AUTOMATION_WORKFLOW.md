# Automated Test Generation Workflow

High-level overview of the automated test generation and execution process.

## Overview

The automation system generates Roku test scripts using Claude Code, runs them, and handles missing elements automatically.

## Workflow

```
1. Generate Test
   ↓
2. Run Test
   ↓
3. Missing Element? → Find & Add Element → Retry Test
   ↓
4. Test Passes ✓
```

## Commands

### 1. Generate Test
```bash
cd ai-automation
npx gulp generate-test
```

Prompts for TestRail case ID, fetches test details, and generates TypeScript test file.

**Output:** `js/automated-tests/tests/[test-name].ts`

### 2. Run Test
```bash
# Fresh deployment
npx gulp runAutomatedTests

# Re-run existing app (faster)
RERUN_AUTOMATED_TESTS=true npx gulp runAutomatedTests
```

Builds, deploys to Roku device, and runs tests.

### 3. Find Missing Element
```bash
npx gulp findElement --elementName=detailScreenTitle
```

Connects to Roku device, finds element in DOM, and adds to `automated-tests-config/elements.ts`.

## Typical Session

```bash
# 1. Generate test from TestRail
cd ai-automation
npx gulp generate-test
# Enter: C5852

# 2. Run the test
cd ..
RERUN_AUTOMATED_TESTS=true npx gulp runAutomatedTests

# 3. If element missing, add it
npx gulp findElement --elementName=missingElement

# 4. Re-run test
RERUN_AUTOMATED_TESTS=true npx gulp runAutomatedTests
```

## Components

- **`gulpfile.js`** - Test generation logic (uses Claude Code SDK)
- **`testrail-case-fetcher.js`** - Fetches test cases from TestRail
- **`dynamic-hierarchy-finder.js`** - Finds elements in Roku DOM
- **Root `gulpfile.js`** - Test execution and element finder tasks

## Configuration

- **`rta-config.json`** - Roku device IP and credentials
- **`.vscode/.env`** - Alternative config location

## Error Handling

When tests fail:
- Review `ai-automation/learned-fixes.md` for similar past errors
- Claude Code will automatically analyze patterns and suggest fixes (`.claude/instructions.md`)
- Record new fixes to build the knowledge base
