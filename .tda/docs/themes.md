# themes

## Purpose

Contains design token files that define the visual theme and typography for the Tubi Roku channel. These JSON token files are the source of truth for colors, spacing, and typography values used across the app's UI components.

## Structure

- `theme.json` - Color and visual theme tokens (~16KB) defining the complete color palette, component-specific colors, and visual styling values used throughout the app
- `typography.tokens.json` - Typography design tokens (~19KB) defining font families, sizes, weights, line heights, and text style presets for all UI text elements

## Architecture

- **Design Token System**: The theme files use a token-based approach where UI components reference named tokens rather than hardcoded values. This enables consistent theming and easier global style updates.
- **Build-Time Processing**: The `js/colorreplace.js` and `js/typography.js` scripts process these token files during the build to generate BrightScript constants or replace placeholder values in the source code.

## Dependencies

**Internal:**

- Processed by `js/colorreplace.js` (color tokens) and `js/typography.js` (typography tokens)
- Values are used in `src/channel/` component XML files and BrightScript source

## Working with this Code

### Common Tasks

- **Update a color**: Modify the value in `theme.json` and run `gulp` tasks to propagate changes.
- **Add a new typography style**: Add the style definition to `typography.tokens.json` following existing naming patterns.

### Things to Watch Out For

- Changes to theme tokens affect the entire app's visual appearance — verify on multiple Roku device resolutions (FHD, HD, SD).
- Token names must match what the source code references; renaming a token requires updating all references.
