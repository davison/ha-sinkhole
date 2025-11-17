# Contributing to ha-sinkhole

Thank you for your interest in contributing! 

We're always happy to receive contributions of any kind. You can help with code submissions, documentation improvements, bug reports, feature requests or helping others with their issues and requests. This document describes the preferred process for issues, pull requests, code style, and testing.

## Code of Conduct
Be respectful and remember that everyone is volunteering their valuable time here.

## Reporting issues
- Search existing issues before opening a new one.
- Provide a clear title and a concise description.
- Include steps to reproduce, expected vs actual behavior, and relevant logs or configuration snippets.

## Feature requests
- Explain the problem and the proposed solution.
- Keep requests focused and include use-cases and any backward-compatibility considerations.

# Code contributions
If you're a developer, power user, or know how to use git/github to make suggested changes to docs or other artifacts, awesome! Here's some info to get started contributing code changes to `ha-sinkhole`

Take a look through any open issues to see what things are a priority, and what you can work on. Feel free to submit new issues for suggestions of features. It's a very good idea to do this before you commit much time to working on the feature in case it's already been considered.

1. Fork the repository.
2. Clone your fork:
   ```bash
   git clone git@github.com:your-username/ha-sinkhole.git
   ```
3. Create a branch for your change:
   ```bash
   cd ha-sinkhole && git checkout -b feat/my-change
   ```
4. Hack on your branch and create a pull request in the main repository when ready.

`ha-sinkhole` uses a large range of technologies. Depending on which part of the code you intend to work on, you'll beenfit from having tooling , IDE or editor support for the following:

* Git / Github
* Podman (container tools)
* YAML
* Markdown
* Makefile
* Bash
* Python
* Ansible
* Jinja2
* Grafana Alloy


## Pull requests
1. Keep PRs small and focused.
2. Rebase or squash local commits as appropriate before opening the PR. A PR can contain multiple commits, but each commit should be a logical change making up one part of the request.
3. Include a descriptive title and a short summary of changes.
4. Link related issues using keywords (e.g., "Fixes #123").
5. Ensure any tests pass locally before submitting.

## Coding style
- Follow the existing project style and patterns.
- Keep code readable and well-documented.
- Follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Follow good [commit hygeine](https://www.pullchecklist.com/posts/git-commit-best-practices)

## Developing and building the container images
This project contains multiple container images (each in its own immediate sub-directory) and provides a `Makefile` to discover and build them. You'll need your distro's version of build tools installed to be able to run `make` and get local builds of the images for faster dev/test cycles.

Each build image has its own `VERSION` file with the current semantic version number of the image in it. This file is updated automatically by github action workflows based on the commit message and the files that have been modified in the commit. You should rarely need to change this manually but it relies on adherance to the [coding rules](#coding-style) in order to work.

### Building all images locally
From the project root..

  ```bash
  make all
  ```
  
  if you want a clean (no-cache) build, pass the `no-cache` argument 
  
  ```bash
  make all no-cache
  ```

The Makefile will:
  - detect the container runtime (podman or docker).
  - find directories from the project root that host a  `Containerfile`.
  - build images and apply a tag name of `local`, ignoring the `VERSION` file completely.
  - print a summary.

Once you have the local images you can test them with a container runtime.

### Testing images locally
- Run the image interactively:
  ```bash
  podman run --rm -it <image> /bin/sh
  ```
- Verify expected behaviour (logs, network, volumes, etc.) before opening a PR.

If you want to work on the ansible code in the `installer`, the best approach is probably to create a python `venv` in the project root directory (can also help with the python code in some of the Github Action code in `./.github`). If you name it `.venv` it will be ignored via `.gitignore`

```bash
python -m venv .venv
source .venv/bin/activate # <-- pick appropriate activate command for your shell.. .csh|.fish etc.
pip install ansible
mkdir .local # <-- will also be ignored by git
cp installer/inventory.example.yaml .local/inventory.yaml
# edit ../.local/inventory.yaml to suit
```

This will enable you to hack and test the ansible code without having to mess about with containers until your feature or change is ready to push.

```bash
cd installer
ansible-playbook -i ../.local/inventory.yaml playbooks/install.yaml
```

## Adding a new image
1. Create a new immediate sub-directory under the repository root (e.g., `./my-component/`).
2. Add a `Containerfile` (don't use `Dockerfile`) in that directory.
3. Add a `VERSION` file with the initial version number for the component
4. Add the build arg and the 4 OCI labels
```Dockerfile
  ARG BUILD_VERSION

  LABEL org.opencontainers.image.source=https://github.com/ha-sinkhole/my-component
  LABEL org.opencontainers.image.description="Description of component."
  LABEL org.opencontainers.image.licenses=MIT
  LABEL org.opencontainers.image.version="$BUILD_VERSION"
  ```

## Commit messages
- Use clear, imperative commit messages (e.g., "Add X support" not "Added X support").
- Include a title (less than 72 characters) and for non-trivial commits, a proper description of the change and the reasons for making it.
- Reference issue numbers where applicable.

# Security issues
For security vulnerabilities, contact the maintainers privately (use the repository's [security policy](./SECURITY.md) for more details) instead of opening a public issue.

# Licensing
By contributing, you agree that your contributions will be licensed under this project's license.


Thank you for helping improve ha-sinkhole!
