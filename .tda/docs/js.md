# js

## Purpose

Contains JavaScript and TypeScript build tooling, automation scripts, and the automated UI test suite for the Tubi Roku channel. This directory powers the Gulp-based build system, Git release management workflows, translation management, code quality tools, and end-to-end automated tests that run against physical Roku devices using the `roku-test-automation` library.

## Structure

- `build.js` - Build functions: `createManifest()` and `createSettings()` for generating Roku manifest and Settings.brs from YAML config templates
- `config.js` - Configuration loader: `load()` reads and merges YAML config files, `getBuildTag()` / `getOneTrustBuildTag()` / `getFoxVideoPlayerBuildTag()` extract version tags
- `git.js` - Comprehensive Git/GitHub automation (~57KB): release PR creation, branch management, tagging, CDN pull requests, cherry-picking, release notes generation, QA branch building
- `translate.js` - Crowdin translation management (~50KB): upload/download translations, process locale files, create Jira tickets for missing translations
- `network.js` - Roku device network utilities: keypress simulation, deep linking, package upload/signing, squashfs installation
- `colorreplace.js` - Color constant replacement tooling for theme management
- `typography.js` - Typography constant replacement from design token files
- `codeclean.js` - Code cleanliness checks: find unused images and unused translations
- `utilities.js` - Shared utility functions (e.g., `NoStackError`)
- `templating.js` - Handlebars template helpers for build-time config injection
- `local-client-error-config.js` - Manages local client error configuration file sync
- `automated-tests.js` - Gulp task definitions for running automated UI tests
- `github-developer-info.json` - GitHub developer team member info
- `automated-tests/` - End-to-end automated UI test suite (TypeScript)
  - `tests/` - Test files organized by feature (~40 test files):
    - `application-launch.ts`, `autoplay-movie.ts`, `autoplay-tv.ts` - App launch and autoplay tests
    - `details-page.ts`, `title-details-page.ts`, `series-details-page.ts` - Content detail page tests
    - `playback.ts`, `live.ts`, `browse-while-watching.ts` - Video playback tests
    - `search.ts`, `categories.ts`, `side-nav.ts` - Navigation tests
    - `sign-up-save-progress-*.ts`, `password-reset.ts` - User authentication tests
    - `parental-controls.ts`, `kids-mode.ts` - Parental control tests
    - `homegrid-video-tiles.ts`, `pivots.ts`, `my-stuff.ts` - Home screen and content browsing tests
    - `manual-regression-*.ts` - Manual regression test suites
  - `analytics/` - Analytics verification tests
    - `pages/` - Page-specific analytics test helpers (homePage, playback, searchPage, etc.)
    - `tests/` - Analytics-specific test files
    - `utils/` - Analytics utility functions
    - `verification/` - Analytics event verification logic
    - `components/` - Shared analytics components
  - `test-helpers.ts` - Centralized test helper class (`TestHelpers`) with methods for navigation, playback, history creation, parental controls, and user management
  - `test-utils.ts` - Low-level test utility functions wrapping `roku-test-automation` APIs
  - `include.ts` - Mocha test setup/initialization file
  - `mocha-reporter.ts` - Custom Mocha reporter
  - `mochawesome-to-allure.ts` - Allure report converter
  - `ad-test-helpers.ts` - Ad-specific test helpers
  - `mock-data-helpers.ts` - Mock data generation for tests
  - `performance-test-utils.ts` - Performance testing utilities
  - `performance-tests/` - Performance-focused test files
  - `mocks/` - Test mock data
  - `tooling-tests.ts` - Tests for the test tooling itself
- `workflows/` - GitHub Actions workflow helper scripts
  - `postPRTestResults.ts` - Posts automated test results as PR comments
  - `prCommentUtils.ts` - Utilities for formatting PR comments
  - `prFormatVerify.ts` - Verifies PR formatting consistency
  - `prInfoVerify.js` - Validates PR metadata
  - `draftPullRequest.js` - Creates draft PRs
  - `generateRtaConfig.js` - Generates `roku-test-automation` config
  - `sendSlackAutomatedTestsResultNotification.ts` - Sends Slack notifications for test results

## Architecture

