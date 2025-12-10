# Pi-hole v6 for QNAP NAS (ARMv7 - 32KB Page Size)

This repository contains the Dockerfile and build instructions to generate a custom **Pi-hole v6** image compatible with legacy QNAP NAS devices running on ARMv7 CPUs with **32KB memory page size**.

## ⚠️ The Problem
Official Pi-hole Docker images (and Alpine Linux in general) are compiled assuming a standard 4KB memory page size.
QNAP NAS models with Annapurna Labs CPUs (like the **TS-431P3**, TS-431P2, TS-231P) use a custom kernel with **32KB page size**.
Running official images on these devices results in immediate crashes (`Segmentation Fault` or `jemalloc` errors).

## ✅ The Solution
This project builds a custom Docker image that fixes these issues by:
1. **Compiling FTL from source** with the linker flag `-Wl,-z,max-page-size=32768`.
2. **Using Debian Bullseye** as the base OS (instead of Alpine) to ensure `bash`, `sqlite3`, and other system tools don't crash.
3. **Packaging official assets** (Web Interface + CLI scripts) on top of the stable base.

## Supported Hardware
Tested and verified on:
- **QNAP TS-431P3** (Annapurna Labs Alpine AL314 Quad-core 1.7GHz)

Likely compatible with:
- TS-431P2, TS-231P3, TS-231P2
- Any ARMv7 device with 32KB kernel pages.

## Usage

### Option 1: Pull from Docker Hub (Recommended)
You can use the pre-built image directly:
`docker pull javiocu/pihole-qnap-32k:v6.3-debian`


### Option 2: Build it yourself
If you prefer to build it from source (requires Docker Buildx for cross-compilation if building on x86):
`docker buildx build --platform linux/arm/v7 --no-cache -t my-pihole-qnap .`

## Docker Compose Example (QNAP Container Station)

Use this YAML in Container Station (Application):
```yaml
version: '3'

networks:
  qnet_static:
    driver: qnet
    driver_opts:
      iface: "eth0" # Adapt to your interface
    ipam:
      driver: qnet
      options:
        iface: "eth0"
      config:
        - subnet: 192.168.1.0/24 # Adapt to your subnet
          gateway: 192.168.1.1   # Adapt to your gateway

services:
  pihole:
    image: javiocu/pihole-qnap-32k:v6.3-debian
    container_name: pihole
    restart: unless-stopped
    networks:
      qnet_static:
        ipv4_address: 192.168.1.100 # Adapt to your desired IP
    environment:
      - TZ=Europe/Madrid
    volumes:
      - /share/Container/pihole/etc:/etc/pihole
      - /share/Container/pihole/dnsmasq:/etc/dnsmasq.d
    devices:
      # CRITICAL: Required for certificate generation on QNAP
      - "/dev/urandom:/dev/random"
      - "/dev/urandom:/dev/urandom"
    cap_add:
      - NET_ADMIN
```

## Disclaimer
This is an unofficial project and is not affiliated with Pi-hole LLC.
It is provided "as is" without warranty of any kind.

## License
Based on [Pi-hole®](https://pi-hole.net).
The source code in this repository is licensed under the **EUPL v1.2** to comply with the original Pi-hole license.
