# Proxmox Node Setup

Each node has 1-2 NICs and 1-2 drives:

- `nic0` (primary): connected to managed 1G switch, carries VLANs, used for management/VM traffic.
- `nic1` (isolated, optional): connected to isolated 2.5G switch, used for cluster communication (if clustered) and NFS storage traffic. Skip the `nic1`/`vmbr1` parts below for single-NIC nodes.
- Drives: 2 drives as ZFS mirror, or single drive (see [Install](#2-install-proxmox)).

## Variables

Fill these in per node before starting, used in the snippets below.

| Variable | Description | Example |
| --- | --- | --- |
| `<HOSTNAME>` | Node hostname, follows naming convention | `hml-home-lab-phy-hv01` |
| `<MGMT_VLAN>` | Management VLAN ID | `20` |
| `<MGMT_IP>` | Static management IP/CIDR | `10.15.20.52/24` |
| `<MGMT_GW>` | Management gateway | `10.15.20.1` |
| `<ISOLATED_IP>` | Static isolated network IP/CIDR, no gateway (2-NIC nodes only) | `192.168.20.52/24` |

## Setup Instructions

### 1. Bios Setup

Enable the following (if available), most are usually on by default:

- Power on after power loss
- VT-x / AMD-V (SVM)
- VT-d / AMD-Vi (IOMMU), needed for passthrough and SR-IOV
- SR-IOV
- Above 4G decoding
- UEFI boot (CSM/legacy off)

Optional:

- Wake-on-LAN
- C-states / ASPM for lower idle power (disable ASPM if NIC drops link)
- Keep iGPU enabled (for transcoding passthrough)
- Disable XMP/EXPO for stability
- Disable unused onboard devices (audio, wifi/bt, serial)

### 2. Install Proxmox

Only connect the primary NIC during install to avoid picking the wrong interface. Install Proxmox ISO and follow the GUI installer:

- Disk:
  - 2 drives: ZFS raid1 (mirror).
  - 1 drive: ext4 (less SSD wear). Use ZFS raid0 only if the node needs ZFS replication.
- Network: Static `<MGMT_IP>` and `<MGMT_GW>` on the primary NIC.
- Hostname: `<HOSTNAME>.internal` FQDN.

### 3. Pin NIC Names

NIC names must be consistent across nodes so the network config below works as a template: `nic0` = primary, `nic1` = isolated. Connect the isolated NIC (if any), then check names with `ip a`.

If any NIC is not named `nicX` (eg. `enp1s0`), pin it and reboot:

```bash
pve-network-interface-pinning generate
reboot
```

After reboot, confirm `nic0` is the primary NIC (has `master vmbr0`) and `nic1` is the isolated one. If they're swapped, edit `Name=` in the generated `.link` files under `/usr/local/lib/systemd/network/` and reboot.

### 4. Proxmox APT Repositories

Disable the enterprise APT sources and use no-subscription sources instead.

> **Note:** The `pve_baseline` Ansible role does this (see [step 7](#7-ansible-baseline)). Manual steps kept for reference.

GUI: `Proxmox node -> Updates -> Repositories`, disable enterprise ceph and enterprise pve sources, then `Add -> Repository -> No-Subscription`. Refresh/upgrade in the Updates tab.

CLI: add `Enabled: false` to `/etc/apt/sources.list.d/ceph.sources` and `/etc/apt/sources.list.d/pve-enterprise.sources`, then create `/etc/apt/sources.list.d/pve.sources`:

```conf
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
```

### 5. Network Settings

Switch config for the primary NIC's port:

- All VLANs **tagged**, including `<MGMT_VLAN>`.
- Port PVID set to an unused VLAN, so untagged traffic goes nowhere.

> **Warning:** Switch and node config must match. If the switch sends `<MGMT_VLAN>` untagged but the node expects `vmbr0.<MGMT_VLAN>` (or vice versa), the node loses its IP and needs console access to fix. Apply switch and node changes together, with console access available.

Edit `/etc/network/interfaces`:

```conf
auto lo
iface lo inet loopback

# primary nic
auto nic0
iface nic0 inet manual

# isolated nic (2-NIC nodes only)
auto nic1
iface nic1 inet manual

# vlan aware bridge for primary nic
auto vmbr0
iface vmbr0 inet manual
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids 2-4094

# management vlan, static IP for host
auto vmbr0.<MGMT_VLAN>
iface vmbr0.<MGMT_VLAN> inet static
        address <MGMT_IP>
        gateway <MGMT_GW>

# linux bridge for isolated nic, no gateway (2-NIC nodes only)
auto vmbr1
iface vmbr1 inet static
        address <ISOLATED_IP>
        bridge-ports nic1
        bridge-stp off
        bridge-fd 0

source /etc/network/interfaces.d/*
```

Apply with `ifreload -a`, then check `Proxmox node -> System -> Network` in the GUI.

### 6. Verify

- For 2-NIC nodes: nodes can ping each other over the isolated network (`<ISOLATED_IP>` range).
- Node can reach the internet (eg. `ping google.com`).
- Unbound override added in OpnSense, node reachable via `<HOSTNAME>.internal`.

### 7. Ansible Baseline

Ansible connects to PVE nodes as root (see [Automation Access](../iac-automation-setup.md#automation-access)). Copy your SSH key to root:

```bash
ssh-copy-id root@<HOSTNAME>.internal
```

Add the node to the `proxmox` group in the environment's inventory (`iac/ansible/inventory/<env>/hosts.yml`), then run the baseline playbook (`ansible-lab` or `ansible-prod`):

```bash
ansible-lab ansible-playbook iac/ansible/playbooks/proxmox.yml --limit <HOSTNAME>
```

This applies `pve_baseline` and `common_baseline`: APT repos, dist-upgrade and reboot if a newer kernel was installed, disabling HA services (non-HA cluster), installing `corosync-qdevice`, timezone, base packages, sshd hardening and journald cap.

If the node will be part of a cluster, run this on every node before [Cluster Setup](pve-cluster-setup.md), so all nodes join on the same PVE version.

### 8. Terraform API User and Token

OpenTofu uses a dedicated non-root user with an API token.

- **Standalone host:** do this now.
- **Clustered host:** skip this, and do it once on any node after [Cluster Setup](pve-cluster-setup.md). Joining a cluster replaces the node's `/etc/pve` (where users and tokens are stored) with the cluster's copy, so a user created before joining is lost.

```bash
pveum user add automation@pve --comment "Terraform"
pveum aclmod / -user automation@pve -role PVEAdmin
pveum user token add automation@pve terraform --privsep 0
```

- `--privsep 0` makes the token inherit the user's permissions, so the ACL only needs setting on the user.
- `PVEAdmin` is broad (but not root-equivalent). Swap for a custom least-privilege role later.
- The token secret is only shown once.

Add to `iac/secrets/<env>.sops.yaml` (see [Secrets](../iac-automation-setup.md#secrets)). For a cluster, any node's address works as the endpoint:

```yaml
proxmox:
  endpoint: https://<HOSTNAME>.internal:8006/
  token_id: automation@pve!terraform
  token_secret: <token secret>
```

Verify with `tofu-lab plan` (or `tofu-prod plan`), which should read the host's nodes without errors.

## Next Steps

- [Cluster Setup](pve-cluster-setup.md), if the node will be part of a cluster.
- NFS storage from the NAS.
