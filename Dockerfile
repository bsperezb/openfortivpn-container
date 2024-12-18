FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Configurar repositorios y habilitar universe
# RUN apt-get update && apt-get install -y iputils-ping
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update

# Instalar dependencias necesarias
RUN apt-get install -y --no-install-recommends \
    openfortivpn \
    curl \
    cron \
    iputils-ping \
    iptables \
    ppp \
    bash \
    build-essential \
    cmake \
    git \
    vim \
    libtool \
    autoconf \
    automake \
    openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verificar que `ping` esté instalado correctamente
RUN dpkg -l | grep iputils-ping || echo "iputils-ping no está instalado"
RUN ls -l /bin/ping /usr/bin/ping || echo "Ping no está disponible"

# Crear dispositivo PPP
RUN mknod /dev/ppp c 108 0 && chmod 600 /dev/ppp

# Copiar y preparar scripts
COPY start_vpn.sh /usr/local/bin/start_vpn.sh
COPY restart_vpn.sh /usr/local/bin/restart_vpn.sh
COPY check_vpn.sh /usr/local/bin/check_vpn.sh
RUN chmod +x /usr/local/bin/start_vpn.sh /usr/local/bin/restart_vpn.sh /usr/local/bin/check_vpn.sh
# RUN chmod +x /usr/local/bin/start_vpn.sh /usr/local/bin/restart_vpn.sh

CMD ["/usr/local/bin/start_vpn.sh"]
# CMD ["bash", "-c", "/usr/local/bin/start_vpn.sh && sleep infinity"]

