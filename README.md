# Home Media Server
**NOTE: This is a fork; please see the original [docker-compose-nas project repo here](https://github.com/AdrienPoupa/docker-compose-nas).**

This is a simple [Docker Compose](https://docs.docker.com/compose/) project used to create a media server on your home network.

The main differences between the original project and this fork:
* This project uses Caddy as a reverse proxy (instead of Traefik)
* Pihole is installed by default (for ad-blocking & local DNS record management)
  * Note: If you do not want to use Pihole, simply remove `pihole` from the `COMPOSE_PROFILES` list within the .env file.
* This fork sets all *arr apps to use the VPN connection by default
* [Kiwix](https://kiwix.org/en/) has been added as an optional application (remove `kiwix` from the `COMPOSE_PROFILES` list within the .env if you do not want Kiwix).
* Minor homepage changes (set a background image, added a Pihole widget, & set widget units to imperial)
* Container image updates are managed through Renovate pull requests, then deployed manually.

Requirements: Any Docker-capable recent Linux distro with Docker Engine and Docker Compose V2. I recommend using the current LTS version of [Ubuntu Server](https://ubuntu.com/download/server).

![Docker-Compose NAS Homepage](https://thefinalsummer.com/wp-content/uploads/2024/11/screenshot-2024-11-03-194012.png "Homepage")

## Table of Contents

<!-- TOC -->
* [Home Media Server](#home-media-server)
  * [Table of Contents](#table-of-contents)
  * [Applications](#applications)
  * [Quick Start](#quick-start)
    * [Homepage Widgets](#homepage-widgets)
  * [Environment Variables](#environment-variables)
  * [PIA WireGuard VPN](#pia-wireguard-vpn)
  * [Sonarr, Radarr, & Lidarr](#sonarr-radarr--lidarr)
    * [File Structure](#file-structure)
    * [Download Client](#download-client)
  * [Prowlarr](#prowlarr)
  * [Bazarr](#bazarr)
  * [qBittorrent](#qbittorrent)
    * [IP Leak Check](#ip-leak-check)
    * [VueTorrent Web UI](#vuetorrent-webui)
  * [Jellyfin](#jellyfin)
  * [Kiwix](#kiwix)
  * [Homepage](#homepage)
  * [Jellyseerr](#jellyseerr)
  * [FlareSolverr](#flaresolverr)
  * [Caddy and SSL Certificates](#caddy-and-ssl-certificates)
    * [Accessing from the outside with Tailscale](#accessing-from-the-outside-with-tailscale)
    * [Expose DNS Server with Tailscale](#expose-dns-server-with-tailscale)
  * [Use Separate Paths for Torrents and Storage](#use-separate-paths-for-torrents-and-storage)

<!-- TOC -->

## Applications

| **Application**                                                    | **Description**                                                                                                                                      | **Image**                                                                                        | **SUBDOMAIN** |
|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|---------------|
| [Pihole](https://docs.pi-hole.net/)                                | A DNS sinkhole that protects your devices from unwanted content. (Adblocker & DNS server for your LAN.)                                              | [pihole/pihole](https://hub.docker.com/r/pihole/pihole)                                          | pihole.       |
| [Sonarr](https://sonarr.tv)                                        | PVR for newsgroup and bittorrent users                                                                                                               | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)                                | sonarr.       |
| [Radarr](https://radarr.video)                                     | Movie collection manager for Usenet and BitTorrent users                                                                                             | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)                                | radarr.       |
| [Bazarr](https://www.bazarr.media/)                                | Companion application to Sonarr and Radarr that manages and downloads subtitles                                                                      | [linuxserver/bazarr](https://hub.docker.com/r/linuxserver/bazarr)                                | bazarr.       |
| [Prowlarr](https://github.com/Prowlarr/Prowlarr)                   | Indexer aggregator for Sonarr and Radarr                                                                                                             | [linuxserver/prowlarr:latest](https://hub.docker.com/r/linuxserver/prowlarr)                     | prowlarr.     |
| [PIA WireGuard VPN](https://github.com/thrnz/docker-wireguard-pia) | Encapsulate qBittorrent traffic in [PIA](https://www.privateinternetaccess.com/) using [WireGuard](https://www.wireguard.com/) with port forwarding. | [thrnz/docker-wireguard-pia](https://hub.docker.com/r/thrnz/docker-wireguard-pia)                |               |
| [qBittorrent](https://www.qbittorrent.org)                         | Bittorrent client with a complete web UI<br/>Uses VPN network<br/>Using Libtorrent 1.x                                                               | [linuxserver/qbittorrent:libtorrentv1](https://hub.docker.com/r/linuxserver/qbittorrent)         | qbittorrent.  |
| [Unpackerr](https://unpackerr.zip)                                 | Automated Archive Extractions                                                                                                                        | [golift/unpackerr](https://hub.docker.com/r/golift/unpackerr)                                    |               |
| [Jellyfin](https://jellyfin.org)                                   | Media server designed to organize, manage, and share digital media files to networked devices                                                        | [jellyfin/jellyfin](https://hub.docker.com/r/jellyfin/jellyfin)                                  | jellyfin.     |
| [Jellyseer](https://jellyfin.org)                                  | Manages requests for your media library                                                                                                              | [fallenbagel/jellyseerr](https://hub.docker.com/r/fallenbagel/jellyseerr)                        | jellyseer.    |
| [Homepage](https://gethomepage.dev)                                | Application dashboard                                                                                                                                | [gethomepage/homepage](https://github.com/gethomepage/homepage/pkgs/container/homepage)          | home.         |
| [Caddy](https://https://caddyserver.com/docs/)                     | Reverse proxy                                                                                                                                        | [slothcroissant/caddy-cloudflaredns](https://hub.docker.com/r/slothcroissant/caddy-cloudflaredns)|               |
| [Autoheal](https://github.com/willfarrell/docker-autoheal/)        | Monitor and restart unhealthy Docker containers                                                                                                      | [willfarrell/autoheal](https://hub.docker.com/r/willfarrell/autoheal)                            |               |
| [Lidarr](https://lidarr.audio)                                     | Music collection manager for Usenet and BitTorrent users<br/>                                                                                        | [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)                                | lidarr.       |
| [Kiwix](https://github.com/kiwix)                                  | Open-source software for offline access to Wikipedia, TED talks, Stack Exchange, and many other resources.<br/>                                      | [ghcr.io/kiwix/kiwix-serve](ghcr.io/kiwix/kiwix-serve)                                           | kiwix.        |
| [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)       | Proxy server to bypass Cloudflare protection in Prowlarr<br/>                                                                                        | [flaresolverr/flaresolverr](https://hub.docker.com/r/flaresolverr/flaresolverr)                  |               |

## Quick Start
💡**Note**: This quick start guide assumes the following:
- You have mounted your media storage on your media server. Make sure you've completed this (and set the path for this media storage in the `.env` file) *before* starting the containers. 
  - [WikiHow article for mounting a local storage drive](https://www.wikihow.com/Linux-How-to-Mount-Drive)
  - [Ubuntu Server documentation for mounting an SMB share using CIFS](https://documentation.ubuntu.com/server/how-to/samba/mount-cifs-shares-permanently/)
  - See the [File Structure](#file-structure) section below for information on setting up folders/directories on your media storage.
- Your server has a static DHCP lease on your LAN. (Check your router's documentation if you're not sure how to do this.)
- You plan to set your media server's IP address as the primary DNS server on your LAN.
  - I recommend setting Cloudflare (1.1.1.1), Quad9 (9.9.9.9), or OpenDNS (208.67.222.222) as a secondary DNS server so that you can still access the Internet if your Pihole container goes down.
- You have purchased a domain name and [linked it to Cloudflare](https://developers.cloudflare.com/fundamentals/setup/manage-domains/add-site/#1--add-site-in-cloudflare), and you have [generated a DNS Zone Edit API key](https://blog.gurucomputing.com.au/Reverse%20Proxies%20with%20Caddy/Adding%20Acme%20Certification/#api-keys).
- You are using [Private Internet Access](https://www.privateinternetaccess.com/buy-vpn-online) as your VPN (see [PIA section below](#pia-wireguard-vpn)).
- You have already [installed Docker](https://docs.docker.com/engine/install/ubuntu/) on your host.

First, clone this project onto your server using `git clone https://github.com/willam-opie/home-media-server`.

From the directory that you cloned the project into, copy the .env template file using `cp .env.example .env`, and input the variable values. See the [Environment Variables](#environment-variables) table below for more information.

Next, if your host is running Ubuntu or Fedora, run `sudo bash pihole-setup.sh`. This alters the default DNS resolver settings [for compatibility with Pihole](https://github.com/pi-hole/docker-pi-hole?tab=readme-ov-file#installing-on-ubuntu-or-fedora).

Then, run `sudo docker compose up -d` to start the media server containers.

💡**Note:** By default, Docker is only accessible with root privileges. If you want to [use Docker as a regular user](https://docs.docker.com/engine/install/linux-postinstall/), you need to add your user to the 'docker' group.

After running `docker compose up -d` for the first time, run `sudo bash update-config.sh`. This script handles the following steps:
- Updates the applications' base URLs and sets the API keys in `.env`. 
- Sets the domain, LAN IP and TAILSCALE IP in etc-pihole/custom.list (creating your local DNS records in Pihole).
- Sets the qBittorrent admin credentials (username: `admin`; password: `adminadmin`)
- Creates Caddyfile (from the template example_Caddyfile) within the container-config directory. Also swaps in the $CLOUDFLARE_EMAIL variable within Caddyfile.
- Restarts the entire docker compose stack at the end of the script.

⚠️ **Note:** The first startup may take several minutes to complete. *Be patient.*

### Updating Containers
Container image updates are proposed by Renovate as pull requests. After you review and merge an update PR, deploy the changes from your server with:

```bash
git pull
docker compose pull
docker compose up -d
```

After deploying, verify container health with `docker compose ps`.

### Homepage Widgets
The `update-config.sh` script inserts the API key values for the \*Arr apps in the `.env` file automatically. Unfortunately, this script *does not* set the API key variables for Jellyfin, Jellyseerr, or Pihole in the `.env` file. If you want the homepage widgets for these apps to display information for these apps, you will need to add their API keys to the `.env` file manually.

Steps for getting the API keys for these apps are listed below:
- **Jellyfin**: Click the hamburger menu in the upper left corner, then click "Dashboard". Next, scroll down on the left sidebar and click "API Keys" (in the "Advanced" section.) Press the + icon to generate a new API Key, then copy and paste this API Key value in the `.env` file for `JELLYFIN_API_KEY`.
- **Pihole**: Sign-in to the Pihole admin dashboard (make sure to set an admin password for Pihole in the `.env` file), then click "Settings" from the left sidebar. Next, click the "API" tab. On the API tab, click the "Show API token" button. Then click "Yes, show API token", and copy the value listed below "Raw API Token". Paste this API Key value in the `.env` file for `PIHOLE_API_KEY`.
- **Jellyseerr**: After completing the Jellyseerr initial config (scroll to [Jellyseer](#jellyseerr) for config steps), click the "Settings" button on the left sidebar. The API Key will appear on the "General" tab. Copy the API Key value and paste it in the `.env` file for `JELLYSEERR_API_KEY`.

## Environment Variables

| Variable                       | Description                                                                                                                                                                                             | Default                                          |
|--------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| `CLOUDFLARE_API_TOKEN`         | Cloudflare API token with Edit zone DNS permissions                                                                                                                                                     |                                                  |
| `CLOUDFLARE_EMAIL`             | Email address used for your Cloudflare account                                                                                                                                                          |                                                  |
| `USER_ID`                      | ID of the user to use in Docker containers                                                                                                                                                              | `1000`                                           |
| `GROUP_ID`                     | ID of the user group to use in Docker containers                                                                                                                                                        | `1000`                                           |
| `TIMEZONE`                     | TimeZone used by the container.                                                                                                                                                                         | `America/Chicago `                               |
| `CONFIG_ROOT`                  | Host location for configuration files                                                                                                                                                                   | `.`                                              |
| `DATA_ROOT`                    | Host location of the data files                                                                                                                                                                         | `/mnt/data`                                      |
| `DOWNLOAD_ROOT`                | Host download location for qBittorrent, should be a subfolder of `DATA_ROOT`                                                                                                                            | `/mnt/data/torrents`                             |
| `DOMAIN`                       | Domain name for the media server/NAS                                                                                                                                                                    |                                                  |
| `JELLYFIN_URL`                 | Subdomain for Jellyfin                                                                                                                                                                                  | `https://jellyfin.${DOMAIN}`                     |
| `JELLYFIN_API_KEY`             | Jellyfin API key to show information in the homepage                                                                                                                                                    |                                                  |
| `PIHOLE_URL`                   | Subdomain for Pihole                                                                                                                                                                                    | `https://pihole.${DOMAIN}`                       |
| `PIHOLE_API_KEY`               | Pihole API key to show information in the homepage                                                                                                                                                      |                                                  |
| `PIHOLE_ADMIN_PASSWORD`        | Pihole admin password to access the web UI                                                                                                                                                              | `superSecretPassword`                            |
| `SONARR_URL`                   | Subdomain for Sonarr                                                                                                                                                                                    | `https://sonarr.${DOMAIN}`                       |
| `SONARR_API_KEY`               | Sonarr API key to show information in the homepage                                                                                                                                                      |                                                  |
| `RADARR_URL`                   | Subdomain for Radarr                                                                                                                                                                                    | `https://radarr.${DOMAIN}`                       |
| `RADARR_API_KEY`               | Radarr API key to show information in the homepage                                                                                                                                                      |                                                  |
| `LIDARR_URL`                   | Subdomain for Lidarr                                                                                                                                                                                    | `https://lidarr.${DOMAIN}`                       |
| `LIDARR_API_KEY`               | Lidarr API key to show information in the homepage                                                                                                                                                      |                                                  |
| `PROWLARR_URL`                 | Subdomain for Prowlarr                                                                                                                                                                                  | `https://prowlarr.${DOMAIN}`                     |
| `PROWLARR_API_KEY`             | Prowlarr API key to show information in the homepage                                                                                                                                                    |                                                  |
| `BAZARR_URL`                   | Subdomain for Bazarr                                                                                                                                                                                    | `https://bazarr.${DOMAIN}`                       |
| `BAZARR_API_KEY`               | Bazarr API key to show information in the homepage                                                                                                                                                      |                                                  |
| `JELLYSEERR_URL`               | Subdomain for Jellyseerr                                                                                                                                                                                | `https://jellyseerr.${DOMAIN}`                   |
| `JELLYSEERR_API_KEY`           | Jellyseer API key to show information in the homepage                                                                                                                                                   |                                                  |
| `QBITTORRENT_URL`              | Subdomain for qBittorrent                                                                                                                                                                               | `https://qbittorrent.${DOMAIN}`                  |
| `QBITTORRENT_USERNAME`         | qBittorrent username to access the web UI                                                                                                                                                               | `admin`                                          |
| `QBITTORRENT_PASSWORD`         | qBittorrent password to access the web UI                                                                                                                                                               | `adminadmin`                                     |
| `PIA_LOCATION`                 | Servers to use for PIA. [see list here](https://serverlist.piaservers.net/vpninfo/servers/v6)                                                                                                           | `us_atlanta`                                     |
| `PIA_USER`                     | PIA username                                                                                                                                                                                            |                                                  |
| `PIA_PASS`                     | PIA password                                                                                                                                                                                            |                                                  |
| `PIA_LOCAL_NETWORK`            | PIA local network                                                                                                                                                                                       | `192.168.1.0/24`                                 |
| `HOMEPAGE_ALLOWED_HOSTS`       | Subdomain for home dashboard. (Required env variable in [≥v1.0.0 of homepage](https://github.com/gethomepage/homepage/releases/tag/v1.0.0#:~:text=%5BBREAKING%5D%20Enhancement%3A%20require,the%20docs))| `home.${DOMAIN}`                                 |
| `HOMEPAGE_VAR_TITLE`           | Title of the homepage                                                                                                                                                                                   | `Home`                                           |
| `HOMEPAGE_VAR_SEARCH_PROVIDER` | Homepage search provider, [see list here](https://gethomepage.dev/en/widgets/search/)                                                                                                                   | `google`                                         |
| `HOMEPAGE_VAR_HEADER_STYLE`    | Homepage header style, [see list here](https://gethomepage.dev/en/configs/settings/#header-style)                                                                                                       | `boxed`                                          |
| `HOMEPAGE_VAR_WEATHER_CITY`    | Homepage weather city name                                                                                                                                                                              | `Waco`                                           |
| `HOMEPAGE_VAR_WEATHER_LAT`     | Homepage weather city latitude                                                                                                                                                                          | `31.559814`                                      |
| `HOMEPAGE_VAR_WEATHER_LONG`    | Homepage weather city longitude                                                                                                                                                                         | `-97.141800`                                     |
| `HOMEPAGE_VAR_WEATHER_UNIT`    | Homepage weather unit, either `metric` or `imperial`                                                                                                                                                    | `imperial`                                       |
| `TAILSCALE_IP`                 | The Tailscale IP address for your server                                                                                                                                                                |                                                  |
| `LAN_IP`                       | The static LAN IP address for your server                                                                                                                                                               |                                                  |
| `ROUTER_IP`                    | Your router/gateway IP address                                                                                                                                                                          | `192.168.1.1`                                    |
| `LAN_CIDR`                     | Your LAN's subnet range                                                                                                                                                                                 | `192.168.1.1/24`                                 |
| `UPSTREAM_DNS`                 | Upstream DNS servers for Pihole (Defaults are Cloudflare & OpenDNS)                                                                                                                                     | `1.1.1.1;1.0.0.1;208.67.222.222;208.67.220.220`  |
| `WEBHOOK_URL`                  | Webhook URL for notifications when your containers are forced to restart by autoheal (ex. ntfy.sh/test)                                                                                                 |                                                  |

## PIA WireGuard VPN

[Private Interet Access](https://www.privateinternetaccess.com/buy-vpn-online) was chosen as the default VPN for this project because it supports WireGuard and [port forwarding](https://github.com/thrnz/docker-wireguard-pia/issues/26#issuecomment-868165281). PIA is also reasonably priced and they [do not store logs](https://www.privateinternetaccess.com/vpn-features/no-logs-vpn).

Before starting the containers, update the `.env` file with your PIA credentials.

By default, the VPN server location is set to `us_atlanta`. You can change this to another location within the `.env` file.

See the full list of PIA VPN locations here: https://serverlist.piaservers.net/vpninfo/servers/v6

(Note: "id" values in the PIA VPN location list correspond to the `.env` file's `PIA_LOCATION` value.)

**You must set the credentials in the `PIA_*` environment variables, otherwise the VPN container will exit, and qBittorrent and the *Arr apps will not start.**

## Sonarr, Radarr, & Lidarr

### File Structure

Sonarr, Radarr, and Lidarr must be configured to support hardlinks. This allows file transfers from the torrent downloads folder to the media storage folder, preventing file duplication and excess storage consumption.
This is achieved by using a single volume shared by the qBittorrent client and the *arr apps.

Subfolders are used to separate your TV shows, movies, and music files.

This folder configuration is explained in detail by [this guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/).

The structure of the shared volume is shown below:

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

After updating your storage volume with this folder structure, follow the below steps to add the appropriate directory to each *Arr app.

Within the *Arr app, go to Settings > Management.
- In Sonarr, set the Root folder to `/data/media/tv`.
- In Radarr, set the Root folder to `/data/media/movies`.
- In Lidarr, set the Root folder to `/data/media/music`.

### Download Client

Add qBittorrent as a download client by clicking Settings > Download Clients. Set the host for qBittorrent to `localhost` and the port to `8080`. 
Input the username and password you set for qBittorrent, then click the Test button to confirm the connection is functioning properly. If you do not see any errors, click Save.

💡**Note:** You will need to repeat this process for all of the *arr apps (Prowlarr, Sonarr, Radarr, and Lidarr).

## Prowlarr

Indexers for all of the *arr apps are configured and managed through Prowlarr. Indexers added to Prowlarr synchronize automatically to the other *arr apps, providing a one-stop location for indexer management.

To sync indexers to Radarr, Sonarr, and Lidarr, you must first add them as apps in Prowlarr. From Prowlarr, click Settings > Apps. Then click the respective *arr app.

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

## Bazarr

Bazarr's Wiki has a [setup guide](https://wiki.bazarr.media/Getting-Started/Setup-Guide/) that walks through how to configure the app. I recommend using OpenSubtitles.com and TVSubtitles for providers.

Use the following values when linking Sonarr and Radarr to Bazarr:
| *Arr App | Address    | Port | Base URL  | 
|----------|------------|------|-----------| 
| Sonarr   | localhost  | 8989 | /sonarr   |
| Radarr   | localhost  | 7878 | /radarr   |

## qBittorrent

Running `update-config.sh` will set qBittorrent's username to `admin` and password to `adminadmin`.

⚠️**Note:** `update-config.sh` will set the above credentials for qBittorrent **regardless** of the values you have set for `QBITTORRENT_USERNAME` and `QBITTORRENT_PASSWORD` in the .env file. Subsequent runs of `update-config.sh` will reset the credentials to username: `admin`, password: `adminadmin`. This is useful if you forget your qBittorrent Web UI credentials.

Use these credentials to access qBittorrent's Web UI, then go to Settings > Web UI and set your own username and password. 

After setting your own username and password for qBittorrent, update the credentials in the `.env` file for `QBITTORRENT_USERNAME` and `QBITTORRENT_PASSWORD`.

If you want to set the qBittorrent password without using the `update-config.sh` script,
since qBittorrent v4.6.2, a temporary password is generated on startup. Get it with `docker compose logs qbittorrent`:
```
The WebUI administrator username is: admin
The WebUI administrator password was not set. A temporary password is provided for this session: <some_password>
```

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

Carefully review Jellyfin's documentation on [hardware transcoding](https://jellyfin.org/docs/general/administration/hardware-acceleration/) if you want to enable it. I have provided a commented out configuration for transcoding with [NVIDIA GPUs](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia) (see below), but [you must install GPU drivers on your host](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia#configure-with-linux-virtualization) for transcoding to function properly. It is a multi-step process. If something is not working right initially, re-read the docs and confirm you haven't missed a step.

https://github.com/william-opie/home-media-server/blob/18643d00120456a1005060163935a0f68b3db103/docker-compose.yml#L37-L59



## Kiwix
Kiwix is configured by default to open ZIM files from `${DATA_ROOT}/media/zim`. You can download/torrent ZIM files from [Kiwix's library](https://library.kiwix.org/#lang=eng).

See the [Kiwix Docker README](https://github.com/kiwix/kiwix-tools/blob/main/docker/server/README.md) for more information about configuring Kiwix.


## Homepage

The homepage comes with sensible defaults; some settings can ben controlled via environment variables in `.env`.

If you to customize further, you can modify the files in `/homepage/*.yaml` according to the [documentation](https://gethomepage.dev). 
Due to how the Docker socket is configured for the Docker integration, files must be edited as root.

The files in `/homepage/tpl/*.yaml` only serve as a base to set up the homepage configuration on first run.

## Jellyseerr

Jellyseer gives you content recommendations, allows others to make requests to you, and allows logging in with Jellyfin credentials.

To setup, go to https://jellyseer.<your-domain-here>/setup, and set the URLs as follows:
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

Set the CloudFlare `.env` values, and make sure your Cloudflare account email address is set within the base Caddyfile.

### Accessing from the outside with Tailscale

If you want to access your media server when you're away from home (without opening ports or exposing your server to the internet),
[Tailscale](https://tailscale.com) is a great solution. Simply create a Tailnet, install the client on both the server and your other devices, 
and they will then be able to connect to one another.

After installing Tailscale on your server, update the `.env` file with your server's `TAILSCALE_IP` address.

See [here](https://tailscale.com/kb/installation) for installation instructions.

### Expose DNS Server with Tailscale

[Tailscale's documentation](https://tailscale.com/kb/1114/pi-hole) provides instructions for using your Pihole server when you're away from your LAN.

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

💡**Note:** You will no longer be able to use hardlinks with this configuration, so your files will be duplicated between the torrent and media storage locations.

In Sonarr and Radarr, go to `Settings` > `Importing` > Untick `Use Hardlinks instead of Copy`
