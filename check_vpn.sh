#!/bin/bash

# Configurar el archivo de log
LOG_FILE="/var/log/vpn_check.log"

# Redirigir toda la salida del script al archivo de log
exec >> "$LOG_FILE" 2>&1

# Asegurar el PATH
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Agregar timestamp inicial al log
echo "===== Verificación de VPN iniciada: $(date) ====="

# Cargar variables de entorno desde el archivo
if [[ -f /etc/vpn_env ]]; then
  source /etc/vpn_env
  echo "Variables cargadas correctamente desde /etc/vpn_env."
else
  echo "Error: Archivo de configuración /etc/vpn_env no encontrado."
  echo "===== Verificación de VPN finalizada con error: $(date) ====="
  exit 1
fi

# Validar que las variables requeridas estén configuradas
if [[ -z "$VPN_CURL_STRING" || -z "$VPN_CURL_RESPONSE" ]]; then
  echo "Error: Variables VPN_CURL_STRING o VPN_CURL_RESPONSE no configuradas."
  echo "===== Verificación de VPN finalizada con error: $(date) ====="
  exit 1
fi

# Ejecutar la consulta CURL y capturar la respuesta
echo "Ejecutando consulta CURL..."
response=$(eval "$VPN_CURL_STRING" 2>&1)  # Capturar stdout y stderr

# Capturar el código de salida de curl
curl_exit_code=$?

# Verificar si curl falló
if [[ $curl_exit_code -ne 0 ]]; then
  echo "Error en la consulta CURL: $response"
  echo "Reiniciando VPN debido a error en CURL..."
  /usr/local/bin/restart_vpn.sh
  if [[ $? -eq 0 ]]; then
    echo "VPN reiniciada exitosamente tras error en CURL."
  else
    echo "Error al intentar reiniciar la VPN tras fallo en CURL."
  fi
  echo "===== Verificación de VPN finalizada con reinicio: $(date) ====="
  exit 1
fi

# Evaluar si la respuesta contiene el string esperado de error
if [[ "$response" == *"$VPN_CURL_RESPONSE"* ]]; then
  echo "Error detectado en la respuesta CURL. Reiniciando VPN..."
  /usr/local/bin/restart_vpn.sh
  if [[ $? -eq 0 ]]; then
    echo "VPN reiniciada exitosamente tras detectar error en la respuesta CURL."
  else
    echo "Error al intentar reiniciar la VPN tras detectar error en la respuesta CURL."
  fi
else
  echo "VPN funcionando correctamente. Respuesta CURL válida."
fi

# Agregar timestamp final al log
echo "===== Verificación de VPN finalizada: $(date) ====="
