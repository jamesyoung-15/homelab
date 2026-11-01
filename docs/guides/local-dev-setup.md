# Local Dev Setup

I use my main PC that runs NixOS for developing automations (IaC, scripts, etc).

## Pre-reqs

Installed on the host:

- Nix with flakes enabled
- direnv, with its shell hook enabled (NixOS: `programs.direnv.enable = true;`)
- VS Code with the `mkhl.direnv` and `redhat.ansible` extensions
- SOPS age key at `~/.sops/homelab-keys.txt` (or set `SOPS_AGE_KEY_FILE`)

Everything else comes from the flake's dev shell:

- Tofu/Terraform
- Ansible
- uv
- sops + age

See `flake.nix` in the repo root for full dev tools.

## First-time Setup

```bash
# Load the dev shell automatically when entering the repo (.envrc is gitignored)
echo "use flake" > .envrc
direnv allow

# Ansible collections (installs to iac/ansible/.ansible/collections)
ansible-galaxy collection install -r iac/ansible/requirements.yml
```

Open the repo root in VS Code and accept the direnv extension's prompt to restart extensions. Ansible hints come from `iac/ansible/ansible.cfg`, which the dev shell points to with `ANSIBLE_CONFIG`.

<!-- TODO: anything else needed on a fresh machine (Cloudflare/R2 access, SSH keys, etc.) -->

## Helper Commands

Available in the dev shell. The `-lab`/`-prod` commands decrypt that environment's secrets from `iac/secrets/` before running.

| Command | Does |
|---|---|
| `ansible-lab <cmd>` / `ansible-prod <cmd>` | Runs an Ansible command against that environment's inventory |
| `tofu-lab <cmd>` / `tofu-prod <cmd>` | Runs `tofu <cmd>` in `iac/terraform/<env>/` |
| `python3 scripts/inventory-md.py` | Regenerates the inventory markdown from the CSVs |

Ansible paths are relative to your current directory, so these are equivalent:

```bash
ansible-lab ansible-playbook iac/ansible/playbooks/proxmox.yml   # from repo root
ansible-lab ansible-playbook playbooks/proxmox.yml               # from iac/ansible
```

## Docs

```bash
zensical serve   # local preview
```

<!-- TODO: notes on publishing (pushes to main touching docs/ deploy via GitHub Actions) -->
