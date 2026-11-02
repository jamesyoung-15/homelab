# Proxmox VM and LXC Naming Convention

The following defines the naming and organization convention for my Proxmox VMs and LXC containers. Rather than enforce a custom ID scheme, I use Proxmox's auto-incrementing IDs combined with hostnames and tags for identification and organization.

## Design Principles

- Let Proxmox auto-increment VM/LXC IDs (simple, no conflicts).
- Hostname is the primary identifier (mirrors infrastructure naming).
- Tags provide flexible organization and filtering, also enables future possibility of tag-based automation, resource tracking, and policy enforcement.

## Proxmox VM/LXC Identification

### VM/CT ID

Let Proxmox auto-assign numeric IDs (100, 101, 102, etc.). These are internal identifiers and do not need to follow a naming convention.

I did consider some ID schemes, such as encoding VLAN and static IP into VM/CT IDs, where `192.168.50.122` becomes 50122 (valid as max ID is like 999999999). However, if I were to change a VM/CT's IP address, I would then need to change the ID which is not that quick on Proxmox. In the end to save myself from overthinking I will just let Proxmox auto-assign and use tags.

### LXC and VM Naming

Set the LXC hostname and VM name to match [Hostname Naming Convention](./hostname-naming-convention.md):

```bash
<Provider>-<Site>-<Environment>-<Type>-<Role><Number>
```

Example hostnames:

```bash
hml-home-prd-lxc-dns01
hml-home-prd-vm-web01
hml-home-lab-vm-test01
```

The hostname is the human-readable, unique identifier for the VM/container across infrastructure.

## Tags

Use tags to organize, filter, and automate VM/container management. Tags follow a `key:value` format.

### Tag Schema

Standard tags for every VM/container:

```bash
vlan:<vlan_id>        VLAN ID (e.g., vlan:50, vlan:60)
env:<environment>     Environment (e.g., env:prd, env:lab, env:dev)
role:<role>           Role from hostname (e.g., role:dns, role:web, role:db)
```

Optional tags for additional context:

```bash
app:<application>     Application/service (e.g., app:nextcloud, app:jellyfin)
tier:<tier>           Criticality tier (e.g., tier:critical, tier:standard, tier:experimental)
site:<site>           Physical/regional location (e.g., site:home, site:prnt)
```

### Tag Examples

Single-purpose service:

```bash
vlan:50
env:prd
role:dns
tier:critical
```

Multi-component service (Nextcloud):

```bash
vlan:50
env:prd
role:web
app:nextcloud
tier:critical
```

Lab experimental VM:

```bash
vlan:60
env:lab
role:test
tier:experimental
```

## Storage Volumes

Name storage volumes using the hostname and purpose:

```bash
<hostname>-<purpose>
```

Examples:

```bash
hml-home-prd-vm-web01-root
hml-home-prd-vm-web01-data
hml-home-prd-lxc-dns01-root
```

Common purposes:

```bash
- root   Root/system filesystem
- data   Data/application storage
```

## Guidelines

1. **Hostname as primary identifier**: Set the hostname according to the [Hostname Naming Convention](./hostname-naming-convention.md). This is the main way to identify VMs/containers.
2. **Proxmox auto-increment IDs**: Use Proxmox's default auto-increment for VM/LXC IDs. Custom numeric schemes are not necessary.
3. **Tag for organization**: Apply tags at minimum: `vlan:<id>`, `env:<env>`, `role:<role>`. Additional tags (`app:<app>`, `tier:<tier>`) can be added as needed.
4. **Consistent tag values**: Tag values should align with hostname convention fields (`env`, `role`, `site`) for consistency.
5. **Tag-based automation**: Leverage tags to drive policies, backups, resource limits, and alerting.

## Examples

### Single-Purpose LXC (DNS)

```text
Proxmox ID: 100
Hostname: hml-home-prd-lxc-dns01
Tags: vlan:50, env:prd, role:dns, tier:critical
```

### Multi-Component Service (Nextcloud)

```text
Proxmox ID: 101
Hostname: hml-home-prd-vm-int01
Tags: vlan:50, env:prd, role:int, app:nextcloud, tier:critical

Proxmox ID: 102
Hostname: hml-home-prd-vm-db01
Tags: vlan:50, env:prd, role:db, app:nextcloud, tier:critical
```

### Lab VM

```text
Proxmox ID: 200
Hostname: hml-home-lab-vm-test01
Tags: vlan:60, env:lab, role:test, tier:experimental
```

---

## Tag-Based Filtering & Automation

In the future, tags can be used for things such as:

- **Backup policies**: Tag VMs with `tier:critical` and apply stricter backup schedules.
- **Network policies**: Tag by `vlan:*` to apply VLAN-specific firewall rules.
- **Resource limits**: Tag by `env:*` to enforce resource quotas per environment.
- **Alerting**: Tag by `tier:critical` to escalate monitoring alerts.
- **Lifecycle management**: Tag by `env:lab` to auto-stop non-critical VMs during maintenance.
