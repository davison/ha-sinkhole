# Installer

HA Sinkhole's installer package is a container that wraps [ansible](https://docs.ansible.com/projects/ansible/latest/getting_started/index.html) and its dependencies. The details of this are mostly irrelevant unless you're [contributing](../CONTRIBUTING.md) to the code as the workings are abstracted from you as an end user. Ansible (and therefore the installer package) is a tool that takes a configuration set called an inventory and plans installation tasks by running playbooks (sets of tasks) for that inventory. It's a "declarative" tool in that it makes a system look like a declared and desired end state.

What this means for HA Sinkhole is that multiple types of nodes can be installed simultaneously on remote target nodes and the installer will only take action as needed. If a file already exists, it won't recreate it, if a service that needs to be running already is, it will do nothing. This makes installs idempotent and the installer can safely be run multiple times against the same inventory. Equally, if you want to change an item of configuration, you change it in the inventory file, re-run the installer and only that change will be made. The installer takes care of dependencies such as needing to reload `systemd` and restart services if a service unit file was changed.

There are some [requirements](../README.md#pre-flight-checklist) for machines that run the installer package and are those that are target nodes for component installations. The main requirement for making the installer work is `ssh`. You must be able to ssh to each target node you wish to install to or manage, and must be able to do so with a key (and not a password). Once there, your user must be able to become root. When run, the install container has your ssh suthentication socket volume mounted in so that it can access your key when performing the ssh login. This socket is typically exposed as an environment variable `SSH_AUTH_SOCK`. You can check that this is setup correctly with the following 3 commands where you should see similar output to those below:

```bash
# check the Env Var is correctly set
env | grep SSH_AUTH_SOCK
SSH_AUTH_SOCK=/home/you/.ssh/agent/s.7IJ34gcr2n.agent.4LfAPQvf2f

# show the file/socket that the Env Var points to
ls -al $SSH_AUTH_SOCK
srw------- 1 you you 0 Nov  7 22:33 /home/you/.ssh/agent/s.7IJ34gcr2n.agent.4LfAPQvf2f=

# List the keys that are known to the current agent
ssh-add -l
2048 SHA256:4R9ob13EdlC4aHE4Fc0pJFM9hLAzQr8m4BdFrqKpWSw /home/you/.ssh/id_rsa (RSA)
```
(real output has been changed)

If you don't get substantially similar output that shows your specific values, the installer won't work. 

* if only the last command failed, run `ssh-add` on its own to add your default key to the agent then try to list it again.
* if either of the first 2 commands fail, or the 2nd one doesn't show the `srw-------` prefix denoting a socket that you can read and write to, then you will need to fix your ssh setup which is beyond the scope of this doc.

## Usage

Once an inventory has been created, the simplest use of the installer is via the wrapper script that just validates some parameters and invokes the container runtime to perform the tasks. The following two commands will completely install and then decommision/uninstall everything declared in the inventory.

```bash
./install.sh -f /path/to/inventory.yaml -c install
./install.sh -f /path/to/inventory.yaml -c uninstall
```

## Configuration

The `installer` itself has no configuration, it acts on the inventory to plan installation tasks for all of the target nodes. The inventory file should be long lived and stored somewhere safe (perhap's verion controlled) so that it can be reused whenever changes are required to the system. There is a well commented [example](../installer/inventory.example.yaml) file that is a good start point for a new installation. If you're an advanced user, or are likely to have a particularly complex setup of HA Sinkhole, you can split the inventory up into multiple files in a directory, passing that directory to the installer as the `inventory` configuration.

There are 3 main sections to the inventory;

* `all` - the global section. `vars` declared in here will apply to all nodes in all node groups but can be selectively overridden by redefining them at the group or node level. Note that it doesn't always make sense to override some vars: the `install_channel` should be consistently applied across all nodes and components in a logical application. Mixing `stable` and `latest` components is probably going to result in several breakages.
  
* node groups define configuration specific to the different types of nodes in HA Sinkhole.
  * DNS Nodes - the combination of resolvers, blocklist management and VIP management that enables the actual HA part of the service.
  * Logging handlers - future components that will extract meta-data from the DNS nodes and pass them to visualisation services.
  * Visualisation - future components hosting dashboards and graphs showing all your interesting DNS and blocklist metrics.
  
* hosts - the individual hosts that make up a group and where variables declared at the global or group level could be overridden for a specific node.

### Configuration overrides

Let's take the example of a multi-dns-node setup where one machine has better hardware or connectivity than the other and we always want to prefer using this node to resolve queries with the other acting as backup only when it's unavailable. In the default configuration supplied, all nodes are equal: they all start in a `state: BACKUP` and with `priority: 100`. The first thing the `vip-manager` does when these machines are installed is choose a primary and dynamically set its `state: MASTER` which might not be the one we want.

We can override the default settings like so to make our `dns1` machine always be the primary, as long as the `dns-node` is running and healthy:

```yaml
dns_nodes:
  vars:
    ha_vars:
      # the following are defaults and don't need to be declared like this, 
      # but they're here just for completeness
      state: BACKUP
      priority: 100
      # ... other settings ...

  hosts:
    dns1:
      ansible_host: 192.168.0.1
      ha_vars_overrides:
        state: MASTER
        priority: 120
    dns2:
      ansible_host: 192.168.0.2
```
In this configuration, `dns1` will always be preferred as a primary node and if taken offline and brought back on, the VIP manager will move the `vip` back to dns1 as soon as it's healthy again.


## Logging

The installer will log to the console as it runs but doesn't store logs anywhere else at this time.