- **Gulp Build System**: The root `gulpfile.js` imports functions from `js/` files and orchestrates the entire build pipeline: config loading → manifest generation → settings injection → BrightScript compilation → packaging → deployment to Roku devices.
- **YAML Config Templating**: `config.js` loads YAML config files (`config/*.yml`), merges them (default + environment-specific), and uses Handlebars templating to inject version numbers and build tags into settings and manifest files via `build.js`.
- **roku-test-automation (RTA)**: Automated tests use the `roku-test-automation` library which communicates with Roku devices via ECP (External Control Protocol) and ODC (On-Device Component) to inspect SceneGraph nodes, simulate remote control inputs, and verify UI state.
- **Page Object Pattern**: Analytics tests use a page-object-like pattern with `analytics/pages/` containing page-specific test helpers and `analytics/utils/` for shared utilities.
- **Mocha + Chai Test Runner**: Tests use Mocha as the test runner with Chai assertions. Test files are TypeScript compiled via `ts-node`. Mocha configuration is in `package.json` with 120s timeout and `bail: false`.

## Key Concepts

- **`testHelpers`** (`automated-tests/test-helpers.ts`): Singleton class providing high-level test operations like `createHistory()`, grid navigation, detail screen verification, and parental control setup.
- **`testUtils`** (`automated-tests/test-utils.ts`): Low-level wrapper around RTA APIs providing `getNodeForElement()`, key press helpers, and element state queries.
- **Element KeyPaths**: Tests reference UI elements via keypaths defined in `automated-tests-config/elements.ts` (e.g., `#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen`). Nested node properties cannot be accessed via chaining — each nested element must have its own keypath entry.
- **`NoStackError`** (`utilities.js`): Custom error class used throughout the build system.

## Dependencies

**Internal:**

- `../config/` - YAML configuration files loaded by `config.js`
- `../automated-tests-config/elements.ts` - UI element keypath definitions used by test utilities
- `../src/channel/` - The channel source code that tests validate

**External:**

- `roku-test-automation ^2.2.1` - Roku device test automation library (ECP + ODC)
- `gulp ^4.0.2` - Build system task runner
- `mocha 10.2.0` - Test runner
- `chai ^4.2.0` - Assertion library
- `mochawesome ^7.1.3` - HTML test report generation
- `allure-commandline ^2.36.0` - Allure test reporting
- `js-yaml ^3.11.0` - YAML parsing for config files
- `handlebars ^4.0.11` - Template engine for build-time config injection
- `@crowdin/crowdin-api-client ^1.30.0` - Crowdin translation management API
- `@octokit/rest ^18.0.9` - GitHub API client for PR/release management
- `typescript ^4.9.5` - TypeScript compiler for test code
- `ts-node ^10.9.1` - TypeScript execution for Mocha tests

## Working with this Code

### Prerequisites

- Node.js 18+ (used in CI Docker images)
- `npm install` from project root
- For automated tests: a Roku device accessible on the network, configured in `rta-config.json`
- For translation management: `CROWDIN_TOKEN` environment variable
- For Git/GitHub operations: GitHub PAT with repo access

### Build & Run

- `gulp build` - Full build pipeline
- `gulp build --staging` - Build with staging config
- `gulp install` - Build and sideload to Roku device
- `npx gulp test --sametab` - Build in test mode and run unit tests on device

### Test

- Automated UI tests: `npx mocha js/automated-tests/tests/<test-file>.ts` (requires connected Roku device)
- Tests run on self-hosted GitHub Actions runners with physical Roku devices
- Test results are posted as PR comments and sent to Slack

### Common Tasks

- **Add a new automated test**: Create a `.ts` file in `js/automated-tests/tests/`, use `testHelpers` and `testUtils` from imports, define elements in `automated-tests-config/elements.ts`
- **Add a new build config**: Add properties to `config/default.yml` and reference in `js/build.js` or `js/config.js`
- **Update translations**: Use `gulp downloadTranslations` to sync from Crowdin

### Things to Watch Out For

- Test element keypaths must be defined in `automated-tests-config/elements.ts` — you cannot traverse nested SceneGraph nodes from returned test objects.
- Mocha timeout is 120 seconds per test; increase for longer playback tests.
- `git.js` is very large (~57KB) and handles many release workflows — be careful with changes.
- Tests require physical Roku devices on the same network; they cannot run in purely virtual CI environments.
