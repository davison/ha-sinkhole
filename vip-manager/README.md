# VIP Manager

The `vip-manager` component is responsible for managing the Virtual IP (VIP) address in the HA Sinkhole application. It uses Keepalived to ensure high availability of the DNS service by managing the VIP and performing master node elections among the cluster members.

## Overview

The `vip-manager` container is built on top of a base image that includes Keepalived. It is designed to run as a systemd service, ensuring that it starts automatically on boot and restarts in case of failure. It requires `root` privileges to operate and cannot be run as a `podman` rootless container.

By default, each Sinkhole DNS node uses identical configuration for the `vip-manager` which means that they all start in `BACKUP` state and with the same priority level of 100. It's fine to leave it like this on all nodes if you have no preference which machine is the primary node, however you can increase the priority of a node and optionally start it up as `MASTER` if you have a preferred primary node (for example with better hardware). See the next section for configuration details.

## Configuration

The `vip-manager` shares a config file with other Sinkhole components located at `/etc/ha-sinkhole/sinkhole.env`. If you used the installer script it would have created this from a well commented template version highlighting the options available to manage sinkhole nodes.

For VIP handling in this container, the following configuration values can be specified:

*   `VIRTUAL_IP=10.0.0.53`
    This is the shared virtual IP address that will float between your nodes. It must be the SAME on all nodes; ensure this is reserved in DHCP or not otherwise in use. There is no default value for this item, it must exist in your config file.

*   `VRRP_SECRET=s3cr3t`
    Secret used within the cluster to manage communication. It must be the SAME on all cluster nodes. There is no default value for this item, it must exist in your config file.

*   `NODE_STATE=BACKUP`
    Defaults to BACKUP. All your nodes will start as BACKUP, and they will elect a MASTER based on priority. To create a preferred master, launch that one container with `NODE_STATE=MASTER`.

*   `NODE_PRIORITY=100`
    Defaults to 100. This is the standard keepalived default. You can run all your nodes with 100, and the one with the highest real IP will win. Or, to create a hierarchy of preferred master nodes, set relatively higher values.

*   `INTERFACE=eth0`
    Defaults to the auto-detected interface. The command `ip route get 8.8.8.8 | awk '{print $5}'` is used as a way to find the primary interface. Alternatively, you can set this to a specific interface name like `eth0`.

*   `VRRP_ROUTER_ID=node1`
    Defaults to the container's hostname (or container ID). Must be unique for each container instance.

## Health Checks

The `healthcheck.sh` script is included to perform regular health checks on the `dns-node` container's `CoreDNS` service. This ensures that the service is running correctly, if it fails then `keepalived` will move the VIP to another working instance.

## Usage

To run the `vip-manager` container, ensure that the necessary environment variables are set in the shared configuration file (`/etc/ha-sinkhole/sinkhole.env`). The service can be managed using systemd commands:

- Start the service: `systemctl start vip-manager`
- Stop the service: `systemctl stop vip-manager`
- Check the status: `systemctl status vip-manager`

## Logging

The `vip-manager` service uses journal logging, which can be accessed using the following command:

```bash
journalctl -u vip-manager
```

## Privileges

The `vip-manager` container requires root privileges and additional capabilities to manage network interfaces and IP addresses. These are defined in the systemd unit file.

## Documentation

For more detailed information on the configuration options and usage, refer to the `keepalived` [documentation](httpos://keepalived.org).
