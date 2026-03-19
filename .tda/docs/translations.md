# translations

## Purpose

Contains the English (US) translation strings for the Tubi Roku channel. This is the base locale file that serves as the source of truth for all user-facing text in the app. Translations to other languages are managed via Crowdin and synchronized using the translation workflow scripts in `js/translate.js`.

## Structure

- `en-US.json` - English (US) translation strings file (~117KB) containing all user-facing text organized as key-value pairs. Keys follow a hierarchical naming convention (e.g., screen names, component contexts).

## Architecture

- **Crowdin Integration**: The English strings are uploaded to Crowdin for translation into supported languages. The `js/translate.js` module handles upload/download operations and locale file processing.
- **Locale File Generation**: During the build process, translation strings are processed and placed into `src/channel/locale/` directory in Roku's expected locale format for runtime string lookup.

## Dependencies

**Internal:**

- Processed by `js/translate.js` for Crowdin sync
- Output goes to `src/channel/locale/` during build

**External:**

- Crowdin translation management platform

## Working with this Code

### Common Tasks

- **Add a new string**: Add the key-value pair to `en-US.json`, then upload to Crowdin for translation.
- **Sync translations**: Use `gulp downloadTranslations` to pull latest translations from Crowdin.

### Things to Watch Out For

- The `en-US.json` file is the source of truth — always add new strings here first.
- See `docs/translation-workflow.md` for the complete translation workflow documentation.
- Unused translation keys should be cleaned up using `gulp listUnusedTranslations`.
