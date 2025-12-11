# Batch Test Generation

Generate multiple test cases sequentially in one Claude Code session, leveraging persistent context for faster generation.

**Usage:** `/gen-batch C845208 C845209 C845210`

**Key Benefit:** The SAME Claude Code session generates all tests, so:
- Project context is loaded once (not for each test)
- Patterns learned from Test 1 automatically apply to Tests 2, 3, etc.
- Element mappings discovered in earlier tests are reused
- Much faster than running gulp generate-test separately

**How it works:**
For each test case ID you provide, I will:
1. Run `cd ai-automation && npx gulp generate-test --caseId=<ID>`
2. Wait for completion
3. Learn from any errors or fixes
4. Move to next test with accumulated knowledge

**Example:**
```
/gen-batch C845208 C845209 C845210 C845211
```

This generates 4 tests sequentially, with each one benefiting from the context of previous generations.

**Arguments:**
- Multiple test case IDs separated by spaces
- Can be in format C845208 or 845208
