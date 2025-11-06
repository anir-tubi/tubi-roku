# Claude Code Instructions for Roku Test Automation

## Automatic Behaviors

### When a Test Fails

1. Search `ai-automation/learned-fixes.md` for similar past fixes
2. If not found, analyze existing tests in `js/automated-tests/tests/` to understand patterns
3. Identify the error type (empty string, visibility, focus, timing, etc.)
4. Apply the appropriate fix based on similar patterns
5. Explain the root cause and solution to the user
6. Offer to record the fix to `learned-fixes.md`

### When Generating Tests

1. Analyze existing tests in `js/automated-tests/tests/` to learn current patterns
2. Check `ai-automation/learned-fixes.md` for common issues on that screen
3. Proactively add waits based on learned patterns
4. Follow the same structure and imports as existing tests
5. **Only import what you actually use** - Do not include unused imports (e.g., don't import `odc` or `utils` if not used)
6. **File naming and organization:**
   - Use the **last part of sub-section** (after last ›) from TestRail for filename, replacing spaces with dashes
   - Example: "Details Page › Series Details Page" → `series-details-page.ts` (uses "Series Details Page")
   - If no sub-section, use main section instead
   - **Check if file exists first:** Search `js/automated-tests/tests/` for matching filename
   - **If file exists:** Add the new test case to the existing file as a new `it()` block
   - **If file doesn't exist:** Create new file with the test case
   - This keeps tests organized by specific feature rather than creating one file per test case

### After Fixing a Test

1. Offer to record the fix to `learned-fixes.md`
2. If user agrees, gather:
   - Test file path
   - Error message
   - Root cause
   - Solution applied
   - Code changes (before/after)
3. Add new entry to `learned-fixes.md`
4. Update statistics in the document

## Core Principles

- **Always add waits before assertions** - Never assert immediately after getting an element
- **Use specific waits, not sleeps** - Wait for actual conditions, not arbitrary time
- **Layer waits properly** - Screen visible → Element visible → Field populated → Assert
- **Learn from code** - Analyze actual test files to understand patterns, not documentation
- **Record fixes** - Build institutional knowledge by documenting every fix

## Learning System

This project uses a learning feedback loop:

1. **Error occurs** → Search `learned-fixes.md` for similar past fixes
2. **Analyze code** → If no match, study existing tests to understand patterns
3. **Apply fix** → Use proven solution or create new one
4. **Record fix** → Add to `learned-fixes.md` with details
5. **Future tests** → Generated with accumulated knowledge built-in

The more fixes recorded, the smarter the system becomes.

## Error Recognition

When you see these patterns, search for similar fixes in `learned-fixes.md`:

- `expected '' to match` or `expected '' to equal` → Empty string error (field not populated yet)
- `expected false to equal true` (visibility) → Visibility error (element not rendered yet)
- `expected undefined to exist` → Element missing or not loaded yet
- `Timed out waiting` → Wait condition failed (check prerequisites)
- `Element not found in elements.ts` → Run `npx gulp findElement --elementName=X`

---

**Key Takeaway:** Build knowledge by recording every fix to `ai-automation/learned-fixes.md`. This creates a growing database of proven solutions.
