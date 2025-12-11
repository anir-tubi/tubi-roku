# Run Test by Case ID

Run a specific test by its TestRail case ID.

**Usage:** `/run-test C845255`

**What this does:**
1. Finds and runs the test with the specified case ID
2. Uses proper environment variables (RERUN_AUTOMATED_TESTS=true)
3. Sets appropriate timeout (120 seconds)
4. Shows you the test results immediately

**Arguments:**
- `{{arg1}}` - TestRail case ID (e.g., C845255 or 845255)

**Example:**
```
/run-test C842086
```

This will run:
```bash
RERUN_AUTOMATED_TESTS=true npx mocha js/automated-tests/tests/**/*.ts --grep "C842086" --timeout 120000
```

**Tip:** After generating a test with `/gen`, use `/run-test` to verify it passes!

**Common Workflow:**
1. `/gen C845255` - Generate the test
2. `/run-test C845255` - Run it to verify
3. If it fails, use `/retry-failed` to auto-fix
