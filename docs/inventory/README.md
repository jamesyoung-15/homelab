# Hardware Inventory

Inventory of server/PC hardware across homelab and personal devices.

## Summary

Generated from the CSVs by `scripts/inventory-md.py`:

- [Components](components.md): CPUs, motherboards, GPUs, PSUs, RAM, storage, NICs
- [Network](network.md): switches

## Source CSVs

| File | Contents |
|---|---|
| [hosts.csv](hosts.csv) | Machines that run an OS: custom builds, prebuilts, SBCs |
| [network.csv](network.csv) | Switches |
| [components/cpu.csv](components/cpu.csv) | CPUs |
| [components/motherboard.csv](components/motherboard.csv) | Motherboards |
| [components/gpu.csv](components/gpu.csv) | Discrete GPUs |
| [components/psu.csv](components/psu.csv) | Power supplies |
| [components/ram.csv](components/ram.csv) | RAM (DIMM/SODIMM) |
| [components/storage.csv](components/storage.csv) | HDDs and SSDs (NVMe, SATA, mSATA) |
| [components/nic.csv](components/nic.csv) | Add-in NICs |

IoT devices are not tracked yet.

## Conventions

CSV designed to be able to put in a relational DB in future to map server to component to track what uses what and stuff like that.

- one row per physical unit (no quantity, this way can map server -> component properly)
- if a part can move between machines, it's a component. Parts that can't (e.g. SBC SoC/RAM, soldered mini-PC CPU) go in the host's `builtin_spec`
- link used component to host, blank for unused
- id prefixed per category, easier if I use a relational DB to map this in future
- unit in column names for easier filtering/sorting
- `status`: `in-use` / `spare` / `faulty` / `active` / `retired` (hosts, network).
- notes is free-text
