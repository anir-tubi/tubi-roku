# docker

## Purpose

Contains Docker configuration for the self-hosted GitHub Actions runner used to execute automated UI tests against physical Roku devices. The runner is deployed as a container in the Tubi SF office network where Roku devices are connected.

## Structure

- `automated-tests-runner/` - Docker setup for the automated test runner
  - `Dockerfile` - Multi-stage Dockerfile based on .NET runtime dependencies image, installs GitHub Actions runner v2.307.1, Node.js 18, and configures the runner with labels `automated-tests-runner,enabled`

## Architecture

- **Self-Hosted Runner**: Automated UI tests require physical Roku devices on the same network. This Dockerfile builds a GitHub Actions self-hosted runner container that registers with the repository and executes test workflows when triggered.
- **Runner Configuration**: The runner is configured at build time with repository URL, registration token, and a custom name. It uses labels (`automated-tests-runner`, `enabled`) to match with workflow `runs-on` selectors.

## Dependencies

**External:**

- GitHub Actions Runner v2.307.1
- Node.js 18 (installed via NodeSource)
- .NET 6.0 runtime dependencies (base image)

## Working with this Code

### Build & Run

- Build: `docker build --build-arg url=<repo-url> --build-arg token=<runner-token> --build-arg name=<runner-name> --build-arg RUNNER_ARCH=x64 -t automated-tests-runner .`
- Run: `docker run automated-tests-runner`

### Things to Watch Out For

- The runner requires a valid registration token from GitHub at build time.
- A `rta-config.json` file must be provided (copied into the container at build time) with the Roku device connection details.
- Runner version updates require rebuilding the Docker image.
