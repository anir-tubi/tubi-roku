# Claude Code Instructions for Roku Test Automation

## Finding UI Elements: ALWAYS Use App-UI API

🚨 **CRITICAL WORKFLOW: When asked to find an element path/keyPath/xpath:**

**✅ CORRECT Process:**
1. Read `rta-config.json` to get the device IP address (in `RokuDevice.devices[0].host`)
2. Query the app-ui API endpoint: `http://{device-ip}:8060/query/app-ui`
3. Search the returned XML for the element name
4. Extract the keyPath from the XML structure
5. Add the element definition to `automated-tests-config/elements.ts`

**Example:**
```bash
# Get device IP from rta-config.json (e.g., 192.168.1.4)
curl -s "http://192.168.1.4:8060/query/app-ui" | grep -A 10 "elementName"
```

**❌ NEVER:**
- Use `grep` to search the codebase for element definitions
- Use `npx app-ui find elementName` (this command doesn't exist)
- Guess or assume element paths without verifying via app-ui API
- Search files like `elements.ts` or Roku source files for element structure

**Why:** The app-ui API returns the ACTUAL current UI tree structure from the running Roku app. Searching the codebase only shows previously defined elements, not the actual UI structure.

**When to use:** Any time you need to:
- Find a new element that's not in elements.ts
- Verify the structure of an existing element
- Debug element path issues
- Understand UI hierarchy for nested elements

## Automatic Behaviors

### When a Test Fails

1. Search `ai-automation/learned-fixes.md` for similar past fixes
2. If not found, analyze existing tests in `js/automated-tests/tests/` to understand patterns
3. Identify the error type (empty string, visibility, focus, timing, etc.)
4. Apply the appropriate fix based on similar patterns
5. Explain the root cause and solution to the user
6. Offer to record the fix to `learned-fixes.md`

### When Generating Tests

1. **🚨 MANDATORY FIRST STEP: Analyze method signatures before using ANY function**
   - **Before writing ANY code, read the actual method definitions:**
     - Read `js/automated-tests/test-utils.ts` to see ALL available methods and their signatures
     - Read `js/automated-tests/test-helpers.ts` to see ALL available helper methods and their signatures
   - **Search for the exact method definition using:**
     - Pattern: `grep "methodName.*{" js/automated-tests/test-utils.ts`
     - Example: `grep "waitForCurrentScreenToEqual.*{" js/automated-tests/test-utils.ts`
   - **Read the parameter list from the actual TypeScript method definition**
   - **NEVER guess parameters - always verify the actual signature first**
   - **Common mistakes to avoid:**
     - ❌ `retryWithTimeOut(callback, timeout, message)` - WRONG! No message parameter
     - ✅ `retryWithTimeOut(callback, timeout)` - CORRECT! Only 2 parameters
     - ❌ `waitForCurrentScreenToEqual(screenId, message, timeout)` - WRONG! No message parameter
     - ✅ `waitForCurrentScreenToEqual(screenId, timeout)` - CORRECT! Only 2 parameters

2. **CRITICAL: Use ONLY existing helper functions from the codebase**
   - ✅ FIRST check `js/automated-tests/test-helpers.ts` for documented helper functions
   - ✅ Then check `js/automated-tests/test-utils.ts` for utility functions
   - ✅ Look at similar tests in the same file to see what functions they use
   - ✅ Use raw `ecp.sendKeypress()`, `odc`, and `utils.sleep()` for actions not covered by helpers
   
   **📚 Available Helper Modules:**
   - **`test-helpers.ts`** - High-level test helpers (CLASS-BASED SINGLETON)
     - Import: `import { testHelpers } from '../test-helpers';` (or `shared` for backward compatibility)
     - Usage: `await testHelpers.createHistory();`
     - **All helpers are GENERIC and FLEXIBLE** - accept parameters for customization
     - **Comprehensively documented** with JSDoc explaining when to use each helper
     - **Categories:** Navigation, Playback, Detail Screen, Autoplay, Settings, Parental Controls, User Management, Content Management, Verification
     - **Key Feature:** Generic helpers replace specific ones (e.g., `navigateToPage()` instead of separate `openMovies()`, `openSeries()`)
   - **`test-utils.ts`** - Core utilities (CLASS-BASED SINGLETON)
     - Import: `import { testUtils } from '../test-utils';`
     - Usage: `await testUtils.startApplicationAtPage('movies');`
   
   - **Example - Common Mistakes:**
     ```typescript
     await testHelpers.createHistory('movie'); // ❌ Wrong signature
     import { createHistory } from '../test-helpers'; // ❌ Wrong - not a named export
     ```
   - **Example - Correct Usage:**
     ```typescript
     import { testHelpers } from '../test-helpers';
     import { testUtils } from '../test-utils';

     await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
     await testHelpers.navigateToPage('movies', 'movieScreenRowList');
     await testHelpers.createHistory(); // No args, or optional seekTimeMs
     ```

   **🎯 Common Helper Patterns (from test-helpers.ts):**
   
   **Navigation:**
   - `startAtHomeScreen(shouldCreateNewUser?, user?)` - Start app at home
   - `navigateToPage(page, waitForElement?)` - Generic page navigation
   - `selectSideNavMenuItem(title, confirmElement?)` - Side nav selection
   - `openCategoriesPage()` - Complete Categories flow
   - `jumpToContinueWatchingRow()` - Jump to CW row
   
   **Playback:**
   - `startPlaybackAndWait(playerElement?, timeout?)` - Press Play + wait
   - `seekToEnd(playerElement?)` - Seek to end for autoplay
   - `exitPlayback(expectedScreen?, backCount?)` - Exit with Back key
   
   **Detail Screen:**
   - `openDetailScreen(titleElement?)` - Press OK + wait
   - `selectLikeOnDetailScreen(confirmElement?)` - Like button flow
   - `selectDislikeOnDetailScreen(focusedElement?)` - Dislike flow
   
   **Autoplay:**
   - `triggerMovieAutoplay(shouldCreateNewUser?, verifyPlayerSize?)` - Complete flow
   - `verifyAutoplayUIShowing(countdownElement?, secondsElement?, verifyPlayerSize?)` - Verify showing
   - `verifyAutoplayUINotShowing(countdownElement?, verifyPlayerSize?)` - Verify NOT showing
   
   **Settings:**
   - `toggleSetting(menuElement, rowIndex, skipElement?)` - Generic toggle
   - `setAutoplay(enabled)` - Turn autoplay ON/OFF
   - `setPreview(enabled)` - Turn preview ON/OFF
   
   **Parental Controls:**
   - `selectParentalControlLevel(level)` - Generic level selector ('littleKids' | 'olderKids' | 'teens' | 'adults')
   - `setParentalControls(level, password?, shouldDismiss?)` - Complete flow with verification
   - `enterPassword(password?, handleKeyboard?)` - Generic password entry
   
   **Verification:**
   - `verifyElementVisible(elementId, expectedValue?)` - Check visibility
   - `verifyElementText(elementId, expectedText, shouldContain?)` - Check text
   - `verifyElementField(elementId, fieldName, expectedValue)` - Check any field
   - `verifyEmptyMyStuffScreen()` - My Stuff empty state
   
   **Content Management:**
   - `createFlexibleUserHistory(user, contentConfig)` - Custom history
   - `createFlexibleUserWatchList(user, contentConfig)` - Custom watchlist
   - `createMixedKidsAndAdultContent(user)` - Kids + adult content
   - `createHistoryForSingleTitle(user, contentType, rating?, watchTime?, hasVideoPreview?)` - Single title
   
   **Generic Interactions:**
   - `navigate(direction, count?, waitForElement?, waitTime?)` - Generic direction nav
   - `pressKeyAndWait(key, count?, waitForElement?, waitForScreen?)` - Press + wait
   - `jumpToRowAndSelect(listElement, rowTitle, shouldSelect?, confirmElement?)` - Jump + optional select

2. Analyze existing tests in `js/automated-tests/tests/` to learn current patterns
3. Check `ai-automation/learned-fixes.md` for common issues on that screen
4. Proactively add waits based on learned patterns
5. **CRITICAL: Use the correct import pattern:**
   - ✅ CORRECT: `import { ecp, odc, utils } from 'roku-test-automation';`
   - ✅ CORRECT: `import { testUtils } from '../test-utils';`
   - ❌ WRONG: `import { ecp } from '../src/ecp';` or `import { odc } from '../src/odc';`
   - Always import `ecp`, `odc`, `utils` from `'roku-test-automation'` package
6. **Only import what you actually use** - Do not include unused imports (e.g., don't import `odc` or `utils` if not used)
7. **File naming and organization:**
   - Use the **last part of sub-section** (after last ›) from TestRail for filename, replacing spaces with dashes
   - Example: "Details Page › Series Details Page" → `series-details-page.ts` (uses "Series Details Page")
   - If no sub-section, use main section instead
   - **Check if file exists first:** Search `js/automated-tests/tests/` for matching filename
   - **If file exists:** Add the new test case to the existing file as a new `it()` block
   - **If file doesn't exist:** Create new file with the test case
   - This keeps tests organized by specific feature rather than creating one file per test case

8. **CRITICAL: Test Setup and before/beforeEach Hooks**
   - **If adding to existing file with `before()` or `beforeEach()` hooks:**
     - The test MUST use the setup from those hooks (don't call `startApplicationAtPage()` again in the test)
     - OR place the test in a NEW separate `describe` block without conflicting hooks
   - **Each test should be self-contained:**
     - Call `startApplicationAtPage()` at the beginning of EACH test
     - Do NOT rely on shared `before()` hooks that might fail
     - This ensures the test can run with `.only()` for debugging
   - **Example - GOOD (self-contained):**
     ```typescript
     it('C12345 - Test Name', async () => {
       await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
       await testUtils.waitForElementToHaveFocus('movieScreenRowList');
       // ... rest of test
     });
     ```
   - **Example - BAD (relies on before() hook):**
     ```typescript
     describe('Movies', function() {
       before(async () => {
         await testUtils.startApplicationAtPage('movies'); // Runs once for ALL tests
       });
       it('C12345 - Test Name', async () => {
         // Assumes setup from before() hook - will fail if before() fails
       });
     });
     ```

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
- **Use actual element names** - Use string element names like `'movieScreenRowList'`, `'detailScreenTitle'`, NOT `elements.detailsPage.buttonList`
- **Never invent helper functions** - If a function doesn't exist in the test file or test-utils, use raw ECP/ODC commands
- **⚠️ ALWAYS VERIFY ENUM VALUES** - Before using ANY enum (e.g., `ecp.Key.*`, `testUtils.*`, etc.), search existing test files to discover the correct enum value. DO NOT guess or assume enum names - always verify by searching the codebase for actual usage patterns.
- **⚠️ ANALYZE NODE MODULES** - When using external libraries (e.g., `roku-test-automation`, `chai`, `mocha`), read the module's source code or type definitions to understand available options, methods, and enums. Check `node_modules/<package>/` for implementation details or `node_modules/@types/<package>/` for TypeScript definitions. Examples:
  - For `ecp.Key.*` enums → Check `node_modules/roku-test-automation/` for Key enum definition
  - For `expect()` matchers → Check `node_modules/chai/` or `node_modules/@types/chai/`
  - For function signatures and options → Read the actual module code, don't assume based on names

## Common Test Language Patterns

### Button Presses and Remote Control Actions
When test cases say:
- **"Press OK"** → `await ecp.sendKeypress(ecp.Key.Ok);`
- **"Tap OK"** → `await ecp.sendKeypress(ecp.Key.Ok);`
- **"Select"** → `await ecp.sendKeypress(ecp.Key.Ok);`
- **"Press Back"** → `await ecp.sendKeypress(ecp.Key.Back);`
- **"Press Down"** → `await ecp.sendKeypress(ecp.Key.Down);`
- **"Press Up"** → `await ecp.sendKeypress(ecp.Key.Up);`
- **"Press Play"** → `await ecp.sendKeypress(ecp.Key.Play);`

Example: "Press OK on the title" means:
1. Title is already in focus (or navigate to it)
2. Send OK keypress: `await ecp.sendKeypress(ecp.Key.Ok);`

### Playback Actions
When test cases say:
- **"Begin playback"** → Press Play button: `await ecp.sendKeypress(ecp.Key.Play);`
- **"Start playback"** → `await ecp.sendKeypress(ecp.Key.Play);` then wait for state
- **"Play the video"** → `await ecp.sendKeypress(ecp.Key.Play);`
- **"Verify playing"** → Check player state: `await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);`
- **⚠️ After Fast Forward or Rewind** → ALWAYS press Play to resume playback:
  ```typescript
  await ecp.sendKeypress(ecp.Key.Forward, { count: 10 }); // Fast forward
  await ecp.sendKeypress(ecp.Key.Play); // Resume playback
  await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);
  ```

Example: "When title in BWW is in focus, tapping OK will begin playback" means:
1. Navigate to BWW and focus on a title
2. Press OK: `await ecp.sendKeypress(ecp.Key.Ok);`
3. Wait for playback: `await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);`


## Common Acronyms and UI Component Names

Understanding alternative names for the same UI components:

### Browse While Watching (BWW)
- **Acronym:** BWW
- **Also called:**
  - YMAL (You May Also Like)
  - Related Content
  - Recommendations
  - Browse Watch While
- **Description:** Content recommendations shown during video playback that allow browsing without stopping the video

### Continue Watching (CW)
- **Acronym:** CW
- **Also called:**
  - Resume
  - In Progress
  - Watch History
- **Description:** Row showing content with playback progress that can be resumed

### My List (ML)
- **Acronym:** ML
- **Also called:**
  - Watch List
  - Watchlist
  - Favorites
  - My Stuff
- **Description:** User's saved content for later watching

### Parental Controls (PC)
- **Acronym:** PC
- **Also called:**
  - Parental Control
  - Kids Safe
  - Content Restrictions
- **Description:** Settings to restrict content based on ratings

### Sea Lion / Live TV (SL)
- **Acronym:** SL
- **Also called:**
  - Sea Lion
  - Live
  - Live TV
  - Linear TV
- **Description:** Live TV streaming feature

### Video Preview (VP)
- **Acronym:** VP
- **Also called:**
  - Video Preview
  - Preview
  - Trailer
  - Auto Preview
- **Description:** Short video previews that play automatically on detail screens

**When generating tests or finding elements:** If you see these acronyms in test cases or element names, understand they may refer to any of their alternative names in the actual UI/code.

## Common Test Patterns by Screen

### Details Page Tests
When testing Details Page (Movie/Series Details):

**Setup Pattern:**
```typescript
await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');
```

**⚠️ CRITICAL: Understanding "Movie with History" in Test Cases**

If the test case says:
- "Given movie has history"
- "Select Movie title with history"
- "Movie with history"
- "Title with history"

**This means YOU MUST CREATE HISTORY IN THE TEST!**

DO NOT try to find or select an existing movie with history. Instead:
1. Launch to Movies page
2. Select ANY movie (first one is fine)
3. Play it to create history
4. Back out to details page
5. THEN test the behavior

**Creating History - CORRECT Pattern (using test-helpers.ts):**
```typescript
import { testHelpers } from '../test-helpers';

// STEP 1: Launch and select a movie
await testUtils.startApplicationAtPage('movies', { shouldCreateNewUser: true });
await testUtils.waitForElementToHaveFocus('movieScreenRowList', 'Timed out waiting for Rowlist to have focus');

// STEP 2: Play content to create history
await ecp.sendKeypress(ecp.Key.Play);
await testHelpers.createHistory(); // ✅ Creates 2min watch time

// STEP 3: Back to Details page
await utils.sleep(2000);
await ecp.sendKeypress(ecp.Key.Back);

// NOW you can test "Remove from History" behavior
await utils.sleep(2500);
await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
```

**Available History Helpers (from test-helpers.ts):**
```typescript
import { testHelpers } from '../test-helpers';

await testHelpers.createHistory();             // Creates 2min watch history (default)
await testHelpers.verifyPlayFromBeginning();   // Verifies playback starts at 0
await testHelpers.verifyResumeWithinRange();   // Verifies resume position is correct

// Create history with custom seek time
await testHelpers.createHistory(60000);        // Seek to 1 minute instead of 2

// NEW GENERIC HELPERS:
await testHelpers.startPlaybackAndWait();      // Press Play + wait for playing state
await testHelpers.exitPlayback('detailScreen', 1); // Exit to detail screen
await testHelpers.seekToEnd();                 // Seek to end (for autoplay tests)
```

**Navigation:**
```typescript
// Back to details page
await ecp.sendKeypress(ecp.Key.Back);
await testUtils.waitForCurrentScreenToEqual('detailScreen');

// Select detail page menu item
await testUtils.selectAndVerifyDetailPageMenuItem('removeFromHistory');
await testUtils.selectAndVerifyDetailPageMenuItem('addToMyList');
```

**Assertions:**
```typescript
// Use waitForElementToShowOnScreen for visibility checks
await testUtils.waitForElementToShowOnScreen('detailScreenTitle', 'Title not visible', 10000);
await testUtils.waitForElementToFullyShowOnScreen('detailScreenTitle', 'Title not fully shown', 10000);

// ⚠️ CRITICAL: Use getElementField to access ANY field from an element node
// DO NOT use getNodeForElement and access properties directly
// getElementField has built-in timeout and error handling

// ❌ WRONG: Direct property access
const element = await testUtils.getNodeForElement('detailScreenTitle');
expect(element.text).to.contain('Expected Title');

// ✅ CORRECT: Use getElementField for any field access
const text = await testUtils.getElementField('detailScreenTitle', 'text');
expect(text).to.contain('Expected Title');

// Accessing content metadata
const content = await testUtils.getElementField('videoPlayerScreen', 'content');
const title = content.title;
const videoId = content.id;

// Accessing other fields (state, visible, focused, etc.)
const adState = await testUtils.getElementField('videoPlayerScreen', 'adState');
const playerState = await testUtils.getElementField('videoPlayerScreen', 'state');
const isVisible = await testUtils.getElementField('detailScreenTitle', 'visible');
const isFocused = await testUtils.getElementField('movieScreenRowList', 'hasFocus');
```

**Getting Focused Items:**
```typescript
// ⚠️ CRITICAL: getCurrentlyFocusedGridItemContent is ONLY for grids/lists
// DO NOT use it for button lists, menus, or non-grid elements

// ❌ WRONG: Using getCurrentlyFocusedGridItemContent on a button list
const focusedButton = await testUtils.getCurrentlyFocusedGridItemContent('vodDetailScreenMenu');
expect(focusedButton.id).to.equal('resume');

// ✅ CORRECT: Use odc.getFocusedNode() for button lists and non-grid elements
const { node } = await odc.getFocusedNode();
expect(node.id).to.equal('resume');

// ✅ CORRECT: getCurrentlyFocusedGridItemContent for actual grids/lists
const focusedItem = await testUtils.getCurrentlyFocusedGridItemContent('movieScreenRowList');
expect(focusedItem.title).to.contain('Expected Title');

// Rule of thumb:
// - For RowList, Grid, CategoryGridList → use getCurrentlyFocusedGridItemContent
// - For ButtonList, EnhancedButtonList, Menu → use odc.getFocusedNode()
// - When in doubt → use odc.getFocusedNode()
```

**Accessing Nested Node Properties:**
```typescript
// ⚠️ CRITICAL: Cannot access nested node properties directly in automated tests
// Both findNode() and property chaining are NOT available in test automation

// ❌ WRONG: Using findNode() to access child nodes
const button = await testUtils.getNodeForElement('vodDetailScreenMenu');
const labelGroup = button.findNode('labelGroup'); // ERROR: findNode is not available!
const isLabelVisible = labelGroup.visible === true;

// ❌ WRONG: Using property chaining to access nested elements
const menu = await testUtils.getNodeForElement('vodDetailScreenMenu');
const firstButton = menu.buttons[0];
const labelGroup = firstButton.elementsGroup?.titleGroup?.labelGroup; // ERROR: Cannot traverse nested objects!
const isLabelVisible = labelGroup?.visible === true;

// ❌ WRONG: Trying to access nested properties from button arrays
const buttons = menu.buttons;
for (let i = 0; i < buttons.length; i++) {
  const button = buttons[i];
  const labelGroup = button.elementsGroup?.titleGroup?.labelGroup; // ERROR: Nested traversal not supported!
}

// ✅ CORRECT: Define EACH nested element in elements.ts with xpath
// In automated-tests-config/elements.ts, add separate entries for each button's nested elements:
//
// likeButtonLabelGroup: {
//   keyPath: '#ContentController...#actionButtonList.#like.#elementsGroup.#titleGroup.#labelGroup',
//   xpath: '//EnhancedButton[@name="like"]//RenderableNode[@name="labelGroup"]'
// }
//
// dislikeButtonLabelGroup: {
//   keyPath: '#ContentController...#actionButtonList.#dislike.#elementsGroup.#titleGroup.#labelGroup',
//   xpath: '//EnhancedButton[@name="dislike"]//RenderableNode[@name="labelGroup"]'
// }

// Then in your test:
const likeButtonLabel = await testUtils.getNodeForElement('likeButtonLabelGroup');
const isLikeLabelVisible = likeButtonLabel.visible === true && likeButtonLabel.opacity > 0;

const dislikeButtonLabel = await testUtils.getNodeForElement('dislikeButtonLabelGroup');
const isDislikeLabelVisible = dislikeButtonLabel.visible === true && dislikeButtonLabel.opacity > 0;

// ✅ ALTERNATIVE: Use app-ui query during test development
// For exploring nested structure, query app-ui:
// curl -s "http://192.168.1.231:8060/query/app-ui" | grep -A 10 "like"
```

**Rule:** For accessing any nested child node properties (like button.elementsGroup.labelGroup, button.icon, etc.):
1. Define EACH nested element separately in `automated-tests-config/elements.ts` with keyPath AND xpath
2. Use `testUtils.getNodeForElement()` to access each element independently
3. NEVER use `findNode()` or property chaining (`.elementsGroup?.titleGroup`) - neither work in test automation
4. Create one element definition per nested node you need to access
5. Use app-ui queries for exploration/debugging during test development

**Why this limitation exists:**
- Test automation can only access nodes that are directly defined in elements.ts
- The returned node objects don't have child nodes populated - they only have direct properties
- Property chaining like `button.elementsGroup.titleGroup.labelGroup` returns undefined because child nodes aren't included
- You must define the full xpath to each nested element you want to access

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
- `Could not get node for element 'xxx'` → Element xpath is stale or element doesn't exist on current screen

## Common Test Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Using `retryWithTimeOut` for simple visibility checks
```typescript
// BAD - verbose and harder to debug
await testUtils.retryWithTimeOut(async () => {
  const element = await testUtils.getNodeForElement('browseWhileWatchingHeader');
  expect(element.visible).to.equal(true);
}, 10000, 'BWW not shown');
```

**✅ CORRECT:**
```typescript
// GOOD - simpler and provides better error messages
await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown below transport controls', 10000);
```

### ❌ Anti-Pattern 2: Using large arbitrary sleeps instead of specific waits
```typescript
// BAD - brittle and slow
await ecp.sendKeypress(ecp.Key.Down);
await utils.sleep(3000); // Why 3000? Is it enough? Too much?
await ecp.sendKeypress(ecp.Key.Down);
await utils.sleep(3500); // Random wait times
```

**✅ CORRECT:**
```typescript
// GOOD - wait for specific conditions
await ecp.sendKeypress(ecp.Key.Down);
await testUtils.waitForElementToFullyShowOnScreen('transportButtons', 'Transport not shown', 10000);
await ecp.sendKeypress(ecp.Key.Down);
await testUtils.waitForElementToShowOnScreen('browseWhileWatchingHeader', 'BWW not shown', 10000);
```

**Sleep Usage Rules:**
- ⛔ **NEVER use sleeps > 2000ms** - use specific wait helpers instead
- ⚠️ **Minimize sleeps < 2000ms** - prefer `waitForElementToShowOnScreen`, `waitForPlayerStateToEqual`, etc.
- ✅ **Only use small sleeps (500-1000ms)** for animation delays or between rapid key presses
- ✅ **Always prefer specific waits** over arbitrary sleeps

**When to use each pattern:**
- **`waitForElementToShowOnScreen`** - For checking if element is visible
- **`waitForElementToFullyShowOnScreen`** - For checking if element is fully rendered
- **`waitForPlayerStateToEqual(elementId, state, timeout)`** - For waiting for player state changes
  - ⚠️ **IMPORTANT**: Player states are NOT elements!
  - States: 'playing', 'paused', 'buffering', 'stopped'
  - **CORRECT**: `await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);`
  - **WRONG**: Do NOT try to find an element named 'playing'
- **`waitForElementToHaveFocus`** - For waiting for focus changes
- **`utils.sleep(500-1000)`** - ONLY for short animation delays
- **`retryWithTimeOut` + assertions** - Only for complex checks involving multiple conditions or field values

## Test Generation Process (5-STEP MANDATORY)

When generating a new test, follow these steps IN ORDER:

### **STEP 1: Understand Requirements**

a) **Read the Test Name** - this contains the EXPECTED BEHAVIOR
   * Examples:
     - "Year displayed and runtime not displayed" → Verify year IS visible AND runtime IS NOT visible
     - "Button is visible" → Verify button IS visible
     - "Movie has history" → YOU must create history in the test
   * Pay attention to: "not", "displayed", "hidden", "visible", "autoplay", "preview"

b) **Read the Pre-conditions** - this tells you what SETUP is needed
   * "be a signed in user" → Use shouldCreateNewUser or create registered user
   * "movie has history" → YOU must create history in the test
   * Identify correct user type (Guest vs Registered)

c) **Read the Test Steps** - this tells you the ACTIONS to perform
   * Understand complete test flow from start to finish
   * Identify all required user actions
   * Note expected outcomes at each step

