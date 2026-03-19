# companion-channel

## Purpose

Contains the source code for a companion Roku channel used for development and testing purposes. This is a separate, smaller Roku channel that can be sideloaded alongside the main Tubi channel for testing-related functionality.

## Structure

- `bsconfig.json` - BrighterScript configuration for the companion channel
- `bslint.json` - BrightScript linter rules for the companion channel
- `manifest` - Roku manifest file for the companion channel
- `.vscode/` - VSCode configuration for launching/debugging the companion channel
- `components/` - SceneGraph components for the companion channel UI
- `images/` - Image assets for the companion channel
- `source/` - BrightScript source files for the companion channel
- `channel-store/` - Channel store assets for the companion channel

## Architecture

- **Standalone Roku Channel**: This is a self-contained Roku channel with its own manifest, source, and components. It can be built and sideloaded independently of the main Tubi channel.
- **Development/Testing Tool**: Used by the Roku team for development workflows that require a secondary channel on the device.

## Dependencies

**External:**

- BrighterScript compiler
- Roku development tools

## Working with this Code

### Build & Run

- Open in VSCode and use the launch configuration to build and sideload to a Roku device.
- Or use `bsc --project companion-channel/bsconfig.json` to compile.

### Things to Watch Out For

- This is a separate channel from the main Tubi app — changes here do not affect the main channel.
- The manifest has its own version numbering independent of the main channel.
