# STAGE 1: Compilador
FROM --platform=linux/arm/v7 alpine:3.20 as builder

# Instalar dependencias
RUN apk update && apk add --no-cache \
    git build-base cmake linux-headers curl \
    gcc abuild binutils musl-dev \
    vim \
    gmp-dev nettle-dev libidn2-dev libunistring-dev \
    libedit-dev sqlite-dev openssl-dev readline-dev zlib-dev mbedtls-dev \
    nettle-static libidn2-static libunistring-static libedit-static \
    sqlite-static openssl-libs-static readline-static zlib-static mbedtls-static

# COMPROBACIÓN (
RUN ls -l /usr/bin/xxd

# Compilar FTL
RUN git clone --depth 1 --branch v6.3 https://github.com/pi-hole/FTL.git /FTL
WORKDIR /FTL
ENV LDFLAGS="-static -Wl,-z,max-page-size=32768"
ENV CFLAGS="-O3"
RUN mkdir -p build && cd build && \
    cmake -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" -DSTATIC=ON .. && \
    make -j$(nproc)

# STAGE 2: Assets Oficiales
FROM --platform=linux/arm/v7 pihole/pihole:latest AS official_assets

# STAGE 3: Runtime Final (USAMOS DEBIAN AQUÍ)
# Debian Bullseye suele ser muy estable en QNAP armv7
FROM --platform=linux/arm/v7 debian:bullseye-slim

# 1. Instalar dependencias runtime (Sintaxis apt-get)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    sqlite3 \
    procps \
    net-tools \
    iproute2 \
    cron \
    lighttpd \
    php-common \
    php-cgi \
    php-sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Crear usuario pihole
RUN groupadd -g 999 pihole && \
    useradd -r -u 999 -g pihole pihole

# 3. Copiar binario FTL (parcheado)
COPY --from=builder /FTL/build/pihole-FTL /usr/bin/pihole-FTL

# 4. Copiar Assets Web y Scripts
COPY --from=official_assets /var/www/html /var/www/html
COPY --from=official_assets /opt/pihole /opt/pihole
COPY --from=official_assets /usr/local/bin/pihole /usr/local/bin/pihole
COPY --from=official_assets /etc/.pihole /etc/.pihole

# 5. Permisos y directorios
RUN mkdir -p /etc/pihole /run/pihole /var/log/pihole /etc/dnsmasq.d && \
    chown -R pihole:pihole /etc/pihole /run/pihole /var/log/pihole \
                           /var/www/html /opt/pihole /etc/.pihole /etc/dnsmasq.d && \
    chmod +x /usr/bin/pihole-FTL /usr/local/bin/pihole

# Puertos
EXPOSE 53/tcp 53/udp 80/tcp 443/tcp

# Healthcheck
HEALTHCHECK CMD /usr/bin/pihole-FTL -t || exit 1

ENTRYPOINT ["/usr/bin/pihole-FTL"]
CMD ["no-daemon"]

