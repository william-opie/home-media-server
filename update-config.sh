#!/bin/bash

# See https://stackoverflow.com/a/44864004 for the sed GNU/BSD compatible hack

function update_arr_config {
  echo "Updating ${container} configuration..."
  until [ -f "${CONFIG_ROOT:-.}"/"$container"/config.xml ]; do sleep 1; done
  sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/$1<\/UrlBase>/" "${CONFIG_ROOT:-.}"/"$container"/config.xml && rm "${CONFIG_ROOT:-.}"/"$container"/config.xml.bak
  CONTAINER_NAME_UPPER=$(echo "$container" | tr '[:lower:]' '[:upper:]')
  sed -i.bak 's/^'"${CONTAINER_NAME_UPPER}"'_API_KEY=.*/'"${CONTAINER_NAME_UPPER}"'_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "${CONFIG_ROOT:-.}"/"$container"/config.xml)"'/' .env && rm .env.bak
  echo "Update of ${container} configuration complete, restarting..."
  docker compose restart "$container"
}

function update_qbittorrent_config {
    echo "Updating ${container} configuration..."
    docker compose stop "$container"
    until [ -f "${CONFIG_ROOT:-.}"/"$container"/qBittorrent/qBittorrent.conf ]; do sleep 1; done
    sed -i.bak '/WebUI\\ServerDomains=*/a WebUI\\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"' "${CONFIG_ROOT:-.}"/"$container"/qBittorrent/qBittorrent.conf && rm "${CONFIG_ROOT:-.}"/"$container"/qBittorrent/qBittorrent.conf.bak
    sed -i.bak '/WebUI\\Username=*/a WebUI\\Username=admin' "${CONFIG_ROOT:-.}"/"$container"/qBittorrent/qBittorrent.conf && rm "${CONFIG_ROOT:-.}"/"$container"/qBittorrent/qBittorrent.conf.bak
    echo "Update of ${container} configuration complete, restarting..."
    docker compose start "$container"
}

function update_bazarr_config {
    echo "Updating ${container} configuration..."
    until [ -f "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml ]; do sleep 1; done
    sed -i.bak "s/base_url: ''/base_url: '\/$container'/" "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml && rm "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml.bak
    sed -i.bak "s/use_radarr: false/use_radarr: true/" "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml && rm "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml.bak
    sed -i.bak "s/use_sonarr: false/use_sonarr: true/" "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml && rm "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml.bak
    until [ -f "${CONFIG_ROOT:-.}"/sonarr/config.xml ]; do sleep 1; done
    SONARR_API_KEY=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "${CONFIG_ROOT:-.}"/sonarr/config.xml)
    sed -i.bak "/sonarr:/,/^radarr:/ { s/apikey: .*/apikey: $SONARR_API_KEY/; s/base_url: .*/base_url: \/sonarr/; s/ip: .*/ip: sonarr/ }" "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml && rm "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml.bak
    until [ -f "${CONFIG_ROOT:-.}"/radarr/config.xml ]; do sleep 1; done
    RADARR_API_KEY=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "${CONFIG_ROOT:-.}"/radarr/config.xml)
    sed -i.bak "/radarr:/,/^sonarr:/ { s/apikey: .*/apikey: $RADARR_API_KEY/; s/base_url: .*/base_url: \/radarr/; s/ip: .*/ip: radarr/ }" "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml && rm "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml.bak
    sed -i.bak 's/^BAZARR_API_KEY=.*/BAZARR_API_KEY='"$(sed -n 's/.*apikey: \(.*\)*/\1/p' "${CONFIG_ROOT:-.}"/"$container"/config/config/config.yaml | head -n 1)"'/' .env && rm .env.bak
    echo "Update of ${container} configuration complete, restarting..."
    docker compose restart "$container"
}

for container in $(docker ps --format '{{.Names}}'); do
  if [[ "$container" =~ ^(radarr|sonarr|lidarr|prowlarr)$ ]]; then
    update_arr_config "$container"
  elif [[ "$container" =~ ^(bazarr)$ ]]; then
    update_bazarr_config "$container"
  elif [[ "$container" =~ ^(qbittorrent)$ ]]; then
    update_qbittorrent_config "$container"
  fi
done

# Extract the values of TAILSCALE_IP, LAN_IP, and DOMAIN from the .env file
TAILSCALE_IP=$(grep '^TAILSCALE_IP=' .env | cut -d '=' -f 2)
LAN_IP=$(grep '^LAN_IP=' .env | cut -d '=' -f 2)
DOMAIN=$(grep '^DOMAIN=' .env | cut -d '=' -f 2)

# Check if TAILSCALE_IP, LAN_IP, and DOMAIN are set in .env file
if [ -n "$TAILSCALE_IP" ] && [ -n "$LAN_IP" ] && [ -n "$DOMAIN" ]; then
  # Run the sed command to replace ${TAILSCALE_IP}, ${LAN_IP}, and ${DOMAIN} in etc-pihole/custom.list
  sed -i.bak \
    -e "s/\${TAILSCALE_IP}/$TAILSCALE_IP/g" \
    -e "s/\${LAN_IP}/$LAN_IP/g" \
    -e "s/\${DOMAIN}/$DOMAIN/g" \
    etc-pihole/custom.list && rm etc-pihole/custom.list.bak
    docker compose restart pihole
else
  echo "Error: One or more required variables (TAILSCALE_IP, LAN_IP, DOMAIN) are not set in the .env file."
  exit 1
fi

# Creates Caddyfile from example_Caddyfile if file does not already exist
if [ ! -f container-config/Caddyfile ]; then
  cp container-config/example_Caddyfile container-config/Caddyfile
fi

# Inserts CLOUDFLARE_EMAIL from .env file in Caddyfile
CLOUDFLARE_EMAIL=$(grep '^CLOUDFLARE_EMAIL=' .env | cut -d '=' -f 2)
if [ -n "$CLOUDFLARE_EMAIL" ]; then
  sed -i.bak \
    -e "s/\${CLOUDFLARE_EMAIL}/$CLOUDFLARE_EMAIL/g" \
    container-config/Caddyfile && rm container-config/Caddyfile.bak
    docker compose restart caddy
else
  echo "Error: CLOUDFLARE_EMAIL variable not set in .env file."
  exit 1
fi

# Restarts full container stack
docker compose down && sleep 3 && docker compose up -d