# Query Roku Device UI

Query the Roku device UI tree and search for specific elements.

**Usage:** `/query-ui lego`

**What this does:**
1. Extracts the Roku device IP from rta-config.json
2. Fetches the current UI tree from http://IP:8060/query/app-ui
3. Searches for elements matching your search term
4. Displays matching nodes with their attributes and keypaths
5. Shows instructions on how to add the element to elements.ts

**Arguments:**
- `{{arg1}}` - Search term to find in the UI tree (e.g., "lego", "playButton", "searchMenuText")

**Example:**
```
/query-ui lego
```

This will search the Roku UI for any elements containing "lego" and show you their keypaths and attributes.

Run these commands:
```bash
ROKU_IP=$(grep -o '"host": "[^"]*"' rta-config.json | head -1 | cut -d'"' -f4); curl -s "http://${ROKU_IP}:8060/query/app-ui" | grep -i "{{arg1}}" | head -20
```

**How to add the found element to elements.ts:**

After finding the element, add it to `automated-tests-config/elements.ts`:

1. Identify the element name attribute from the XML (e.g., `name="searchHintText"`)
2. Build the keyPath from the XML hierarchy (e.g., `#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#searchHintText`)
3. Add to the elements object with a descriptive comment:

```typescript
/** Description of what this element represents */
elementName: {
  keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#screenName.#elementName',
},
```

**Example:**
```typescript
/** Search hint text showing number of titles found (e.g., "193 titles found") */
searchHintText: {
  keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#searchHintText',
},
```
