# Migration: nixarr → podman containers (ironforge)

**Goal:** Replace the `nixarr` NixOS module on `ironforge` with independently-pinned
podman containers (LinuxServer.io images), using this repo's existing podman patterns.
**Hard requirement: preserve all existing data for every service** (app config,
databases, indexers, quality profiles, watch history, media library).

This is a self-contained brief for a new session. Read it top to bottom before
making changes. Work **one service at a time** with verification + rollback.

---

## Why we're doing this

nixarr bundles the *arr stack as a single fast-moving flake that pins its own
nixpkgs. On 2026-05-19 a ~6-month upstream jump (`7cc52193`→`3bde55fe`) shipped a
new `nixarr_py` library whose Python dependency metadata fails nixpkgs'
`pythonRuntimeDepsCheckHook`, breaking the entire ironforge build. We currently
work around it with a `dontCheckRuntimeDeps` override in
`modules/services/media-server.nix`. We don't use nixarr's headline feature (VPN
namespace confinement — there's no torrent client, sabnzbd is usenet), so the
integrated module buys us little while coupling us to its churn. Containers
decouple each app onto its own pinned digest and fit our existing podman tooling.

---

## Current state (facts gathered from ironforge 2026-05-30)

Host: `ironforge` (Hetzner dedicated, `root@10.1.1.3:2222`, `buildOnTarget = true`,
nixpkgs-stable / NixOS 25.05, x86_64-linux).

Defined in `modules/services/media-server.nix` (imported by
`colmena/hosts/ironforge.nix`). nixarr options: `mediaDir = /data/media`,
`stateDir = /data/.state/nixarr`.

### Services, ports, current run-as identity, and config location

| Service    | Web port | Runs as (uid:gid)  | Config dir (PRESERVE)                  | Notes |
|------------|----------|--------------------|----------------------------------------|-------|
| jellyfin   | 8096     | jellyfin 146 : media 169 | `/data/.state/nixarr/jellyfin`   | has config/ data/ cache/ metadata; biggest dir |
| sonarr     | 8989     | sonarr 274 : media 169   | `/data/.state/nixarr/sonarr`     | config.xml + sonarr.db |
| radarr     | 7878     | radarr 275 : media 169   | `/data/.state/nixarr/radarr`     | config.xml + radarr.db |
| lidarr     | 8686     | lidarr 306 : media 169   | `/data/.state/nixarr/lidarr`     | config.xml + lidarr.db |
| prowlarr   | 9696     | prowlarr 293 : prowlarr 287 | `/data/.state/nixarr/prowlarr` | indexers live here; pushes to the *arrs |
| bazarr     | 6767     | bazarr 232 : media 169   | `/data/.state/nixarr/bazarr`     | subtitle config + db |
| sabnzbd    | 6336     | sabnzbd 38 : media 169   | `/data/.state/nixarr/sabnzbd`    | `sabnzbd.ini` (usenet) |
| seerr      | 5055     | seerr 262 : seerr 250    | `/data/.state/nixarr/seerr`      | was "jellyseerr", renamed upstream |
| recyclarr  | (none)   | recyclarr : root         | `/data/.state/nixarr/recyclarr`  | quality-profile sync; config inline in media-server.nix |

Also under `/data/.state/nixarr/`: `api-keys/` and `secrets/` (nixarr-managed
sops API keys used by its settings-sync — see "Settings sync" below).

### Storage (host-level CIFS mounts → keep as-is, bind into containers)

| Mount point             | Backing (Hetzner storage box) | Options |
|-------------------------|-------------------------------|---------|
| `/data/media`           | `//…/u543742-sub2`            | autofs, uid=0 gid=169, file/dir_mode=0775, mapposix, wsize=1MiB |
| `/mnt/downloads-storage`| `//…/u543742-sub6`            | autofs, uid=0 gid=169, file/dir_mode=0775, mapposix, wsize=1MiB |

These come from `lib/mk-cifs-mount.nix` (`videos`/sub2 and `downloads`/sub6) in
the current module. **Keep these `mkCifsMount` calls unchanged** in the new module;
just bind-mount the paths into containers. CIFS cannot `chmod` — this is why the
current config has a sabnzbd `permissions =` fixup. Containers solve this with
`UMASK` + matching `PGID`, not chmod.

### Custom behavior currently in media-server.nix to carry over

- nginx reverse proxies for each web UI via `lib/mk-nginx-proxy.nix`
  (300s timeouts, `client_max_body_size 0`), hostnames `*.${domain}`.
- `MemoryHigh` caps: jellyfin 4G, sabnzbd 2G (memory-constrained 7.6 GiB host).
- sabnzbd `cache_limit = 256M` fixup + the `permissions =` blanking (CIFS).
- `sabnzbd-healthcheck` oneshot + 5-min timer (restarts stuck downloads).
- `users.groups.media.gid = 169`.

---

## Target architecture

Mirror the `orgrimmar` pattern (see `modules/services/resume.nix` as the
reference implementation):

- `virtualisation.oci-containers.backend = "podman"`, one container per app.
- Images pinned via the fetcher: add to `apps/fetcher/containers.toml`, run
  `just update-claude`/the container updater to regenerate
  `apps/fetcher/containers-sha.nix`, reference by digest. **Pin digests; never
  track `latest` for a media stack.**
- Shared podman network via `lib/mk-podman-network.nix` (e.g. `"media"`) so
  prowlarr/recyclarr/bazarr can reach the *arrs by container name.
- Reverse proxies via `lib/mk-nginx-proxy.nix` (reuse current settings).
- Publish each web port to `127.0.0.1:<port>` only; nginx terminates TLS.
- `MemoryHigh` caps via `systemd.services."podman-<name>".serviceConfig`
  (oci-containers are systemd units, so this still works).

### Images (LinuxServer.io unless noted)

| Service   | Image |
|-----------|-------|
| jellyfin  | `ghcr.io/linuxserver/jellyfin` (or `docker.io/jellyfin/jellyfin`) |
| sonarr    | `ghcr.io/linuxserver/sonarr` |
| radarr    | `ghcr.io/linuxserver/radarr` |
| lidarr    | `ghcr.io/linuxserver/lidarr` |
| prowlarr  | `ghcr.io/linuxserver/prowlarr` |
| bazarr    | `ghcr.io/linuxserver/bazarr` |
| sabnzbd   | `ghcr.io/linuxserver/sabnzbd` |
| seerr     | `docker.io/fallenbagel/jellyseerr` (LS has no image; this is the maintained one) |
| recyclarr | `ghcr.io/recyclarr/recyclarr` |

LinuxServer images take `PUID`, `PGID`, `TZ`, `UMASK`. Map the app's data to
`/config`, media to `/data/media` (or `/media`), downloads to the downloads path.

---

## Data preservation strategy (the critical part)

**Principle:** each app's existing config dir under `/data/.state/nixarr/<svc>`
becomes that container's `/config`. We do not recreate config — we adopt it.

### Ownership: unify on one PUID:PGID

LinuxServer apps don't need the per-service UIDs nixarr used (146/274/275/…).
Pick a single identity for the containerized stack and chown each config dir to
it **once**, before first container start:

- `PGID = 169` (the existing `media` group — CIFS mounts are already `gid=169`,
  mode 0775, so group members can read/write media + downloads).
- `PUID =` a chosen uid that is a member of gid 169. Simplest: reuse one existing
  uid (e.g. keep per-app, or pick a single `media` user). A single shared PUID
  across all *arr containers is fine and simplifies permissions.

Per service, the one-time adoption (do while the service/container is stopped):

```bash
# example for sonarr; repeat per service with its dir
install -d -o <PUID> -g 169 /data/.state/nixarr/sonarr
chown -R <PUID>:169 /data/.state/nixarr/sonarr
```

**Do NOT** `chown -R` the CIFS mounts (`/data/media`, `/mnt/downloads-storage`) —
they're remote, already gid 169 / 0775, and a recursive chown over CIFS is slow
and pointless. Use `UMASK=002` on the containers so new files are group-writable.

### Internal layout caveat (verify per app)

LinuxServer `/config` expects the app's files at the root of `/config`
(`config.xml`, `<app>.db` for the *arrs; `config/`,`data/`,`cache/`,`metadata/`
for jellyfin). nixarr generally stores them the same way, but **verify each app's
config dir layout matches what the image expects before cutting over** — if an app
nests its data one level deeper, bind that subdir as `/config` instead. Confirm by
listing the dir (`ls -la /data/.state/nixarr/<svc>`) and checking the app's docs.

### Keep a rollback copy

Before touching a service's data, snapshot it:

```bash
cp -a --reflink=auto /data/.state/nixarr/<svc> /data/.state/nixarr/<svc>.pre-podman
```

(ironforge `/` is ext4; `--reflink=auto` falls back to a full copy. jellyfin's dir
may be large — check space first, `df -h /`.)

---

## Per-service container spec (volume mapping)

| Service  | `/config` ← (host)                | media/downloads binds | extra |
|----------|-----------------------------------|-----------------------|-------|
| jellyfin | `/data/.state/nixarr/jellyfin`    | `/data/media:/data/media` (ro ok) | `/dev/dri` only if HW transcoding (see gotchas) |
| sonarr   | `/data/.state/nixarr/sonarr`      | `/data/media`, `/mnt/downloads-storage` | |
| radarr   | `/data/.state/nixarr/radarr`      | `/data/media`, `/mnt/downloads-storage` | |
| lidarr   | `/data/.state/nixarr/lidarr`      | `/data/media`, `/mnt/downloads-storage` | |
| prowlarr | `/data/.state/nixarr/prowlarr`    | (none needed) | talks to *arrs over the podman net |
| bazarr   | `/data/.state/nixarr/bazarr`      | `/data/media` | needs same media paths as sonarr/radarr |
| sabnzbd  | `/data/.state/nixarr/sabnzbd`     | `/mnt/downloads-storage` | usenet; see cache_limit gotcha |
| seerr    | `/data/.state/nixarr/seerr`       | (none) | env `LOG_LEVEL`, port 5055 |
| recyclarr| `/data/.state/nixarr/recyclarr`   | (none) | config from inline nixarr block → recyclarr.yml |

**Path consistency matters for the *arrs:** sonarr/radarr/bazarr and sabnzbd must
see the *same* media/downloads paths inside the container as they have recorded in
their DBs, or imports/hardlinks break. Bind them at the **same absolute paths**
(`/data/media`, `/mnt/downloads-storage`) inside every container. Confirm the
recorded root-folder/download-client paths in each app match after cutover.

---

## Settings sync (prowlarr / recyclarr)

nixarr's declarative settings-sync (`nixarr-sync-*`, the `api-keys`/`secrets`
dirs) is what tripped the build. Replace it with native tooling:

