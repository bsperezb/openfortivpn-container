#!/bin/bash

# Finalizar cualquier instancia previa de openfortivpn
pkill -f openfortivpn

# Iniciar la VPN nuevamente
nohup /usr/local/bin/start_vpn.sh > /vpnrestart.log 2>&1 &
echo "VPN reiniciada correctamente."

