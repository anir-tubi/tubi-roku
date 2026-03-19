# Tubi Roku Channel

## Overview

The Tubi Roku Channel is a free ad-supported streaming (FAST) app built for the Roku platform using BrightScript and Roku SceneGraph. It provides VOD (Video on Demand) content browsing, live TV via an Electronic Program Guide (EPG), video playback with ad breaks, user authentication, deep linking, and cross-device features like Roku Continue Watching. The app is published on the Roku Channel Store as channel ID 41468 and serves millions of users.

## Introduction

This repository contains the complete source code, build tooling, automated test infrastructure, and CI/CD pipelines for the Tubi Roku channel. The app is written primarily in BrightScript (Roku's proprietary scripting language) with SceneGraph XML for UI layout, and TypeScript/JavaScript for build tooling and automated tests.

The Roku channel uses a component library architecture where the app is split into a base channel (sideloaded/submitted to Roku) and multiple dynamically-loaded component libraries hosted on CDN (starter components, remote components, OneTrust consent SDK, Fox Video Player). This architecture enables over-the-air updates to most of the app without going through the full Roku Channel Store certification process.

Key domain concepts:
- **BrightScript** - Roku's scripting language used for all app logic
- **SceneGraph** - Roku's XML-based UI framework for defining component hierarchies
- **Component Libraries** - Dynamically loaded `.pkg` bundles from CDN that extend the base channel
- **ECP (External Control Protocol)** - Roku's REST API for device control, used by automated tests
- **ODC (On-Device Component)** - RTA's mechanism for inspecting SceneGraph nodes during tests
- **Rooibos** - BrightScript unit testing framework
- **RTA (roku-test-automation)** - Library for automating UI tests against physical Roku devices

The project is actively developed by the Tubi Roku team with frequent releases. Version numbering follows Roku's manifest convention: Major.Minor.Build.Revision.

## Project Structure

| Directory | Description | Documentation |
| --------- | ----------- | ------------- |
| `src/` | Core Roku channel source code (BrightScript, SceneGraph XML, assets) | [src.md](src.md) |
| `js/` | Build tooling, Gulp tasks, Git/release automation, and automated UI test suite | [js.md](js.md) |
| `ai-automation/` | AI-powered test generation system using Claude and TestRail | [ai-automation.md](ai-automation.md) |
| `config/` | Environment-specific YAML configuration files | [config.md](config.md) |
| `scripts/` | Git hooks setup and Roku Static Channel Analysis tool | [scripts.md](scripts.md) |
| `docs/` | Architecture documentation, diagrams, and developer guides | [docs.md](docs.md) |
| `automated-tests-config/` | UI element keypath definitions for automated tests | [automated-tests-config.md](automated-tests-config.md) |
| `themes/` | Design token files for colors and typography | [themes.md](themes.md) |
| `translations/` | English (US) translation strings, synced to Crowdin | [translations.md](translations.md) |
| `docker/` | Dockerfile for self-hosted GitHub Actions test runner | [docker.md](docker.md) |
| `testRail/` | Python scripts for syncing test results to TestRail | [testRail.md](testRail.md) |
| `build-config/` | BrighterScript configs for validating build outputs | [build-config.md](build-config.md) |
| `companion-channel/` | Companion Roku channel for development/testing | [companion-channel.md](companion-channel.md) |
| `fox-video-player/` | Fox Video Player component library source | [fox-video-player.md](fox-video-player.md) |
| `fox-video-player-components/` | Pre-built Fox Video Player .pkg binary | [fox-video-player-components.md](fox-video-player-components.md) |
| `OTPublishersSDK/` | OneTrust privacy consent SDK for Roku | [OTPublishersSDK.md](OTPublishersSDK.md) |
| `channel-store/` | Roku Channel Store marketing assets | [channel-store.md](channel-store.md) |

### Dependency Graph

```
Main Channel (src/channel/)
├── config/ (build-time settings injection)
├── themes/ (color/typography tokens → build-time processing)
├── translations/ (locale strings → build-time processing)
├── OTPublishersSDK/ (runtime component library)
├── fox-video-player/ (runtime component library)
└── fox-video-player-components/ (pre-built .pkg for CDN)

Build System (gulpfile.js + js/)
├── config/ (YAML loading & merging)
├── src/channel/ (source to compile & package)
├── build-config/ (post-build validation)
└── themes/ + translations/ (processing)

Automated Tests (js/automated-tests/)
├── automated-tests-config/elements.ts (element definitions)
├── docker/ (self-hosted runner)
└── testRail/ (result sync)

AI Test Generation (ai-automation/)
├── automated-tests-config/elements.ts (context for prompts)
├── js/automated-tests/ (existing tests as examples)
└── TestRail API (test case specs)
```

## Architecture

The Tubi Roku channel follows a **two-thread architecture**:

1. **Main BrightScript Thread** (`src/channel/source/main.brs`): Initializes the app, handles the message loop, manages logging/Sentry, and processes Roku Continue Watching API calls.
2. **SceneGraph Render Thread**: Runs all UI components starting from `TubiScene` → `ContentController` → individual screens. `ContentController` acts as the central coordinator for screen navigation and feature logic.

Background **Task nodes** (`src/channel/components/tasks/`) run in separate threads for async operations like API calls, ad fetching, analytics, and Braze integration.

The app uses **runtime component libraries** loaded from CDN, allowing most code updates without full Roku Channel Store republishing:
- Starter Component Library (loaded during app initialization)
- Remote Component Library (main app components)
- OneTrust Component Library (privacy consent)
- Fox Video Player Library (video playback)

## Development Workflow

### Prerequisites

- Node.js 18+
- npm
- Gulp CLI (`npm install -g gulp-cli`)
- A Roku device in developer mode (for sideloading and testing)
- Python 3 (for TestRail sync scripts)

### Common Commands

```bash
npm install                          # Install all dependencies
gulp build                           # Build the channel (default: dev config)
gulp build --staging                 # Build with staging config
gulp build --production              # Build with production config
gulp install                         # Build and sideload to Roku device
gulp test --sametab                  # Run Rooibos unit tests on device
npx bsc --project bsconfig.json     # Run BrighterScript compiler checks
npx mocha js/automated-tests/tests/<file>.ts  # Run specific automated UI test
```

### CI/CD

The project uses GitHub Actions with a mix of cloud-hosted and self-hosted runners:

- **BSC Check** (`bsc.yml`): Runs on every PR — compiles source and validates all three build outputs (local, starter, remote). Also runs formatting checks with ReviewDog.
- **Unit Tests** (`executeUnitTests.yml`): Runs on PRs to master — builds in test mode, sideloads to a physical Roku device, executes Rooibos unit tests.
- **Automated UI Tests** (`automatedTests.yml`, `run-automated-tests.yml`): Runs end-to-end UI tests against physical Roku devices on self-hosted runners.
- **Static Analysis** (`static-analysis.yml`): Runs Roku SCA tool for certification compliance.
- **Component Library Deploy** (`deploy-component-lib.yml`): Deploys component libraries to CDN.
- **Translation Sync** (`download-translations.yml`, `cherry-pick-translations.yml`): Manages Crowdin translation workflows.
- **PR Verification** (`prInfoVerify.yml`, `draftPullRequest.yml`): Validates PR metadata and formatting.

## Key Technologies

- **Language**: BrightScript (Roku's scripting language)
- **UI Framework**: Roku SceneGraph (XML + BrightScript)
- **Compiler**: BrighterScript 0.67.3 (superset of BrightScript with enhanced features)
- **Linter**: @rokucommunity/bslint 0.7.6
- **Build System**: Gulp 4 with Node.js
- **Unit Testing**: Rooibos (BrightScript test framework)
- **UI Testing**: roku-test-automation 2.2.1 + Mocha + Chai (TypeScript)
- **AI Test Generation**: Claude (AWS Bedrock) + TestRail API
- **CI/CD**: GitHub Actions (cloud + self-hosted runners with physical Roku devices)
- **Translations**: Crowdin
- **Test Management**: TestRail
- **Privacy SDK**: OneTrust Publishers SDK
- **Deployment**: Roku Channel Store (base channel) + S3/CloudFront CDN (component libraries)