d) **Derive Test Requirements** from Analysis:
   * Test Name = WHAT to verify (expected behavior)
   * Steps = HOW to get there (navigation and actions)
   * Pre-conditions = SETUP required before test
   * User authentication needs (Guest vs Registered user)
   * Screen navigation path
   * Required helper functions (createHistory, navigateToPage, etc.)
   * Assertions needed to verify behavior

### **STEP 2: READ test-helpers.ts (MANDATORY)**

🚨 YOU MUST READ THIS FILE BEFORE WRITING ANY CODE: `js/automated-tests/test-helpers.ts`

Look for helpers that match your requirements:
- Navigation helpers (navigateToPage, startAtHomeScreen, etc.)
- Playback helpers (startPlaybackAndWait, seekToEnd, etc.)
- Content helpers (createHistory, jumpToContinueWatchingRow, etc.)
- Verification helpers (verifyElementVisible, verifyElementText, etc.)

Read the JSDoc comments for each helper to understand:
- What it does
- What parameters it takes
- When to use it

If you find a helper that does what you need, USE IT. Do NOT write custom logic.

### **STEP 3: READ test-utils.ts (MANDATORY)**

🚨 YOU MUST READ THIS FILE: `js/automated-tests/test-utils.ts`

Look for utility functions:
- Wait functions (waitForElementToShowOnScreen, waitForPlayerStateToEqual, etc.)
- Element functions (getElementField, getNodeForElement, etc.)
- Navigation functions (startApplicationAtPage, waitForCurrentScreenToEqual, etc.)

