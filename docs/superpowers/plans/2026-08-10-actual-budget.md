# Actual Budget on Orgrimmar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the official Actual Budget server on Orgrimmar as an internal-only, digest-pinned Podman service with daily Borg backups.

**Architecture:** A focused `actual.nix` service module will create the durable `/var/actual` state directory, run Actual with Podman, and bind its HTTP port to loopback. The shared nginx/ACME helper will publish that loopback endpoint only to the private network. Gnomeregan's existing SSH/rsync-staged Borg pattern will snapshot `/var/actual` daily.

**Tech Stack:** NixOS `virtualisation.oci-containers` (Podman), nginx/ACME, Actual Budget official Docker image, SOPS-independent persistent state, BorgBackup, Colmena.

## Global Constraints

- Expose Actual only at `https://actual.internal.freddrake.com`; permit `10.1.0.0/16` and `100.64.0.0/10`, then deny all other clients.
- Bind the application only to `127.0.0.1:5006`; do not add a firewall port.
- Persist the complete Actual data directory at `/var/actual`, mounted at `/data` in the container.
- Keep Actual password authentication as the initial-login mechanism; do not put a user password in Nix, SOPS, or a container command line.
- Register the official `docker.io/actualbudget/actual-server:latest` image in the fetcher and use its generated linux/amd64 digest; never reference an unpinned image.
- Back up `/var/actual` through gnomeregan's existing daily remote Borg job pattern using root on `10.1.1.4:2222` and `/home/fdrake/.ssh/id_ansible`.
- Do not deploy as part of this change unless the user separately requests deployment.

---

### Task 1: Add and resolve the Actual container image pin

**Files:**
- Modify: `apps/fetcher/containers.toml`
- Modify (generated): `apps/fetcher/containers-sha.nix`

**Interfaces:**
- Consumes: the fetcher's `[[containers]]` schema (`repository`, `name`, `tag`, `architectures`).
- Produces: `containers-sha."docker.io"."actualbudget/actual-server"."latest"."linux/amd64"`, a digest-qualified image reference for the service module.

- [ ] **Step 1: Request approval for the configuration-validation exception to strict test-first development**

  This is declarative Nix configuration and has no existing unit-test harness. Before changing it, ask the user to approve using Nix parsing/evaluation plus focused static assertions as the test mechanism, per the TDD skill's configuration-file exception.

- [ ] **Step 2: Add the image source declaration**

  Add this exact stanza near the other Docker Hub images in `apps/fetcher/containers.toml`:

  ```toml
  [[containers]]
  repository = "docker.io"
  name = "actualbudget/actual-server"
  tag = "latest"
  architectures = ["linux/amd64"]
  ```

- [ ] **Step 3: Resolve the digest with the repository fetcher**

  Run:

  ```bash
  just update-container-digests
  ```

  Confirm `apps/fetcher/containers-sha.nix` contains exactly one new `actualbudget/actual-server` entry under `docker.io`, keyed by `latest` and `linux/amd64`, with a `docker.io/actualbudget/actual-server@sha256:...` value. If the update also refreshes unrelated image digests, revert only those unrelated generated-entry changes before continuing.

- [ ] **Step 4: Validate the generated Nix expression**

  Run:

  ```bash
  nix-instantiate --parse apps/fetcher/containers-sha.nix >/dev/null
  rg -n -A5 -B2 'actualbudget/actual-server' apps/fetcher/containers-sha.nix
  ```

  Expected: parsing succeeds and the output shows the linux/amd64 digest-qualified reference.

- [ ] **Step 5: Commit the image pin**

  ```bash
  git add apps/fetcher/containers.toml apps/fetcher/containers-sha.nix
  git commit -m "chore(containers): pin Actual Budget image"
  ```

### Task 2: Define the internal-only Actual Podman service

**Files:**
- Create: `modules/services/actual.nix`
- Modify: `colmena/hosts/orgrimmar.nix`

**Interfaces:**
- Consumes: `containers-sha."docker.io"."actualbudget/actual-server"."latest"."linux/amd64"` from Task 1 and `mkNginxProxy { host; port; extraConfig; }`.
- Produces: systemd-generated `podman-actual.service`, persistent `/var/actual`, a loopback listener at `127.0.0.1:5006`, and the `actual.internal.freddrake.com` nginx vhost.

