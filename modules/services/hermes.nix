# Hermes Agent (NousResearch) — self-hosted chat agent with persistent memory,
# wired to an Obsidian PKM vault stored in our internal gitea.
#
# Design notes (see also the deploy decisions captured in the PR/commit):
#   - Runs as the published Docker Hub image, digest-pinned via containers-sha.
#   - `gateway run` long-running daemon. CLI/dashboard only — no messaging bots.
#   - LLM provider: DeepSeek (DEEPSEEK_API_KEY, from the sops env file).
#   - NO docker socket and NO docker terminal backend: this box's podman socket
#     is effectively host-root (it controls gitea/CI/paperless). Hermes uses its
#     `local` backend, so the agent only ever runs commands inside its own
#     container — no host-container access.
#   - Dashboard binds loopback (127.0.0.1:9119) and is exposed only behind the
#     nginx TLS vhost hermes.<domain>, protected by Hermes' own basic auth
#     (HERMES_DASHBOARD_BASIC_AUTH_* live in the sops env file).
#   - Obsidian vault: a host-side systemd timer git-syncs the internal gitea repo
#     into /var/hermes/vault (read+write, auto-commit back). The gitea SSH key
#     lives ONLY in the sync service — it is never exposed to the agent.
{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};

  host = "hermes";
  dashboardPort = "9119";
  domain = config.soft-secrets.networking.domain;

  # Shared identity for the Hermes container (HERMES_UID/GID) and the host-side
  # vault sync service, so bind-mounted vault files have one consistent owner.
  hermesUid = 10000;
  hermesGid = 10000;

  dataDir = "/var/hermes";
  vaultDir = "${dataDir}/vault";

  # The internal gitea repo holding the Obsidian vault. Git-over-SSH reaches the
  # gitea container on :22 (gitea.<domain> -> 10.1.1.4 via networking.extraHosts).
  vaultRepo = "git@gitea.${domain}:fdrake/PKM-Personal.git";

  sshKey = config.sops.secrets.hermes-vault-ssh-key.path;
  knownHosts = "${dataDir}/.ssh/known_hosts";

  vaultSyncScript = pkgs.writeShellScript "hermes-vault-sync" ''
    set -euo pipefail
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i ${sshKey} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=${knownHosts}"
    git=${pkgs.git}/bin/git

    if [ ! -d ${vaultDir}/.git ]; then
      echo "Cloning vault from ${vaultRepo} ..."
      $git clone ${vaultRepo} ${vaultDir}
    fi

    cd ${vaultDir}
    $git config user.name "Hermes Agent"
    $git config user.email "hermes@${domain}"

    # Pull first; rebase local agent edits on top. Abort on conflict rather than
    # risk clobbering hand-authored notes — a human resolves and the next tick
    # recovers.
    if ! $git pull --rebase --autostash; then
      echo "ERROR: vault pull/rebase hit a conflict; leaving working tree for manual resolution" >&2
      $git rebase --abort 2>/dev/null || true
      exit 1
    fi

    # Commit + push any agent-authored changes.
    if [ -n "$($git status --porcelain)" ]; then
      $git add -A
      $git commit -m "hermes vault autosync"
      $git push
      echo "Pushed vault changes."
    else
      echo "Vault clean; nothing to push."
    fi
  '';
in
  lib.mkMerge [
    (mkNginxProxy {
      inherit host;
      port = dashboardPort;
    })
    {
      # Shared system identity for the container and the vault sync service.
      users.groups.hermes.gid = hermesGid;
      users.users.hermes = {
        isSystemUser = true;
        uid = hermesUid;
        group = "hermes";
        home = dataDir;
        description = "Hermes Agent service identity";
      };

      sops.secrets = {
        # Created in nix-secrets: DEEPSEEK_API_KEY, API_SERVER_KEY,
        # HERMES_DASHBOARD_BASIC_AUTH_USERNAME/PASSWORD/SECRET.
        hermes-env = {
          sopsFile = config.secrets.host.orgrimmar.hermes-env;
          mode = "0400";
          key = "data";
        };
        # ed25519 private key for the gitea vault repo. Read only by the
        # (hermes-owned) sync service — never mounted into the agent container.
        hermes-vault-ssh-key = {
          sopsFile = config.secrets.host.orgrimmar.hermes-vault-key;
          mode = "0400";
          owner = "hermes";
          key = "data";
        };
      };

      systemd = {
        tmpfiles.rules = [
          "d ${dataDir} 0750 ${toString hermesUid} ${toString hermesGid} -"
          "d ${dataDir}/.ssh 0700 ${toString hermesUid} ${toString hermesGid} -"
          "d ${vaultDir} 0750 ${toString hermesUid} ${toString hermesGid} -"
        ];

        services.hermes-vault-sync = {
          description = "Sync Hermes Obsidian vault with internal gitea";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          path = [pkgs.git pkgs.openssh];
          serviceConfig = {
            Type = "oneshot";
            User = "hermes";
            Group = "hermes";
            ExecStart = vaultSyncScript;
          };
        };
      };

      systemd.timers.hermes-vault-sync = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "10min";
          Persistent = true;
        };
      };

      virtualisation.oci-containers = {
        backend = "podman";
        containers.hermes = {
          image = containers-sha."docker.io"."nousresearch/hermes-agent"."v2026.6.19"."linux/amd64";
          autoStart = true;
          # NixOS oci-containers uses `cmd` (NOT `command`) for the args passed
          # to the image entrypoint. Without this the image runs its default
          # interactive `hermes` CLI, which exits immediately on a non-TTY stdin
          # ("Input is not a terminal. Goodbye!") and the container flaps.
          cmd = ["gateway" "run"];
          # All state (config.yaml, memory, skills, sessions) lives under
          # /opt/data; the vault is bind-mounted in for the Obsidian skill.
          volumes = [
            "${dataDir}:/opt/data"
            "${vaultDir}:/opt/data/vault"
          ];
          environment = {
            TZ = "America/New_York";
            HERMES_UID = toString hermesUid;
            HERMES_GID = toString hermesGid;
            # Dashboard fronted by nginx + Hermes basic auth. Bind 0.0.0.0
            # *inside the container* so podman's published port can reach it
            # (podman forwards the published port to the container's eth0, not
            # its loopback). The host publish below pins it to 127.0.0.1, so it
            # stays private to the host and is only reachable via the nginx vhost.
            HERMES_DASHBOARD = "1";
            HERMES_DASHBOARD_HOST = "0.0.0.0";
            HERMES_DASHBOARD_PORT = dashboardPort;
            # Local OpenAI-compatible API the dashboard talks to; loopback only,
            # key supplied via the env file. Not published off-box.
            API_SERVER_ENABLED = "true";
            API_SERVER_HOST = "127.0.0.1";
            # Bundled Obsidian skill reads/writes markdown here.
            OBSIDIAN_VAULT_PATH = "/opt/data/vault";
          };
          environmentFiles = [config.sops.secrets.hermes-env.path];
          # Dashboard only; gateway makes outbound connections, no inbound ports.
          ports = ["127.0.0.1:${dashboardPort}:${dashboardPort}"];
        };
      };
    }
  ]
