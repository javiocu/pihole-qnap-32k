# Pi-hole v6.4 for QNAP NAS (ARMv7 - 32KB Page Size)

Custom-built Pi-hole FTL v6.4 image specifically designed for QNAP NAS devices with ARMv7 CPUs and 32KB memory page size (e.g., TS-431P3 with Annapurna Labs AL314 kernel).

## Why This Image?

Official Pi-hole Docker images crash on QNAP NAS models with 32KB kernel page size due to binary incompatibility (Segmentation Fault). This image solves that by:

- **Statically compiled FTL** with `max-page-size=32768` linker flag
- **Alpine 3.20** build environment for clean compilation
- **Debian Bullseye** runtime base for stability
- Includes **full web interface** and CLI tools (`pihole -g`, gravity update)
- Official Pi-hole assets (web UI, scripts) from `pihole/pihole:latest`
- Full ARM v7 (32-bit) compatibility

## Supported Hardware

✅ **Tested & Verified:** QNAP TS-431P3  
⚠️ **Likely Compatible (Untested):** TS-431P2, TS-231P3, and other ARMv7 QNAP NAS models with Annapurna Labs AL314/AL324 CPUs.

## Quick Start

### Using Docker Compose (Recommended)

Copy this YAML into Container Station → Applications → Create:

```yaml
networks:
  qnet_static:
    driver: qnet
    driver_opts:
      iface: "eth0"  # Adapt to your interface (e.g. eth0, bond0)
    ipam:
      driver: qnet
      options:
        iface: "eth0"
      config:
        - subnet: 192.168.1.0/24  # Adapt to your subnet
          gateway: 192.168.1.1    # Adapt to your gateway

services:
  pihole:
    image: javiocu/pihole-qnap-32k:v6.4
    container_name: pihole
    hostname: pihole
    restart: unless-stopped
    networks:
      qnet_static:
        ipv4_address: 192.168.1.100  # Adapt to your desired IP
    mac_address: 02-42-C0-A8-01-64   # Optional but recommended
    environment:
      - TZ=Europe/Madrid
    volumes:
      - /share/Container/pihole/etc:/etc/pihole
      - /share/Container/pihole/dnsmasq:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
```

## Configuration

- Change `ipv4_address` to a free IP on your network
- Update volume paths (`/share/...`) to match your QNAP shared folder structure
- Set your timezone in `TZ` variable
- Generate a MAC address or keep the example one

## First Run

Access the web interface at:

- **HTTP:** `http://YOUR_PIHOLE_IP/admin`

**Password:** On first run, check the container logs to get the auto-generated password:

```bash
docker logs pihole | grep "password"
```

Or set a custom password:

```bash
docker exec -it pihole pihole -a -p YourNewPassword
```

**Important:** Update gravity (blocklists) from the web UI: **Tools → Update Gravity**

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `UTC` | Timezone (e.g., `Europe/Madrid`) |
| `WEBPASSWORD` | _(auto-generated)_ | Web interface password (optional) |

## Volumes

| Path | Description |
|------|-------------|
| `/etc/pihole` | Configuration, database, certificates |
| `/etc/dnsmasq.d` | Custom blocklists and DNS rules |

## Troubleshooting

### "Gravity database not available" error

Run gravity update from web UI or execute:

```bash
docker exec pihole pihole -g
```

### Cannot access web interface

1. Check firewall rules on QNAP
2. Verify IP address doesn't conflict with existing devices
3. Check container logs: `docker logs pihole`

### Web interface shows "FTL offline"

Restart the container:

```bash
docker restart pihole
```

## Technical Details

- **Base:** Alpine 3.20 (builder) + Debian Bullseye Slim (runtime)
- **FTL Version:** v6.4 (compiled Feb 2026)
- **Compilation:** Static linking with musl
- **Architecture:** ARMv7l (32-bit)
- **Page Size:** 32KB (0x8000)
- **Assets:** Official Pi-hole web interface and scripts

## Source Code

Dockerfile and build instructions available on GitHub:  
👉 [https://github.com/javiocu/pihole-qnap-32k](https://github.com/javiocu/pihole-qnap-32k)

## License & Credits

This project is an unofficial build based on [Pi-hole®](https://pi-hole.net/).  
The software in this container is distributed under the **EUPL v1.2** license, same as the original project.
