# Translation Workflow Guide

This guide covers the complete workflow for managing translations in the Tubi Roku application, from adding new strings to deploying updates.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Translation System Architecture](#translation-system-architecture)
- [Adding New English Strings](#adding-new-english-strings)
- [Automated Translation Workflow](#automated-translation-workflow)
- [Troubleshooting](#troubleshooting)
- [Manual Commands Reference](#manual-commands-reference)
- [Best Practices](#best-practices)

## Overview

The Tubi Roku app supports multiple languages:
- **en-US** (English - United States) - Primary/source language
- **es-MX** (Spanish - Mexico)
- **fr-CA** (French - Canada)

All translations are managed through:
- **Local storage**: `translations/en-US.json` (source file)
- **BrightScript file**: `TubiLanguageTranslate.brs` (runtime translations)
- **Crowdin**: External translation management platform

## Prerequisites

Before working with translations, ensure you have:

1. **Crowdin Personal Access Token**:
   - Go to your [Crowdin profile](https://crowdin.com/settings#api-key)
   - Generate a new API token
   - Save it securely

2. **Jira API Token** (for automatic ticket creation):
   - Visit [Jira API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
   - Create a new API token
   - Save it securely

3. **Set environment variables** (recommended):
   ```shell
   export ROKU_CROWDIN_TOKEN="your_crowdin_token"
   export JIRA_TOKEN="your_jira_token"
   export JIRA_EMAIL="your_jira_email@tubi.tv"
   ```

4. **Access to project files**:
   - Write access to `/translations/en-US.json`
   - Ability to run gulp commands

**Note:** The Jira environment variables are required for `gulp stage` to automatically create/update Jira tickets for the internationalization team.

## Translation System Architecture

### File Structure

```
project-total-recall/
├── translations/
│   └── en-US.json              # Source translation file
├── src/channel/source/lib/
│   └── TubiLanguageTranslate.brs  # BrightScript translation functions
└── js/
    └── translate.js            # Translation processing scripts
```

### Translation Flow

**Adding New Translations:**
```
1. Developer adds/modifies en-US.json
2. Use getTranslation() in code
3. Commit and merge PR to master
```

**During Release Process:**
```
4. Create QA branch and run gulp stage
   - gulp stage automatically checks for translation changes:
     * Compares current en-US.json with what's on Crowdin
     * Detects new translation keys added
     * Detects existing translations that were modified
   
   - If changes detected, gulp stage will:
     * Upload latest English strings to Crowdin
     * Create a Jira ticket for the internationalization team with:
       - List of new translation keys
       - List of updated translation keys
       - Context and descriptions from en-US.json
       - Tagged with QA branch name as a label (e.g., "qa_3_6_120")
     
   - If translations are updated during QA cycle:
     * gulp stage detects the changes again
     * Updates the existing Jira ticket (doesn't create duplicate)
     * Adds a comment to the ticket: "Translation description was updated"
     * Uploads the updated strings to Crowdin
   
   - Translators receive notification and work on translations in Crowdin

5. Translators complete work and mark Jira ticket as "Done"
   - GitHub Action automatically triggers when ticket status changes to "Done"
   - Action downloads latest translations from Crowdin
   - Action creates a pull request with updated translations to master

6. Review and merge translation pull request
   - Team reviews the translation PR
   - After approval and merge to master:
     * GitHub Action automatically triggers
     * Action checks PR labels to identify the QA branch (e.g., "qa_3_6_120")
     * Action automatically cherry-picks the merged PR to the QA branch
   
7. TubiLanguageTranslate.brs now has all languages in QA branch
8. Deploy with new translations
```

**Note:** The entire translation workflow is automated:
- `gulp stage` handles upload and Jira ticket creation
- GitHub Actions handle downloading translations when Jira ticket is marked "Done"
- GitHub Actions automatically cherry-pick translation PRs to QA branches
- Developers only need to add translations and review the final PR

## Adding New English Strings

### Step 1: Update en-US.json

Add your translation key to `/translations/en-US.json`:

```json
{
  "your_new_key": {
    "description": "Context about where/how this string is used",
    "message": "The actual English text displayed to users"
  }
}
```

**Best Practices:**
- Use snake_case for keys
- Provide clear, detailed descriptions
- Keep messages concise but complete
- Include placeholders if needed (e.g., "{{count}} items")

### Step 2: Use in Code

Reference your translation in BrightScript code:

```brightscript
m.label.text = getTranslation("your_new_key")
```

**Important Rules:**
- ❌ **NEVER** hardcode text strings in BrightScript
- ✅ **ALWAYS** use `getTranslation()` for user-facing text
- ✅ Include script reference in XML:
  ```xml
  <script type="text/brightscript" uri="pkg:/source/lib/TubiLanguageTranslate.brs" />
  ```

## Automated Translation Workflow

### Quick Update Command

The `updateTranslations` command automates the entire process:

```shell
gulp updateTranslations
```

### What It Does

This automated workflow:

1. **Downloads** translations from Crowdin
   - Waits for build completion if needed
2. **Processes** translation files
   - Updates `TubiLanguageTranslate.brs`
   - Removes empty translations
   - Updates `markedEmptyTranslationForLocale` metadata
3. **Creates** a new branch: `translations_update_{MM}_{DD}`
4. **Commits** changes with message "updated translations"
5. **Pushes** to remote
6. **Creates** pull request with:
   - Summary of changes
   - QA testing steps template
   - Release notes template

### Benefits

- ✅ Saves time - no manual branch/PR creation
- ✅ Consistency - standardized PR format
- ✅ Automation - fewer manual steps
- ✅ Safety - creates PR for review before merge

## Troubleshooting

### Translation Not Showing

**Problem:** New translation key not working in app

**Solution:**
1. Verify key exists in `en-US.json`
2. Run `gulp updateLocalTranslations`
3. Check `TubiLanguageTranslate.brs` was updated
4. Rebuild and redeploy app

### Empty Translations

**Problem:** Some languages showing empty strings

**Expected Behavior:** 
- Empty translations are automatically removed during download
- App falls back to English for missing translations
- `markedEmptyTranslationForLocale` field tracks which locales need translation

### Crowdin Build Timeout

**Problem:** Download command times out waiting for Crowdin build

**Solution:**
1. Wait a few minutes
2. Try download command again
3. Check Crowdin dashboard for build status
4. Contact translation team if persistent

### Translation Key Conflicts

**Problem:** Key already exists with different text

**Solution:**
1. Check existing usage with grep:
   ```shell
   grep -r "your_key" src/
   ```
2. Either:
   - Reuse existing key if meaning matches
   - Create new, more specific key
   - Update existing key if all usages should change

### Special Characters

**Problem:** Special characters not displaying correctly

**Solution:**
- Ensure proper encoding in JSON (UTF-8)
- Use Unicode escape sequences if needed
- Test with actual device

### Jira Ticket Not Created

**Problem:** `gulp stage` ran but no Jira ticket was created

**Solution:**
1. Verify `JIRA_TOKEN` and `JIRA_EMAIL` environment variables are set
2. Check if translations actually changed (compare with Crowdin)
3. Review console output for any Jira-related errors
4. If no changes detected, no ticket is created (working as intended)

### Multiple Jira Tickets

**Problem:** Multiple Jira tickets exist for same QA cycle

**Expected Behavior:**
- Only one ticket should exist per QA branch
- `gulp stage` should update existing ticket, not create new ones
- If you see duplicates, there may be a bug - report it

**Solution:**
- Use the most recent ticket
- Consolidate information if needed
- Report the issue to the team

### Translation PR Not Created

**Problem:** Jira ticket is marked "Done" but no translation PR was created

**Solution:**
1. Check GitHub Actions tab for failed workflows
2. Verify GitHub Action has access to Jira and Crowdin
3. Check if translations actually exist on Crowdin
4. Wait a few minutes - action may still be running
5. Check Jira ticket for QA branch label - action needs this to create PR

### Translation PR Not Cherry-Picked

**Problem:** Translation PR merged to master but not cherry-picked to QA branch

**Solution:**
1. Check GitHub Actions tab for failed cherry-pick workflows
2. Verify PR has correct QA branch label (e.g., "qa_3_6_120")
3. Check if QA branch still exists
4. Look for merge conflicts - action cannot auto-resolve conflicts
5. Manual cherry-pick may be needed if conflicts exist

## Manual Commands Reference

**Note:** Manual upload/download is rarely needed. The automated workflow handles everything via `gulp stage` and GitHub Actions. Use these commands only for special cases.

### Manual Upload

Upload translations to Crowdin outside the normal release process.

**When to use:**
- Urgent translation updates outside of release cycle
- Testing translation changes before a release
- Bulk translation updates without going through QA

**Command:**

```shell
gulp uploadTranslations
# Or with token: gulp uploadTranslations --crowdinToken "TOKEN"
```

### Manual Download

Download translations from Crowdin for testing or debugging.

**When to use:**
- Testing translations before translators complete work
- Debugging translation issues
- Urgent translation updates outside normal workflow

**Command:**

```shell
gulp downloadTranslations
# Or with token: gulp downloadTranslations --crowdinToken "TOKEN"
```

## Best Practices

### DO ✅

- **DO** provide detailed descriptions in `en-US.json`
- **DO** use `getTranslation()` for all user-facing text
- **DO** let `gulp stage` automatically upload translations (normal workflow)
- **DO** let GitHub Actions handle download and cherry-picking (automated)
- **DO** review translation PRs when they're auto-created
- **DO** verify QA branch label is correct on Jira tickets
- **DO** test translations on actual devices
- **DO** monitor GitHub Actions for any automation failures

### DON'T ❌

- **DON'T** hardcode text strings in BrightScript
- **DON'T** modify `es-MX` or `fr-CA` translations directly
- **DON'T** commit downloaded translation JSON files
- **DON'T** skip translation validation before releases
- **DON'T** add translations without descriptions
- **DON'T** manually upload translations unless needed (gulp stage handles it)

## Related Documentation

- [Crowdin Project](https://crowdin.com/project/tubiapps)
- [Localization Notion Page](https://www.notion.so/tubi/Localization-d5007e6666d1436bac4391acef5c73bf)
- [Main README](../README.md#updating-the-static-text-translations-in-app)

## Getting Help

- **Translation Issues**: Contact internationalization team via Slack
- **Jira Ticket Questions**: Check the auto-generated Jira ticket created by `gulp stage`
- **Technical Issues**: Create ticket in JIRA
- **Crowdin Access**: Contact project admin
- **Questions**: Ask in `#roku_dev` Slack channel

**Note:** When `gulp stage` runs, it automatically creates a Jira ticket for the internationalization team. You can monitor this ticket to track translation progress and communicate with translators.