Read the method signatures to understand parameters.
NEVER guess parameters - read the actual signature!

### **STEP 4: Look at Similar Tests in the Target File**

- Search for tests in the same section/screen
- Look for tests with similar requirements
- Copy the patterns they use
- See what imports they have at the top

### **STEP 5: Write Code Using Discovered Helpers**

- Use the helpers/utils you found in steps 2-4
- DO NOT write custom logic if a helper exists
- DO NOT manually iterate content if a helper can do it (use helper instead)
- DO NOT manually check conditions if a wait function exists

🚨 **CRITICAL EXAMPLES:**

❌ **WRONG** (writing custom iteration to find content with preview):
```typescript
const content = await testUtils.getRowListRowItemsContent('homeScreenRowList', 0);
for (const [itemIndex, item] of content.entries()) {
  if (item.video_preview_url !== '') {
    await testUtils.jumpToRowItem('homeScreenRowList', [0, itemIndex]);
    break;
  }
}
```

✅ **CORRECT** (using helper from test-helpers.ts):
```typescript
// Read test-helpers.ts and you'll find: findContentPositionInGridThatContainsVideoPreview
const position = await testHelpers.findContentPositionInGridThatContainsVideoPreview('homeScreenRowList', true);
if (position.length > 0) {
  await testUtils.jumpToRowItem('homeScreenRowList', position);
}
```

