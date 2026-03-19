# fox-video-player-components

## Purpose

Contains a pre-built Fox Video Player component library package (`.pkg` file) that is the compiled/signed artifact ready for deployment to CDN. This is the distributable binary of the Fox Video Player.

## Structure

- `fox_video_player_1_40_0.pkg` - Compiled and signed Roku component library package (v1.40.0, ~982KB)

## Architecture

- **Pre-Built Binary**: This directory stores the compiled `.pkg` artifact. The build and deployment workflow (`.github/workflows/deploy-component-lib.yml`) handles uploading this to the S3-backed CDN.
- **CDN Deployment**: The package is deployed to `mrcdn-staging.tubitv.com/appFiles/fox-video-player-components/` and loaded by the Tubi channel at runtime.

## Dependencies

**Internal:**

- Source code is in `fox-video-player/`
- Deployment handled by `.github/workflows/deploy-component-lib.yml`

## Working with this Code

### Things to Watch Out For

- The `.pkg` file is a binary — it cannot be modified directly. Rebuild from source in `fox-video-player/` to create a new version.
- Version numbers in the filename must match the `foxVideoPlayerComponentsUrl` in config.
