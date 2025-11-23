# DNS Node

The `dns-node` container is responsible for DNS resolution using [CoreDNS](https://coredns.io/), a flexible and extensible DNS server. It serves DNS queries and can be configured to block specific domains based on the blocklists provided by the [blocklist-updater](../blocklist-updater/README.md) container. The `dns-node` mounts the same host volume as the updater; `/var/lib/ha-sinkhole/data` and reads the consolidated `blocklists.hosts` file that the updater creates. If the file changes, `coredns` will reload the contents of it.

In addition to providing a sinkhole service for bad actor domains, `dns-node` will pass any unblocked domain queries to a variety of upstream DNS resolvers so that the client can obtain correct IP addresses for those hosts. Upstream DNS servers can include public resolvers like Quad1 or Quad9 `1.1.1.1`, `9.9.9.9` or Google's DNS servers (though you probably shouldn't) or maybe your ISP's servers.

You can also optionally include a local upstream server - often your router or DHCP service - that will answer queries for hosts on your local network for a specific local domain and this can be done alongside the blocklist and upstream services.

## Usage

The `dns-node` container relies on the [blocklist-updater](../blocklist-updater/README.md) container having already created the `blocklists.hosts` file. The updater service is listed as a dependency of the `dns-node` service to ensure that it runs and creates the file prior to the DNS container starting up. This file will be monitored for changes by the `dns-node` container. By default this file will be in `/var/lib/ha-sinkhole/data` on the host file system.

The `dns-node` container includes health checks to ensure that it is functioning correctly, these are used by the [vip-manager](../vip-manager/README.md) to determine which node should be primary. You can stop, (re)start or check the status of the service using:

```bash
systemctl --user restart dns-node.service
systemctl --user status dns-node.service
systemctl --user stop dns-node.service
```

If you stop the service on the machine that is currently the primary/master node, you should immediately see the VIP address move over to one of your other nodes and that the service as a whole continues uninterrupted.

## Configuration

The `dns-node` container is configured through the following setings defined in the `inventory.yaml` file. Note that if you change any of the settings on the host's service unit files and then re-run the installer, they will revert to whatever is in the inventory file. The best way to manage all `ha-sinkhole` nodes and components is by re-running the [installer](../installer/README.md) with a modified configuration.

*   `upstream_dns` is a list of DNS servers that can resolve queries which are not subject to blocking. They are typically your ISP's DNS servers, public servers such as Quad1 or Quad9, or perhaps OpenDNS servers. The defaults are Quad1 and Quad9 which will be queried round-robin.
   
    ```yaml
    dns_nodes:
      vars:
        upstream_dns:
          - 1.1.1.1
          - 9.9.9.9
    ```
*   `local_domain` is your internal LAN or office domain that you may have DHCP providing addresses for and which you want to be able to resolve hostnames. For example, `mydomain.local`. This would normally be a domain that is not resolvable by public upstream servers and requires an internal server (your DHCP or router/gateway typically) to resolve the hosts.

    ```yaml
    dns_nodes:
      vars:
        local_domain: mydomain.local
    ```
    Any requests for hostnames that the server receives with no domain on them will have the `local_domain` appended to them and sent to the `local_upstream_dns` resolver which you should also configure along with this setting.

    There is no default for this, if it's not provided in the inventory, no local address resolution will occur. When the server receives requests for bare hostnames with no domain, it will append the domain `_invalid.local` and attempt to resolve it at Google, which will fail. The failed result will be cached.

*  `local_upstream_dns` is the IP address of a machine that can resolve addresses in your `local_domain` and the two settings go hand-in-hand, there's little point setting one without the other. This machine could be your router or DHCP server or some other resolver that has knowledge of your local network. Incoming requests for bare hostnames will have `local_domain` appended to them and sent to this server for resolution.
    ```yaml
    dns_nodes:
      vars:
        local_upstream_dns: 192.168.0.1
    ```

* `local_hosts` is a list of IP:hostname mappings, each line being in the same format that would be valid in a system's `/etc/hosts` file. This setting enables you to override addresses in the blocklist, declare aliases for hosts on your network that wouldn't otherwise be resolved by your `local_upstream_dns` server or any other reason you need to fix a host to an IP manually.
    ```yaml
    dns_nodes:
      vars:
        local_hosts:
          - "5.6.7.8 my.server.com"
          - "192.168.0.100 nas.local media.local docs.local"
    ```

* `trusted_nets` are the CIDRs that the DNS resolver will allow queries to originate from. This defaults to the RFC1918 address sets plus the guest address that podman rootless network uses if unconfigured. But this can be locked down further or expanded as required.
    ```yaml
    dns_nodes:
      vars:
        trusted_nets:
          - 192.168.0.1/24
          - 169.254.1.2/32
    ```

## Logging

Logs for the `dns-node` container can be viewed using the journal:

```bash
journalctl -u dns-node.service
```
