# Docker Compose NAS
This is a fork; see the original [docker-compose-nas project repo here](https://github.com/AdrienPoupa/docker-compose-nas). 

Most of the README content comes from the original repo; I have made some edits to account for the changes I have made in this fork.

This is a simple Docker compose project used to create a media server on your home network.

This fork differs from the original in that it uses Caddy as a reverse proxy (instead of Traefik),
and Pihole is installed by default (instead of Adguard, which is an optional add-on in the original project).
This fork also sets the *arr apps to use the VPN connection by default; this was an optional config in the original project.

Requirements: Any Docker-capable recent Linux distro with Docker Engine and Docker Compose V2.

![Docker-Compose NAS Homepage](https://thefinalsummer.com/wp-content/uploads/2024/07/screenshot-2024-07-17-203004.png "Homepage")

## Table of Contents

<!-- TOC -->
* [Docker Compose NAS](#docker-compose-nas)
  * [Table of Contents](#table-of-contents)
  * [Applications](#applications)
  * [Quick Start](#quick-start)
  * [Environment Variables](#environment-variables)
  * [PIA WireGuard VPN](#pia-wireguard-vpn)
  * [Sonarr, Radarr & Lidarr](#sonarr-radarr--lidarr)
    * [File Structure](#file-structure)
    * [Download Client](#download-client)
  * [Prowlarr](#prowlarr)
  * [qBittorrent](#qbittorrent)
  * [Jellyfin](#jellyfin)
  * [Homepage](#homepage)
  * [Jellyseerr](#jellyseerr)
  * [FlareSolverr](#flaresolverr)
  * [Caddy and SSL Certificates](#caddy-and-ssl-certificates)
    * [Accessing from the outside with Tailscale](#accessing-from-the-outside-with-tailscale)
    * [Expose DNS Server with Tailscale](#expose-dns-server-with-tailscale)
  * [Customization](#customization)
<!-- TOC -->

## Applications

| **Application**                                                    | **Description**                                                                                                                                      | **Image**                                                                                        | **SUBDOMAIN** |
|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|---------------|
| [Sonarr](https://sonarr.tv)                                        | PVR for newsgroup and bittorrent users                                                                                                               | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)                                | sonarr.       |
| [Radarr](https://radarr.video)                                     | Movie collection manager for Usenet and BitTorrent users                                                                                             | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)                                | radarr.       |
| [Bazarr](https://www.bazarr.media/)                                | Companion application to Sonarr and Radarr that manages and downloads subtitles                                                                      | [linuxserver/bazarr](https://hub.docker.com/r/linuxserver/bazarr)                                | bazarr.       |
| [Prowlarr](https://github.com/Prowlarr/Prowlarr)                   | Indexer aggregator for Sonarr and Radarr                                                                                                             | [linuxserver/prowlarr:latest](https://hub.docker.com/r/linuxserver/prowlarr)                     | prowlarr.     |
| [PIA WireGuard VPN](https://github.com/thrnz/docker-wireguard-pia) | Encapsulate qBittorrent traffic in [PIA](https://www.privateinternetaccess.com/) using [WireGuard](https://www.wireguard.com/) with port forwarding. | [thrnz/docker-wireguard-pia](https://hub.docker.com/r/thrnz/docker-wireguard-pia)                |               |
| [qBittorrent](https://www.qbittorrent.org)                         | Bittorrent client with a complete web UI<br/>Uses VPN network<br/>Using Libtorrent 1.x                                                               | [linuxserver/qbittorrent:libtorrentv1](https://hub.docker.com/r/linuxserver/qbittorrent)         | qbittorrent.  |
| [Unpackerr](https://unpackerr.zip)                                 | Automated Archive Extractions                                                                                                                        | [golift/unpackerr](https://hub.docker.com/r/golift/unpackerr)                                    |               |
| [Jellyfin](https://jellyfin.org)                                   | Media server designed to organize, manage, and share digital media files to networked devices                                                        | [linuxserver/jellyfin](https://hub.docker.com/r/linuxserver/jellyfin)                            | jellyfin.     |
| [Jellyseer](https://jellyfin.org)                                  | Manages requests for your media library                                                                                                              | [fallenbagel/jellyseerr](https://hub.docker.com/r/fallenbagel/jellyseerr)                        | jellyseer.    |
| [Homepage](https://gethomepage.dev)                                | Application dashboard                                                                                                                                | [gethomepage/homepage](https://github.com/gethomepage/homepage/pkgs/container/homepage)          | home.         |
| [Caddy](https://https://caddyserver.com/docs/)                     | Reverse proxy                                                                                                                                        | [slothcroissant/caddy-cloudflaredns](https://hub.docker.com/r/slothcroissant/caddy-cloudflaredns)|               |
| [Watchtower](https://containrrr.dev/watchtower/)                   | Automated Docker images update                                                                                                                       | [containrrr/watchtower](https://hub.docker.com/r/containrrr/watchtower)                          |               |
| [Autoheal](https://github.com/willfarrell/docker-autoheal/)        | Monitor and restart unhealthy Docker containers                                                                                                      | [willfarrell/autoheal](https://hub.docker.com/r/willfarrell/autoheal)                            |               |
| [Lidarr](https://lidarr.audio)                                     | Music collection manager for Usenet and BitTorrent users<br/>                                                                                        | [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)                                | lidarr.       |
| [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)       | Proxy server to bypass Cloudflare protection in Prowlarr<br/>                                                                                        | [flaresolverr/flaresolverr](https://hub.docker.com/r/flaresolverr/flaresolverr)                  |               |

## Quick Start

From the directory that you cloned the project into, copy the .env template file using `cp .env.example .env`, and set the variable values.
Next, if your host is running Ubuntu or Fedora, run `sudo bash pihole-setup.sh`. This alters the default DNS resolver settings [for compatibility with Pihole](https://github.com/pi-hole/docker-pi-hole?tab=readme-ov-file#installing-on-ubuntu-or-fedora).
Then, run `sudo docker compose up -d` to start the media server containers.

💡Note: By default, Docker is only accessible with root privileges. If you want to [use Docker as a regular user](https://docs.docker.com/engine/install/linux-postinstall/), you need to add your user to the 'docker' group.

After running `docker compose up` for the first time, run `sudo bash update-config.sh` to update the applications' base URLs and set the API keys in `.env`. This will also set the domain, LAN IP and TAILSCALE IP in etc-pihole/custom.list (setting your local DNS records in Pihole).

If you want to see Jellyfin information on the homepage widget, create an API key in Jellyfin's Settings and enter the value for `JELLYFIN_API_KEY`.
If you want to see Pihole information on the homepage widget, retrieve the Pihole API key from the admin dashboard and enter the value for `PIHOLE_API_KEY`.

## Environment Variables

| Variable                       | Description                                                                                                                                                                                            | Default                                          |
|--------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| `CLOUDFLARE_API_TOKEN`         | Cloudflare API token with Edit zone DNS permissions                                                                                                                                                    |                                                  |
| `CLOUDFLARE_EMAIL`             | Email address used for your Cloudflare account                                                                                                                                                         |                                                  |
| `USER_ID`                      | ID of the user to use in Docker containers                                                                                                                                                             | `1000`                                           |
| `GROUP_ID`                     | ID of the user group to use in Docker containers                                                                                                                                                       | `1000`                                           |
| `TIMEZONE`                     | TimeZone used by the container.                                                                                                                                                                        | `America/Chicago `                               |
| `CONFIG_ROOT`                  | Host location for configuration files                                                                                                                                                                  | `.`                                              |
| `DATA_ROOT`                    | Host location of the data files                                                                                                                                                                        | `/mnt/data`                                      |
| `DOWNLOAD_ROOT`                | Host download location for qBittorrent, should be a subfolder of `DATA_ROOT`                                                                                                                           | `/mnt/data/torrents`                             |
| `DOMAIN`                       | Domain name for the media server/NAS                                                                                                                                                                   |                                                  |
| `JELLYFIN_URL`                 | Subdomain for Jellyfin                                                                                                                                                                                 | `https://jellyfin.${DOMAIN}`                     |
| `JELLYFIN_API_KEY`             | Jellyfin API key to show information in the homepage                                                                                                                                                   |                                                  |
| `PIHOLE_URL`                   | Subdomain for Pihole                                                                                                                                                                                   | `https://pihole.${DOMAIN}`                       |
| `PIHOLE_API_KEY`               | Pihole API key to show information in the homepage                                                                                                                                                     |                                                  |
| `PIHOLE_ADMIN_PASSWORD`        | Pihole admin password to access the web UI                                                                                                                                                             | `superSecretPassword`                            |
| `SONARR_URL`                   | Subdomain for Sonarr                                                                                                                                                                                   | `https://sonarr.${DOMAIN}`                       |
| `SONARR_API_KEY`               | Sonarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `RADARR_URL`                   | Subdomain for Radarr                                                                                                                                                                                   | `https://radarr.${DOMAIN}`                       |
| `RADARR_API_KEY`               | Radarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `LIDARR_URL`                   | Subdomain for Lidarr                                                                                                                                                                                   | `https://lidarr.${DOMAIN}`                       |
| `LIDARR_API_KEY`               | Lidarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `PROWLARR_URL`                 | Subdomain for Prowlarr                                                                                                                                                                                 | `https://prowlarr.${DOMAIN}`                     |
| `PROWLARR_API_KEY`             | Prowlarr API key to show information in the homepage                                                                                                                                                   |                                                  |
| `BAZARR_URL`                   | Subdomain for Bazarr                                                                                                                                                                                   | `https://bazarr.${DOMAIN}`                       |
| `BAZARR_API_KEY`               | Bazarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `JELLYSEERR_URL`               | Subdomain for Jellyseerr                                                                                                                                                                               | `https://jellyseerr.${DOMAIN}`                   |
| `JELLYSEERR_API_KEY`           | Jellyseer API key to show information in the homepage                                                                                                                                                  |                                                  |
| `QBITTORRENT_URL`              | Subdomain for qBittorrent                                                                                                                                                                              | `https://qbittorrent.${DOMAIN}`                  |
| `QBITTORRENT_USERNAME`         | qBittorrent username to access the web UI                                                                                                                                                              | `admin`                                          |
| `QBITTORRENT_PASSWORD`         | qBittorrent password to access the web UI                                                                                                                                                              | `adminadmin`                                     |
| `PIA_LOCATION`                 | Servers to use for PIA. [see list here](https://serverlist.piaservers.net/vpninfo/servers/v6)                                                                                                          | `us_atlanta`                                     |
| `PIA_USER`                     | PIA username                                                                                                                                                                                           |                                                  |
| `PIA_PASS`                     | PIA password                                                                                                                                                                                           |                                                  |
| `PIA_LOCAL_NETWORK`            | PIA local network                                                                                                                                                                                      | `192.168.1.0/24`                                 |
| `HOMEPAGE_VAR_TITLE`           | Title of the homepage                                                                                                                                                                                  | `Home`                                           |
| `HOMEPAGE_VAR_SEARCH_PROVIDER` | Homepage search provider, [see list here](https://gethomepage.dev/en/widgets/search/)                                                                                                                  | `google`                                         |
| `HOMEPAGE_VAR_HEADER_STYLE`    | Homepage header style, [see list here](https://gethomepage.dev/en/configs/settings/#header-style)                                                                                                      | `boxed`                                          |
| `HOMEPAGE_VAR_WEATHER_CITY`    | Homepage weather city name                                                                                                                                                                             | `Waco`                                           |
| `HOMEPAGE_VAR_WEATHER_LAT`     | Homepage weather city latitude                                                                                                                                                                         | `31.559814`                                      |
| `HOMEPAGE_VAR_WEATHER_LONG`    | Homepage weather city longitude                                                                                                                                                                        | `-97.141800`                                     |
| `HOMEPAGE_VAR_WEATHER_UNIT`    | Homepage weather unit, either `metric` or `imperial`                                                                                                                                                   | `imperial`                                       |
| `TAILSCALE_IP`                 | The Tailscale IP address for your server                                                                                                                                                               |                                                  |
| `LAN_IP`                       | The static LAN IP address for your server                                                                                                                                                              |                                                  |
| `ROUTER_IP`                    | Your router/gateway IP address                                                                                                                                                                         | `192.168.1.1`                                    |
| `LAN_CIDR`                     | Your LAN's subnet range                                                                                                                                                                                | `192.168.1.1/24`                                 |
| `UPSTREAM_DNS`                 | Upstream DNS servers for Pihole (Defaults are Cloudflare & OpenDNS)                                                                                                                                    | `1.1.1.1;1.0.0.1;208.67.222.222;208.67.220.220`  |
| `WEBHOOK_URL`                  | Webhook URL for notifications when your containers are forced to restart by autoheal (ex. ntfy.sh/test)                                                                                                |                                                  |

## PIA WireGuard VPN

I chose PIA since it supports WireGuard and [port forwarding](https://github.com/thrnz/docker-wireguard-pia/issues/26#issuecomment-868165281),
but you could use other providers:

- OpenVPN: [linuxserver/openvpn-as](https://hub.docker.com/r/linuxserver/openvpn-as)
- WireGuard: [linuxserver/wireguard](https://hub.docker.com/r/linuxserver/wireguard)
- NordVPN + OpenVPN: [bubuntux/nordvpn](https://hub.docker.com/r/bubuntux/nordvpn/dockerfile)
- NordVPN + WireGuard (NordLynx): [bubuntux/nordlynx](https://hub.docker.com/r/bubuntux/nordlynx)

For PIA + WireGuard, fill `.env` and fill it with your PIA credentials.

The location of the server it will connect to is set to `LOC=us_atlanta`, defaulting to Atlanta, GA (USA).

You need to fill the credentials in the `PIA_*` environment variables, 
otherwise the VPN container will exit and qBittorrent will not start.

## Sonarr, Radarr & Lidarr

### File Structure

Sonarr, Radarr, and Lidarr must be configured to support hardlinks, to allow instant moves and prevent using twice the storage
(Bittorrent downloads and final file). The trick is to use a single volume shared by the Bittorrent client and the *arrs.
Subfolders are used to separate the TV shows from the movies.

The configuration is well explained by [this guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/).

In summary, the final structure of the shared volume will be as follows:

```
data
├── torrents = shared folder qBittorrent downloads
│  ├── movies = movies downloads tagged by Radarr
│  └── tv = movies downloads tagged by Sonarr
└── media = shared folder for Sonarr and Radarr files
   ├── movies = Radarr
   └── tv = Sonarr
   └── music = Lidarr
```

Go to Settings > Management.
In Sonarr, set the Root folder to `/data/media/tv`.
In Radarr, set the Root folder to `/data/media/movies`.
In Lidarr, set the Root folder to `/data/media/music`.

### Download Client

Add qBittorrent as a download client by clicking Settings > Download Clients. Set the host for qBittorrent to `localhost` and the port to `8080`. 
Input the username and password you set for qBittorrent, then click the Test button to confirm the connection is functioning properly. If you do not see any errors, click Save.
💡Note: You will need to repeat this process for all of the *arr apps (Prowlarr, Sonarr, Radarr, and Lidarr).

## Prowlarr

Indexers for all of the *arr apps are configured and managed through Prowlarr. Indexers added to Prowlarr synchronize automatically to the other *arr apps, providing a one-stop location for indexer management.

To sync indexers to Radarr, Sonarr and Lidarr, you must first add them as apps in Prowlarr. From Prowlarr, click Settings > Apps. Then click the respective *arr app.

| *Arr App | Server URL                      |
|----------|---------------------------------|
| Prowlarr | `http://localhost:9696/prowlarr`|
| Radarr   | `http://localhost:7878/radarr`  |
| Sonarr   | `http://localhost:8989/sonarr`  |
| Lidarr   | `http://localhost:8686/lidarr`  |

API keys for each individual *arr app can be found within Settings > Security > API Key (from the respective *arr app's web portal; ex. to get the API key for Sonarr, go to sonarr.<your-domain>, then click Settings > Security > API Key).
Alternatively, you can find the API keys for the *arr apps with your `.env` file (assuming you ran the `update-config.sh` script).

See example screenshot below showing how Radarr is configured as an app within Prowlarr:
![Prowlarr-Radarr App Config](https://thefinalsummer.com/wp-content/uploads/2024/07/screenshot-2024-07-20-164728.png "Radarr App Config")


## qBittorrent

Running `update-config.sh` will set qBittorrent's password to `adminadmin` (or whatever value you set for `QBITTORRENT_PASSWORD` in the .env file).

If you want to set the qBittorrent password without using the `update-config.sh` script,
since qBittorrent v4.6.2, a temporary password is generated on startup. Get it with `docker compose logs qbittorrent`:
```
The WebUI administrator username is: admin
The WebUI administrator password was not set. A temporary password is provided for this session: <some_password>
```

Use this password to access the UI, then go to Settings > Web UI and set your own password, 
then set it in `.env`'s `QBITTORRENT_PASSWORD` variable.

The login page can be disabled on for the local network in by enabling `Bypass authentication for clients`.

```
192.168.0.0/16
127.0.0.0/8
172.17.0.0/16
```

Set the default save path to `/data/torrents` in Settings, and restrict the network interface to WireGuard (`wg0`). **Make sure to restrict the network interface to WireGuard!** 
Otherwise, your IP address may be exposed when torrenting.

### IP Leak Check
To confirm that the VPN setup ***is not*** leaking your personal IP address when torrenting, you can use https://ipleak.net/. Scroll to "Torrent Address Detection", click "Activate", then copy the Magnet link. 
Next, add the Magnet link to qBittorrent. From qBittorrent, click the "Add Torrent Link" button in the upper left corner, then paste the link in the download from URLs or Magnet links field, then scroll down and click the Download button.
![Adding Magnet Link to qBittorrent](https://thefinalsummer.com/wp-content/uploads/2024/07/screenshot-2024-07-20-170521.png)
Within ~10 seconds, ipleak.net will show the IP address used by qBittorrent. If everything is setup properly, your personal IP address should not be exposed. 

After completing the test, right-click the download in qBittorrent, then click remove to delete it.

### VueTorrent WebUI

To use the VueTorrent WebUI, go to `qBittorrent`, `Options`, `Web UI`, `Use Alternative WebUI`, and enter `/vuetorrent`. Special thanks to gabe565 for the easy enablement with (https://github.com/gabe565/linuxserver-mod-vuetorrent).

## Jellyfin

To enable [hardware transcoding](https://jellyfin.org/docs/general/administration/hardware-acceleration/),
depending on your system, you may need to add the following block:

```    
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0
```

Generally, running Docker on Linux you will want to use VA-API, but the exact mount paths may differ depending on your
hardware.

## Homepage

The homepage comes with sensible defaults; some settings can ben controlled via environment variables in `.env`.

If you to customize further, you can modify the files in `/homepage/*.yaml` according to the [documentation](https://gethomepage.dev). 
Due to how the Docker socket is configured for the Docker integration, files must be edited as root.

The files in `/homepage/tpl/*.yaml` only serve as a base to set up the homepage configuration on first run.

## Jellyseerr

Jellyseer gives you content recommendations, allows others to make requests to you, and allows logging in with Jellyfin credentials.

To setup, go to https://hostname/jellyseerr/setup, and set the URLs as follows:
- Jellyfin: http://jellyfin:8096/jellyfin
- Radarr:
  - Hostname: vpn
  - Port: 7878
  - URL Base: /radarr
- Sonarr
  - Hostname: vpn
  - Port: 8989
  - URL Base: /sonarr

## FlareSolverr

In Prowlarr, add the FlareSolverr indexer with the URL http://127.0.0.1:8191/

## Caddy and SSL Certificates

While you can use a private IP to access your server, how cool would it be for it to be accessible through a subdomain
with a valid SSL certificate?

Caddy makes this easy by using Let's Encrypt and a
[supported ACME challenge provider](https://caddy.community/t/how-to-use-dns-provider-modules-in-caddy-2/8148). For simplicity, this project uses Cloudflare.

Set the CloudFlare `.env` values, and make sure to enter your Cloudflare account email address on the base Caddyfile. (Note: You will need to rename 
the `example_Caddyfile` file to `Caddyfile` for Caddy to function properly).

### Accessing from the outside with Tailscale

If you want to access your media server when you're away from home (without opening ports or exposing your server to the internet),
[Tailscale](https://tailscale.com) is a great solution. Simply create a Tailnet, install the client on both the server and your other devices, 
and they will then be able to connect to one another.

After installing Tailscale on your server, update the `.env` file with your server's `TAILSCALE_IP` address.

See [here](https://tailscale.com/kb/installation) for installation instructions.

### Expose DNS Server with Tailscale

[Tailscale's documentation](https://tailscale.com/kb/1114/pi-hole) provides instructions for using your Pihole server when you're away from your LAN.


## Customization

You can override the configuration of a service or add new services by creating a new `docker-compose.override.yml` file,
then appending it to the `COMPOSE_FILE` environment variable: `COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml`

[See official documentation](https://docs.docker.com/compose/extends).

For example, use a [different VPN provider](https://github.com/bubuntux/nordvpn):

```yml
services:
  vpn:
    image: ghcr.io/bubuntux/nordvpn
    cap_add:
      - NET_ADMIN               # Required
      - NET_RAW                 # Required
    environment:                # Review https://github.com/bubuntux/nordvpn#environment-variables
      - USER=user@email.com     # Required
      - "PASS=pas$word"         # Required
      - CONNECT=United_States
      - TECHNOLOGY=NordLynx
      - NETWORK=192.168.1.0/24  # So it can be accessed within the local network
```

## Use Separate Paths for Torrents and Storage

If you want to use separate paths for torrents download and long term storage, to use different disks for example,
set your `docker-compose.override.yml` to:

```yml
services:
  sonarr:
    volumes:
      - ./sonarr:/config
      - ${DATA_ROOT}/media/tv:/data/media/tv
      - ${DOWNLOAD_ROOT}/tv:/data/torrents/tv
  radarr:
    volumes:
      - ./radarr:/config
      - ${DATA_ROOT}/media/movies:/data/media/movies
      - ${DOWNLOAD_ROOT}/movies:/data/torrents/movies
```

Note you will lose the hard link ability, ie your files will be duplicated.

In Sonarr and Radarr, go to `Settings` > `Importing` > Untick `Use Hardlinks instead of Copy`