❌ **WRONG** (manually checking element visibility with retryWithTimeOut):
```typescript
await testUtils.retryWithTimeOut(async () => {
  const element = await testUtils.getNodeForElement('elementName');
  expect(element.visible).to.equal(true);
}, 10000);
```

✅ **CORRECT** (using dedicated wait function from test-utils.ts):
```typescript
await testUtils.waitForElementToShowOnScreen('elementName', 'Element not visible', 10000);
```

⚠️ **REMEMBER:**
- If test mentions "movie has history" → YOU must create history in test
- For "Remove from History" tests → Create history first, then remove
- DO NOT invent functions - only use what you find in steps 2-4
- Use raw ecp.sendKeypress(), odc, utils.sleep() only if no helper exists

## Understanding Element Behavior Patterns

### Combined-Info Elements

**FIRST: Analyze the element name to understand what it contains:**
- Element names like "titleAndGenre", "yearAndDuration", "nameAndRole" indicate COMBINED INFO in one element
- These elements show different pieces of info in their .text property based on app state
- The test verifies WHAT INFO IS SHOWN, not just if element is visible

**PATTERN 1: Testing content within a combined-info element**

When test says "X displayed and Y not displayed" AND element name is like "xAndY":

```typescript
// The element exists and is visible, but shows only some info
const element = await testUtils.getNodeForElement('combinedInfoElement');

// Check for presence of X (use appropriate pattern for what X is)
expect(element.text).to.match(/pattern-for-X/);

// Check for absence of Y (use appropriate pattern for what Y is)
expect(element.text).to.not.match(/pattern-for-Y/);
```

