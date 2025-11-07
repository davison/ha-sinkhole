# HA Sinkhole

Inspired by the fantastic [pi-hole](https://github.com/pi-hole/pi-hole) project, big shout out to the creators and contributors there!

I've used pi-hole for years and couldn't live without that functionality on my network, but it's not easy to make it highly available and I really wanted that. There are several guides available for making pi-hole HA, but they're fragile, bolt-on solutions which are unsupported by the pi-hole project.

I created `ha-sinkhole` to solve specifically that problem. It addresses that single concern and does not, by design, offer many of the existing pi-hole features (notably DHCP). It also currently comes with no visualisation features or web interface, but that will change once the core HA sinkhole feature is working and stable.

You can deploy one or more `ha-sinkhole` DNS nodes that will share a virtual IP (VIP) address on your network. The nodes will take care of managing the IP address and if a node fails or is taken down during maintenance, one of the others will assume the VIP. All DNS clients are given the VIP as their DNS server and therefore as long as at least one of your nodes is alive, your DNS and sinkhole service will be operational. Follow the quick start steps on each machine you want to use as a node. One machine will work, two is the minimum for high availability and more can be added at any time if you want additional resilience.

Whether you're installing on a raspberry pi, a bare metal server, a local VM, or on cloud instances, it should work. As `ha-sinkhole` uses containers, deploying inside a container is unlikely to succeed.

## Quick Start Guide

1. Ensure your host machine has an up to date `linux` distro.
2. You will need a container management application installed. [podman](https://podman.io/) is strongly recommended, [docker](https://www.docker.com/) should also just work. Install using your distro's packaging tool.
3. Run the `ha-sinkhole` installer and configure the required variables of `VIRTUAL_IP` and `VRRP_SECRET`. All the other options can be skipped and left at default values for now.

    ```bash
    git clone https://github.com/davison/ha-sinkhole.git && cd ha-sinkhole/scripts
    ./install.sh
    ```
    `VIRTUAL_IP` and `VRRP_SECRET` must be the *same* on every node you want to cluster.
4. Repeat steps 1 - 3 on all your additional nodes.
5. Configure your DNS clients with the `VIRTUAL_IP` address.
6. Enjoy ad-free browsing with highly available DNS!

## Customising Deployments

### DNS Sinkhole Nodes

Sinkhole nodes are made up from 3 containers, each performing a specific function. All containers are configured through the environment (typically a single `.env` file that is local to the node). This can be ingested via `systemd` and `podman quadlets` or with `docker compose` files.

The installer script will install `stable` versions of containers and components. If you want the bleeding edge, run the installer with `latest` as an argument:

```bash
cd ha-sinkhole/scripts && ./install.sh latest
```

1. [dns-node](./dns-node/) is the DNS resolver and is built on top of [coredns](https://coredns.io/), a very fast, reliable and highly configurable resolver. 
2. [blocklist-updater](./blocklist-updater/) is a cron like container that periodically updates the sources for the domains to block.
3. [vip-manager](./vip-manager/) based on [keepalived](https://www.keepalived.org/) is the component that manages the VIP and elections of master nodes among the cluster members.

The [example .env file](./services/sinkhole.example.env) documents all of the available configuration items for the node. It's shared among the 3 containers.

### Log Aggregators

(not yet implemented)

Features will enable the logs and metadata to be stored/parsed for visualisation 

### Visualisation

(not yet implemented)

Graphs and metrics of blocked/allowed queries, similar to pi-hole graphs

## Contents <!-- omit from toc -->
- [HA Sinkhole](#ha-sinkhole)
  - [Quick Start Guide](#quick-start-guide)
  - [Customising Deployments](#customising-deployments)
    - [DNS Sinkhole Nodes](#dns-sinkhole-nodes)
    - [Log Aggregators](#log-aggregators)
    - [Visualisation](#visualisation)

