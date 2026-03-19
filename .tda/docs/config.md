# config

## Purpose

Contains YAML configuration files that define environment-specific settings for the Tubi Roku channel. These files control everything from API endpoints and feature flags to Roku manifest properties and BrighterScript compile-time constants. Configuration is loaded and merged at build time by the Gulp build system via `js/config.js`.

## Structure

- `default.yml` - Base configuration with all default values; every other environment config extends this. Contains:
  - `settings:` - App runtime settings (mode, version, platform name, component library URLs, feature flags like `youboraEnabled`, `clientLogsEnabled`, `realtimeMetricsEnabled`, debug options)
  - `manifest:` - Roku channel manifest properties (title, splash screens, icon paths, DRM requirements, resolution, channel token, dial title)
  - `component_library_manifest:` - Remote component library manifest
  - `starter_library_manifest:` - Starter component library manifest
  - `one_trust_library_manifest:` - OneTrust privacy SDK manifest
  - `fox_video_player_library_manifest:` - Fox video player library manifest
- `build.yml` - Build-specific overrides (minimal)
- `dev.yml.example` - Example dev config (actual `dev.yml` is gitignored); developer-specific settings like Roku device IP, passwords, local mode
- `production.yml` - Production overrides (minimal, ensures correct production settings)
- `qa.yml` - QA environment config with QA-specific API endpoints, proxy settings, and debug flags enabled
- `staging.yml` - Staging environment config
- `test.yml` - Test mode config (sets `mode: "test"` for running Rooibos unit tests)

## Architecture

- **Layered Config Merging**: `js/config.js` loads `default.yml` first, then deep-merges the environment-specific YAML file (e.g., `qa.yml`) on top. This allows each environment to override only what it needs.
- **Handlebars Templating**: Config values use Handlebars placeholders (e.g., `{{versionUnderscored}}`, `{{bsConst}}`) that get resolved at build time by `js/build.js` when generating `Settings.brs` and the Roku manifest file.
- **bs_const Compile-Time Flags**: The `settings.bs_const` section defines BrighterScript compile-time constants (e.g., `consoleLoggingEnabled`, `useQaAnalyticsProxy`) that control conditional compilation via `#if` directives in BrightScript source code.

## Key Concepts

- **`settings.mode`**: Controls the app's runtime behavior — `"production"`, `"dev"`, `"qa"`, `"staging"`, or `"test"`. Test mode triggers Rooibos unit test execution instead of normal app flow.
- **`settings.useStarterComponents`**: Must always be `true` for production. Controls whether the app loads the starter component library from CDN during launch.
- **`settings.useRemoteComponents`**: Controls remote component library loading.
- **`settings.bs_const.consoleLoggingEnabled`**: BrighterScript compile-time flag; must be `false` for production to strip all `tubiLog()` calls.
- **Component Library URLs**: `starterComponentsUrl`, `remoteComponentsUrl`, `oneTrustComponentsUrl`, `foxVideoPlayerComponentsUrl` define CDN URLs for dynamically loaded component libraries, with version placeholders.

## Dependencies

**Internal:**

- Referenced by `js/config.js` (loader) and `js/build.js` (template processor)
- Values flow into `src/channel/source/Settings.brs` and the Roku manifest at build time

**External:**

- `js-yaml` - YAML parsing
- `handlebars` - Template resolution

## Working with this Code

### Common Tasks

- **Add a new feature flag**: Add it to `settings:` in `default.yml` with a sensible default, then override in environment-specific files as needed. Reference it in BrightScript via `m.constants.settings.yourFlag`.
- **Add a new bs_const**: Add it to `settings.bs_const:` in `default.yml`. Use it in BrightScript with `#if yourConst` directives.
- **Set up local dev environment**: Copy `dev.yml.example` to `dev.yml` and fill in your Roku device IP and passwords.

### Things to Watch Out For

- `dev.yml` is gitignored — each developer maintains their own local copy.
- NEVER change `charlesProxyEnabled` to `true` or `consoleLoggingEnabled` to `true` in `default.yml` or `production.yml`.
- `useStarterComponents` must always be `true` in production.
- Component library URLs contain version placeholders (`{{versionUnderscored}}`) that must be kept in sync with actual deployed library versions.
