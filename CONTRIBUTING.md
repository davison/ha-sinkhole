# Contributing to ha-sinkhole

Thank you for your interest in contributing. This document describes the preferred process for issues, pull requests, code style, and testing.

## Code of Conduct
Be respectful and professional. Follow the project's code of conduct in all interactions.

## Getting started
1. Fork the repository.
2. Clone your fork:
   - git clone git@github.com:your-username/ha-sinkhole.git
3. Create a branch for your change:
   - git checkout -b feat/my-change

## Reporting issues
- Search existing issues before opening a new one.
- Provide a clear title and a concise description.
- Include steps to reproduce, expected vs actual behavior, and relevant logs or configuration snippets.

## Feature requests
- Explain the problem and the proposed solution.
- Keep requests focused and include use-cases and any backward-compatibility considerations.

## Pull requests
1. Keep PRs small and focused.
2. Rebase or squash local commits as appropriate before opening the PR.
3. Include a descriptive title and a short summary of changes.
4. Link related issues using keywords (e.g., "Fixes #123").
5. Ensure the test suite passes locally before submitting.

## Coding style
- Follow the existing project style and patterns.
- Keep code readable and well-documented.
- Add or update docstrings and README sections when public interfaces change.

## Developing and building the container images
This project contains multiple container images (each in its own immediate sub-directory) and provides a helper script to discover and build them.

### Prerequisites
- Linux host (development/testing).
- podman or docker available on PATH (podman is preferred).
- A POSIX-compatible shell (the build script is a bash script).
  
### How containers are discovered
- The build script scans immediate sub-directories (depth 2) for files named Containerfile or Dockerfile.
- If a Containerfile/Dockerfile includes a LABEL with a version or tag (for example LABEL tag="v1.2.3" or LABEL version="1.2.3") the script uses that value as the image tag. Otherwise the image is tagged with :latest.
- The default image prefix (registry/namespace) used for tags is the repository directory name. You can change this by editing the build script or building manually.

### Building all images
- Make the build script executable if needed:
  - chmod +x ./build-images.sh
- Run the build script from the repository root:
  - ./build-images.sh
- The script will:
  - detect the container runtime (podman or docker),
  - find Containerfile/Dockerfile files,
  - derive image names and tags,
  - build each image and print a summary.

### Notes on running the script
- The script expects to be run as a non-root user (it performs a no_root check).
- Temporary build logs are created for each build (e.g., buildlog.* in the system tmp dir) and are retained if a build fails — inspect them for diagnosing failures.
- To build a single image manually:
  - cd into the directory that contains the Containerfile/Dockerfile
  - podman build -t <prefix>/<dir>:<tag> .
  (or use docker build if you prefer)

### Adding a new image
1. Create a new immediate sub-directory under the repository root (e.g., ./my-component/).
2. Add a Containerfile (or Dockerfile) in that directory.
3. Add a LABEL tag="vX.Y.Z" or LABEL version="X.Y.Z" to control the tag that the build script will use (optional).
4. Update any documentation or the example .env if the new container requires configuration.

### Testing images locally
- Run the image interactively:
  - podman run --rm -it <image> /bin/sh
- Verify expected behaviour (logs, network, volumes, etc.) before opening a PR.

## Commit messages
- Use clear, imperative commit messages (e.g., "Add X support" not "Added X support").
- Reference issue numbers where applicable.

## Security issues
For security vulnerabilities, contact the maintainers privately (use the repository's security policy if present) instead of opening a public issue.

## Licensing
By contributing, you agree that your contributions will be licensed under this project's license.

## Questions
If you're unsure where to start, open an issue describing what you'd like to work on and maintainers will help.

Thank you for helping improve ha-sinkhole!
