# Proxmox Cluster Setup

Joins Proxmox VE hosts into a cluster.

## Pre-requisites

- Every node has been through [Proxmox Node Setup](pve-node-setup.md) up to and including the [Ansible baseline](pve-node-setup.md#7-ansible-baseline), so all nodes join on the same PVE version.
- 2-NIC nodes can ping each other over the isolated network.
- Nodes have no guests (VMs/CTs).

## Variables

| Variable | Description | Example |
| --- | --- | --- |
| `<CLUSTER_NAME>` | Cluster name, see [naming convention](../../references/naming-convention/hostname-naming-convention.md#proxmox-clusters) | `home-lab-pve01` |
| `<FIRST_NODE>` | Hostname of the node that creates the cluster | `hml-home-lab-phy-hv01` |
| `<ISOLATED_IP>` | Each node's own isolated network IP, without the `/24` | `192.168.20.52` |
| `<MGMT_IP>` | Each node's own management IP, without the `/24` | `10.15.20.52` |
| `<QDEVICE_IP>` | IP of the QDevice (qnetd) host | `10.15.60.83` |

The cluster name can't easily be changed after creation.

Corosync links use plain IPs as corosync resolves hostnames at startup, so a DNS problem would stop it from forming the cluster. The isolated network has no DNS anyway. `link0` is the isolated network, and `link1` is the management network as a fallback if the isolated switch or NIC fails.

## Setup Instructions

### 1. Create Cluster

On `<FIRST_NODE>`:

```bash
pvecm create <CLUSTER_NAME> --link0 <ISOLATED_IP> --link1 <MGMT_IP>
```

### 2. Join Nodes

On each other node, using that node's own IPs:

```bash
pvecm add <FIRST_NODE>.internal --link0 <ISOLATED_IP> --link1 <MGMT_IP>
```

Prompts for `<FIRST_NODE>`'s root password and to confirm its fingerprint. The `<FIRST_NODE>` address is only used to reach its API for the join, so a hostname is fine here.

Check `pvecm status` shows all nodes and `Quorate: Yes`.

### 3. Add QDevice

With an even number of nodes, a QDevice adds a tie-breaking vote. Without one, rebooting either node of a 2-node cluster loses quorum, which makes `/etc/pve` read-only until it's back.

Prep the QDevice host first:

- `corosync-qnetd` installed and running (lab: `iac/ansible/playbooks/qdevice.yml`).
- Root SSH login with a password allowed for the one-time setup. Key-only is fine afterwards.
- On the same VLAN as the nodes, so they can reach it on TCP 5403 without firewall rules.

The nodes need `corosync-qdevice`, which `pve_baseline` installs.

From `<FIRST_NODE>`:

```bash
pvecm qdevice setup <QDEVICE_IP>
```

Prompts for the QDevice host's **root** password (to install `<FIRST_NODE>`'s SSH key there). It then sets up certificates and starts `corosync-qdevice` on every node, so all nodes must be online.

### 4. Verify

- `pvecm status` shows `Expected votes` and `Total votes` as node count + 1 (eg. 3 for 2 nodes), and `Quorate: Yes`.
- The membership list in `pvecm status` includes a `Qdevice` line with flags `A,V,NMW`.
- Rerun the baseline playbook on all nodes, expect `changed=0`.
- Reboot one node: the remaining node stays quorate.

### 5. Terraform API User and Token

Users and tokens are cluster-wide, so do this once on any node, following [Terraform API User and Token](pve-node-setup.md#8-terraform-api-user-and-token) in the node guide.

## References

- Official Proxmox Doc on [Cluster Manager](https://pve.proxmox.com/wiki/Cluster_Manage)
- [bpg proxmox provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) for Terraform/Opentofu
