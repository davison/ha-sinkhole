# Installer

HA Sinkhole's installer package is a container that wraps [ansible](https://docs.ansible.com/projects/ansible/latest/getting_started/index.html) and its dependencies. The details of this are mostly irrelevant unless you're [contributing](../CONTRIBUTING.md) to the code as the workings are abstracted from you as an end user. Ansible (and therefore the installer package) is a tool that takes a configuration set called an inventory and plans installation tasks by running playbooks (sets of tasks) for that inventory. It's a "declarative" tool in that it makes a system look like a declared and desired end state.

What this means for HA Sinkhole is that multiple types of nodes can be installed simultaneously on remote target nodes and the installer will only take action as needed. If a file already exists, it won't recreate it, if a service that needs to be running already is, it will do nothing. This makes installs idempotent and the installer can safely be run multiple times for the same inventory. Equally, if you want to change an item of configuration, you change it in the inventory file, re-run the installer and only that change will be made. The installer takes care of dependencies such as needing to reload `systemd` and restart services if a service unit file was changed.

There are some [requirements](../README.md#pre-flight-checklist) for machines that run the installer package or that are target nodes for component installations. The main requirements are a working SSH setup and passwordless sudo on target nodes.

## SSH Authentication Setup

**Linux:**

You must be able to SSH to each target node with key-based authentication. The installer container needs access to your SSH agent. Verify your setup with:

```bash
# Check SSH_AUTH_SOCK is set
env | grep SSH_AUTH_SOCK
# Should show: SSH_AUTH_SOCK=/path/to/agent.socket

# Verify it's a socket
ls -al $SSH_AUTH_SOCK
# Should show: srw------- ... /path/to/agent.socket

# Verify keys are loaded
ssh-add -l
# Should list your SSH key(s)
```

If the last command shows no keys, add yours with: `ssh-add ~/.ssh/id_ed25519`

**macOS:**

Container mode has SSH and permission limitations on macOS. Use **native mode** instead:

```bash
# Install Ansible natively
pipx install ansible-core

# Verify SSH agent has your key
ssh-add -l

# Run installer with -n flag
./install.sh -f /path/to/inventory.yaml -n
```

## Usage

Once an inventory has been created, use the wrapper script to run the installer.

**Linux:**

```bash
# One-liner install
curl -sL https://bit.ly/ha-install | bash -s -- -f /path/to/inventory.yaml

# Or for uninstall
curl -sL https://bit.ly/ha-install | bash -s -- -f /path/to/inventory.yaml -c uninstall
```

**macOS:**

```bash
# Download the script first
curl -sL https://bit.ly/ha-install -o install.sh
chmod +x install.sh

# Run in native mode
./install.sh -f /path/to/inventory.yaml -n

# Or for uninstall
./install.sh -f /path/to/inventory.yaml -c uninstall -n
```

**Options:**

- `-f <file>` - Path to inventory YAML file (required)
- `-c <command>` - Command to run: `install` (default) or `uninstall`
- `-n` - Native mode (run Ansible directly, not in container - required on macOS)
- `-l` - Use local installer container (for development only)
- `-h` - Show help

It's best to always fetch the latest wrapper script to ensure compatibility with the current installer container version.

## Configuration

The `installer` itself has no configuration, it acts on the inventory to plan installation tasks for all of the target nodes. The inventory file should be long lived and stored somewhere safe so that it can be reused whenever changes are required to the system. There is a well commented [example](../installer/inventory.example.yaml) file that is a good start point for a new installation. If you're an advanced user, or are likely to have a particularly complex setup of HA Sinkhole, you can split the inventory up into multiple files in a directory, passing that directory to the installer as the `inventory` configuration.

There are 3 main sections to the inventory;

* `all` - the global section. `vars` declared in here will apply to all nodes in all node groups. For example, the `install_channel` should be consistently applied across all machines and containers to ensure a working application.
  
* node groups define configuration specific to the different types of nodes in HA Sinkhole.
  * `dns_nodes` - the combination of resolver, blocklist management, VIP management and metrics collector that enables the actual HA part of the service.
  * `prom_nodes` - future components hosting local grafana stack services for dashboards and graphs showing all your interesting DNS and blocklist metrics.
  
* `hosts` - the individual hosts that make up a group and where variables declared at the group level could be overridden for a specific node.

### Configuration overrides by host

Let's take the example of an HA setup where one machine has better hardware or connectivity than the other and we always prefer using this node to resolve queries, with the other acting as backup only when it's unavailable. In the default configuration supplied, all nodes are equal: they all start in a `state: BACKUP` and with `priority: 100`. The first thing the `vip-manager` does when these machines are installed is choose a primary and dynamically set its `state: MASTER` which might not be the one we want.

We can override the default settings like so to make our `dns1` machine always be the primary for as long as the `dns-resolver` is running and healthy:

```yaml
dns_nodes:
  vars:
    host_vars:
      # the following are defaults and don't need to be declared like this, 
      # but they're here just for completeness
      state: BACKUP
      priority: 100
      # ... other settings ...

  hosts:
    dns1:
      ansible_host: 192.168.0.1
      host_vars_overrides:
        state: MASTER
        priority: 120
    dns2:
      ansible_host: 192.168.0.2
```
In this configuration, `dns1` will always be preferred as a primary node and if taken offline and brought back on, the VIP manager will move the `vip` back to `dns1` as soon as it's healthy again.


## Logging

The installer will log minimal information to the console as it runs and notify where the log file is for the main installation tasks.
