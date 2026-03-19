# scripts

## Purpose

Contains build-time scripts and third-party tools used in the development and CI pipeline. Includes the Git hook setup script and Roku's Static Channel Analysis (SCA) command-line tool for code quality validation.

## Structure

- `setup-hooks.js` - npm `postinstall` hook that configures Git hooks for the repository (runs automatically after `npm install`)
- `sca-cmd/` - Roku Static Channel Analysis CLI tool
  - `bin/sca-cmd` - Unix executable launcher
  - `bin/sca-cmd.bat` - Windows executable launcher
  - `lib/sca-cmd.jar` - Java JAR containing the SCA analysis engine
  - `LICENSE` - License file for the SCA tool
  - `README.md` - SCA tool documentation

## Architecture

- **Git Hooks via postinstall**: The `setup-hooks.js` script runs as an npm `postinstall` hook (defined in `package.json`) to configure Git hooks automatically when developers run `npm install`.
- **Static Channel Analysis**: The SCA tool is a Java-based static analysis tool provided by Roku for validating BrightScript channel code against Roku's certification requirements and best practices. It's used in the CI pipeline via the `static-analysis.yml` GitHub Actions workflow.

## Key Concepts

- **SCA (Static Channel Analysis)**: Roku's official tool for detecting certification issues, security problems, and code quality violations in Roku channels before submission to the Roku Channel Store.

## Dependencies

**External:**

- Java Runtime Environment (JRE) - Required to run `sca-cmd.jar`

## Working with this Code

### Build & Run

- Git hooks are set up automatically via `npm install` (triggers `setup-hooks.js`)
- `scripts/sca-cmd/bin/sca-cmd` - Run static channel analysis manually

### Things to Watch Out For

- `sca-cmd.jar` requires a Java runtime to be available on the system.
- The SCA tool is a third-party binary from Roku — do not modify it.