**Examples of regex patterns:**
- Year (4-digit number): `/\d{4}/`
- Duration/Runtime (time format): `/\d+\s*(h|hr|hour|min|m)/i`
- Genre (words): `/comedy|drama|action/i`
- Rating (like PG-13, R): `/\b(G|PG|PG-13|R|NC-17)\b/i`

**PATTERN 2: Testing visibility of separate elements**

When test says "X visible and Y not visible" AND elements are separate:

```typescript
const xElement = await testUtils.getNodeForElement('xElement');
expect(xElement.visible).to.equal(true);

const yElement = await testUtils.getNodeForElement('yElement');
expect(yElement.visible).to.equal(false);
```

**HOW TO DECIDE which pattern to use:**
1. Look at element names in the test steps or error messages
2. If element name combines multiple concepts (e.g., "titleAndYear") → Use PATTERN 1 (text matching)
3. If there are separate elements → Use PATTERN 2 (visibility checks)
4. Check existing tests in the same file for similar scenarios

### Getting Focused Items

⚠️ **getCurrentlyFocusedGridItemContent is ONLY for grids/lists**

DO NOT use it for button lists, menus, or non-grid elements!

❌ **WRONG:** Using getCurrentlyFocusedGridItemContent on a button list
```typescript
const focusedButton = await testUtils.getCurrentlyFocusedGridItemContent('vodDetailScreenMenu');
expect(focusedButton.id).to.equal('buttonId');
```

