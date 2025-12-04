# Blocklist Updater

The `blocklist-updater` container is responsible for periodically fetching and processing blocklists to create the `blocklists.hosts` file. This file is essential for the `dns-resolver` container, which reads it to determine which domains to block. This container runs a Python script that updates the blocklists (daily be default). It is designed to be run as a rootless systemd service via a systemd timer, although it will also run whenever the [dns-resolver](../dns-resolver/README.md) container (re)starts too as that relies on its output.

## Usage

1. **Service Management**: The `blocklist-updater` container is managed by systemd. It should only be operated via the `timer` unit and is not designed to be enabled, disabled, started or stopped via `systemctl`.

3. **Timer**: The blocklist updater is scheduled to run daily using a systemd timer. You can enable and check the timer status with:

   ```bash
   systemctl --user enable blocklist-updater.timer
   systemctl --user list-timers
   ```

The container must share a volume with the `dns-resolver` container to ensure that the `blocklists.hosts` file is accessible. This volume is mounted from `/var/lib/ha-sinkhole/data` on the host and that directory is created by the installer and set with ownership of the non-root user (`ansible_user` in the inventory file).

## Configuration

The `blocklist-updater` is only interested in the `blocklist_urls` config element. This is a list of one or more URLs that point to valid format blocklists. The example inventory file lists several options and more may be available. Files in "hosts" file format, plain domain lists or AdBlock Pro list format should all work. By default, a single URL is configured. The service will de-duplicate and sort the final list before writing it to the destination directory ready for the [dns-resolver](../dns-resolver/README.md) to consume.

```yaml
    dns_nodes:
      vars:
        blocklist_urls:
          - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

Others that you may wish to add to or replace it with are:
```yaml
   - http://sysctl.org/cameleon/hosts
   - https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
   - https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
   - https://raw.githubusercontent.com/chadmayfield/pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list
   - https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt
```     

## Logging

The container uses journal logging, which can be accessed with:

```bash
journalctl -u blocklist-updater.service
```
