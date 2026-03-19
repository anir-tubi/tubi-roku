# src

## Purpose

Contains the core Roku channel application source code written in BrightScript and SceneGraph XML. This is the main application directory that gets packaged into the Roku channel (`.pkg`) for deployment. It houses all UI components, business logic, data models, background tasks, and unit tests for the Tubi Roku streaming app.

The `src/` directory contains two subdirectories: `channel/` (the main app code) and `experiments/` (gitignored experiment code).

## Structure

- `channel/` - Root of the Roku channel source code (set as `rootDir` in `bsconfig.json`)
  - `source/` - BrightScript source files loaded into the main thread
    - `main.brs` - Application entry point; initializes constants, logging, Sentry, creates `TubiScene`, and runs the main message loop
    - `Constants.brs` - Defines all runtime constants via `getConstants()` including device info, API URLs, registry IDs, error types, and feature flags
    - `Settings.brs` - Placeholder for build-time generated `getSettings()` function (replaced by Gulp during build)
    - `Themes.brs` - Theme configuration
    - `localClientErrorConfig.brs` - Client error configuration for error handling
    - `lib/` - Shared BrightScript utility libraries (TubiRequest, TubiAuth, TubiLogger, Sentry, etc.)
    - `3rdparty/` - Third-party BrightScript libraries (e.g., rodash)
    - `tests/` - Rooibos unit test files for BrightScript source code
  - `components/` - SceneGraph XML components and their BrightScript controllers
    - `StarterConfig/` - Starter configuration component loaded during app initialization
    - `controllers/` - Main app controllers
      - `TubiScene/` - Root scene graph node (`TubiScene.brs`, `TubiScene.xml`, `TrackerTask.xml` for RALE)
      - `ContentController/` - Central navigation and screen management controller with 30+ helper files (e.g., `HomeScreenHelpers.brs`, `VideoHelpers.brs`, `DeeplinkHelpers.brs`, `AdPlayerHelpers.brs`)
      - `BackgroundScene/` - Permanent background scene to prevent app closure
    - `screens/` - Individual UI screens (~38 screens) including:
      - `HomeScreen/` - Main landing screen with content grids
      - `DetailScreen/`, `VodDetailScreen/`, `PivotDetailScreen/` - Content detail views
      - `VideoPlayerScreen/`, `LinearVideoPlayerScreen/` - VOD and live TV playback
      - `AdPlayerScreen/` - Ad playback screen
      - `EPGScreen/` - Electronic Program Guide for live TV
      - `SearchScreen/` - Content search
      - `SignInScreen/`, `ProfileScreen/`, `SettingsScreen/` - User account screens
      - `BaseScreen/` - Base screen component that other screens extend
    - `lib/` - Reusable UI component library (80+ components) including:
      - `ProgramGuide/` - Live TV program guide component
      - `ScreenStack/` - Screen navigation stack manager
      - `CategoryGridList/`, `CategoryGridPoster/` - Content browsing grid components
      - Various mixins (e.g., `AnalyticsMixin.brs`, `EPGMixin.brs`, `ExperimentMixin.brs`, `FocusMixin.brs`, `GlobalMixin.brs`)
    - `tasks/` - Background SceneGraph Task nodes for async operations
      - `MainTask/` - Primary background task for API calls
      - `AdsTask/`, `AdsSSAITask/`, `TubiAdsTask/` - Ad-related background tasks
      - `BrazeTask/` - Braze push notification integration
      - `GeneralTask/` - General-purpose task with screen-specific parsers in `Parsers/` subdirectory
      - `TrackingLoggingTask/` - Analytics and logging background task
      - `VideoMonitoringTasks/` - Video playback monitoring (Youbora, etc.)
    - `models/` - SceneGraph ContentNode definitions (XML) for data models like `TubiContentNode`, `AdContentNode`, `EPGContentNode`, `CategoryContentNode`, etc.
    - `data/` - Static JSON data files (keyboard definitions)
    - `tests/` - Rooibos unit test framework setup (`UnitTestNotifier`, `rooibos/`)
  - `images/` - App image assets (splash screens, icons, UI elements)
  - `fonts/` - Font files bundled with the channel
  - `locale/` - Localization strings and locale-specific images

## Architecture

