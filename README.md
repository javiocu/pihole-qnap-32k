Pi-hole v6 for QNAP ARMv7 32KB pagesize. Statically compiled FTL + Debian Bookworm builder + Bullseye runtime. Ready for TS-431P3 and similar.

# Pi-hole v6.6.2 for QNAP NAS (ARMv7 - 32KB Page Size)

Custom-built **Pi-hole FTL v6.6.2** image specifically designed for **QNAP NAS devices** with ARMv7 CPUs and 32KB memory page size (e.g., TS-431P3 with Annapurna Labs AL314 kernel).

## Why This Image?

Official Pi-hole Docker images crash on QNAP NAS models with 32KB kernel page size due to binary incompatibility (Segmentation Fault). This image solves that by:

- **Statically compiled FTL** with `-static -Wl,-z,max-page-size=32768` linker flag
- **Debian Bookworm builder** (CMake 3.25, nettle 3.10.2, mbedtls 4.0.0 from source) + **Debian Bullseye runtime**
- Includes **web interface**, **lighttpd**, **PHP**, and **CLI tools** (`pihole`, `pihole-FTL`)
- Full **ARMv7** (32-bit) compatibility
- Official Pi-hole web assets from upstream

## Supported Hardware

✅ **Tested & Verified:** QNAP TS-431P3 (Alpine AL314 CPU)  
⚠️ **Likely Compatible:** TS-431P2, TS-231P3, and other ARMv7 QNAP NAS models with 32KB page kernels

## Quick Start

### Using Docker Compose (Recommended for Container Station)

```yaml
networks:
  qnet_static:
    driver: qnet
    driver_opts:
      iface: "eth0"
    ipam:
      driver: qnet
      options:
        iface: "eth0"
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1

services:
  pihole:
    image: javiocu/pihole-qnap-32k:v6.6.2-debian
    container_name: pihole
    hostname: pihole
    restart: unless-stopped
    networks:
      qnet_static:
        ipv4_address: 192.168.1.94
    mac_address: 02:42:C0:A8:01:5E
    cap_add:
      - NET_ADMIN
    volumes:
      - /share/Container/pihole/etc:/etc/pihole
      - /share/Container/pihole/dnsmasq:/etc/dnsmasq.d
    environment:
      - TZ=Europe/Madrid
```

### First Run

Access the web interface at: `http://192.168.1.94/admin`

```bash
# Get the random password from logs
docker logs pihole | grep -i password
# Or set a new one
docker exec -it pihole pihole setpassword
```

## Integration with WireGuard

```yaml
services:
  pihole:
    image: javiocu/pihole-qnap-32k:v6.6.2-debian
    container_name: pihole
    networks:
      qnet_static:
        ipv4_address: 192.168.1.94
    # ...

  wireguard:
    image: your-wireguard-image:latest
    container_name: wireguard
    depends_on:
      - pihole
    network_mode: service:pihole
    # ...
```

## Upgrading from v6.4

```bash
cd /share/Container/pihole
docker-compose down
cp -r etc etc-backup-$(date +%Y%m%d)
# Edit docker-compose.yml → change image to v6.6.2-debian
docker-compose up -d
```

All settings, blocklists, and custom DNS entries are preserved.

## Technical Details

| | |
|---|---|
| **FTL Version** | v6.6.2 |
| **Builder** | Debian Bookworm Slim (CMake 3.25) |
| **Runtime** | Debian Bullseye Slim |
| **nettle** | 3.10.2 (compiled from source) |
| **mbedtls** | 4.0.0 (compiled from source) |
| **Linking** | Static (`-static -Wl,-z,max-page-size=32768`) |
| **Web Server** | lighttpd + PHP |
| **Architecture** | linux/arm/v7 |

## Changelog

### v6.6.2-debian (2026-05)
- Updated to Pi-hole FTL v6.6.2
- Changed builder to Debian Bookworm (CMake 3.25 nativo)
- nettle 3.10.2 compilada desde fuentes (requiere balloon.h de nettle ≥3.9)
- mbedtls 4.0.0 compilada desde fuentes
- Linkado 100% estático verificado (`ldd: not a dynamic executable`)
- Runtime Debian Bullseye preservado

### v6.4 (2026-02)
- Updated to Pi-hole FTL v6.4
- Alpine-based static compilation

### v6.3-debian (2025-12)
- Initial release with 32KB page size support

## License & Credits

Unofficial build of [Pi-hole®](https://pi-hole.net) for QNAP compatibility.  
Pi-hole® is licensed under the **EUPL v1.2**.  
Not affiliated with or endorsed by Pi-hole LLC.

## Source & Support

- 🔧 Build issues: [GitHub](https://github.com/javiocu/pihole-qnap-32k/issues)
- 💬 General Pi-hole: [discourse.pi-hole.net](https://discourse.pi-hole.net/)