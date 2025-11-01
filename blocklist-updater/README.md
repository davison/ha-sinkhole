# Blocklist Updater

The `blocklist-updater` container is responsible for periodically fetching and processing blocklists to create the `blocklists.hosts` file. This file is essential for the `dns-node` container, which reads it to determine which domains to block.

## Overview

This container runs a Python script that updates the blocklists (daily be default). It is designed to be run as a systemd service on a systemd timer although it will run whenever the [dns-node](../dns-node/) container starts too as that relies on its output.

## Usage

1. **Service Management**: The `blocklist-updater` container is managed by systemd. It should only be operated via the `timer` unit and is not designed to be enabled, disabled, started or stopped via `systemctl`.

3. **Timer**: The blocklist updater is scheduled to run daily using a systemd timer. You can enable and check the timer status with:

   ```bash
   systemctl --user enable blocklist-updater.timer
   systemctl --user list-timers
   ```

The container must share a volume with the `dns-node` container to ensure that the `blocklists.hosts` file is accessible. This volume is mounted from `/var/lib/ha-sinkhole/data` on the host.

## Configuration

The `blocklist-updater` shares a config file with other Sinkhole components located at `/etc/ha-sinkhole/sinkhole.env`. If you used the installer script it would have created this from a well commented template version highlighting the options available to manage sinkhole nodes.

For this container, the following configuration values can be specified:

*  `BLOCKLIST_URLS=https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
   Blocklist URLs are the sources of domain lists that should be sink-holed on the network. The script that fetches them on a timer will de-duplicate before updating the DNS server with the combined, unique list of domains. The default value is Steven Black's list, here are some alternatives and additions:
      - http://sysctl.org/cameleon/hosts
      - https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
      - https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
      - https://raw.githubusercontent.com/chadmayfield/pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list
      - https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt
  
   More than one URL in the list should be space separated without quotes.
   
   ```
   BLOCKLIST_URLS=https://example.com/list1 https://test.com/list2
   ```

## Logging

The container uses journal logging, which can be accessed with:

```bash
journalctl -u blocklist-updater.service
```
