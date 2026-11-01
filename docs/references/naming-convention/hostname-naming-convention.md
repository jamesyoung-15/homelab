# Hostname Naming Convention

The following defines my naming convention for the hostname structure used across all infrastructure. This includes homelab, cloud providers, virtual machines, and containers.

## Design Principles

- Consistent structure across homelab and cloud.
- Hybrid friendly.
- Migration safe for virtual machines.
- Predictable for automation and scripting.
- Simple enough to maintain long term.

## Hostname Format

All systems follow this format:

```bash
<Provider>-<Site>-<Environment>-<Type>-<Role><Number>
```

Example:

```bash
hml-home-prd-phy-nas01
```

Try to have every hostname contain all five fields for consistency.

---

## Fields

### Provider

Identifies who owns or operates the infrastructure.

Common values:

```bash
- hml   Personal homelab
- aws   Amazon Web Services
- htz   Hetzner
- ocl   Oracle Cloud
- cdf   Cloudflare
```

Keep provider codes short and stable.

### Site

Identifies the physical or regional location.

Site codes are exactly 4 lowercase characters. 
This keeps homelab codes consistent with the cloud region codes below, and keeps [cluster names](#proxmox-clusters) within Proxmox's length limit.

Homelab examples:

```bash
- home   Primary home
- prnt   Parents' place
```

Cloud examples:

```bash
- use1   AWS us-east-1
- usw2   AWS us-west-2
- hel1   Hetzner Helsinki
- fsn1   Hetzner Falkenstein
```

Try to include site value for all systems, even if there is only one location.

### Environment

Identifies lifecycle or purpose.

Common values:

```bash
- prd   Production
- lab   Experimental
- dev   Development
- stg   Staging
```

### Type

Identifies how the system runs.

```bash
Common values:

- phy   Physical machine
- vm    Virtual machine
- lxc   Proxmox container
```

Type describes platform, not function.

### Role

Describes what the system does.

Examples:

```bash
- hv     Proxmox hypervisor
- nas    Storage server
- web    Web server
- db     Database server
- int    Internal services
- dns    DNS server
- vpn    VPN server
- mon    Monitoring
- proxy  Reverse proxy
- backup Backup server
```

Role names should be short and consistent.

### Number

Two digit identifier per role within the same provider, site, and environment.

Examples:

```bash
- hv01
- web01
- web02
- db01
```

Numbering starts at 01 and increments as needed.

---

## Examples

### Homelab at primary home

hml-home-prd-phy-hv01  
hml-home-prd-phy-hv02  
hml-home-prd-phy-nas01  

hml-home-prd-vm-web01  
hml-home-prd-vm-db01  
hml-home-prd-vm-int01  

hml-home-prd-lxc-dns01  
hml-home-prd-lxc-vpn01  

### Homelab at secondary location

hml-prnt-prd-phy-hv01  
hml-prnt-prd-vm-backup01  

### AWS

aws-use1-prd-vm-web01  
aws-use1-prd-vm-api01  

### Hetzner

htz-hel1-prd-vm-edge01  

---

## Rules

1. All hostnames are lowercase.
2. Use hyphens between fields.
3. Always include all five fields.
4. Do not encode hardware model, storage, or cluster node.
5. Do not encode the Proxmox host into VM or container names.
6. Keep role names short and consistent.
7. Only increment numbers within the same provider, site, environment, and role.
8. Site codes are exactly 4 characters.

---

## Proxmox Clusters

Proxmox cluster names are limited to 15 characters (letters, digits, and hyphens, starting with a letter) and can't easily be renamed after creation, so they use a shortened form of the hostname format:

```bash
<Site>-<Environment>-pve<Number>
```

Examples:

```bash
home-prd-pve01   Production cluster
home-lab-pve01   Lab cluster
home-prd-pve02   Second production cluster
prnt-prd-pve01   Cluster at parents' place
```

- Drops Provider, as Proxmox clusters only exist in the homelab (always `hml`).
- Drops Type, as a cluster is a logical grouping rather than something that runs as `phy`/`vm`/`lxc`.
- Role is `pve` rather than `hv`, since `hv` names a single node.
- Number is always included, so a second cluster at the same site and environment doesn't need a rename.
- With 4 character site codes, every cluster name is 14 characters, under the 15 character limit.
- A node's hostname shares the site and environment with its cluster, eg. `hml-home-prd-phy-hv01` belongs to `home-prd-pve01`.
