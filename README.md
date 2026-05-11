# openfortivpn-container

Cliente VPN en Docker con auto-reconexión. Inicia automáticamente al arrancar el contenedor y se reinicia solo si detecta pérdida de conectividad.

## Requisitos

- Docker y Docker Compose
- Módulo PPP del kernel activo: `modprobe ppp`
- Dispositivo `/dev/ppp` disponible en el host

## Configuración

Crea un archivo `.env` en la raíz del proyecto:

```env
VPN_HOST=vpn.empresa.com
VPN_USER=usuario
VPN_PASSWORD=contraseña
VPN_PORT=443
VPN_CERT=sha256:xxxxxxxxxxxxxxxx

# Opcional: activa el health check automático
VPN_CURL_STRING=curl -s --max-time 10 http://10.0.0.1/api/ping
VPN_CURL_RESPONSE=error
```

> Si `VPN_CURL_STRING` y `VPN_CURL_RESPONSE` no están definidos, el contenedor conecta la VPN pero no verifica la conectividad.

## Puesta en marcha

```bash
# Construir y levantar
docker-compose up --build -d

# Solo levantar (imagen ya construida)
docker-compose up -d

# Detener
docker-compose down
```

## Leer logs

```bash
# Log principal (inicio de VPN y reinicios)
docker exec vpntest tail -f /var/log/vpn.log

# Log del health check (se ejecuta cada minuto si está configurado)
docker exec vpntest tail -f /var/log/vpn_check.log

# Logs del contenedor (salida de Docker)
docker-compose logs -f vpn
```

## Diagnóstico de errores

| Síntoma | Causa probable | Solución |
|---|---|---|
| Contenedor se detiene al iniciar | Variables de entorno faltantes | Verificar que `.env` tenga `VPN_HOST`, `VPN_USER`, `VPN_PASSWORD`, `VPN_PORT`, `VPN_CERT` |
| `Error: /dev/ppp not found` | Módulo PPP no cargado | Ejecutar `modprobe ppp` en el host |
| VPN conecta pero se cae seguido | Conexión inestable sin health check | Definir `VPN_CURL_STRING` y `VPN_CURL_RESPONSE` para activar auto-reconexión |
| `trusted-cert` rechazado | Fingerprint incorrecto | Revisar `VPN_CERT` — debe coincidir con el certificado del servidor |
| Health check reinicia VPN constantemente | `VPN_CURL_RESPONSE` hace match en respuestas normales | Ajustar el string de error para que solo coincida en fallo real |

## Comandos útiles dentro del contenedor

```bash
# Ver estado de la VPN
docker exec vpntest ps aux | grep openfortivpn

# Reiniciar VPN manualmente
docker exec vpntest /usr/local/bin/restart_vpn.sh

# Ver variables de entorno cargadas
docker exec vpntest cat /etc/vpn_env
```

## CI/CD

El workflow `.github/workflows/generate-image.yml` construye y publica la imagen en GitHub Container Registry al hacer push a `main`. Requiere el secret `GHCR_TOKEN` configurado en el repositorio.

Para usar la imagen publicada en lugar de construir localmente, descomentar el bloque comentado en `docker-compose.yml` que apunta a `ghcr.io/bsperezb/openfortivpn:latest`.
