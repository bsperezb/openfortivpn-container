# Usar la imagen base de Ubuntu 20.04.1
FROM ubuntu:20.04

# Establecer el entorno no interactivo para evitar prompts durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar repositorios e instalar dependencias necesarias
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    sed -i 's|http://archive.ubuntu.com|http://mirrors.kernel.org|g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    openfortivpn \
    curl \
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
    openssl \
    software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Crear el dispositivo /dev/ppp
RUN mknod /dev/ppp c 108 0 && chmod 600 /dev/ppp

# Copiar el script para iniciar la VPN
COPY start_vpn.sh /usr/local/bin/start_vpn.sh
COPY restart_vpn.sh /usr/local/bin/restart_vpn.sh

# Dar permisos de ejecución al script
RUN chmod +x /usr/local/bin/start_vpn.sh
RUN chmod +x /usr/local/bin/restart_vpn.sh

# Ejecutar el script automáticamente al iniciar el contenedor
CMD ["/usr/local/bin/start_vpn.sh"]

