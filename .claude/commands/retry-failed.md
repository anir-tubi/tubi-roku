# Smart Test Retry

Automatically find and retry all failing tests, applying learned fixes.

**Usage:** `/retry-failed`

**What this does:**

1. **Scans Recent Test Runs**
   - Looks for failed test output in recent mocha runs
   - Extracts test case IDs from failures (e.g., C842086, C842118)

2. **Analyzes Each Failure**
   - Categorizes error type (timing, visibility, missing element, etc.)
   - Checks learned-fixes.md for similar past solutions
   - Applies appropriate fixes automatically

3. **Re-runs Tests Intelligently**
   - Runs each failed test individually with proper timeouts
   - Uses the retry logic built into gulp generate-test
   - Reports which tests now pass and which still fail

4. **Provides Summary**
   - Shows: Total failed → How many fixed → Still failing
   - Lists any tests that need manual attention

**Example Output:**
```
Found 5 failed tests:
✓ C842086 - Now passing (visibility fix applied)
✓ C842118 - Now passing (timing fix applied)
✗ C842120 - Still failing (needs manual review)
✓ C842088 - Now passing (missing element added)
✓ C842089 - Now passing (reused fix from C842088)

Summary: 4/5 tests fixed automatically
```

**When to use:**
- After running a full test suite
- When you see multiple test failures
- To apply learned fixes to old failing tests
