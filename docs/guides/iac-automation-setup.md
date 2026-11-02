# IaC Automation Setup

One-time setup to make the homelab drivable with automation (Ansible and OpenTofu). Per-host steps (SSH keys, API tokens, baseline playbooks) live in each host's setup guide, linked below.

## Pre-requisites

- Local dev environment set up, see [Local Dev Setup](local-dev-setup.md)
- OpnSense configured (VLANs, DNS overrides)
- Cloudflare account (R2 for OpenTofu state, DNS)

## Automation Access

How automation connects to each type of host:

| Host type | Ansible connects as | OpenTofu uses | Set up in |
| --------- | ------------------- | ------------- | --------- |
| Proxmox VE nodes | `root` (SSH key) | `automation@pve` API token | [Proxmox Node Setup](proxmox/pve-node-setup.md), [Proxmox Cluster Setup](proxmox/pve-cluster-setup.md) |
| Proxmox Backup Server | `root` (SSH key) | - | [PBS Setup](proxmox/pbs-node-setup.md) |
| NAS and other Debian hosts | `automation` (passwordless sudo) | - | [NAS Node Setup](nas/nas-node-setup.md) |

- **PVE and PBS use root** because the cluster needs root SSH between nodes and for QDevice setup, and Proxmox tooling (`pvecm`, `pveum`, `qm`) assumes root. A sudo user wouldn't reduce exposure since root SSH has to stay enabled anyway. Root login is key-only, set by `common_baseline_sshd_permit_root_login: prohibit-password` in the group's `group_vars`.
- **Plain Debian hosts use an `automation` user**, created by Ansible on the first run (which connects as the personal account made during install). Root SSH stays disabled.
- **Ansible SSH user** is set per group with `ansible_user` in `iac/ansible/inventory/<env>/group_vars/<group>.yml`.

## Secrets

Secrets are encrypted with SOPS + age in `iac/secrets/<env>.sops.yaml`. `.sops.yaml` in the repo root sets the age recipient for that path.

The age key lives at `~/.sops/homelab-keys.txt`. To edit a secrets file:

```bash
SOPS_AGE_KEY_FILE=~/.sops/homelab-keys.txt sops iac/secrets/<env>.sops.yaml
```

The `ansible-<env>` and `tofu-<env>` wrapper commands decrypt the file and export these (see `scripts/with-secrets.sh`):

| Secrets key | Exported as | Used for |
| --- | --- | --- |
| `proxmox.endpoint` | `TF_VAR_proxmox_endpoint` | Proxmox API URL |
| `proxmox.token_id` | `TF_VAR_proxmox_token_id` | Proxmox API token ID |
| `proxmox.token_secret` | `TF_VAR_proxmox_token_secret` | Proxmox API token secret |
| `cloudflare.account_id` | `TF_VAR_cloudflare_account_id` | Cloudflare account, R2 endpoint |
| `cloudflare.api_token` | `TF_VAR_cloudflare_api_token` | Cloudflare DNS/zone token |
| `cloudflare.r2.bucket` | `TF_VAR_cloudflare_r2_bucket` | OpenTofu state bucket |
| `cloudflare.r2.access_key_id` | `AWS_ACCESS_KEY_ID` | R2 (S3-compatible) state backend |
| `cloudflare.r2.secret_access_key` | `AWS_SECRET_ACCESS_KEY` | R2 (S3-compatible) state backend |

## Proxmox API Token

OpenTofu uses a dedicated non-root Proxmox user with an API token, created once per standalone host or once per cluster. See [Terraform API User and Token](proxmox/pve-node-setup.md#8-terraform-api-user-and-token).

## Cloudflare R2 Setup

For now will be using Cloudflare R2 as S3-compatible remote backend for OpenTofu state with one bucket per environment. 

To setup:

1. Create an R2 bucket.
2. Create an R2 API token with read/write access to the bucket, and note the access key ID and secret access key.
3. Add the bucket name, access key ID and secret access key to `iac/secrets/<env>.sops.yaml` under `cloudflare.r2`.

## Cloudflare DNS Setup

A separate token with permissions for the relevant zone and DNS settings.

1. Create an account API token scoped to the zone(s) it manages.
2. Add it to `iac/secrets/<env>.sops.yaml` as `cloudflare.api_token`, along with `cloudflare.account_id`.
