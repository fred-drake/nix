# Hearthstone — gateway & internal DNS resolver

**Read this first whenever _many_ `*.internal.freddrake.com` names fail at
once** (e.g. "paperless is down" but gitea/jellyfin/gatus are *also*
unreachable). The usual cause is not the individual service — it's the DNS
resolver going offline. The servers behind those names are almost always fine.

## What hearthstone is

| Property | Value |
|----------|-------|
| Role | Home/office gateway router **and** the resolver for the `internal.freddrake.com` zone |
| Device | OpenWrt router |
| SSH | `ssh root@192.168.8.1` (it is the LAN default gateway; **not** in `~/.ssh/config`, **not** colmena-managed) |
| Tailnet | headscale (`headscale.brainrush.ai`), **not** Tailscale SaaS |
| Tailnet IP | `100.64.0.13` — this exact IP matters (see below) |
| headscale node | ID 14, user `fdrake` |
| tailscaled state | `/etc/tailscale/tailscaled.state`; OpenWrt service config via `uci show tailscale` |
| Original `tailscale up` flags | `--advertise-exit-node --accept-routes --accept-dns=false` |

**Why one box failing blackholes the whole internal zone:** the tailnet-wide
split-DNS sends the entire `internal.freddrake.com` domain to hearthstone's
tailnet IP:

```
Split DNS Routes:
  - internal.freddrake.com  ->  100.64.0.13   (hearthstone)
```

(see it locally with `tailscale dns status`). If hearthstone drops off the
tailnet, **every** internal name stops resolving even though the Hetzner boxes
are up. This is why reclaiming the *exact* IP `100.64.0.13` on recovery is
critical — a different IP would require editing the split-DNS config, which
lives in the **separate brainrush repo** on `br-prod-gateway`, not in this one.

Note: the `10.1.0.0/16` Hetzner subnet route is advertised by the *other*
headscale box (`100.64.0.9`), not hearthstone. So when hearthstone is down you
can still reach the Hetzner servers **by IP** — only name resolution is broken.

## Network topology recap

- This Mac is itself a headscale node (`100.64.0.12`, iface `utun10`). Its
  client is the GUI-app variant at `/usr/local/bin/tailscale`, so the daemon
  runs inside the app — `pgrep tailscaled` finds nothing and plain
  `tailscale status` can say "stopped" even when `--json` shows `Running`.
  Trust `tailscale status --json` / `tailscale ip -4`.
- headscale control plane: `headscale.brainrush.ai`, CLI on host
  `br-prod-gateway` (reachable; `headscale` is on PATH there, v0.27.x).
- The internal-DNS dependency means: **if local tailscale is actually down,
  the fleet looks dead but isn't.** Check `tailscale status` locally first.

## Diagnosis (fast path)

```bash
# 1. From the Mac: is it DNS-wide, or one service?
tailscale dns status | grep internal.freddrake.com      # -> 100.64.0.13
tailscale status | grep -i hearthstone                  # offline? last seen?
tailscale ping 100.64.0.13                              # tx but rx 0 = resolver down

# 2. Confirm the servers are actually fine (bypass DNS by IP):
#    orgrimmar=10.1.1.4 ironforge=10.1.1.3 stormwind=10.1.1.5  (all :443)
curl -skL -o /dev/null -w '%{http_code}\n' --max-time 20 \
  --resolve paperless.internal.freddrake.com:443:10.1.1.4 \
  https://paperless.internal.freddrake.com/             # 200 => server fine, DNS is the problem

# 3. Get onto hearthstone and inspect tailscaled:
ssh root@192.168.8.1 "tailscale status; tailscale debug prefs | grep -iE 'ControlURL|LoggedOut|WantRunning'"
```

Two distinct failure signatures seen on hearthstone:

- **State wiped / control URL reset** (what happened 2026-06-23): `ControlURL`
  shows `https://controlplane.tailscale.com` (the Tailscale-SaaS *default*),
  `PrivateNodeKey` zeroed, `BackendState: NeedsLogin`, and the login URL points
  at `login.tailscale.com`. Trigger: the OpenWrt `tailscale` package was
  upgraded (to `1.92.5-1`) and reinitialized `tailscaled.state`. **Do NOT click
  a `login.tailscale.com` URL** — that registers against the wrong control
  plane. The OpenWrt `uci` config stores no `login_server`, so a reset always
  defaults back to Tailscale SaaS.
- **Plain node-key expiry**: `WantRunning: true`, `LoggedOut: false`,
  `NeedsLogin`, but `ControlURL` still headscale. Recovery is the same
  re-register step below.

## Recovery — re-register hearthstone on headscale

1. **Generate a pre-auth key** on the headscale server (`fdrake` is user ID 5):

   ```bash
   ssh br-prod-gateway "headscale preauthkeys create --user 5 --expiration 2h"
   ```

   (`headscale users list` to confirm IDs; the CLI wants the numeric `--user`
   ID, not the name. Beware: its table output is ANSI-colored, so don't pipe it
   through awk and feed the result straight to `--user`.)

2. **Re-auth on hearthstone with the full original flag set.** `tailscale up`
   refuses a partial flag set when prior non-default prefs exist — you must list
   them all (it will print the exact required command if you miss one):

   ```bash
   ssh root@192.168.8.1 "tailscale up \
     --login-server=https://headscale.brainrush.ai \
     --auth-key=<KEY> \
     --advertise-exit-node --accept-routes --accept-dns=false"
   ```

   The machine key normally survives a state reset, so hearthstone reattaches to
   node 14 and **reclaims `100.64.0.13` automatically** — no DNS reconfig
   needed. Verify: `ssh root@192.168.8.1 "tailscale ip -4"` => `100.64.0.13`.

3. **Verify end-to-end from the Mac** over the normal path (no IP hacks):

   ```bash
   tailscale ping 100.64.0.13                                  # pong
   curl -skL -o /dev/null -w '%{http_code}\n' --max-time 20 \
     https://paperless.internal.freddrake.com/                 # 200
   ```

If the IP comes back as something other than `100.64.0.13` (machine key was
also wiped → new node, gets the lowest free IP), either delete the stale node 14
and retry, or update the split-DNS record in the brainrush repo to the new IP.

## Permanent prevention (not yet done)

The OpenWrt `tailscale` package upgrade resetting state is the real trigger, and
the box has no persisted `login_server`. Options to harden: pin/hold the
OpenWrt tailscale package, or persist the login-server + flags so a package
upgrade can't strand the resolver on Tailscale SaaS. Until that's done, expect a
repeat on the next router package upgrade.
