# Contributing to ha-sinkhole

Thank you for your interest in contributing! 

We're always happy to receive contributions of any kind. You can help with code submissions, documentation improvements, bug reports, feature requests or helping others with their issues and requests. This document describes the preferred process for issues, pull requests, code style, and testing.

## Code of Conduct
Be respectful and remember that everyone is volunteering their valuable time here.

## Getting started with code contributions
1. Fork the repository.
2. Clone your fork:
   ```bash
   git clone git@github.com:your-username/ha-sinkhole.git
   ```
3. Create a branch for your change:
   ```bash
   cd ha-sinkhole && git checkout -b feat/my-change
   ```

## Reporting issues
- Search existing issues before opening a new one.
- Provide a clear title and a concise description.
- Include steps to reproduce, expected vs actual behavior, and relevant logs or configuration snippets.

## Feature requests
- Explain the problem and the proposed solution.
- Keep requests focused and include use-cases and any backward-compatibility considerations.

## Pull requests
1. Keep PRs small and focused.
2. Rebase or squash local commits as appropriate before opening the PR. A PR can contain multiple commits, but each commit should be a logical change making up one part of the request.
3. Include a descriptive title and a short summary of changes.
4. Link related issues using keywords (e.g., "Fixes #123").
5. Ensure any tests pass locally before submitting.

## Coding style
- Follow the existing project style and patterns.
- Keep code readable and well-documented.
- Add or update docstrings and README sections when public interfaces change.
- Follow good [commit hygeine](https://www.pullchecklist.com/posts/git-commit-best-practices)

## Developing and building the container images
This project contains multiple container images (each in its own immediate sub-directory) and provides a helper script to discover and build them.

### Building all images locally
- Make the build script executable if needed: `chmod +x ./build-images.sh`
- Run the build script from the `scripts` directory:
  
  ```bash
  cd scripts && ./build-images.sh
  ```
  
  if you want a clean (no-cache) build, pass the `clean` argument to the script
  
  ```bash
  ./build-images.sh clean
  ```

The script will:
  - detect the container runtime (podman or docker),
  - find directories from the project root that host a  `Containerfile`
  - build images and apply a tag name of `local`,
  - build each image and print a summary.

Once you have the local images you can test them with a container runtime.

### Adding a new image
1. Create a new immediate sub-directory under the repository root (e.g., `./my-component/`).
2. Add a `Containerfile` (don't use `Dockerfile`) in that directory.
3. Add a `VERSION` file with the initial version number for the component
4. Add a build arg and the 4 OCI labels
```Dockerfile
  ARG BUILD_VERSION

  LABEL org.opencontainers.image.source=https://github.com/ha-sinkhole/my-component
  LABEL org.opencontainers.image.description="Description of component."
  LABEL org.opencontainers.image.licenses=MIT
  LABEL org.opencontainers.image.version="$BUILD_VERSION"
  ```

### Testing images locally
- Run the image interactively:
  ```bash
  podman run --rm -it <image> /bin/sh
  ```
- Verify expected behaviour (logs, network, volumes, etc.) before opening a PR.

## Commit messages
- Use clear, imperative commit messages (e.g., "Add X support" not "Added X support").
- Include a title (less than 72 characters) and for non-trivial commits, a proper description of the change and the reasons for making it.
- Reference issue numbers where applicable.

# Reporting issues / bugs
- Search existing issues before opening a new one.
- Provide a clear title and a concise description.
- Include steps to reproduce, expected vs actual behavior, and relevant logs or configuration snippets.

# Feature requests
- Explain the problem and the proposed solution.
- Keep requests focused and include use-cases and any backward-compatibility considerations.

# Security issues
For security vulnerabilities, contact the maintainers privately (use the repository's security policy if present) instead of opening a public issue.

# Licensing
By contributing, you agree that your contributions will be licensed under this project's license.


Thank you for helping improve ha-sinkhole!
