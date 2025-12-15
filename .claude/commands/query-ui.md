# Query Roku Device UI

Query the Roku device UI tree, find elements, and add them to elements.ts.

**Usage:** `/query-ui lego`

**What this does:**
1. Extracts the Roku device IP from rta-config.json
2. Fetches the current UI tree from http://IP:8060/query/app-ui
3. Searches for elements matching your search term
4. Displays matching nodes with their attributes
5. **Automatically adds the found element to elements.ts** (if you confirm)

**Arguments:**
- `{{arg1}}` - Search term to find in the UI tree (e.g., "lego", "playButton", "searchMenuText", "193 titles found")

**Example:**
```
/query-ui 193 titles found
```

This will search the Roku UI for any elements containing "193 titles found", show you the results, and then add it to elements.ts.

First, extract the Roku IP:
```bash
grep -o '"host": "[^"]*"' rta-config.json | head -1 | cut -d'"' -f4
```

Then search for the element (replace ROKU_IP with the IP from above):
```bash
curl -s "http://ROKU_IP:8060/query/app-ui" | grep -F '{{arg1}}' | head -20
```

After showing the results, I will:
1. Analyze the XML structure to identify the element name and attributes
2. Ask you what name you want to use for the element in elements.ts
3. Ask for a description of what the element represents
4. Build the correct keyPath from the XML hierarchy
5. Add the element to `automated-tests-config/elements.ts` with proper formatting

**Note:**
- Uses `-F` for fixed string matching to handle special characters in URLs
- Replace `ROKU_IP` with the actual IP address from the first command (usually 192.168.1.220)
