# DNS Node Container

The `dns-node` container is responsible for DNS resolution using CoreDNS. This README provides details on how to configure and use the `dns-node` container.

## Overview

The `dns-node` container is built on top of CoreDNS, a flexible and extensible DNS server. It serves DNS queries and can be configured to block specific domains based on the blocklists provided by the `blocklist-updater` container.

## Configuration

The `dns-node` container is configured through the following environment variables defined in the `/etc/ha-sinkhole/sinkhole.env` file. 

*   `UPSTREAM_DNS=1.1.1.1 9.9.9.9`
    A space separated list (no quotes) of upstream DNS server IP addresses that you wish to forward non-blocked queries to. Defaults to Quad1 and Quad9.

## Usage

To run the `dns-node` container, ensure that the [blocklist-updater](../blocklist-updater/) container has already created the `blocklists.hosts` file. This file will be monitored for changes by the `dns-node` container. By default this file will be in `/var/lib/ha-sinkhole/data` on the host file system.

### Starting the Container

You can start the `dns-node` container using the provided systemd service file located in the `services` directory:

```bash
systemctl --user start dns-node.service
```

### Monitoring Logs

Logs for the `dns-node` container can be viewed using the journal:

```bash
journalctl -u dns-node.service
```

## Health Checks

The `dns-node` container includes health checks to ensure that it is functioning correctly, these are used by the [vip-manager](../vip-manager/) to determine which node should be primary. You can check the status of the service using:

```bash
systemctl --user status dns-node.service
```

## Troubleshooting

If you encounter issues, check the logs for any error messages. Ensure that the environment configuration is correct and that the `blocklist-updater` has run successfully to create the necessary blocklist file.

## Additional Information

For more details on CoreDNS and its configuration options, refer to the [CoreDNS documentation](https://coredns.io/).