- [ ] **Step 1: Write focused static assertions before adding the module**

  Create a temporary validation script outside the repository, `/tmp/assert-actual-config.sh`, that asserts the intended module and host import are absent before implementation:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  test ! -e modules/services/actual.nix
  ! rg -q 'modules/services/actual.nix' colmena/hosts/orgrimmar.nix
  ```

  Run it from the repository root. Expected: exit 0. This establishes that the assertions target the new deployment behavior rather than pre-existing configuration.

- [ ] **Step 2: Add the minimal service module**

  Create `modules/services/actual.nix` following the `filebrowser.nix` pattern:

  ```nix
  {
    config,
    pkgs,
    ...
  }: let
    containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
    mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
    host = "actual";
    port = "5006";
  in {
    imports = [
      (mkNginxProxy {
        inherit host port;
        extraConfig = ''
          allow 10.1.0.0/16;
          allow 100.64.0.0/10;
          deny all;
        '';
      })
    ];

    systemd.tmpfiles.rules = [
      "d /var/actual 0750 root root -"
    ];

    virtualisation.oci-containers = {
      backend = "podman";
      containers.actual = {
        image = containers-sha."docker.io"."actualbudget/actual-server"."latest"."linux/amd64";
        autoStart = true;
        ports = ["127.0.0.1:${port}:5006"];
        volumes = ["/var/actual:/data"];
      };
    };
  }
  ```

  Do not set `ACTUAL_HTTPS_*`: nginx owns TLS. Do not set a user password or non-default authentication environment variable.

- [ ] **Step 3: Wire the module into Orgrimmar**

  Add `../../modules/services/actual.nix` to the full `orgrimmar` host's `imports` list in `colmena/hosts/orgrimmar.nix`, next to the other application service modules. Do not import it into `_orgrimmar` or `orgrimmar-init`.

- [ ] **Step 4: Replace the red assertion with behavior assertions and evaluate the host**

  Replace `/tmp/assert-actual-config.sh` with assertions that verify the service source has the required invariants:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  test -f modules/services/actual.nix
  rg -q 'modules/services/actual.nix' colmena/hosts/orgrimmar.nix
  rg -q '127.0.0.1:\$\{port\}:5006' modules/services/actual.nix
  rg -q '/var/actual:/data' modules/services/actual.nix
  rg -q 'allow 10.1.0.0/16;' modules/services/actual.nix
  rg -q 'allow 100.64.0.0/10;' modules/services/actual.nix
  rg -q 'deny all;' modules/services/actual.nix
  ! rg -q 'ACTUAL_HTTPS\|ACTUAL_LOGIN_METHOD\|password' modules/services/actual.nix
  ```

  Run the assertions, then run:

  ```bash
  nix run nixpkgs#alejandra -- modules/services/actual.nix colmena/hosts/orgrimmar.nix
  nix-instantiate --parse modules/services/actual.nix >/dev/null
  nix run nixpkgs#colmena -- --impure eval -E '{ nodes, ... }: nodes.orgrimmar.config.virtualisation.oci-containers.containers.actual'
  git diff --check
  ```

  Expected: all assertions and Nix parsing/evaluation succeed; evaluation returns the digest image, loopback port binding, `/data` volume, and auto-start configuration.

- [ ] **Step 5: Commit the service**

  ```bash
  git add modules/services/actual.nix colmena/hosts/orgrimmar.nix
  git commit -m "feat(orgrimmar): add Actual Budget service"
  ```

### Task 3: Include Actual state in the daily Borg backups

**Files:**
- Modify: `modules/services/borg-backup.nix`

**Interfaces:**
- Consumes: `/var/actual` created by Task 2 and the existing remote backup identity/SSH authorization.
- Produces: `hetzner-actual` Borg job, included in the daily wrapper and hourly freshness report under the existing retention policy.

