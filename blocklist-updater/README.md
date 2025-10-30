# blocklist-updater/README.md

# Blocklist Updater

The `blocklist-updater` container is responsible for periodically fetching and processing blocklists to create the `/data/blocklists.hosts` file. This file is essential for the `dns-node` container, which reads it to determine which domains to block.

## Overview

This container runs a Python script that updates the blocklists every 6 hours. It is designed to be run as a systemd service, ensuring that it operates reliably and can be monitored through the system's logging facilities.

## Usage

1. **Configuration**: Ensure that the environment variables required for the blocklist updater are set in the `/etc/ha-sinkhole/sinkhole.env` file. This file should include any necessary URLs or sources for the blocklists.

2. **Service Management**: The `blocklist-updater` container is managed by systemd. It should only be operated via the `timer` unit and is not designed to be enabled, disabled, started or stopped via `systemctl`.

3. **Timer**: The blocklist updater is scheduled to run every 6 hours using a systemd timer. You can check the timer status with:

   ```bash
   systemctl list-timers
   ```

## Logging

The container uses journal logging, which can be accessed with:

```bash
journalctl -u blocklist-updater.service
```

## Privileges

The `blocklist-updater` container requires certain privileges to access the necessary resources. Please refer to the local README.md for detailed information on the required privileges.

## Shared Volume

The container must share a volume with the `dns-node` container to ensure that the `/data/blocklists.hosts` file is accessible. This volume is mounted from `/var/lib/ha-sinkhole/data` on the host.

## Initial Run

The initial run of the `blocklist-updater` is crucial to ensure that the `/data/blocklists.hosts` file is created before the `dns-node` container starts. Make sure to start the service manually after deployment to perform this initial run.

## Conclusion

The `blocklist-updater` container plays a vital role in maintaining the effectiveness of the DNS sinkhole by ensuring that the blocklists are up to date. Proper configuration and management of this container are essential for the overall functionality of the `ha-sinkhole` application.