- **Prowlarr → *arrs:** native Prowlarr feature. In Prowlarr's UI add each *arr
  as an "App" (Settings → Apps) with its URL (`http://sonarr:8989` on the podman
  net) and API key. Prowlarr then pushes indexers automatically. No nix needed.
- **recyclarr:** runs as its own container on a timer/cron. Convert the inline
  `recyclarr.configuration` (currently in media-server.nix: sonarr+radarr
  base_urls with `!env_var *_API_KEY`) into a `recyclarr.yml` mounted into the
  container; inject API keys via env/secret. API keys are in each *arr's
  `config.xml` (preserved in `/config`).

---

## Migration procedure (phased, per-service, reversible)

Do the **least-risky, lowest-dependency** services first to build confidence;
leave prowlarr/sonarr/radarr (the interconnected core) for when the pattern is
proven. Suggested order: **bazarr or seerr → sabnzbd → lidarr → sonarr → radarr →
prowlarr → jellyfin** (jellyfin last; biggest data, most user-visible).

For each service:

1. **Write the container** in the new module (copy the shape from `resume.nix`):
   image (pinned), `PUID/PGID/TZ/UMASK`, `/config` + media binds, network,
   `127.0.0.1:<port>` publish, nginx proxy, MemoryHigh if applicable.
