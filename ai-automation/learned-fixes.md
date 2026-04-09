# Learned Test Fixes

Track test failures and solutions to build institutional knowledge. Claude Code references this file to find similar past fixes and apply proven solutions.

---

## Fix Template

```markdown
### Fix #[NUMBER]: [Brief Description]
**Date:** YYYY-MM-DD
**Test File:** `path/to/test.ts`
**Error Type:** [Empty String | Visibility | Undefined | Focus | Grid | Player | Navigation | Property]

**Error Message:**
[Exact error message]

**Root Cause:**
[Why this happened]

**Solution Applied:**
[What was changed]

**Code Changes:**
BEFORE:
[Failing code]

AFTER:
[Fixed code]

**Pattern Matched:** [Similar to Fix #X, or new pattern]
**Lessons Learned:** [Key insights]
```

---

## Recorded Fixes

### Fix #1: Creator Search Test Requires Experiment Override
**Date:** 2026-03-25
**Test File:** `js/automated-tests/tests/creatorverse.ts`
**Error Type:** Visibility

**Error Message:**
```
Error: Search results grid does not contain expected Creator Page tile
```

**Root Cause:**
1. The `roku_search_creator_tile_v1` experiment defaults to `enabled: false`, so creator tiles never appear in results without an explicit override.

**Solution Applied:**
1. Added `experimentOverrides` to `startApplicationAtPage` to enable `roku_search_creator_tile_v1`.

**Code Changes:**
BEFORE:
```typescript
await testUtils.startApplicationAtPage('home', { shouldCreateNewUser: true });
```

AFTER:
```typescript
await testUtils.startApplicationAtPage('home', {
  shouldCreateNewUser: true,
  experimentOverrides: {
    roku_search_creator_tile: {
      roku_search_creator_tile_v1: {
        default: { "enabled": true }
      }
    }
  }
});
```

**Pattern Matched:** New pattern
**Lessons Learned:**
- Search tests that depend on feature-flagged content MUST include the corresponding `experimentOverrides` in `startApplicationAtPage`.
- Experiment name for creator tiles in search: `roku_search_creator_tile` / `roku_search_creator_tile_v1` with `{ "enabled": true }`.

---

## Error Patterns Summary

---

## Screen-Specific Patterns