✅ **CORRECT:** Use odc.getFocusedNode() for button lists and non-grid elements
```typescript
const { node } = await odc.getFocusedNode();
expect(node.id).to.equal('expectedButtonId');
```

✅ **CORRECT:** getCurrentlyFocusedGridItemContent for actual grids/lists
```typescript
const focusedItem = await testUtils.getCurrentlyFocusedGridItemContent('movieScreenRowList');
expect(focusedItem.title).to.contain('some value');
```

**Rule of thumb:**
- For RowList, Grid, CategoryGridList → use getCurrentlyFocusedGridItemContent
- For ButtonList, EnhancedButtonList, Menu → use odc.getFocusedNode()
- When in doubt → use odc.getFocusedNode()

## Understanding Autoplay Behavior

### What "Autoplay" means in Tubi app:

When test cases mention "autoplay", this refers to the following sequence:

**1. Preview Phase:**
- User focuses on a title (on detail screen, home screen, or any screen with content)
- A preview video (trailer/clip) starts playing automatically in the background
- Element: `previewVideoPlayer`
- State: `'playing'`

**2. Autoplay Transition:**
- After the preview ends OR user waits on the focused title
- The preview TRANSFORMS into the actual video player
- The FULL content starts playing automatically
- Element transitions: `previewVideoPlayer` → `videoPlayerScreen`
- State: `'playing'`
- This can happen from ANY screen (detail screen, home screen, browse, etc.)