2. **Disable** that service in the nixarr block (e.g. `sonarr.enable = false`) in
   the same commit so they don't both claim the port/data.
3. **Stop + snapshot + chown** on the host (service is being removed anyway):
   ```bash
   systemctl stop sonarr      # old nixarr unit
   cp -a /data/.state/nixarr/sonarr /data/.state/nixarr/sonarr.pre-podman
   chown -R <PUID>:169 /data/.state/nixarr/sonarr
   ```
4. **Deploy** (`colmena apply --on ironforge --impure` — builds on target).
5. **Verify:** container active (`systemctl status podman-sonarr`), web UI loads
   via nginx, the app shows its **existing** indexers/profiles/library/history,
   root-folder + download-client paths intact, a test grab imports correctly.
6. **Rollback if needed:** re-enable the nixarr service, restore
   `<svc>.pre-podman`, redeploy.
7. Once confident, delete the `.pre-podman` snapshot.

Tackle one service per deploy. Don't batch the whole stack in one shot.

---

## Gotchas / carry-overs

- **CIFS can't chmod.** Don't rely on the app chowning media. Use `UMASK=002`
  and `PGID=169`. The old sabnzbd `permissions =` fixup is no longer needed once
  sabnzbd runs as PGID 169 with UMASK 002.
- **sabnzbd memory.** Keep `cache_limit = 256M` (set it in sabnzbd.ini, preserved
  in /config) and cap the container: `systemd.services."podman-sabnzbd".serviceConfig.MemoryHigh = "2G"`.
