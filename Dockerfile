# ============================================================
# STAGE 1: Compilar FTL v6.6.2 estático — Debian Bookworm ARMv7
# ============================================================
FROM --platform=linux/arm/v7 debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates build-essential cmake ninja-build m4 \
    libgmp-dev libidn2-dev libunistring-dev libreadline-dev \
    xxd curl \
    && rm -rf /var/lib/apt/lists/*

# libnettle 3.10.2 estática
RUN wget -q https://ftp.gnu.org/gnu/nettle/nettle-3.10.2.tar.gz && \
    tar -xzf nettle-3.10.2.tar.gz && \
    cd nettle-3.10.2 && \
    ./configure \
        --libdir=/usr/local/lib \
        --enable-static \
        --disable-shared \
        --disable-openssl \
        --disable-mini-gmp \
        --disable-documentation && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf nettle-3.10.2 nettle-3.10.2.tar.gz

# libmbedtls 4.0.0 estática
RUN wget -q https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-4.0.0/mbedtls-4.0.0.tar.bz2 && \
    tar -xjf mbedtls-4.0.0.tar.bz2 && \
    cd mbedtls-4.0.0 && \
    cmake -S . -B build \
        -DCMAKE_C_FLAGS="-fomit-frame-pointer" \
        -DENABLE_TESTING=OFF \
        -DENABLE_PROGRAMS=OFF \
        -DBUILD_SHARED_LIBS=OFF && \
    cmake --build build -j$(nproc) && \
    cmake --install build && \
    cd .. && rm -rf mbedtls-4.0.0 mbedtls-4.0.0.tar.bz2

WORKDIR /src
COPY FTL-v6.6.2.tar.gz /tmp/FTL.tar.gz
RUN tar xz --strip-components=1 -f /tmp/FTL.tar.gz && \
    rm /tmp/FTL.tar.gz

RUN mkdir -p build && cd build && \
    cmake \
        -DCMAKE_C_FLAGS="-O3" \
        -DCMAKE_EXE_LINKER_FLAGS="-static -Wl,-z,max-page-size=32768" \
        -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-z,max-page-size=32768" \
        -DCMAKE_MODULE_LINKER_FLAGS="-Wl,-z,max-page-size=32768" \
        -DCMAKE_C_STANDARD_LIBRARIES="-lm -lc -lgcc" \
        -DSTATIC=ON \
        .. && \
    make -j$(nproc) && \
    strip pihole-FTL

# ============================================================
# STAGE 2: Assets oficiales
# ============================================================
FROM --platform=linux/arm/v7 pihole/pihole:latest AS official-assets

# ============================================================
# STAGE 3: Runtime final — Debian Bullseye ARMv7
# El binario es estático → no depende de las .so del sistema
# ============================================================
FROM --platform=linux/arm/v7 debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl sqlite3 procps net-tools \
    iproute2 cron lighttpd php-common php-cgi php-sqlite3 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 999 pihole && \
    useradd -r -u 999 -g pihole pihole

COPY --from=builder /src/build/pihole-FTL /usr/bin/pihole-FTL
COPY --from=official-assets /var/www/html /var/www/html
COPY --from=official-assets /opt/pihole /opt/pihole
COPY --from=official-assets /usr/local/bin/pihole /usr/local/bin/pihole
COPY --from=official-assets /etc/.pihole /etc/.pihole

RUN mkdir -p /etc/pihole /run/pihole /var/log/pihole /etc/dnsmasq.d && \
    chown -R pihole:pihole /etc/pihole /run/pihole /var/log/pihole \
                           /var/www/html /opt/pihole /etc/.pihole && \
    chmod +x /usr/bin/pihole-FTL /usr/local/bin/pihole

EXPOSE 53/tcp 53/udp 80/tcp 443/tcp

# AHORA — FTL v6 usa sintaxis sin doble guión
ENTRYPOINT ["/usr/bin/pihole-FTL"]
CMD ["no-daemon"]