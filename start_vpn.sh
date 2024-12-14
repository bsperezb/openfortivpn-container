#!/bin/bash

# Check data
if [[ -z "$VPN_HOST" || -z "$VPN_USER" || -z "$VPN_PORT" || -z "$VPN_PASSWORD" || -z "$VPN_CERT" ]]; then
  echo "Error: Faltan variables de entorno requeridas (VPN_HOST, VPN_USER, VPN_PASSWORD, VPN_CERT)."
  exit 1
fi

VPN_ADDRESS="$VPN_HOST:$VPN_PORT"
# Vpn up
nohup openfortivpn "$VPN_ADDRESS" -u "$VPN_USER" -p "$VPN_PASSWORD" --trusted-cert "$VPN_CERT" --persistent=9000 > vpn.log 2>&1 &

# Mensaje indicando que el comando se está ejecutando
echo "Conexión VPN en segundo plano... los logs se guardan en vpn.log"
sleep infinity