- **jellyfin memory.** `MemoryHigh = "4G"` via the podman-jellyfin systemd unit.
- **sabnzbd healthcheck.** The existing oneshot + 5-min timer can stay almost
  verbatim — it queries the API on `127.0.0.1:6336` and `systemctl restart`s.
  Point it at `podman-sabnzbd.service` and read the api key from the (now
  container-mounted) `sabnzbd.ini`.
- **jellyfin hardware transcoding.** If currently used, pass `/dev/dri` into the
  container and add the `render`/`video` gid. On this Hetzner box you're likely
  software-transcoding (no iGPU) — confirm in Jellyfin → Dashboard → Playback
  before assuming; if SW, skip device passthrough.
- **seerr rename.** Already migrated under nixarr (jellyfin-seerr). Its config is
  in `…/seerr`; the container is `fallenbagel/jellyseerr`, port 5055.
- **Inter-container DNS.** With a shared podman network, apps reach each other by
  container name (`http://sonarr:8989`). Update Prowlarr "Apps" and recyclarr/
  bazarr to use those names, not `127.0.0.1`.
- **Don't track `latest`.** Pin every image by digest via the fetcher so a deploy
  never silently pulls a breaking version (the whole point of this migration).

---

## Decommission nixarr (after all services migrated + verified)

1. Remove the `nixarr` block, the `nixarr.nixarr-py.package` override, and the
   `nixarr` flake input usage from `colmena/hosts/ironforge.nix` (the
   `nixarr.nixosModules.default` import and the `nixarr` arg in
   `colmena/default.nix`).
2. Drop the `nixarr` input from `flake.nix` / `flake.lock` (`nix flake lock`).
3. Keep `users.groups.media.gid = 169` and the `mkCifsMount` calls.
4. Final `colmena apply --on ironforge`; confirm no leftover nixarr units and all
   container web UIs healthy.
5. After a confidence window, remove `/data/.state/nixarr/{api-keys,secrets}` and
   any `.pre-podman` snapshots.

---

## Repo references to copy from

- `modules/services/resume.nix` — canonical multi-container service: oci-containers,
  pinned digest, podman network, nginx proxy, sops env, 127.0.0.1 publish.
- `lib/mk-podman-network.nix`, `lib/mk-nginx-proxy.nix`, `lib/mk-cifs-mount.nix`.
- `apps/fetcher/containers.toml` (+ `containers-sha.nix`) — image pinning.
- `colmena/hosts/orgrimmar.nix` — a Hetzner host running a podman service stack.
- Current `modules/services/media-server.nix` — source of truth for ports, nginx
  settings, memory caps, the sabnzbd healthcheck, and CIFS mount definitions.

---

## Implementation log (2026-05-30)

### Mechanism implemented: the `migrated` toggle

`modules/services/media-server.nix` now carries one source of truth:

```nix
migrated = ["bazarr"];          # add a service name here to flip it to podman
isPodman = name: builtins.elem name migrated;
isNixarr = name: !(isPodman name);
```

