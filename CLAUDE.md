# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dockerized OpenFortiVPN container — a self-healing VPN client that runs in Docker, automatically starts on container boot, and restarts itself when health checks detect connectivity loss.

## Common Commands

```bash
# Build the Docker image locally
docker build -t openfortivpn:latest .

# Start the VPN container
docker-compose up -d

# Stop the container
docker-compose down

# Rebuild and start
docker-compose up --build -d

# View VPN logs
docker-compose logs -f vpn

# View logs inside container
docker exec vpntest tail -f /var/log/vpn.log
docker exec vpntest tail -f /var/log/vpn_check.log
```

## Architecture

Single Docker container running OpenFortiVPN with three Bash scripts coordinating the VPN lifecycle:

- **`start_vpn.sh`** — Container entrypoint (set as `CMD`). Writes credentials to `/etc/vpn_env`, launches OpenFortiVPN via `nohup` in the background, optionally sets up a cron job for health checks, then runs `sleep infinity` to keep the container alive.
- **`restart_vpn.sh`** — Kills all `openfortivpn` processes via `pkill`, then relaunches with the same credentials from `/etc/vpn_env`.
- **`check_vpn.sh`** — Cron-executed every minute. Runs `$VPN_CURL_STRING` and triggers `restart_vpn.sh` if the connection fails or returns `$VPN_CURL_RESPONSE`.

### Runtime files (created inside container)
- `/etc/vpn_env` — Credential store sourced by restart/check scripts
- `/var/log/vpn.log` — Startup and restart logs
- `/var/log/vpn_check.log` — Health check logs

## Configuration

All configuration is via environment variables defined in `docker-compose.yml` (or a `.env` file, which is gitignored).

| Variable | Required | Purpose |
|---|---|---|
| `VPN_HOST` | Yes | VPN server hostname/IP |
| `VPN_USER` | Yes | VPN username |
| `VPN_PASSWORD` | Yes | VPN password |
| `VPN_PORT` | Yes | VPN port (typically 443) |
| `VPN_CERT` | Yes | Certificate fingerprint for SSL validation |
| `VPN_CURL_STRING` | No | CURL command to probe connectivity |
| `VPN_CURL_RESPONSE` | No | Error string in CURL response that triggers a restart |

Health checking is only enabled when both `VPN_CURL_STRING` and `VPN_CURL_RESPONSE` are set.

## CI/CD

`.github/workflows/generate-image.yml` triggers on push to `main`, builds the Docker image, and pushes it to GitHub Container Registry (`ghcr.io`) as `ghcr.io/{username}/openfortivpn:latest`. Requires a `GHCR_TOKEN` secret configured in GitHub.

## Key Docker Requirements

The container requires elevated privileges to manage network interfaces:
- `privileged: true`
- Capabilities: `NET_ADMIN`, `NET_RAW`
- Device: `/dev/ppp` (PPP device for VPN protocol)
- Network mode: `host` (VPN needs access to the host network stack)
