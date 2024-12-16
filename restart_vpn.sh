#!/bin/bash

# Configurar el log principal
LOG_FILE="/var/log/vpn.log"
ENV_FILE="/etc/vpn_env"

# Redirigir toda la salida del script al log (stdout y stderr)
exec >> "$LOG_FILE" 2>&1

# Asegurar el PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


# Agregar timestamp inicial al log
echo "===== Reinicio de VPN iniciado: $(date) ====="

# check env
if [[ -f "$ENV_FILE" ]]; then
  echo "Cargando variables de entorno desde $ENV_FILE..."
  source "$ENV_FILE"
fi

# Finalizar cualquier instancia previa de openfortivpn
echo "Finalizando instancias previas de openfortivpn..."
if pkill -f openfortivpn; then
  echo "Instancias previas de openfortivpn terminadas correctamente."
else
  echo "No se encontraron instancias previas de openfortivpn o error al finalizar."
fi

VPN_ADDRESS="$VPN_HOST:$VPN_PORT"
nohup openfortivpn "$VPN_ADDRESS" -u "$VPN_USER" -p "$VPN_PASSWORD" --trusted-cert "$VPN_CERT" --persistent=9000 >> "$LOG_FILE" 2>&1 &
if [[ $? -eq 0 ]]; then
    echo "VPN iniciada correctamente en segundo plano."
else
    echo "Error al iniciar la VPN."
    exit 1
fi

# # Iniciar la VPN nuevamente
# echo "Iniciando VPN nuevamente..."
# nohup /usr/local/bin/start_vpn.sh >> "$LOG_FILE" 2>&1 &
# if [[ $? -eq 0 ]]; then
#   echo "VPN reiniciada correctamente."
# else
#   echo "Error al reiniciar la VPN."
#   exit 1
# fi

# Agregar timestamp final al log
echo "===== Reinicio de VPN finalizado: $(date) ====="
