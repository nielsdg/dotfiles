# Caddy SSL Setup

Caddy reverse proxy with automatic SSL certificates from Let's Encrypt using DuckDNS DNS validation.

## Installation

```bash
./install-caddy.yml
```

## Configuration

Edit `Caddyfile` to add or modify services. The format is:

```
subdomain.nielsdg.duckdns.org {
    reverse_proxy service_name:port
    tls {
        dns duckdns {env.DUCKDNS_TOKEN}
    }
}
```

## Services

- **FreshRSS**: https://freshrss.nielsdg.duckdns.org
- **Home Assistant**: https://ha.nielsdg.duckdns.org

## DNS Setup

Make sure your DuckDNS subdomains point to your server's IP:
- freshrss.nielsdg.duckdns.org
- ha.nielsdg.duckdns.org

You can use wildcards (*.nielsdg.duckdns.org) in DuckDNS settings.

## Updating Configuration

After editing the Caddyfile:

```bash
cd ~/caddy
docker compose restart
```

## Notes

- Home Assistant uses `host.docker.internal:8123` to access the host network mode container
- FreshRSS needs to be on the same Docker network as Caddy (caddy_default)
- Certificates auto-renew before expiry
