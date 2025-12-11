# Generate Test from TestRail

Generate a single Roku automation test from a TestRail case ID.

**Usage:** `/gen C845255`

**What this does:**
1. Changes to ai-automation directory
2. Runs gulp generate-test with the provided case ID
3. Shows you the generation progress and results

**Arguments:**
- `{{arg1}}` - TestRail case ID (e.g., C845255 or 845255)

Run the command:
```bash
cd ai-automation && npx gulp generate-test --caseId={{arg1}}
```
