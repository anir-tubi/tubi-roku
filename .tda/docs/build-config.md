# build-config

## Purpose

Contains BrighterScript configuration files for validating the three separate build output folders: local (sideloaded channel), starter (starter component library), and remote (remote component library). These configs are used during CI to verify that each build output compiles cleanly with `bsc`.

## Structure

- `local-bsconfig.json` - BrighterScript config pointing to the local/sideloaded build output folder
- `remote-bsconfig.json` - BrighterScript config pointing to the remote component library build output folder
- `starter-bsconfig.json` - BrighterScript config pointing to the starter component library build output folder

## Architecture

- **Post-Build Validation**: After `gulp build` creates the three output folders (local, starter, remote), each of these bsconfig files is used to run `bsc` validation against the respective output to catch compilation errors. This is part of the BSC CI workflow (`.github/workflows/bsc.yml`).

## Dependencies

**Internal:**

- References build output from `gulp build` (the `build/` directory which is gitignored)
- Used by `.github/workflows/bsc.yml` CI pipeline

## Working with this Code

### Build & Run

- `npx bsc --project ./build-config/local-bsconfig.json --create-package false --copy-to-staging false` - Validate local build output
- `npx bsc --project ./build-config/starter-bsconfig.json --create-package false --copy-to-staging false` - Validate starter output
- `npx bsc --project ./build-config/remote-bsconfig.json --create-package false --copy-to-staging false` - Validate remote output

### Things to Watch Out For

- These configs reference the `build/` output directory which only exists after running `gulp build`.
- If a build output validation fails in CI, run `gulp build` locally and then run the `bsc` check against the specific output to debug.
