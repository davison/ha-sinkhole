# VIP Manager

The `vip-manager` component is responsible for managing the Virtual IP (VIP) address in the HA Sinkhole application. It uses [Keepalived](httpos://keepalived.org) to ensure high availability of the DNS service by managing the VIP and performing master node elections among the cluster members. The VIP should be an address on the same network as the hosts and protected from use by other machines (i.e. outside of a DHCP range). When the `vip-manager` chooses a primary/master node based on configuration and current service status' of the [dns-nodes](../dns-node/) it will add the VIP as an alias to the same NIC as the machine uses for its default route and then aggressively ARP so that routing equipment updates to send traffic for that IP address to the new primary node.

`vip-manager` is designed to run as a systemd service, ensuring that it starts automatically on boot and restarts in case of failure. It requires `root` privileges to operate and cannot be run as a `podman` rootless container due to the privileges required to manage network interfaces.

By default, each Sinkhole DNS node uses identical configuration for the `vip-manager` which means that they all start in `BACKUP` state and with the same priority level of 100. It's fine to leave it like this on all nodes if you have no preference which machine is the primary node, however you can increase the priority of a node and optionally start it up as `MASTER` if you have a preferred primary node (for example with better hardware). See the [configuration](#configuration) section below for details.

An additional job performed by `vip-manager` is to forward traffic from the standard DNS port of 53 to an unprivileged port of 1053 on whichever machine has the VIP address. This is because the `dns-node` container is designed to run rootless (using `podman`) and so listens on that unprivileged port (1053) for the DNS requests. In order for clients to be able to use the default DNS port (53) netfilter rules via `nftables` are added to control the port mapping. These rules rewrite all packets arriving on the `$VIRTUAL_IP` address at port 53 to a `dnat` of 1053. This should be significantly more secure than running the DNS server as root. The `nftables` configuration looks like this (the VIP address is templated and would be replaced with the real VIP):

```sh
add table ip dns_port_forward
add chain ip dns_port_forward dns_dnat { type nat hook prerouting priority dstnat; }
add rule ip dns_port_forward dns_dnat ip daddr "$VIRTUAL_IP" tcp dport 53 dnat to :1053
add rule ip dns_port_forward dns_dnat ip daddr "$VIRTUAL_IP" udp dport 53 dnat to :1053
```

The running container has a `healthcheck.sh` script, included to perform regular health checks on the `dns-node` container's `CoreDNS` service. This ensures that the service is running correctly, if it fails then `keepalived` will move the VIP to another working instance even in the event that the `dns-node` container continues to run.

## Usage

The service can be managed using systemd commands:

```bash
systemctl start vip-manager
systemctl stop vip-manager
systemctl status vip-manager
```

If the service is stopped, the VIP will move to another machine in the cluster if any remain.

## Configuration

For `vip-manager`, the following configuration values from the inventory config file are relevant:

*   `vip` is the shared virtual IP address that will float between your nodes. It must be the SAME on all nodes; ensure this is reserved in DHCP or not otherwise in use. There is no default value for this item, it must exist in your config file.
    ```yaml
    dns_nodes:
      vars:
        vip: 192.168.0.53
    ```

*   `vrrp_secret` is the secret used within the cluster to manage communication. It must be the SAME on all cluster nodes. There is no default value for this item, it must exist in your config file.
    ```yaml
    dns_nodes:
      vars:
        vrrsp_secret: wh0_goes_th3r3
    ```

*   `state` specifies the node state that machines will try to start in. It defaults to `BACKUP`. If all your nodes start as `BACKUP`, they will elect a `MASTER` based on a combination of `priority`, IP address and status of the `dns-node` service, though these details are mostly irrelevant. To create a preferred master, launch that one container with `state:MASTER` and a higher priority as shown in the overridden `host_vars`. You probably want to do this if you have one machine with better hardware than the others that should always be preferred as a primary service provider.
    ```yaml
    dns_nodes:
      vars:
        host_vars:
          # at the group level, only BACKUP really makes sense. Override as 
          # shown to make a single machine the preferred MASTER
          state: BACKUP 
    hosts:
      dns2:
        host_vars_overrides:
          state: MASTER
          priority: 110
    ```

*   `priority` defaults to 100. This is the standard keepalived default. You can run all your nodes with 100, and the one with the highest real IP will win. Or, to create a hierarchy of preferred master nodes, set relatively higher values.

*   `interface` should rarely need to be configured. It defaults to the auto-detected interface, discovered using the command `ip route get 8.8.8.8 | awk '{print $5}'`. If for some reason this does not return the correct interface to use for the incoming DNS requests, you can set this to a specific interface name like `eth0`. It probably *only* makes sense to set this at a specific machine (override) level unless all the machines in your group are identical and have the same issue.
    ```yaml
    hosts:
      dns2:
        host_vars_overrides:
          interface: eth0
    ```

*   `vrrp_router_id` should also rarely need to be configured. It defaults to the container's hostname (or container ID). It __must__ be unique for each container instance and so if your containers are generating identical names that are being used as a router ID, you can override that behaviour here. This setting __only__ makes sense at an individual machine level.
    ```yaml
    hosts:
      dns2:
        host_vars_overrides:
          vrrp_router_id: dns2
    ```


## Logging

The `vip-manager` service uses journal logging, which can be accessed using the following command:

```bash
journalctl -u vip-manager
```
