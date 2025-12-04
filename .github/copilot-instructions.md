`ha-sinkhole` is a project that enables the highly available deployment of DNS sinkhole servers. It has similar aims to the DNS and Blocklist features of the popular `pi-hole` project.

The project is a mono-repo consisting of a number of container image builds and some supporting scripts and files. Container builds are directories housing a `Containerfile` and a `VERSION` file. Each container is versioned independently of the project releases and each other. The current semantic version of each container is held in the `VERSION` file in the root of the container image context directory as clean semver (e.g., `0.3.1`). When published, container images are tagged with a 'v' prefix (e.g., `v0.3.1`) following common container tagging conventions.

The project prefers and recommends the use of `podman` and OCI specifications over `docker` and all code and suggestions should reflect this. However, `docker` as a container build or runtime technology should work.

CI is managed on github with github actions. Workflows are defined in the `.github/workflows` directory and actions exist to lint commit messages, which are *required* to follow convventional commit standards. In addition to linting, actions will attempt to autobump container versions according to the commit message (unless committed changes are made to the `VERSION` file directly) and build and push container images to the github container registry.

The `installer` container contains ansible tasks and podman quadlet files that are used by systemd on nodes that the containers are run on.

Consume all of the markdown files in the project root directory and in the root of each container directory in order to add context to all code suggestions.