- **SceneGraph Component Model**: The app uses Roku's SceneGraph framework where each screen/component is defined by an XML layout file and a BrightScript controller file. Components communicate via field observation (`observeField`) and SceneGraph node events.
- **ContentController Pattern**: A single `ContentController` component acts as the central coordinator for all screen navigation, with screen-specific logic factored into `*Helpers.brs` files (e.g., `HomeScreenHelpers.brs`, `VideoHelpers.brs`). This controller manages the `ScreenStack` for navigation history.
- **Two-Thread Architecture**: BrightScript runs in a main thread (`source/main.brs`) that handles the message loop, logging, and Roku Continue Watching API calls. The SceneGraph render thread runs all UI components. Background `Task` nodes handle async operations like API calls and ad fetching.
- **Task-Based Async**: All network requests and heavy processing run in SceneGraph Task nodes (`components/tasks/`) to avoid blocking the render thread. `GeneralTask/Parsers/` contains screen-specific response parsers.
- **Mixin Pattern**: Shared behavior is provided via BrightScript "mixin" files (e.g., `AnalyticsMixin.brs`, `FocusMixin.brs`, `ExperimentMixin.brs`) included in components that need that functionality.
- **Component Libraries**: The app uses remote component libraries (`remoteComponentsUrl`, `starterComponentsUrl`, `oneTrustComponentsUrl`, `foxVideoPlayerComponentsUrl`) loaded at runtime from CDN, enabling over-the-air updates without full channel republishing.
- **Build-Time Config Injection**: `Settings.brs` is a placeholder that gets replaced at build time by Gulp with actual configuration values from `config/*.yml` files, templated via Handlebars.

## Key Concepts

- **`getConstants()`** (`source/Constants.brs`): Returns the master constants object containing all settings, device info, API URLs, registry section IDs, error types, and feature flags. This is the central configuration for the entire app.
- **`getSettings()`** (`source/Settings.brs`): Build-time generated function returning environment-specific settings (API endpoints, feature flags, debug options). Produced by Gulp from `config/*.yml`.
- **`ContentController`** (`components/controllers/ContentController/`): The central navigation controller managing screen transitions, deep linking, video playback, ads, and user authentication flows.
- **`TubiScene`** (`components/controllers/TubiScene/`): The root SceneGraph scene that bootstraps the app, creates the ContentController, and handles startup arguments.
- **`ScreenStack`** (`components/lib/ScreenStack/`): Manages the navigation stack of screens, enabling push/pop navigation patterns.
- **`BaseScreen`** (`components/screens/BaseScreen/`): Base component extended by all screen components.
- **`GeneralTask`** (`components/tasks/GeneralTask/`): Multipurpose background task with screen-specific parsers for API responses.
- **Content Nodes** (`components/models/`): XML-defined SceneGraph ContentNode types (e.g., `TubiContentNode`, `EPGContentNode`, `CategoryContentNode`) representing domain data models.

## Dependencies

**Internal:**

- `../config/` - Build-time configuration files (YAML) that get templated into `Settings.brs`
- `../themes/` - Theme token files referenced for UI theming
- `../translations/` - Translation strings used in locale files
- `../OTPublishersSDK/` - OneTrust privacy consent SDK components
- `../fox-video-player/` - Fox video player component library sources
- `../build-config/` - BrighterScript config files for local/remote/starter builds

**External:**

- `brighterscript 0.67.3` - BrightScript compiler and language server
- `@rokucommunity/bslint 0.7.6` - BrightScript linter
- `brighterscript-xml-plugin` - XML validation plugin for SceneGraph components
- `rooibos-cli ^1.3.0` - Unit testing framework for BrightScript
- `roku_ads_lib` - Roku Advertising Framework (RAF) for ad insertion
- Widevine DRM - Required for protected content playback

## Working with this Code

### Prerequisites

- Node.js (for build tooling)
- Gulp CLI (`npm install -g gulp-cli`)
- A Roku device in developer mode (for sideloading and testing)
- `npm install` to install build dependencies

### Build & Run

- `gulp build` - Compile and package the channel for sideloading
- `gulp build --staging` / `--production` / `--qa` / `--test` - Build with specific environment config
- `gulp install` - Build and sideload to a connected Roku device
- `npx bsc --project bsconfig.json` - Run BrighterScript compiler checks

### Test

- Unit tests use the Rooibos framework (`source/tests/`, `components/tests/rooibos/`)
- `gulp test --sametab` - Build in test mode, sideload, and run Rooibos unit tests on a Roku device
- Tests run on self-hosted GitHub Actions runners with physical Roku devices

### Things to Watch Out For

- `Settings.brs` is a placeholder — the real function is generated at build time by Gulp. Never modify the generated version directly.
- `ContentController` has 30+ helper files; changes to screen navigation often require modifying helpers and the main `ContentController.brs`.
- `rooibosFunctionMap.brs` is auto-generated by Rooibos and is gitignored — do not commit it.
- The `bs_const` values in `config/*.yml` control compile-time conditionals; changing them affects which code paths are included in the build.
- Remote component libraries are loaded from CDN at runtime — changes to components may require a component library deployment before they take effect in production.
- The `experiments/` subdirectory is gitignored and contains experiment-specific code.
