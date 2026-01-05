# Query Roku Device UI

Query the Roku device UI tree, find elements, and add them to elements.ts.

**Usage:** `/query-ui [search_term]`

**What this does:**
1. Prompts for a search term if not provided as an argument
2. Extracts the Roku device IP from rta-config.json
3. Fetches the current UI tree from http://IP:8060/query/app-ui
4. Searches for elements matching your search term
5. Displays matching nodes with their attributes
6. **Automatically adds the found element to elements.ts** (if you confirm)

**Arguments:**
- `{{arg1}}` - (Optional) Search term to find in the UI tree (e.g., "lego", "playButton", "searchMenuText", "193 titles found")

**Examples:**
```
/query-ui skinAdRow
/query-ui 193 titles found
/query-ui
```

If you run `/query-ui` without arguments, I will ask you for the search term.

**Step 1:** If no search term provided (`{{arg1}}` is empty), ask the user for the search term using AskUserQuestion tool.

**Step 2:** Extract the Roku IP:
```bash
grep -o '"host": "[^"]*"' rta-config.json | head -1 | cut -d'"' -f4
```

**Step 3:** Search for the element using the search term (either from `{{arg1}}` or from user input):
```bash
curl -s "http://ROKU_IP:8060/query/app-ui" | grep -F 'SEARCH_TERM' | head -20
```

Replace `ROKU_IP` with the IP from Step 2 and `SEARCH_TERM` with the search term from Step 1 or `{{arg1}}`.

**Step 4:** Get more context (show 10 lines before the match to understand the hierarchy):
```bash
curl -s "http://ROKU_IP:8060/query/app-ui" | grep -B 10 'SEARCH_TERM' | head -30
```

**Step 5:** After showing the results, ask the user:
1. What name to use for this element in elements.ts (suggest using the element's `name` attribute)
2. What description to use for the element

**Step 6:** Build the keyPath from the XML hierarchy and add the element to `automated-tests-config/elements.ts` with:
- The chosen element name as the key
- A comment with the description
- The keyPath built from the XML structure

**Notes:**
- Uses `-F` for fixed string matching to handle special characters in URLs
- The keyPath should follow the pattern: `#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#screenName...#elementName`
- Add the new element near similar elements in elements.ts (e.g., home screen elements together)
