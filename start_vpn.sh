#!/bin/bash

# Configurar el log principal
LOG_FILE="/var/log/vpn.log"
ENV_FILE="/etc/vpn_env"

# Redirigir toda la salida del script al log (stdout y stderr)
exec >> "$LOG_FILE" 2>&1

# Asegurar el PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Agregar timestamp inicial al log
echo "===== Script iniciado: $(date) ====="

# Si existe el archivo de variables de entorno, cargarlo
if [[ -f "$ENV_FILE" ]]; then
  echo "Cargando variables de entorno desde $ENV_FILE..."
  source "$ENV_FILE"
fi

# Si las variables no están definidas, guardarlas en el archivo ENV
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Creando archivo de entorno $ENV_FILE con las variables actuales..."

  # Validar variables requeridas
  if [[ -z "$VPN_HOST" || -z "$VPN_USER" || -z "$VPN_PORT" || -z "$VPN_PASSWORD" || -z "$VPN_CERT" ]]; then
    echo "Error: Faltan variables de entorno requeridas (VPN_HOST, VPN_USER, VPN_PASSWORD, VPN_CERT)."
    exit 1
  fi

  # Guardar variables en el archivo de entorno
  cat <<EOF > "$ENV_FILE"
VPN_HOST="$VPN_HOST"
VPN_USER="$VPN_USER"
VPN_PORT="$VPN_PORT"
VPN_PASSWORD="$VPN_PASSWORD"
VPN_CERT="$VPN_CERT"
VPN_CURL_STRING="${VPN_CURL_STRING:-}"
VPN_CURL_RESPONSE="${VPN_CURL_RESPONSE:-}"
EOF

  # Asegurar permisos del archivo
  chmod 600 "$ENV_FILE"
  echo "Archivo de entorno $ENV_FILE creado con éxito."
fi

VPN_ADDRESS="$VPN_HOST:$VPN_PORT"

# Iniciar VPN en segundo plano
echo "Iniciando VPN..."
nohup openfortivpn "$VPN_ADDRESS" -u "$VPN_USER" -p "$VPN_PASSWORD" --trusted-cert "$VPN_CERT" --persistent=9000 >> "$LOG_FILE" 2>&1 &
if [[ $? -eq 0 ]]; then
  echo "VPN iniciada correctamente en segundo plano."
else
  echo "Error al iniciar la VPN."
  exit 1
fi

# Programar cron job si las variables están definidas
if [[ -n "$VPN_CURL_STRING" && -n "$VPN_CURL_RESPONSE" ]]; then
  echo "Configurando cron job para verificación de VPN..."

  # Asegurar que el cron job no esté duplicado
  (crontab -l | grep -v "/usr/local/bin/check_vpn.sh" || true) > /tmp/cron.tmp
  echo "*/1 * * * * /usr/local/bin/check_vpn.sh >> /var/log/check_vpn.log 2>&1" >> /tmp/cron.tmp
  crontab /tmp/cron.tmp
  rm /tmp/cron.tmp
  echo "Cron job configurado para ejecutarse cada minuto."

  # Iniciar cron si no está activo
  if ! pgrep cron >/dev/null; then
    service cron start
    echo "Servicio cron iniciado."
  fi
else
  echo "No se configuró cron job. Variables de entorno VPN_CURL_STRING o VPN_CURL_RESPONSE no definidas."
fi

# Mensaje indicando que la VPN se está ejecutando
echo "Conexión VPN en segundo plano iniciada."

# Agregar timestamp final al log
echo "===== Script finalizado: $(date) ====="

# Mantener el script activo
sleep infinity