- Each `nixarr.<svc>.enable = isNixarr "<svc>"`; the sabnzbd/jellyfin systemd
  customizations and the sabnzbd healthcheck/timer are also guarded by
  `isNixarr`, so they vanish automatically as those services are migrated.
- An `mkLs` LinuxServer container factory builds each container (shared identity,
  `/config` adoption, media binds). `containerDefs` holds the per-service specs;
  only `migrated` services are activated via `lib.filterAttrs`, along with the
  `media-net` podman network (`mkPodmanNetwork`).
- nginx proxies are emitted for ALL services regardless of backend — both nixarr
  and the containers publish on `127.0.0.1:<port>`, so the proxy target is
  identical and the cutover is transparent to nginx.
- **To migrate the next service:** add its name to `migrated`, add its `mkLs`
  spec to `containerDefs`, run the runbook below. Service name == its config dir
  under `/data/.state/nixarr/<name>` (so `seerr`, not `jellyseerr`).

Shared identity: a `media` user (uid 169) was added to match the existing `media`
group (gid 169). LinuxServer containers run `PUID=169 PGID=169 UMASK=002`.

### Verified live facts (ironforge, gathered 2026-05-30)

Re-verify the per-service ones at migration time; they drive correctness.

- `/` has ~22 GiB free; total nixarr state ≈ 1.1 GiB (jellyfin 648 MiB largest),
  so `.pre-podman` snapshots are cheap.
- Per-app uids (jellyfin 146, sonarr 274, radarr 275, lidarr 306, prowlarr 293,
  bazarr 232, sabnzbd 38, seerr 262) all become irrelevant — unify on 169.
- **sabnzbd writes to `/data/media`, NOT `/mnt/downloads-storage`.** complete=
  `/data/media/usenet/manual`, incomplete=`/data/media/usenet/.incomplete`,
  categories tv/movies/music/prowlarr under `/data/media/usenet/<cat>`. The *arr +
  sabnzbd containers must bind `/data/media`. `/mnt/downloads-storage` (sub6)
  appears unused by the current config; bind it anyway for safety.
- **sabnzbd.ini has `host = 127.0.0.1`** → container loopback, unreachable from a
  published port. When migrating sabnzbd, set `host = 0.0.0.0` in sabnzbd.ini.
- **No HW transcoding in use:** `encoding.xml` has `HardwareAccelerationType=none`
  (despite `/dev/dri/renderD128` existing). Jellyfin container needs **no
  `/dev/dri` passthrough** to preserve current behavior. Re-check the dashboard
  before migrating jellyfin in case that changed.
- bazarr had `use_sonarr: false` / `use_radarr: false` — no live *arr integration,
  which is why it was the safe first pilot (zero container→host dependencies).