- [ ] **Step 1: Write a failing focused backup-membership assertion**

  Create `/tmp/assert-actual-backup.sh` outside the repository:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  rg -q 'dailyRemoteNames = \["hermes" "actual"\];' modules/services/borg-backup.nix
  rg -q '^    actual = {' modules/services/borg-backup.nix
  rg -q 'paths = \["/var/actual"\];' modules/services/borg-backup.nix
  rg -q 'daily: gitea, paperless, hermes, actual' modules/services/borg-backup.nix
  ```

  Run it before editing. Expected: it fails because the Actual remote job is not yet configured.

- [ ] **Step 2: Add the remote backup definition and daily membership**

  In `modules/services/borg-backup.nix`:

  1. Change `dailyRemoteNames` to `["hermes" "actual"]`.
  2. Add this sibling entry in `remoteBackups`:

     ```nix
     actual = {
       host = "10.1.1.4";
       port = 2222;
       user = "root";
       # Actual keeps all recoverable server and budget state in the /data
       # bind mount declared by modules/services/actual.nix. SOPS has no
       # runtime secrets for this service.
       paths = ["/var/actual"];
       identityFile = "/home/fdrake/.ssh/id_ansible";
     };
     ```

  3. Update the daily wrapper `description` to list Actual: `Sequential borg backups (daily: gitea, paperless, hermes, actual)`.

- [ ] **Step 3: Verify the backup assertions turn green**

  Run:

  ```bash
  /tmp/assert-actual-backup.sh
  nix run nixpkgs#alejandra -- modules/services/borg-backup.nix
  nix-instantiate --parse modules/services/borg-backup.nix >/dev/null
  nix run nixpkgs#colmena -- --impure eval -E '{ nodes, ... }: nodes.gnomeregan.config.services.borgbackup.jobs."hetzner-actual".paths'
  nix run nixpkgs#colmena -- --impure eval -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.borg-backup-daily.script'
  git diff --check
  ```

  Expected: the first evaluation returns the remote staging path for Actual's Borg job; the daily script includes `hetzner-actual` after staging `/var/actual` over SSH.

- [ ] **Step 4: Confirm remote access prerequisites without altering authorization**

  Inspect `colmena/hetzner-common/default.nix` to verify it authorizes the public key matching gnomeregan's `/home/fdrake/.ssh/id_ansible`. Then, if both hosts are reachable, run:

  ```bash
  ssh -o BatchMode=yes -o ConnectTimeout=10 gnomeregan.internal.freddrake.com 'bash -s' <<'REMOTE'
  sudo ssh -i /home/fdrake/.ssh/id_ansible -p 2222 \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile=/tmp/gnomeregan-backup-known_hosts \
    -o IdentitiesOnly=yes \
    root@10.1.1.4 'hostname; test -e /var/actual || true'
  REMOTE
  ```

  Expected before deployment: SSH succeeds; the directory may not yet exist. Do not treat a missing directory as a failure before the Orgrimmar service is deployed.

- [ ] **Step 5: Commit the backup integration**

  ```bash
  git add modules/services/borg-backup.nix
  git commit -m "feat(backups): back up Actual Budget daily"
  ```

### Task 4: Run final repository validation and refresh the graph

**Files:**
- Modify (generated): `graphify-out/` graph artifacts, only if they are tracked and changed by the update command.

**Interfaces:**
- Consumes: the image pin, Orgrimmar service, and gnomeregan backup job from Tasks 1–3.
- Produces: verified Nix evaluation and an updated codebase knowledge graph.

- [ ] **Step 1: Run the focused validation suite**

  ```bash
  /tmp/assert-actual-config.sh
  /tmp/assert-actual-backup.sh
  nix run nixpkgs#alejandra -- modules/services/actual.nix colmena/hosts/orgrimmar.nix modules/services/borg-backup.nix
  nix-instantiate --parse modules/services/actual.nix >/dev/null
  nix-instantiate --parse modules/services/borg-backup.nix >/dev/null
  nix run nixpkgs#colmena -- --impure eval -E '{ nodes, ... }: { actual = nodes.orgrimmar.config.virtualisation.oci-containers.containers.actual; backup = nodes.gnomeregan.config.services.borgbackup.jobs."hetzner-actual".paths; }'
  git diff --check
  ```

  Expected: all assertions pass, both Nix files parse, Colmena evaluates both host configurations, and no whitespace errors are reported.

- [ ] **Step 2: Run the project-level check**

  ```bash
  nix flake check
  ```

  Expected: exits successfully. If it fails because of a pre-existing or unrelated evaluation failure, capture the exact failure and do not claim a clean validation.

- [ ] **Step 3: Update the codebase graph**

  ```bash
  graphify update .
  ```

  Report any graph-health warning; stage generated graph artifacts only if this repository already tracks them.

- [ ] **Step 4: Commit generated graph changes only when applicable**

  ```bash
  git status --short graphify-out
  git add graphify-out
  git commit -m "chore(graph): update service graph"
  ```

  Skip this commit if `graphify update .` makes no tracked changes.

- [ ] **Step 5: Offer the separate deployment step**

  Report that implementation and local evaluation are complete, then ask whether to deploy Orgrimmar and gnomeregan. If asked, use the infrastructure deployment workflow: one colmena-deployer subagent per host, verify the Actual HTTPS endpoint from the Tailnet after Orgrimmar, and run/inspect the Borg job only after `/var/actual` exists.
