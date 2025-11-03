# Overview

`ha-sinkhole` is a project that enables the highly available deployment of DNS sinkhole servers. It has similar aims to the DNS and Blocklist features of the popular `pi-hole` project.

The project is a mono-repo consisting of a number of container image builds and some supporting scripts and files. Container builds are directories housing a `Containerfile` and a `VERSION` file. Each container is versioned independently of the project releases and each other. The current semantic version of each container is held in the `VERSION` file in the root of the container image context directory.

The project prefers and recommends the use of `podman` and OCI specifications over `docker` and all code and suggestions should reflect this. However, `docker` as a container build or runtime technology should work. 

The `services` directory contains podman quadlet files that are used by systemd on nodes that the containers are run on.
