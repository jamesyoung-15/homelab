# NAS Node Setup

My NAS setup instructions. NAS hardware will use:

- 2 NICs (primary and isolated): primary reaches wider network/internet (1G), isolated is segregated and only for file share (2.5G)
- Drives: Prod will have boot + mirrored disks, lab may vary depending on needs (possible to just use single disk to save money)

## Variables

| Variable | Description | Example |
| --- | --- | --- |
| `<HOSTNAME>` | NAS hostname, follows naming convention | `hml-home-prd-phy-nas01` |
| `<USER>` | Personal account created during install | `james` |
| `<MGMT_IP>` | Static management IP/CIDR | `10.15.20.15/24` |
| `<ISOLATED_IP>` | Static isolated network IP, no gateway | `192.168.20.15` |
| `<ENV>` | Environment, picks the `ansible-<env>` / `tofu-<env>` wrapper | `prod` |

## Setup Instructions

### 1. Server Setup

Go into Bios, enable power-on after power loss setting to ensure server always boots after power-loss.

### 2. Install Debian to Server

Install Debian netiso and boot installer on server.

### 3. Installer Options

Follow the installer setup instructions, only things to look out for:

- choose correct NIC as primary NIC (don't use secondary/isolated NIC)
- choose empty root password to setup a local account with `sudo`
- most likely won't need LVM for boot disk unless hardware setup changes

### 4. Set Static IPs

If the installer didn't prompt for static IP, set it manually by editing `/etc/network/interfaces`. Add the isolated NIC too, without a gateway:

```conf
# primary nic
auto <primary nic>
iface <primary nic> inet static
  address <MGMT_IP>
  gateway 10.15.20.1

# isolated nic, NFS only
auto <isolated nic>
iface <isolated nic> inet static
  address <ISOLATED_IP>/24
```

Then restart network service or reboot. Add an Unbound host override in OpnSense for `<HOSTNAME>.internal`.

### 5. SSH Key

On the IaC machine, copy your SSH key to the personal account created during install, then SSH once by hostname to accept the host key (Ansible can't answer the prompt):

```bash
ssh-copy-id <USER>@<HOSTNAME>.internal
ssh <USER>@<HOSTNAME>.internal
```

### 6. Inventory

Add the host to the `nas` group in `iac/ansible/inventory/<ENV>/hosts.yml`. `group_vars/nas.yml` sets the `automation` user used from the bootstrap onwards (see [Automation Access](../iac-automation-setup.md#automation-access)):

```yaml
ansible_user: automation
ansible_ssh_private_key_file: ~/.ssh/hml-automation
```

### 7. Bootstrap

The first run connects as the personal account, overriding `ansible_user`:

```bash
ansible-<ENV> ansible-playbook iac/ansible/playbooks/linux_bootstrap.yml \
  -e target_hosts=<HOSTNAME> -e ansible_user=<USER> --ask-become-pass
```

This applies `common_baseline` (timezone, base packages, sshd hardening incl. password auth off, journald cap, dist-upgrade and reboot if a newer kernel was installed) and `iac_user_setup` (`automation` user with SSH key and passwordless sudo).

`target_hosts` has no default, so the playbook fails rather than running against every host if it's missing.

Verify: `ssh -i ~/.ssh/hml-automation automation@<HOSTNAME>.internal 'sudo -n true'` succeeds. From here on, Ansible connects as `automation`.

### 8. Disks

Run the NAS playbook once without pools defined. It installs the tools and ZFS, and prints each disk with its `/dev/disk/by-id` names:

```bash
ansible-<ENV> ansible-playbook iac/ansible/playbooks/nas_setup.yml --limit <HOSTNAME>
```

Use the `ata-*` ids (they contain the serial number), and match them against the serials on the physical drives.

Before building pools, run a SMART long test on every HDD (especially refurbished ones). It takes hours, check results once done:

```bash
sudo smartctl -t long /dev/disk/by-id/<disk id>
sudo smartctl -a /dev/disk/by-id/<disk id>    # check the self-test log and reallocated/pending sectors
```

### 9. Host Vars

Create `iac/ansible/inventory/<ENV>/host_vars/<inventory name>.yml` with pools, datasets and exports. One pool per mirror, so either pair of disks can be swapped or moved independently:

```yaml
zfs_setup_pools:
  - name: tank12
    vdevs:
      - type: mirror
        disks:
          - /dev/disk/by-id/ata-<model>_<serial>
          - /dev/disk/by-id/ata-<model>_<serial>
  - name: tank06
    vdevs:
      - type: mirror
        disks:
          - /dev/disk/by-id/ata-<model>_<serial>
          - /dev/disk/by-id/ata-<model>_<serial>

zfs_setup_datasets:
  - name: tank12/proxmox

nfs_server_exports:
  - path: /tank12/proxmox
    clients:
      - host: 192.168.20.0/24
        options: rw,sync,no_subtree_check,no_root_squash
```

- Pools default to `ashift=12`, `compression=lz4`, `atime=off` (`zfs_setup` defaults), overridable per pool with `pool_properties` / `filesystem_properties`.
- Export datasets, not pool roots. Each dataset mounts at `/<pool>/<name>` and gets its own properties, quota and snapshots.
- `no_root_squash` is needed as Proxmox writes as root. Only acceptable because the export is limited to the isolated subnet.
- Bare metal uses the default `linux-headers-amd64` for ZFS. Cloud-image VMs need `zfs_setup_kernel_headers_package: linux-headers-cloud-amd64`.

### 10. ZFS and NFS

Dry run first, `zpool create` is destructive, so check the disks in the diff:

```bash
ansible-<ENV> ansible-playbook iac/ansible/playbooks/nas_setup.yml --limit <HOSTNAME> --check --diff
ansible-<ENV> ansible-playbook iac/ansible/playbooks/nas_setup.yml --limit <HOSTNAME>
```

Verify on the NAS:

- `sudo zpool status` shows each pool `ONLINE` with the expected mirrors.
- `sudo zfs get compression,atime <pool>` shows `lz4` and `off`.
- `sudo exportfs -v` lists each export with its options.
- Rerunning the playbook gives `changed=0`.

`nfs-server` showing `active (exited)` is normal, the server runs in the kernel. Its log may show `can't open /etc/exports` from the first start during package install, before the template was written.

### 11. Proxmox NFS Storage

Added with OpenTofu, in the environment's Terraform config:

```hcl
resource "proxmox_storage_nfs" "nas01-nfs" {
  id      = "nas01-nfs"
  server  = "<ISOLATED_IP>"
  export  = "/tank12/proxmox"
  content = ["images", "iso", "backup"]
  options = "vers=4.2"
}
```

- `server` is the isolated IP, so traffic stays on the 2.5G network (no DNS there).
- `nodes` left unset makes the storage available on every node in the cluster, including ones added later. Set it only if some nodes can't reach the isolated network.
- Storage config is cluster-wide, one resource covers all nodes.

Apply with `tofu-<ENV> apply`, then verify on each node:

- `showmount -e <ISOLATED_IP>` lists the export.
- `pvesm status` shows `nas01-nfs` as active.
- `/mnt/pve/nas01-nfs` exists, and a file uploaded via one node is visible from the other.

## Notes

### Removing NFS Storage

When removing the storage or rebuilding the NAS, remove the Proxmox storage **before** the NFS server goes away. Otherwise nodes keep a stale mount, which can hang `df`/`pvestatd` and makes re-adding the storage fail with `unable to activate storage ... does not exist or is unreachable`.

```bash
tofu-<ENV> destroy -target=proxmox_storage_nfs.nas01-nfs
```

If the NAS is also managed by OpenTofu (eg. a lab VM), `depends_on` on the storage resource makes OpenTofu destroy it first and create it after.

Then on each node, check for and remove any leftover mount:

```bash
mount | grep nas01-nfs
umount -f -l /mnt/pve/nas01-nfs
```

After reinstalling the NAS, remove its old host key before SSHing again: `ssh-keygen -R <HOSTNAME>.internal`.

### Lab VM NAS

The full flow was rehearsed on a lab VM (`hml-home-lab-vm-nas01`, Debian cloud image created with OpenTofu, single-disk pool). Differences from bare metal:

- Cloud-init creates the `automation` user, so the bootstrap runs as `automation` from the start.
- Kernel headers are `linux-headers-cloud-amd64`.
- On a fresh build OpenTofu has to run in two stages: VM, then Ansible (ZFS/NFS), then the NFS storage. A single apply tries to add the storage before NFS exists.