**3. Key Distinction:**
- **Preview** = Short trailer/clip that plays in background while browsing
- **Autoplay** = Full content playback that starts automatically after preview ends
- Autoplay is NOT the same as "pressing Play button"
- Autoplay happens automatically without user action
- Autoplay can trigger from any screen where preview is playing

### Testing Autoplay:

Example code:
```typescript
// Wait for preview to start (can be on any screen)
await testUtils.waitForPlayerStateToEqual('previewVideoPlayer', 'playing', 10000);

// Wait for preview to finish and autoplay to start (preview transforms to full player)
await testUtils.waitForCurrentScreenToEqual('videoPlayerScreen', 10000);
await testUtils.waitForPlayerStateToEqual('videoPlayerScreen', 'playing', 10000);

// Verify we're in actual playback, not preview
const content = await testUtils.getElementField('videoPlayerScreen', 'content');
expect(content.title).to.exist; // Should have actual content metadata
```

### Common Autoplay Test Scenarios:
- "Verify autoplay starts after preview" → Wait for videoPlayerScreen + playing state
- "Verify autoplay countdown appears" → Check for autoplay UI elements at end of content
- "Disable autoplay in settings" → Verify videoPlayerScreen does NOT appear after preview
- "Autoplay next episode" → After current content ends, next episode starts automatically
- Autoplay can trigger from home screen, detail screen, browse screens, etc.

---

**Key Takeaway:** Build knowledge by recording every fix to `ai-automation/learned-fixes.md`. This creates a growing database of proven solutions.
