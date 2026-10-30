# IP Addressing Strategy

This page documents IP address allocation strategy across VLANs. Defines static IP ranges for infrastructure devices and DHCP pools for clients.

## Overview

All VLANs follow a consistent /24 subnet pattern:

- **x.x.X.1** — OPNsense gateway
- **x.x.X.10-99** — Static IPs (infrastructure, servers, network gear)
- **x.x.X.100-254** — DHCP pool (clients, temporary devices)

## VLAN 10 (Management)

Network devices only.

```txt
10.15.10.1 — OPNsense interface
10.15.10.10-49 — Switches, network gear
10.15.10.50-60 — Wireless APs
10.15.10.61-99 — Reserved for other infrastructure
10.15.10.100-254 — DHCP pool
```

## VLAN 20 (Infrastructure)

Proxmox nodes and compute resources.

```txt
10.15.20.1 — OPNsense interface
10.15.20.10-60 — Proxmox nodes, NAS, bare-metal server
10.15.20.61-99 — Reserved for future infrastructure
10.15.20.100-254 — DHCP pool
```

## VLAN 30 (Trusted)

Personal devices.

```txt
10.15.30.1 — OPNsense interface
10.15.30.10-99 — Reserved for future static IPs
10.15.30.100-254 — DHCP pool
```

## VLAN 35 (Shared)

Friends/family and personal auxiliary devices.

```txt
10.15.35.1 — OPNsense interface
10.15.35.10-99 — Reserved for future static IPs
10.15.35.100-254 — DHCP pool
```

## VLAN 40 (DMZ)

Internet-facing services.

```txt
10.15.40.1 — OPNsense interface
10.15.40.10-99 — Static IPs for DMZ services (reverse proxy, etc.)
10.15.40.100-254 — DHCP pool
```

## VLAN 50 (Services)

Internal services and applications.

```txt
10.15.50.1 — OPNsense interface
10.15.50.10-99 — Static IPs (may decrease/remove as most services will use DHCP)
10.15.50.100-254 — DHCP pool
```

## VLAN 60 (Lab)

Experimental workloads.

```txt
10.15.60.1 — OPNsense interface
10.15.60.10-99 — Lab infrastructure (test VMs, containers)
10.15.60.100-254 — DHCP pool
```

## VLAN 70 (IoT)

Smart home devices.

```txt
10.15.70.1 — OPNsense interface
10.15.70.10-99 — Static IPs for critical IoT (Zigbee hub, Z-Wave hub, etc.)
10.15.70.100-254 — DHCP pool (bulbs, sensors, switches)
```

## VLAN 80 (Isolated)

Untrusted IoT devices.

```txt
10.15.80.1 — OPNsense interface
10.15.80.10-99 — Reserved for future static IPs
10.15.80.100-254 — DHCP pool (IP cameras, etc.)
```

## VLAN 90 (Guest)

Guest and untrusted devices.

```txt
10.15.90.1 — OPNsense interface
10.15.90.100-254 — DHCP pool
```

## VLAN 100 (WireGuard)

Remote VPN access.

```txt
10.15.100.1 — OPNsense interface / WireGuard server
10.15.100.2-254 — WireGuard client pool
```

## General Rules

- **Infrastructure/Network gear** (switches, APs, Proxmox nodes): Configure static IPs on the device OS. Optionally add Unbound DNS Host Overrides for hostname resolution
- **Services/Containers/VMs**: Use DHCP with dnsmasq Host reservations (hardware addresses) for both IP stability and automatic DNS registration
- Always use static IPs (10-99 range) for infrastructure devices that require reliable addressing
- Proxmox nodes should have static IPs for cluster communication
- DHCP pools (100-254) for client devices only
- Never use 10.x.x.0 or 10.x.x.255 (network/broadcast addresses)
- Reserve 10-99 ranges even if not fully populated for future growth