- podman is 5.4.1 (supports `host.containers.internal`).
- Config dir layouts match LinuxServer `/config` expectations: *arrs = `config.xml`
  + `<app>.db` at root; jellyfin = `config/ data/ cache/ log/`; bazarr = `config/
  db/ log/ cache/ backup/ restore/`; sabnzbd = `sabnzbd.ini` + `admin/`; seerr =
  `settings.json` + `db/` + `cache/` → mount at **`/app/config`** (not `/config`)
  and run with `--user 169:169` (jellyseerr is not an LS image; it ignores
  PUID/PGID — `mkLs`'s `user` arg handles this).

### Per-service specs for the remaining 8 (verify at migration time)

Order, lowest cross-dependency first: **sabnzbd → seerr → lidarr → sonarr →
radarr → prowlarr → recyclarr → jellyfin**. While the *arrs are still on nixarr,
container→host calls use `host.containers.internal`; once both ends are
containers they use the container name over `media-net`.

| Svc | image (`containers-sha`) | mounts | port | extras |
|-----|--------------------------|--------|------|--------|
| sabnzbd | `ghcr.io`/`linuxserver/sabnzbd` | `/config`, `/data/media` | 6336 | set ini `host=0.0.0.0`; `MemoryHigh=2G`; the cache/permissions fixup + healthcheck are already `isNixarr "sabnzbd"`-guarded — re-point healthcheck at `podman-sabnzbd` and read the api key from the mounted ini |
| seerr | `docker.io`/`fallenbagel/jellyseerr` | `/app/config` | 5055 | `mkLs { user = "169:169"; configMount = "/app/config"; }`; nginx host stays `jellyseerr` |
| lidarr | `ghcr.io`/`linuxserver/lidarr` | `/config`, `/data/media` | 8686 | |
| sonarr | `ghcr.io`/`linuxserver/sonarr` | `/config`, `/data/media` | 8989 | |
| radarr | `ghcr.io`/`linuxserver/radarr` | `/config`, `/data/media` | 7878 | |
| prowlarr | `ghcr.io`/`linuxserver/prowlarr` | `/config` | 9696 | after cutover set its Apps to `http://sonarr:8989` etc. on media-net |
| recyclarr | `ghcr.io`/`recyclarr/recyclarr` | `/config` | (none) | the inline nixarr block had only sonarr+radarr instances and no templates; author a `recyclarr.yml`, inject `*_API_KEY` via env, run on a timer |
| jellyfin | `ghcr.io`/`linuxserver/jellyfin` | `/config`, `/data/media` | 8096 | `MemoryHigh=4G`; NO `/dev/dri`; biggest data — do last |

All 9 images are pinned by digest in `apps/fetcher/containers.toml` +
`containers-sha.nix` (regenerated with `update-container-digests`).

### Per-service deploy runbook (proven on bazarr)

1. Edit `media-server.nix`: add name to `migrated`; add `mkLs` spec to `containerDefs`.
2. `colmena build --on ironforge --impure` (builds on target, no activation).
3. Host prep (the service is being removed from nixarr anyway):
   ```bash
   systemctl stop <svc>
   cp -a /data/.state/nixarr/<svc> /data/.state/nixarr/<svc>.pre-podman
   chown -R 169:169 /data/.state/nixarr/<svc>
   ```
4. `colmena apply --on ironforge --impure`. **ironforge does not auto
   restart/reload units on activation** ("activation left incomplete" warning is
   normal) — then on the host: `systemctl daemon-reload && systemctl start
   podman-network-media.service podman-<svc>.service`.
5. Verify: `systemctl is-active podman-<svc>`; HTTP 200 on `127.0.0.1:<port>` and
   via nginx; `podman exec <svc> id abc` → `169` (allow a few seconds for the LS
   startup remap); existing db/settings present and owned 169:169; a write to
   `/data/media` succeeds; `podman logs <svc>` clean. Tidy any `1000:1000` temp
   files the LS init writes before remapping.
6. Rollback: remove name from `migrated`, restore `<svc>.pre-podman`, redeploy.
   Delete the snapshot once confident.

### Status

- [x] All 9 media images pinned by digest in the fetcher.
- [x] Shared `media` user/identity + `media-net` + `mkLs` factory + toggle.
- [x] ironforge builds cleanly with the new module (the existing `nixarr-py`
      `dontCheckRuntimeDeps` override remains necessary while nixarr stays
      enabled for not-yet-migrated services).
- [x] **bazarr migrated & verified live** (direct + nginx HTTP 200; runs as 169;
      `bazarr.db` adopted; CIFS write OK; logs clean). Snapshot
      `/data/.state/nixarr/bazarr.pre-podman` retained.
- [x] **sabnzbd migrated & verified live** (direct + nginx HTTP 200; runs as 169;
      downloads dir `/data/media/usenet/.incomplete` visible; CIFS write OK;
      `MemoryHigh=2G` on `podman-sabnzbd`; healthcheck refactored to a
      backend-parameterized helper, `After=podman-sabnzbd`, restarts
      `podman-sabnzbd`, ran once → "SABnzbd healthy"; timer active).
      cache_limit/permissions now live in the preserved ini (no ExecStartPre).
      Snapshot `/data/.state/nixarr/sabnzbd.pre-podman`.
      **Listen-host note:** the manual `sabnzbd.ini` `host` edit was NOT needed —
      the LinuxServer image sets its own listen host (`::`) at startup, so the
      published `127.0.0.1:6336` reaches it (proven by the HTTP 200s). The plan's
      "set host=0.0.0.0" step can be skipped for sabnzbd; if a future LS image
      changes this and the published port returns nothing, set `host = 0.0.0.0`
      in the preserved ini and restart `podman-sabnzbd`.
- [x] **seerr migrated & verified live** (`fallenbagel/jellyseerr`, not an LS
      image: mounted at `/app/config`, run via `mkLs { user = "169:169"; }` with
      no PUID/PGID env). Direct + nginx HTTP 200 (nginx host stays `jellyseerr`);
      container `id` → `uid=169 gid=169`; `db/db.sqlite3` adopted and being
      written; no non-169 writes; log "Server ready on port 5055"; API
      `/api/v1/status` → `{"version":"2.7.3",…}` (app + adopted db alive). The old
      nixarr unit was `seerr.service` (option `nixarr.seerr.enable`, dir `…/seerr`,
      nginx host `jellyseerr`). Snapshot `/data/.state/nixarr/seerr.pre-podman`.
      Note: needs the same post-apply `systemctl daemon-reload && systemctl start
      podman-seerr` as the others (ironforge doesn't auto-start new units).
      **Container→host DNS gotcha (important, applies to every cross-service
      call):** seerr stores its Jellyfin/Sonarr/Radarr connections as the public
      FQDNs (`jellyfin.internal.freddrake.com` etc.) over HTTPS:443. Those names
      only resolve to `127.0.0.1` via the host's `/etc/hosts` — meaningless inside
      a container, whose resolver is podman aardvark-dns. Symptom: "Unable to
      connect to Jellyfin server" on login. Fix: add
      `--add-host=<svc>.<domain>:host-gateway` for each FQDN the container calls
      (host-gateway → `10.89.0.1`, the media-net gateway = host's nginx, which
      terminates TLS and proxies to the app). seerr's `mkLs` now maps jellyfin +
      sonarr + radarr this way. **An oci-container `extraOptions` change recreates
      the container but ironforge won't auto-restart it — `systemctl restart
      podman-seerr` after apply.** As each target moves onto media-net, drop its
      add-host entry and repoint seerr at the container name instead.
- [x] **lidarr migrated & verified live** (LS *arr; `/config` + `/data/media`,
      port 8686). podman active; nixarr lidarr gone; runs as 169; HTTP 302 direct
      / 200 via nginx; `lidarr.db` adopted + written; no non-169 writes; media
      write OK; log clean. Snapshot `/data/.state/nixarr/lidarr.pre-podman`.
      **Download-client repoint (per-app DB, not Nix):** its SABnzbd client was
      stored as `sabnzbd.internal.freddrake.com:443 ssl=true`, which resolves to
      127.0.0.1 inside the container (the /etc/hosts propagation gotcha). Since
      sabnzbd is now a container on media-net, the target is the bare container
      name `host=sabnzbd port=6336 useSsl=false`. **Prerequisite:** sabnzbd's
      `host_whitelist` (preserved in sabnzbd.ini, was just
      `sabnzbd.internal.freddrake.com`) rejects a `Host: sabnzbd` request with
      403 — so add `sabnzbd` (the container name) to `host_whitelist` and restart
      `podman-sabnzbd` BEFORE the *arr will accept the client (lidarr
      tests-before-save, so a 403 makes the PUT 400). This media-net repoint is
      the preferred fix when both ends are containers (direct, no hairpin through
      host nginx), vs the `--add-host …:host-gateway` used for seerr→jellyfin
      while jellyfin is still on the host. sonarr/radarr will need the same
      repoint + the same whitelist entry already in place.
- [x] **sonarr migrated & verified live** (LS *arr; `/config` + `/data/media`,
      port 8989). podman active; nixarr sonarr gone; runs as 169; HTTP 302 direct
      / via nginx; `sonarr.db` adopted + written; no non-169 writes; media write
      OK. Snapshot `/data/.state/nixarr/sonarr.pre-podman`. SABnzbd download
      client repointed `sabnzbd.internal.freddrake.com:443 ssl` → `sabnzbd:6336`
      plaintext via API v3 (test 200, PUT 200) — whitelist already had `sabnzbd`
      from the lidarr step.
- [x] **radarr migrated & verified live** (LS *arr; `/config` + `/data/media`,
      port 7878). podman active; nixarr radarr gone; runs as 169; HTTP 302 direct
      / via nginx; `radarr.db` adopted + written; no non-169 writes; media write
      OK; logs clean. Snapshot `/data/.state/nixarr/radarr.pre-podman`. SABnzbd
      download client repointed to `sabnzbd:6336` plaintext (stored confirmed).
      **Build-blocker hit & resolved (important ordering constraint):** migrating
      radarr removed the LAST of sonarr/radarr from nixarr, which tripped a hard
      nixarr assertion — `nixarr.recyclarr.enable requires at least one of
      nixarr.radarr.enable or nixarr.sonarr.enable`. So **recyclarr must leave
      nixarr no later than the second of {sonarr,radarr} you migrate.** Resolved
      by disabling nixarr recyclarr in the same step (added `recyclarr` to
      `migrated` with no container yet — it's a non-user-facing periodic
      quality-profile sync; its config under `…/recyclarr` is preserved and
      untouched). recyclarr is currently NOT running until containerized (next).
- [x] **recyclarr containerized & verified live** (`ghcr.io/recyclarr/recyclarr`).
      Implemented as a **systemd timer + oneshot `podman run --rm … sync`** (NOT
      an oci-container — recyclarr is a batch tool, not a daemon), `OnCalendar=daily`
      + `RandomizedDelaySec=1h`. Runs on media-net as `--user 169:169`; config is a
      Nix-managed `recyclarr.yml` (mirrors the former inline block: sonarr/radarr
      instances, no templates) mounted read-only over the preserved `/config`.
      API keys are read at start from each *arr's `config.xml` into a tmpfs
      `RuntimeDirectory` env file (mode 0600, auto-removed after the run — never
      in the nix store or `ps`). Manual trigger → `Result=success`, log: "Processing:
      sonarr / Processing: radarr / Sync complete!"; no lingering container; env
      file cleaned; timer active. recyclarr config dir chowned 269→169; snapshot
      `/data/.state/nixarr/recyclarr.pre-podman`.
- [x] **prowlarr migrated & verified live** (LS *arr; `/config` only, no media
      bind; port 9696). podman active; nixarr prowlarr gone; runs as 169; HTTP 200
      direct / via nginx; `prowlarr.db` adopted (owned 169); logs clean (0
      errors/60s after restart). Snapshot `/data/.state/nixarr/prowlarr.pre-podman`.
      **Apps repoint (per-app DB, both URLs):** its 3 Applications (Sonarr/Radarr/
      Lidarr) each stored TWO FQDN URLs — `baseUrl` (prowlarr→arr) and
      `prowlarrUrl` (the address prowlarr pushes into the arr as the indexer
      host). Both resolved to 127.0.0.1 in-container. Repointed via API v1
      (test 201/202, PUT 202): baseUrl → `http://sonarr:8989` / `http://radarr:7878`
      / `http://lidarr:8686`; prowlarrUrl → `http://prowlarr:9696` (all three).
      No useSsl field — the scheme is in the URL string. Triggered
      `ApplicationIndexerSync`; prowlarr health clean; **verified the push landed:
      all 6 sonarr indexers now reference `http://prowlarr:9696`, 0 on the FQDN.**
- [x] **jellyfin migrated & verified live** (LS jellyfin; `/config` +
      `/data/media:ro`; port 8096). podman active; nixarr jellyfin gone; runs as
      169; HTTP 302 direct / via nginx; `System/Info/Public` returns the adopted
      server (ServerName/Id preserved); media library readable read-only inside
      the container (write correctly denied); `MemoryHigh=4G` on podman-jellyfin;
      logs clean; NO `/dev/dri` (software transcoding, unchanged). seerr→jellyfin
      login path still works (resolves via host-gateway to nginx). Snapshot
      `/data/.state/nixarr/jellyfin.pre-podman` (~648 MiB — checked disk first).

**ALL 9 SERVICES MIGRATED.** No nixarr media service units remain active. Running
containers: jellyfin, sonarr, radarr, lidarr, prowlarr, bazarr, sabnzbd, seerr;
timers: recyclarr-sync, sabnzbd-healthcheck. nixarr itself is still enabled in the
module (all `<svc>.enable = isNixarr …` now resolve false) — see decommission
section to remove the nixarr block, the `nixarr-py` override, and the flake input.
- [ ] Decommission nixarr (remove module block + `nixarr-py` override + flake input).
