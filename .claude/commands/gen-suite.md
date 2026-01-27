# Generate Tests from TestRail Suite

Generate automated tests for all test cases in a TestRail suite or section.

**Usage:** `/gen-suite 47 100771`

**What this does:**
1. Fetches all test cases from the specified TestRail suite/section
2. Generates automated tests for each case sequentially
3. Saves all tests to the appropriate files
4. Provides a summary of successful and failed generations

**Arguments:**
- `{{arg1}}` - Suite ID (required) - e.g., 47
- `{{arg2}}` - Section ID (optional) - e.g., 100771 to filter to a specific section within the suite

**Examples:**
```
/gen-suite 47                    # Generate all tests in suite 47
/gen-suite 47 100771            # Generate tests in suite 47, section 100771 only
```

**How to find Suite/Section IDs:**

From a TestRail URL like:
```
https://tubi.testrail.io/index.php?/suites/view/47&group_by=cases:section_id&group_order=asc&display_deleted_cases=0&display=compact&group_id=100771
```

- Suite ID: **47** (from `/suites/view/47`)
- Section ID: **100771** (from `group_id=100771`)

**Step 1:** Build the gulp command based on provided arguments.

If both suite and section provided ({{arg1}} and {{arg2}}):
```bash
cd ai-automation && npx gulp generate-suite --suiteId={{arg1}} --sectionId={{arg2}}
```

If only suite provided ({{arg1}} only):
```bash
cd ai-automation && npx gulp generate-suite --suiteId={{arg1}}
```

If no arguments provided, ask the user for the suite ID and optionally the section ID using AskUserQuestion tool.

**Step 2:** Run the command and show the output.

**Notes:**
- This will generate tests sequentially, learning from each previous test
- The same Claude Code session handles all generations for better context
- Progress and summary will be shown at the end
- Tests are NOT automatically run after generation
