# VIP Manager

The `vip-manager` component is responsible for managing the Virtual IP (VIP) address in the HA Sinkhole application. It uses Keepalived to ensure high availability of the DNS service by managing the VIP and performing master node elections among the cluster members.

## Overview

The `vip-manager` container is built on top of a base image that includes Keepalived. It is designed to run as a systemd service, ensuring that it starts automatically on boot and restarts in case of failure.

## Configuration

The `vip-manager` uses a configuration file template located at `keepalived.conf.template`. This template should be customized to fit your network environment, including the VIP address and VRRP settings.

## Health Checks

The `healthcheck.sh` script is included to perform regular health checks on the `vip-manager` container. This ensures that the service is running correctly and can manage the VIP as expected.

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

The `vip-manager` container requires certain privileges to manage network interfaces and IP addresses. Ensure that these privileges are documented and granted as necessary.

## Documentation

For more detailed information on the configuration options and usage, refer to the `keepalived` documentation and the comments within the configuration template.
