FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update

RUN apt-get install -y --no-install-recommends \
    curl \
    cron \
    iputils-ping \
    iptables \
    ppp \
    bash \
    openssl \
    libssl-dev \
    pkg-config \
    build-essential \
    autoconf \
    automake \
    libtool \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    git clone --depth 1 --branch v1.22.1 https://github.com/adrienverge/openfortivpn.git && \
    cd openfortivpn && \
    aclocal && autoconf && automake --add-missing && \
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make && make install && \
    cd /tmp && rm -rf openfortivpn

RUN mknod /dev/ppp c 108 0 && chmod 600 /dev/ppp

COPY start_vpn.sh /usr/local/bin/start_vpn.sh
COPY restart_vpn.sh /usr/local/bin/restart_vpn.sh
COPY check_vpn.sh /usr/local/bin/check_vpn.sh
RUN chmod +x /usr/local/bin/start_vpn.sh /usr/local/bin/restart_vpn.sh /usr/local/bin/check_vpn.sh

CMD ["/usr/local/bin/start_vpn.sh"]
