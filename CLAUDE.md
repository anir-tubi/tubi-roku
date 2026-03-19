# Project Guidelines

For detailed codebase documentation, see [.tda/docs/index.md](./.tda/docs/index.md).

## Development

This is the Tubi Roku Channel — a free ad-supported streaming app for the Roku platform built with BrightScript and SceneGraph.

### Quick Start

1. Install Node.js and Gulp CLI: `npm install -g gulp-cli`
2. Install dependencies: `npm install`
3. Copy `config/dev.yml.example` to `config/dev.yml` and configure your Roku device IP/password
4. Build and sideload: `gulp install`

### Common Commands

- `gulp build` - Build the channel
- `gulp build --staging` - Build with staging config
- `gulp install` - Build and sideload to Roku device
- `gulp test --sametab` - Run unit tests on device
- `npx bsc --project bsconfig.json` - Run BrighterScript compiler checks

### Code Style

- BrightScript: Follow the [Tubi BrightScript Style Guide](https://gist.github.com/brybott-tubi/ba0233b203a8f5c3ff75d7a59a7ee6e5)
- Linting: `bslint.json` rules enforced by `@rokucommunity/bslint`
- Formatting: `bsfmt.json` for BrighterScript formatting
- TypeScript (tests/tooling): ESLint with `@typescript-eslint`

### Git Workflow

- `master` is the main development branch
- Feature branches are created off `master`
- PRs target `master`
- Releases branch from `master` with semantic versioning (Major.Minor.Build.Revision)

### Testing

- **Unit Tests**: Rooibos framework, run on physical Roku devices via `gulp test`
- **Automated UI Tests**: TypeScript tests using `roku-test-automation`, run via Mocha against physical Roku devices
- **Static Analysis**: Roku SCA tool for certification compliance
- **BSC Checks**: BrighterScript compiler validation on all PR pushes
