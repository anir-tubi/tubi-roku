# fox-video-player

## Purpose

Contains the SceneGraph component source files for the Fox Video Player, a video player component library that is loaded at runtime as a Roku component library from CDN. This player handles video playback for specific content types.

## Structure

- `components/` - SceneGraph XML and BrightScript components for the Fox Video Player
  - Contains the player UI components, controls, and playback logic

## Architecture

- **Runtime Component Library**: The Fox Video Player is deployed as a separate `.pkg` component library to CDN (`foxVideoPlayerComponentsUrl` in config) and loaded at runtime by the main Tubi channel. This allows updating the player independently of the main channel.
- **Integration Point**: The main channel uses `FoxVideoPlayerWrapperScreen` (in `src/channel/components/screens/`) as the integration point for this player.

## Dependencies

**Internal:**

- Loaded at runtime by the main Tubi channel via `foxVideoPlayerComponentsUrl` setting
- Integrated via `FoxVideoPlayerWrapperScreen` and `FoxVideoPlayerWrapperScreenHelpers.brs`

**External:**

- Roku Ad Framework (`roku_ads_lib`)
- Google IMA3 (`googleima3`) - For ad integration

## Working with this Code

### Things to Watch Out For

- Changes require deploying a new component library `.pkg` to CDN and updating the version in `config/default.yml`.
- The `fox_video_player_library_manifest` in `config/default.yml` defines the manifest for this library.
