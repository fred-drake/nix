{config, ...}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    allowDHCP = false;
    port = 80;
    host = "192.168.208.7";
    settings = {
      http = {
        pprof = {
          port = 6060;
          enabled = false;
        };
        session_ttl = "720h";
      };
      users = [
        {
          # name = config.soft-secrets.adguard.username;
          name = "adguardhome";
          # password = config.soft-secrets.adguard.hashed-pasword;
          password = "$2a$10$l9S1SoFalbtvrWV.Vy3WCunXQV.r8dc8eCxUYrmTU1Ez/jqelgZXu";
        }
      ];
      auth_attempts = 5;
      block_auth_min = 15;
      http_proxy = "";
      language = "";
      theme = "auto";
      dns = {
        bind_hosts = ["192.168.40.4"];
        port = 53;
        anonymize_client_ip = false;
        ratelimit = 20;
        ratelimit_subnet_len_ipv4 = 24;
        ratelimit_subnet_len_ipv6 = 56;
        ratelimit_whitelist = [];
        refuse_any = true;
        upstream_dns = ["https://dns10.quad9.net/dns-query"];
        upstream_dns_file = "";
        bootstrap_dns = ["9.9.9.10" "149.112.112.10" "2620:fe::10" "2620:fe::fe:10"];
        fallback_dns = [];
        upstream_mode = "load_balance";
        fastest_timeout = "1s";
        allowed_clients = [];
        disallowed_clients = [];
        blocked_hosts = ["version.bind" "id.server" "hostname.bind"];
        trusted_proxies = ["127.0.0.0/8" "::1/128"];
        cache_size = 4194304;
        cache_ttl_min = 0;
        cache_ttl_max = 0;
        cache_optimistic = false;
        bogus_nxdomain = [];
        aaaa_disabled = false;
        enable_dnssec = false;
        edns_client_subnet = {
          custom_ip = "";
          enabled = false;
          use_custom = false;
        };
        max_goroutines = 300;
        handle_ddr = true;
        ipset = [];
        ipset_file = "";
        bootstrap_prefer_ipv6 = false;
        upstream_timeout = "10s";
        private_networks = [];
        use_private_ptr_resolvers = true;
        local_ptr_upstreams = [];
        use_dns64 = false;
        dns64_prefixes = [];
        serve_http3 = false;
        use_http3_upstreams = false;
        serve_plain_dns = true;
        hostsfile_enabled = true;
      };
      tls = {
        enabled = false;
        server_name = "";
        force_https = false;
        port_https = 443;
        port_dns_over_tls = 853;
        port_dns_over_quic = 853;
        port_dnscrypt = 0;
        dnscrypt_config_file = "";
        allow_unencrypted_doh = false;
        certificate_chain = "";
        private_key = "";
        certificate_path = "";
        private_key_path = "";
        strict_sni_check = false;
      };
      querylog = {
        dir_path = "";
        ignored = [];
        interval = "2160h";
        size_memory = 1000;
        enabled = true;
        file_enabled = true;
      };
      statistics = {
        dir_path = "";
        ignored = [];
        interval = "24h";
        enabled = true;
      };
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];
      whitelist_filters = [];
      user_rules = [
        "192.168.30.1 gateway-30.internal.freddrake.com"
        "192.168.30.2 larussa-30.internal.freddrake.com"
        "192.168.30.3 dhcp1-server.internal.freddrake.com"
        "192.168.30.4 dhcp2-server.internal.freddrake.com"
        "192.168.30.6 docker5-30.internal.freddrake.com"
        "192.168.30.12 fred-macbook-pro-wireless.internal.freddrake.com"
        "192.168.30.13 mac-studio.internal.freddrake.com"
        "192.168.30.16 mac-studio-wireless.internal.freddrake.com"
        "192.168.30.17 nuc9-30.internal.freddrake.com"
        "192.168.30.18 brother-printer.internal.freddrake.com"
        "192.168.30.20 rp1-30.internal.freddrake.com"
        "192.168.30.22 sonos-sub-office.internal.freddrake.com"
        "192.168.30.23 sonos-one-office-r.internal.freddrake.com"
        "192.168.30.24 sonos-beam-office.internal.freddrake.com"
        "192.168.30.25 sonos-play1-tvroom-rs.internal.freddrake.com"
        "192.168.30.26 sonos-sub-tv-room.internal.freddrake.com"
        "192.168.30.27 sonos-playbar-tv-room.internal.freddrake.com"
        "192.168.30.28 sonos-play1-tv-room-ls.internal.freddrake.com"
        "192.168.30.29 sonos-playbar-living-room.internal.freddrake.com"
        "192.168.30.30 sonos-one-living-room-l.internal.freddrake.com"
        "192.168.30.31 devone.internal.freddrake.com"
        "192.168.30.32 nixoswinvm.internal.freddrake.com"
        "192.168.30.50 fred-macbook-air-wireless.internal.freddrake.com"
        "192.168.30.51 fred-iphone.internal.freddrake.com"
        "192.168.30.52 macbookx86.internal.freddrake.com"
        "192.168.30.53 laisa-desktop.internal.freddrake.com"
        "192.168.30.54 laisa-iphone.internal.freddrake.com"
        "192.168.30.56 hp-officejet-3830.internal.freddrake.com"
        "192.168.30.57 fredpc.internal.freddrake.com"
        "192.168.30.58 brynn-desktop-2.internal.freddrake.com"
        "192.168.40.1 gateway-40.internal.freddrake.com"
        "192.168.40.2 larussa-40.internal.freddrake.com"
        "192.168.40.4 pihole1-40.internal.freddrake.com"
        "192.168.40.6 pihole2-40.internal.freddrake.com"
        "192.168.40.7 docker5-40.internal.freddrake.com"
        "192.168.40.9 ps5-wired.internal.freddrake.com"
        "192.168.40.11 office-led-strip.internal.freddrake.com"
        "192.168.40.12 brynn-led-lights.internal.freddrake.com"
        "192.168.40.13 goal-light.internal.freddrake.com"
        "192.168.40.14 freds-kindle.internal.freddrake.com"
        "192.168.40.15 orbit-irrigation-controller.internal.freddrake.com"
        "192.168.40.16 office-vizio-wifi.internal.freddrake.com"
        "192.168.40.17 bedroom-lamps.internal.freddrake.com"
        "192.168.40.18 ps4-wired.internal.freddrake.com"
        "192.168.40.19 living-room-vizio-wireless.internal.freddrake.com"
        "192.168.40.21 homeassistant-app-40.internal.freddrake.com"
        "192.168.40.28 ring-patio-camera.internal.freddrake.com"
        "192.168.40.29 goblin-40.internal.freddrake.com"
        "192.168.40.30 roku-brynns-room.internal.freddrake.com"
        "192.168.40.31 office-echo.internal.freddrake.com"
        "192.168.40.32 ecobee-thermostat.internal.freddrake.com"
        "192.168.40.33 closet-light.internal.freddrake.com"
        "192.168.40.34 garage-light.internal.freddrake.com"
        "192.168.40.35 scrypted-app.internal.freddrake.com"
        "192.168.40.36 kitchen-light.internal.freddrake.com"
        "192.168.40.37 pool-light.internal.freddrake.com"
        "192.168.40.38 homebridge-40.internal.freddrake.com"
        "192.168.40.39 master-bedroom-tv.internal.freddrake.com"
        "192.168.40.40 echo-master-bathroom.internal.freddrake.com"
        "192.168.40.41 echo-dining-room.internal.freddrake.com"
        "192.168.40.42 echo-master-bedroom.internal.freddrake.com"
        "192.168.40.43 echo-tv-room.internal.freddrake.com"
        "192.168.40.44 bookshelf-led.internal.freddrake.com"
        "192.168.40.45 echo-spare-bedroom.internal.freddrake.com"
        "192.168.40.46 myq-garage-door-opener.internal.freddrake.com"
        "192.168.40.47 brynns-room-echo.internal.freddrake.com"
        "192.168.40.48 office-monitor-lamp.internal.freddrake.com"
        "192.168.40.49 ring-camera-front.internal.freddrake.com"
        "192.168.40.50 3d-printer-lights.internal.freddrake.com"
        "192.168.40.51 ring-front-door.internal.freddrake.com"
        "192.168.40.52 octopi.internal.freddrake.com"
        "192.168.40.53 sense-power-meter.internal.freddrake.com"
        "192.168.40.54 kiosk.internal.freddrake.com"
        "192.168.40.55 tesla-model-s.internal.freddrake.com"
        "192.168.40.56 phone-charger-plug.internal.freddrake.com"
        "192.168.40.57 appletv-office-wireless.internal.freddrake.com"
        "192.168.40.62 dhcp1-40.internal.freddrake.com"
        "192.168.40.63 dhcp2-40.internal.freddrake.com"
        "192.168.40.65 scoreboard.internal.freddrake.com"
        "192.168.40.66 christmas-tree.internal.freddrake.com"
        "192.168.40.69 hue-bridge.internal.freddrake.com"
        "192.168.40.70 appletv-tvroom.internal.freddrake.com"
        "192.168.40.71 docker-40.internal.freddrake.com"
        "192.168.40.72 nuc9-40.internal.freddrake.com"
        "192.168.40.75 hubitat.internal.freddrake.com"
        "192.168.40.76 appletv-livingroom.internal.freddrake.com"
        "192.168.40.77 tv-room-tv.internal.freddrake.com"
        "192.168.40.78 appletv-masterbedroom.internal.freddrake.com"
        "192.168.40.79 appletv-office.internal.freddrake.com"
        "192.168.40.88 rp1-40.internal.freddrake.com"
        "192.168.40.92 smart-strip-right.internal.freddrake.com"
        "192.168.40.93 smart-strip-left.internal.freddrake.com"
        "192.168.50.1 gateway-50.internal.freddrake.com"
        "192.168.50.2 larussa-50.internal.freddrake.com"
        "192.168.50.3 restic.internal.freddrake.com"
        "192.168.50.4 k8s.internal.freddrake.com"
        "192.168.50.7 kobold.internal.freddrake.com"
        "192.168.50.8 goblin.internal.freddrake.com"
        "192.168.50.9 minio-nexus-app.internal.freddrake.com"
        "192.168.50.10 rp1.internal.freddrake.com"
        "192.168.50.11 nuc3.internal.freddrake.com"
        "192.168.50.12 nuc1.internal.freddrake.com"
        "192.168.50.13 scannerpi.internal.freddrake.com"
        "192.168.50.14 sabnzbd.internal.freddrake.com"
        "192.168.50.17 overseerr.internal.freddrake.com"
        "192.168.50.18 docker-50.internal.freddrake.com"
        "192.168.50.19 homeassistant-app.internal.freddrake.com"
        "192.168.50.20 youtubedownloader-app.internal.freddrake.com"
        "192.168.50.21 youtubedownloader-mongodb-app.internal.freddrake.com"
        "192.168.50.22 storage1.internal.freddrake.com"
        "192.168.50.23 gitea-app.internal.freddrake.com"
        "192.168.50.24 forgejo.internal.freddrake.com"
        "192.168.50.29 transmission-app.internal.freddrake.com"
        "192.168.50.30 sonarr.internal.freddrake.com"
        "192.168.50.31 prowlarr.internal.freddrake.com"
        "192.168.50.32 radarr.internal.freddrake.com"
        "192.168.50.33 actualbudget.internal.freddrake.com"
        "192.168.50.34 mqtt.internal.freddrake.com"
        "192.168.50.35 traefik.internal.freddrake.com"
        "192.168.50.35 homeassistant.internal.freddrake.com"
        "192.168.50.35 youtubedownloader.internal.freddrake.com"
        "192.168.50.35 gitea.internal.freddrake.com"
        "192.168.50.36 homebridge.internal.freddrake.com"
        "192.168.50.39 nuc5.internal.freddrake.com"
        "192.168.50.41 plex-app.internal.freddrake.com"
        "192.168.50.46 minio-loki-app.internal.freddrake.com"
        "192.168.50.48 palworld.internal.freddrake.com"
        "192.168.50.49 vrising.internal.freddrake.com"
        "192.168.50.51 nfs-server.internal.freddrake.com"
        "192.168.50.60 lb1-vip.internal.freddrake.com"
        "192.168.50.60 ersatzminio-backup.internal.freddrake.com"
        "192.168.50.60 minio-backup-ui.internal.freddrake.com"
        "192.168.50.60 minio-loki-ui.internal.freddrake.com"
        "192.168.50.60 minio-nexus.internal.freddrake.com"
        "192.168.50.60 omada.internal.freddrake.com"
        "192.168.50.60 plex.internal.freddrake.com"
        "192.168.50.60 readarr.internal.freddrake.com"
        "192.168.50.60 scanner-api.internal.freddrake.com"
        "192.168.50.60 tdarr.internal.freddrake.com"
        "192.168.50.60 torrent.internal.freddrake.com"
        "192.168.50.60 uptime-kuma.internal.freddrake.com"
        "192.168.50.69 cluster-vip.internal.freddrake.com"
        "192.168.50.69 docker-hub.internal.freddrake.com"
        "192.168.50.69 images.internal.freddrake.com"
        "192.168.50.69 loki.internal.freddrake.com"
        "192.168.50.69 pihole-exporter-pihole1.internal.freddrake.com"
        "192.168.50.69 pihole-exporter-pihole2.internal.freddrake.com"
        "192.168.50.69 traefik-swarm.internal.freddrake.com"
        "192.168.50.79 nuc9-50.internal.freddrake.com"
        "192.168.50.80 dhcp1-50.internal.freddrake.com"
        "192.168.50.81 dhcp2-50.internal.freddrake.com"
        "192.168.50.93 scoreboard-lan.internal.freddrake.com"
        "192.168.50.94 docker5-50.internal.freddrake.com"
        "192.168.50.99 nuc8-proxmox.internal.freddrake.com"
        "192.168.50.102 nuc6.internal.freddrake.com"
        "192.168.50.108 nuc7-proxmox.internal.freddrake.com"
        "192.168.50.110 minio-backup-app.internal.freddrake.com"
        "192.168.50.150 k8s-ingress.internal.freddrake.com"
        "192.168.50.150 argocd.internal.freddrake.com"
        "192.168.50.150 grafana.internal.freddrake.com"
        "192.168.50.150 longhorn.internal.freddrake.com"
        "192.168.50.150 nodered.internal.freddrake.com"
        "192.168.50.150 paperless.internal.freddrake.com"
        "192.168.50.150 prometheus.internal.freddrake.com"
        "192.168.70.10 specops.internal.freddrake.com"
        "192.168.208.1 gateway.internal.freddrake.com"
        "192.168.208.2 larussa.internal.freddrake.com"
        "192.168.208.4 esxi1.internal.freddrake.com"
        "192.168.208.5 nuc9.internal.freddrake.com"
        "192.168.208.6 docker5.internal.freddrake.com"
        "192.168.208.7 pihole1.internal.freddrake.com"
        "192.168.208.7 adguard1.internal.freddrake.com"
        "192.168.208.8 pakedge.internal.freddrake.com"
        "192.168.208.9 pihole2.internal.freddrake.com"
        "192.168.208.9 adguard2.internal.freddrake.com"
        "192.168.208.10 ap-hallway.internal.freddrake.com"
        "192.168.208.11 ap-tv-room.internal.freddrake.com"
        "192.168.208.12 dhcp1.internal.freddrake.com"
        "192.168.208.13 dhcp2.internal.freddrake.com"
        "192.168.208.14 mac-studio-208.internal.freddrake.com"
        "192.168.208.15 larussa-ipmi.internal.freddrake.com"
        "192.168.208.16 orgrimmar.internal.freddrake.com"
        "192.168.208.17 procurve.internal.freddrake.com"
        "192.168.208.18 dalaran.internal.freddrake.com"
        "192.168.208.19 thrall-ipmi.internal.freddrake.com"
        "192.168.208.20 thrall.internal.freddrake.com"
        "192.168.208.21 thrall-vmbr3.internal.freddrake.com"
        "192.168.208.22 khadgar.internal.freddrake.com"
        "192.168.208.23 medivh.internal.freddrake.com"
        "192.168.208.24 rp7.internal.freddrake.com"
        "192.168.208.25 gnome.internal.freddrake.com"
        "192.168.208.26 murloc.internal.freddrake.com"
        "192.168.208.27 anduin-ipmi.internal.freddrake.com"
        "192.168.208.28 office-switch.internal.freddrake.com"
        "192.168.208.29 anduin.internal.freddrake.com"
        "192.168.208.30 laisa-bridge-switch.internal.freddrake.com"
        "192.168.208.31 baine-ipmi.internal.freddrake.com"
        "192.168.208.32 baine.internal.freddrake.com"
        "192.168.208.33 backup.internal.freddrake.com"
        "192.168.208.34 docker.internal.freddrake.com"
        "192.168.208.35 sylvanas.internal.freddrake.com"
        "192.168.208.36 sylvanas-idrac.internal.freddrake.com"
        "192.168.208.37 sylvanas-vmbr3.internal.freddrake.com"
        "192.168.208.39 hallway-switch.internal.freddrake.com"
        "192.168.208.40 tvroom-switch.internal.freddrake.com"
        "192.168.208.41 omada-app.internal.freddrake.com"
        ""
      ];
      dhcp = {
        enabled = false;
        interface_name = "";
        local_domain_name = "lan";
        dhcpv4 = {
          gateway_ip = "";
          subnet_mask = "";
          range_start = "";
          range_end = "";
          lease_duration = 86400;
          icmp_timeout_msec = 1000;
          options = [];
        };
        dhcpv6 = {
          range_start = "";
          lease_duration = 86400;
          ra_slaac_only = false;
          ra_allow_slaac = false;
        };
      };
      filtering = {
        blocking_ipv4 = "";
        blocking_ipv6 = "";
        blocked_services = {
          schedule = {time_zone = "UTC";};
          ids = [];
        };
        protection_disabled_until = null;
        safe_search = {
          enabled = false;
          bing = true;
          duckduckgo = true;
          ecosia = true;
          google = true;
          pixabay = true;
          yandex = true;
          youtube = true;
        };
        blocking_mode = "default";
        parental_block_host = "family-block.dns.adguard.com";
        safebrowsing_block_host = "standard-block.dns.adguard.com";
        rewrites = [];
        safe_fs_patterns = ["/var/lib/private/AdGuardHome/userfilters/*"];
        safebrowsing_cache_size = 1048576;
        safesearch_cache_size = 1048576;
        parental_cache_size = 1048576;
        cache_time = 30;
        filters_update_interval = 24;
        blocked_response_ttl = 10;
        filtering_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = false;
        protection_enabled = true;
      };
      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
          hosts = true;
        };
        persistent = [
          {
            name = "Testing";
            ids = [
              "192.168.208.250"
              "192.168.208.248"
            ];
            tags = [];
            upstreams = [];
            uid = "019552db-d957-7480-a29e-7e712c1d0c27";
            safe_search.enabled = false;
            blocked_services = {
              schedule.time_zone = "UTC";
              ids = [];
            };
            upstreams_cache_size = 0;
            upstreams_cache_enabled = false;
            use_global_settings = false;
            filtering_enabled = false;
            parental_enabled = false;
            safebrowsing_enabled = false;
            use_global_blocked_services = false;
            ignore_querylog = false;
            ignore_statistics = false;
          }
        ];
      };
      log = {
        enabled = true;
        file = "";
        max_backups = 0;
        max_size = 100;
        max_age = 3;
        compress = false;
        local_time = false;
        verbose = false;
      };
      os = {
        group = "";
        user = "";
        rlimit_nofile = 0;
      };
      schema_version = 29;
    };
  };
}
