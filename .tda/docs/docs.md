# docs

## Purpose

Contains supplemental documentation for the Tubi Roku channel, including architectural overviews, development guides, performance documentation, and workflow references. Also includes reference images, screenshots, and design assets.

## Structure

- `architecture.md` - High-level architecture document covering functional requirements (VOD navigation, video playback, deep linking, authentication, Live TV), visual requirements, operational requirements, screen flow, threading model, data model, and source layout
- `branch-component-library-deployment.md` - Guide for deploying component libraries from feature branches
- `http2.md` - HTTP/2 support documentation
- `manual_release.md` - Manual release process documentation
- `performance.md` - Performance optimization guidelines
- `translation-workflow.md` - Translation workflow documentation for Crowdin integration
- `tubi_tv_smoke_test.md` - Smoke test checklist for QA verification
- `generic_code_to_make_and_manage_a_queue_of_async_http_calls.md` - Reference implementation for async HTTP request queuing
- `CharlesRewrites.xml` - Charles Proxy rewrite configuration for debugging network requests
- `images/` - Documentation images subdirectory
- Various screenshots and diagrams:
  - `tubitv_roku_screen_flow.png` - App screen navigation flow diagram
  - `tubi_data_flow.png` - Data flow architecture diagram
  - `tubitv_roku_logical_entities.png` - Logical entity relationship diagram
  - `tubitv_roku_threading_model.png` - Threading model diagram
  - `roku-performance-grid.png` - Performance benchmark visualization
  - VSCode-related screenshots (`vscode_build_*.png`, `vscode_rendezvous_logging_*.png`, `vscode_roku_device_view_panel.png`)
  - `dev-mode.png`, `remote.png` - Developer setup reference images

## Architecture

- **Reference Documentation**: These docs serve as reference material for the Roku team. They are not auto-generated and are maintained manually.
- **Architecture Diagrams**: Key architectural diagrams (screen flow, data flow, threading model, entity relationships) are PNG images referenced from `architecture.md`.

## Dependencies

**Internal:**

- Referenced by `README.md` (links to `remote.png`, `dev-mode.png`)
- Referenced by `CONTRIBUTING.md` (links to `architecture.md`)

## Working with this Code

### Common Tasks

- **Update architecture docs**: Edit `architecture.md` and regenerate diagrams as needed.
- **Add new documentation**: Create a new `.md` file in this directory and link from `README.md` or `CONTRIBUTING.md`.
