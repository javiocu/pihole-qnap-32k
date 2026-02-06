# Pi-hole v6.4 for QNAP NAS (ARMv7 - 32KB Page Size)

Custom-built **Pi-hole FTL v6.4** image specifically designed for **QNAP NAS devices** with ARMv7 CPUs and 32KB memory page size (e.g., TS-431P3 with Annapurna Labs AL314 kernel).

## Why This Image?

Official Pi-hole Docker images crash on QNAP NAS models with 32KB kernel page size due to binary incompatibility (Segmentation Fault). This image solves that by:

- **Statically compiled FTL** with `max-page-size=32768` linker flag
- **Alpine Linux builder** + **Debian Bullseye runtime** for maximum compatibility
- Includes **web interface** (lighttpd + PHP) and **CLI tools** (`pihole -g`, gravity update)
- Uses **official Pi-hole assets** from latest release
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
    hostname: pihole
    restart: unless-stopped
    networks:
      qnet_static:
        ipv4_address: 192.168.1.94 # Adapt to your desired IP
    mac_address: 02-42-7B-F4-ED-94  # Optional: set fixed MAC
    environment:
      - TZ=Europe/Madrid
    volumes:
      - /share/Container/pihole/etc:/etc/pihole
      - /share/Container/pihole/dnsmasq:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
```

### Configuration

1. Change `ipv4_address` to a free IP on your network
2. Update volume paths (`/share/...`) to match your QNAP shared folder structure
3. Set your timezone in `TZ` variable
4. Remove `mac_address` line or change to your desired MAC

### First Run

Access the web interface at:
- **HTTP:** `http://YOUR_PIHOLE_IP/admin`

**Password:** On first run, check container logs to get the auto-generated password:
```bash
docker logs pihole | grep password
```

Or set it manually:
```bash
docker exec pihole pihole -a -p yourpassword
```

**Important:** On first run, update gravity (blocklists) from the web UI: **Tools → Update Gravity** to populate the database.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | UTC | Timezone (e.g., `Europe/Madrid`) |
| `WEBPASSWORD` | (auto-generated) | Web interface password |

## Volumes

| Path | Description |
|------|-------------|
| `/etc/pihole` | Configuration, database, certificates |
| `/etc/dnsmasq.d` | Custom blocklists and DNS rules |

## Integration with WireGuard

This image works perfectly with WireGuard using `network_mode: service:pihole`. See example:

```yaml
services:
  pihole:
    image: javiocu/pihole-qnap-32k:v6.4
    # ... pihole config ...

  wireguard:
    image: wireguard-qnap-32k:latest
    container_name: wireguard
    restart: unless-stopped
    depends_on:
      - pihole
    network_mode: service:pihole  # Shares network with Pi-hole
    privileged: true
    # ... wireguard config ...
```

## Troubleshooting

**"Gravity database not available" error:**  
Run gravity update from web UI or execute: `docker exec pihole pihole -g`

**Cannot access web interface:**  
Check firewall rules and verify IP address doesn't conflict with existing devices.

**Segmentation Fault (exit code 139):**  
You're using the wrong image. Make sure you're using `javiocu/pihole-qnap-32k:v6.4` and not the official `pihole/pihole` image.

## Technical Details

- **Builder:** Alpine Linux 3.20 (musl libc)
- **Runtime:** Debian Bullseye Slim (armhf)
- **FTL Version:** v6.4 (static binary, compiled Feb 2026)
- **Web Server:** lighttpd + PHP-CGI
- **Architecture:** ARMv7l (32-bit)
- **Page Size:** 32KB (0x8000)
- **Compilation:** Static linking with `-Wl,-z,max-page-size=32768`

## Migration from v6.3

Simply change the image tag in your docker-compose.yml:
```yaml
image: javiocu/pihole-qnap-32k:v6.4  # Changed from v6.3
```

Your configuration and databases are fully compatible (no migration needed).

## Source Code

Dockerfile and build instructions available on GitHub:  
👉 **[https://github.com/javiocu/pihole-qnap-32k](https://github.com/javiocu/pihole-qnap-32k)**

## License & Credits

This project is an unofficial build based on [Pi-hole®](https://pi-hole.net).

The software in this container is distributed under the **EUPL v1.2** license, same as the original project.

---

**Version:** v6.4 (February 2026)  
**Maintainer:** javiocu  
**Docker Hub:** [javiocu/pihole-qnap-32k](https://hub.docker.com/r/javiocu/pihole-qnap-32k)

---

**Made with ❤️ for QNAP users who want privacy-focused filtering DNS on their NAS without fucking 32k problems**
