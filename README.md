# Pi-hole v6.4 for QNAP NAS (ARMv7 - 32KB Page Size)

Custom-built **Pi-hole FTL v6.4** image specifically designed for **QNAP NAS devices** with ARMv7 CPUs and 32KB memory page size (e.g., TS-431P3 with Annapurna Labs AL314 kernel).

## Why This Image?

Official Pi-hole Docker images crash on QNAP NAS models with 32KB kernel page size due to binary incompatibility (Segmentation Fault). This image solves that by:

- **Dynamically compiled FTL** with `max-page-size=32768` linker flag
- **Debian Bookworm base** (upgraded from Bullseye) for modern library support
- **Full TLS/HTTPS support** via custom-compiled mbedTLS v3.6.2
- Includes **web interface** and **CLI tools** (`pihole -g`, gravity update)
- Full **ARM v7** (32-bit) compatibility

## Supported Hardware

✅ **Tested & Verified:** QNAP TS-431P3  
⚠️ **Likely Compatible (Untested):** TS-431P2, TS-231P3, and other ARMv7 QNAP NAS models with Annapurna Labs AL314/AL324 CPUs.

## Quick Start

### Using Docker Compose (Recommended)

Copy this YAML into **Container Station → Applications → Create**:

```yaml
version: '3'

networks:
  qnet_static:
    driver: qnet
    driver_opts:
      iface: "eth0" # Adapt to your interface (e.g. eth0, bond0)
    ipam:
      driver: qnet
      options:
        iface: "eth0"
      config:
        - subnet: 192.168.1.0/24 # Adapt to your subnet
          gateway: 192.168.1.1   # Adapt to your gateway

services:
  pihole:
    image: javiocu/pihole-qnap-32k:v6.4
    container_name: pihole
    restart: unless-stopped
    networks:
      qnet_static:
        ipv4_address: 192.168.1.100 # Adapt to your desired IP
    environment:
      - TZ=Europe/Madrid
      - WEBPASSWORD=yoursecurepassword  # Set initial web admin password
    volumes:
      - /share/Container/pihole/etc:/etc/pihole
      - /share/Container/pihole/dnsmasq:/etc/dnsmasq.d
    # Devices mapping is NO LONGER REQUIRED with this version
    cap_add:
      - NET_ADMIN
```

### Configuration

1. Change `ipv4_address` to a free IP on your network
2. Update volume paths (`/share/...`) to match your QNAP shared folder structure
3. Set your timezone in `TZ` variable
4. Set a strong password in `WEBPASSWORD`

### First Run

Access the web interface at:
- **HTTP:** `http://YOUR_PIHOLE_IP/admin`
- **HTTPS:** `https://YOUR_PIHOLE_IP/admin` (Self-signed cert by default)

**Important:** On first run, update gravity (blocklists) from the web UI: **Tools → Update Gravity** to populate the database.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | UTC | Timezone (e.g., `Europe/Madrid`) |
| `WEBPASSWORD` | (random) | Initial web interface password |
| `FTLCONF_webserver_port` | 80 | HTTP port (internal) |
| `FTLCONF_dns_port` | 53 | DNS port |

## Volumes

| Path | Description |
|------|-------------|
| `/etc/pihole` | Configuration, database, certificates |
| `/etc/dnsmasq.d` | Custom blocklists and DNS rules |

## Troubleshooting

**"Gravity database not available" error:**  
Run gravity update from web UI or execute: `docker exec pihole pihole -g`

**Cannot access web interface:**  
Check firewall rules and verify IP address doesn't conflict with existing devices. Try accessing via HTTPS if HTTP fails.

## Technical Details

- **Base:** Debian Bookworm Slim (armhf)
- **FTL Version:** v6.4 (compiled Feb 2026)
- **SSL/TLS:** mbedTLS 3.6.2 (custom build) + Nettle 3.10
- **Architecture:** ARMv7l (32-bit)
- **Page Size:** 32KB (0x8000)

## Source Code

Dockerfile and build instructions available on GitHub:  
👉 **[https://github.com/javiocu/pihole-qnap-32k](https://github.com/javiocu/pihole-qnap-32k)**

## License & Credits

This project is an unofficial build based on [Pi-hole®](https://pi-hole.net).

The software in this container is distributed under the **EUPL v1.2** license, same as the original project.
