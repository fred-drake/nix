# Hermes Native Buzz Pilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the existing always-on Hermes service on orgrimmar to Hermes 0.20 and make it an owner-only native participant in a dedicated private Buzz channel.

**Architecture:** Upgrade and validate Hermes independently before enabling Buzz. Build a static Buzz CLI from the exact deployed relay revision with the unstable Rust toolchain, mount it into Hermes, and configure Hermes through a read-only managed-scope file plus its existing SOPS environment. Enroll a dedicated identity directly with the relay and add it as a bot to a human-owned private channel.

**Tech Stack:** NixOS, Colmena, Nix `buildRustPackage`, Podman, SOPS, Hermes Agent 0.20, Buzz relay/CLI, Borg.

## Global Constraints

- Upgrade from `nousresearch/hermes-agent:v2026.6.19` (Hermes 0.17) to digest-pinned `v2026.8.3` (Hermes 0.20) before adding Buzz.
- Keep the existing `/var/hermes` profile, memory, sessions, provider configuration, dashboard, and vault intact.
- The Hermes 0.20 container starts as root for initialization, then drops to UID/GID 10000 through `HERMES_UID` and `HERMES_GID`; do not set the OCI `user` field.
- Build the Buzz CLI from deployed relay revision `4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc`, not moving `main`.
- Use direct relay membership. Do not add an API token or NIP-OA auth tag.
- Set Buzz transport to `auto` exclusively in managed policy, with owner-only allowlisting, channel mention gating, and one dedicated private channel; do not define `BUZZ_TRANSPORT` in the environment.
- Owner direct messages are explicitly allowed; non-owner messages and DMs must be rejected before model/tool execution.
- Configure non-secret Hermes policy through managed scope at `/etc/hermes/config.yaml`; do not mutate `/var/hermes/config.yaml` on every restart.
- Future personas are separate Hermes containers/services with distinct state, vaults, secrets, Buzz identities, channels, dashboard ports, and hostnames.
- Deploy only orgrimmar. Never run `just switch`.

---

### Task 1: Upgrade the Hermes image to 0.20

**Files:**
- Modify: `apps/fetcher/containers.toml`
- Modify: `apps/fetcher/containers-sha.nix`
- Modify: `modules/services/hermes.nix`

**Interfaces:**
- Consumes: existing Hermes 0.17 service and persistent `/var/hermes` state.
- Produces: a buildable Hermes 0.20 service that uses the image's supported root-to-UID/GID initialization path.

- [ ] **Step 1: Record the pre-upgrade state without secrets**

Run:

```bash
ssh root@orgrimmar 'podman exec hermes hermes --version; podman exec hermes python -c '\''from hermes_cli.config import check_config_version; print(check_config_version())'\''; systemctl is-active podman-hermes.service'
```

Expected: Hermes `v0.17.0 (2026.6.19)`, config schema `(30, 30)`, service `active`.

- [ ] **Step 2: Point the container pin at Hermes 0.20**

Change only the Hermes entry in `apps/fetcher/containers.toml`:

```toml
[[containers]]
repository = "docker.io"
name = "nousresearch/hermes-agent"
tag = "v2026.8.3"
architectures = ["linux/amd64"]
```

Run `update-container-digests`, then retain only the generated Hermes digest change in `apps/fetcher/containers-sha.nix`; restore every unrelated moving-tag change from `HEAD`.

Expected: the generated Linux AMD64 reference uses Docker Hub's architecture digest for `v2026.8.3`; unrelated image references are unchanged.

- [ ] **Step 3: Adopt the 0.20 container user contract**

In `modules/services/hermes.nix`, remove:

```nix
user = "${toString hermesUid}:${toString hermesGid}";
```

Keep `HERMES_UID` and `HERMES_GID`. Add a comment explaining that Hermes 0.20's s6 entrypoint must start as root and drops the gateway to the configured service identity after volume ownership/config migration.

- [ ] **Step 4: Evaluate, format, and build only orgrimmar**

Run:

```bash
alejandra modules/services/hermes.nix apps/fetcher/containers-sha.nix
colmena eval --impure -E '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.image'
colmena build --on orgrimmar --impure
```

Expected: evaluation shows the new digest-pinned `v2026.8.3` image and the target build succeeds.

- [ ] **Step 5: Commit the upgrade configuration**

```bash
git add apps/fetcher/containers.toml apps/fetcher/containers-sha.nix modules/services/hermes.nix
git commit -m "feat(hermes): upgrade to 0.20"
```

### Task 2: Quiesce, back up, deploy, and validate Hermes 0.20

**Files:**
- Modify: none

**Interfaces:**
- Consumes: Task 1's image/configuration commit.
- Produces: a running and migration-validated Hermes 0.20 instance plus two quiesced rollback sources: a local full-state copy and a verified Borg archive.

- [ ] **Step 1: Record state, quiesce all writers, and make a local rollback copy**

Record current version, schema `(30, 30)`, and effective `OBSIDIAN_VAULT_PATH` without printing secrets. Then create the exact evidence handoff after stopping all writers:

```bash
set -euo pipefail
EVIDENCE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hermes-v020-evidence.XXXXXX")
chmod 700 "$EVIDENCE_DIR"
ssh root@orgrimmar /bin/sh -s > "$EVIDENCE_DIR/quiesced-state.tsv" <<'REMOTE'
set -eu
old_image=$(podman inspect hermes --format '{{.ImageName}}')
systemctl stop hermes-vault-sync.timer hermes-vault-sync.service podman-hermes.service
test "$(systemctl is-active podman-hermes.service || true)" = inactive
test "$(systemctl is-active hermes-vault-sync.timer || true)" = inactive
test ! -e /var/hermes-pre-v020
cp -a --reflink=auto /var/hermes /var/hermes-pre-v020
printf '%s\t%s\t%s\n' "$(date +%s)" "$(sha256sum /var/hermes/config.yaml | cut -d' ' -f1)" "$old_image"
REMOTE
IFS=$'\t' read -r QUIESCE_EPOCH CONFIG_SHA256 HERMES_017_IMAGE < "$EVIDENCE_DIR/quiesced-state.tsv"
test -n "$QUIESCE_EPOCH" -a -n "$CONFIG_SHA256" -a -n "$HERMES_017_IMAGE"
printf '%s\n' "$QUIESCE_EPOCH" > "$EVIDENCE_DIR/quiesce-epoch"
printf '%s\n' "$CONFIG_SHA256" > "$EVIDENCE_DIR/config-sha256"
printf '%s\n' "$HERMES_017_IMAGE" > "$EVIDENCE_DIR/hermes-017-image"
```

Expected: no process can write Hermes state or the vault, and the copied state is the already validated schema-30 state. Keep the rollback copy and evidence directory until final verification completes.

- [ ] **Step 2: Create and verify a quiesced Borg snapshot**

Pass the epoch explicitly to one fail-fast gnomeregan command and capture its stdout on the controller:

```bash
QUIESCE_EPOCH=$(<"$EVIDENCE_DIR/quiesce-epoch")
ssh gnomeregan bash -s -- "$QUIESCE_EPOCH" \
  > "$EVIDENCE_DIR/hermes-pre-v020-borg.json" <<'REMOTE'
set -euo pipefail
quiesce=$1
sudo systemctl start --wait borgbackup-job-hetzner-hermes.service
sudo systemctl start --wait backup-status.service
sudo jq -e --argjson q "$quiesce" '.volumes.hermes.last_backup_epoch > $q' \
  /var/lib/backup-status/status.json >/dev/null
archive=$(sudo env BORG_REPO=/mnt/hetzner-backup/borg-repos/hermes \
  BORG_PASSCOMMAND='cat /run/secrets/hetzner-borg-passphrase' \
  borg list --json --last 1)
printf '%s' "$archive" | jq -e --argjson q "$quiesce" '
  .archives | length == 1 and
  ((.[0].start | split(".")[0] + "Z" | fromdateiso8601) > $q) and
  (.[0].name | length > 0)
' >/dev/null
printf '%s' "$archive"
REMOTE
jq -e '.archives | length == 1 and (.[0].name | length > 0)' \
  "$EVIDENCE_DIR/hermes-pre-v020-borg.json" >/dev/null
```

Use `systemctl start --wait` as the transient job result; do not use `is-active`. Leave Hermes and vault sync stopped if any assertion fails.

- [ ] **Step 3: Deploy only orgrimmar with a named child**

Launch a Pi child using agent definition `generalist`, machine handle `hermes-upgrade-deployer`, and the bounded task: run `colmena apply --on orgrimmar --impure` from the isolated worktree and return only activation status/root-cause lines.

Expected: orgrimmar activates successfully; no other host is targeted.

- [ ] **Step 4: Verify version, migration, runtime identity, and preserved state**

Run:

```bash
ssh root@orgrimmar 'set -e; systemctl is-active podman-hermes.service; podman exec hermes hermes --version; podman exec hermes python -c '\''from hermes_cli.config import check_config_version; print(check_config_version())'\''; podman top hermes user pid args; test -d /var/hermes-pre-v020'
```

Expected: service `active`, Hermes `v0.20.0 (2026.8.3)`, schema `(33, 33)`, and the gateway command runs as UID 10000 under the root-owned s6 supervisor.

Compare the same effective Obsidian vault path recorded in Step 1, memory/session paths, and file counts against the pre-upgrade record. Verify the dashboard on `127.0.0.1:9119`, the configured provider with a harmless Hermes health/status command, and the latest 150 service log lines. The expected migration backup names are `config.yaml.bak-*` and `.env.bak-*`.

- [ ] **Step 5: Re-enable vault synchronization**

After all Step 4 checks pass:

```bash
ssh root@orgrimmar 'systemctl enable --now hermes-vault-sync.timer; systemctl is-active hermes-vault-sync.timer'
```

Expected: timer `active` and Hermes remains healthy.

- [ ] **Step 6: Use the exact rollback order on any failure**

If deployment or validation fails and the local copy exists, run the complete local restore in one fail-fast boundary:

```bash
(
set -euo pipefail
CONFIG_SHA256=$(grep -E '^[0-9a-f]{64}$' "$EVIDENCE_DIR/config-sha256")
HERMES_017_IMAGE=$(grep -E '^docker.io/nousresearch/hermes-agent@sha256:[0-9a-f]{64}$' "$EVIDENCE_DIR/hermes-017-image")
test -n "$CONFIG_SHA256" -a -n "$HERMES_017_IMAGE"
ssh root@orgrimmar /bin/sh -s -- "$CONFIG_SHA256" "$HERMES_017_IMAGE" <<'REMOTE'
set -eu
config_sha256=$1
old_image=$2
systemctl stop podman-hermes.service hermes-vault-sync.timer hermes-vault-sync.service
systemctl mask --runtime podman-hermes.service hermes-vault-sync.timer hermes-vault-sync.service
test -d /var/hermes-pre-v020
mv /var/hermes "/var/hermes.failed-$(date -u +%Y%m%dT%H%M%SZ)"
mv /var/hermes-pre-v020 /var/hermes
test "$(sha256sum /var/hermes/config.yaml | cut -d' ' -f1)" = "$config_sha256"
podman run --rm --entrypoint python --user 10000:10000 \
  -e HOME=/var/hermes -v /var/hermes:/var/hermes:ro "$old_image" \
  -c 'from hermes_cli.config import check_config_version; value=check_config_version(); print(value); assert value == (30, 30)'
REMOTE
)
```

Only then unmask `podman-hermes.service` and activate the previous closure. Keep vault sync masked until 0.17 health is proven.

If the local copy is unavailable, pass the captured archive name to this single fail-fast fallback (run only while the new closure exists but all writers are stopped):

```bash
(
set -euo pipefail
ARCHIVE=$(jq -er '.archives[0].name | select(length > 0)' "$EVIDENCE_DIR/hermes-pre-v020-borg.json")
CONFIG_SHA256=$(grep -E '^[0-9a-f]{64}$' "$EVIDENCE_DIR/config-sha256")
HERMES_017_IMAGE=$(grep -E '^docker.io/nousresearch/hermes-agent@sha256:[0-9a-f]{64}$' "$EVIDENCE_DIR/hermes-017-image")
test -n "$ARCHIVE" -a -n "$CONFIG_SHA256" -a -n "$HERMES_017_IMAGE"
ssh gnomeregan bash -s -- "$ARCHIVE" "$CONFIG_SHA256" "$HERMES_017_IMAGE" <<'REMOTE'
set -euo pipefail
archive=$1
config_sha256=$2
old_image=$3
restore_dir=$(mktemp -d /var/tmp/hermes-restore.XXXXXX)
trap 'sudo rm -rf "$restore_dir"' EXIT
sudo ssh -i /home/fdrake/.ssh/id_ansible -p 2222 \
  -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new \
  -o UserKnownHostsFile=/var/lib/backup-staging/known_hosts \
  root@10.1.1.4 'set -e; systemctl stop podman-hermes.service hermes-vault-sync.timer hermes-vault-sync.service; systemctl mask --runtime podman-hermes.service hermes-vault-sync.timer hermes-vault-sync.service; mv /var/hermes "/var/hermes.failed-$(date -u +%Y%m%dT%H%M%SZ)"; install -d -m 0755 -o 10000 -g 10000 /var/hermes'
cd "$restore_dir"
sudo env BORG_REPO=/mnt/hetzner-backup/borg-repos/hermes \
  BORG_PASSCOMMAND='cat /run/secrets/hetzner-borg-passphrase' \
  borg extract "::$archive" var/lib/backup-staging/hermes/hermes
sudo rsync -aHAX --delete \
  -e 'ssh -i /home/fdrake/.ssh/id_ansible -p 2222 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/var/lib/backup-staging/known_hosts' \
  "$restore_dir/var/lib/backup-staging/hermes/hermes/" \
  root@10.1.1.4:/var/hermes/
sudo ssh -i /home/fdrake/.ssh/id_ansible -p 2222 \
  -o IdentitiesOnly=yes -o UserKnownHostsFile=/var/lib/backup-staging/known_hosts \
  root@10.1.1.4 "set -e; test \"\$(stat -c %u:%g /var/hermes)\" = 10000:10000; test \"\$(sha256sum /var/hermes/config.yaml | cut -d' ' -f1)\" = '$config_sha256'; podman run --rm --entrypoint python --user 10000:10000 -e HOME=/var/hermes -v /var/hermes:/var/hermes:ro '$old_image' -c 'from hermes_cli.config import check_config_version; value=check_config_version(); print(value); assert value == (30, 30)'"
REMOTE
)
```

Only after that direct schema/ownership/digest assertion may `podman-hermes.service` be unmasked and the previous 0.17 closure activated. Keep vault sync masked until 0.17 health is proven; then unmask/re-enable it. Never start 0.17 against schema-33 state. Never start 0.17 against schema-33 state.

### Task 3: Build and mount the relay-matched Buzz CLI

**Files:**
- Create: `apps/buzz-cli.nix`
- Modify: `apps/fetcher/repos.toml`
- Modify: `apps/fetcher/repos-src.nix`
- Modify: `colmena/default.nix`
- Modify: `colmena/hosts/orgrimmar.nix`
- Modify: `modules/services/hermes.nix`

**Interfaces:**
- Consumes: exact Buzz revision `4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc` and `nixpkgs-unstable` Rust 1.97.
- Produces: a static `$out/bin/buzz`, installed on orgrimmar and mounted read-only at `/usr/local/bin/buzz` inside Hermes.

- [ ] **Step 1: Pin the exact deployed Buzz source**

Append to `apps/fetcher/repos.toml`:

```toml
[[repos]]
name = "buzz-src"
url = "https://github.com/block/buzz"
rev = "4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc"
```

Run `just update-repos`, retain only the generated `buzz-src` addition in `apps/fetcher/repos-src.nix`, and restore unrelated source-pin movement from `HEAD`.

- [ ] **Step 2: Expose unstable packages to the Orgrimmar module**

Pass `nixpkgs-unstable` into the Orgrimmar host import in `colmena/default.nix`. In `colmena/hosts/orgrimmar.nix`, import an `x86_64-linux` `pkgsUnstable` set and include it in the existing `_module.args` alongside `secrets`.

Verify:

```bash
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.rustc.version'
```

Expected: Rust 1.97 or newer, satisfying Buzz's minimum Rust 1.88.

- [ ] **Step 3: Create the static package and target-side hash loop**

Create `apps/buzz-cli.nix` with this interface and behavior:

```nix
{
  binutils,
  file,
  lib,
  pkgs,
  pkgsStatic ? pkgs.pkgsStatic,
  rustPlatform,
  static ? true,
}:
let
  src = (import ./fetcher/repos-src.nix {inherit pkgs;}).buzz-src;
  builder =
    if static
    then pkgsStatic.rustPlatform
    else rustPlatform;
in
  builder.buildRustPackage {
    pname = "buzz-cli";
    version = "0.1.0-4749bc7b";
    inherit src;
    cargoHash = lib.fakeHash;
    cargoBuildFlags = ["-p" "buzz-cli" "--bin" "buzz"];
    doInstallCheck = true;
    nativeInstallCheckInputs = [file] ++ lib.optionals static [binutils];
    installPhase = ''
      runHook preInstall
      mapfile -t candidates < <(find target -type f -path '*/release/buzz' -perm -0100)
      test "''${#candidates[@]}" -eq 1
      install -Dm755 "''${candidates[0]}" "$out/bin/buzz"
      runHook postInstall
    '';
    installCheckPhase = ''
      "$out/bin/buzz" --help >/dev/null
      ${lib.optionalString static ''
        file "$out/bin/buzz" | grep -q 'statically linked'
        ! readelf -l "$out/bin/buzz" | grep -q 'interpreter'
      ''}
    '';
  }
```

Stage the new file, run `colmena build --on orgrimmar --impure` so the `x86_64-linux` derivation is built on the target, copy the reported actual `cargoHash` into the file, and rerun until the install checks pass. Do not attempt the Linux build on the aarch64-Darwin controller.

- [ ] **Step 4: Wire the package into Hermes**

In `modules/services/hermes.nix`, accept `pkgsUnstable`, create:

```nix
buzzCli = pkgsUnstable.callPackage ../../apps/buzz-cli.nix {pkgs = pkgsUnstable;};
```

Add `buzzCli` to `environment.systemPackages` and add this container volume:

```nix
"${buzzCli}/bin/buzz:/usr/local/bin/buzz:ro"
```

Do not enable the Buzz platform yet.

- [ ] **Step 5: Build and evaluate the exact mounted artifact**

Stage every new file before Nix evaluation, then run:

```bash
alejandra apps/buzz-cli.nix apps/fetcher/repos-src.nix colmena/default.nix colmena/hosts/orgrimmar.nix modules/services/hermes.nix
colmena build --on orgrimmar --impure
colmena eval --impure -E '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.volumes'
```

Extract the Buzz volume's source store path from the evaluation and verify that exact path exists on orgrimmar after the target-side build. The derivation's install check proves static linkage; the exact-image execution check follows after deployment in Step 7. A real HTTPS/CA and NIP-98 operation follows after enrollment in Task 4.

Build the same pinned source natively for the controller and record its store path:

```bash
DARWIN_BUZZ=$(nix build --no-link --print-out-paths --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin;
  in pkgs.callPackage ./apps/buzz-cli.nix {inherit pkgs; static = false;}
')
"$DARWIN_BUZZ/bin/buzz" --help >/dev/null
```

This native build supplies the exact relay-revision CLI for human-identity channel provisioning; do not use Buzz.app's unpinned sidecar for writes.

- [ ] **Step 6: Commit the CLI package and integration**

```bash
git add apps/buzz-cli.nix apps/fetcher/repos.toml apps/fetcher/repos-src.nix colmena/default.nix colmena/hosts/orgrimmar.nix modules/services/hermes.nix
git commit -m "feat(buzz): package relay-matched CLI"
```

- [ ] **Step 7: Deploy the CLI-only change and verify it**

Launch a Pi child using agent definition `generalist`, machine handle `buzz-cli-deployer`, and a bounded `colmena apply --on orgrimmar --impure` task in the isolated worktree. Then run:

```bash
ssh root@orgrimmar 'set -e; buzz --help >/dev/null; podman exec --user 10000:10000 hermes /usr/local/bin/buzz --help >/dev/null; systemctl is-active podman-hermes.service; ! podman exec hermes hermes gateway status 2>&1 | grep -qi buzz'
```

Expected: the host and exact running Hermes 0.20 image execute the same mounted binary, Hermes remains active, and neither credentials nor managed policy have enabled Buzz yet.

### Task 4: Provision the Hermes Buzz identity and private channel

**Files:**
- Modify in secrets repository: `secrets/host/orgrimmar/hermes-env.sops`
- Modify in secrets repository only if required by local convention: `.sops.yaml`

**Interfaces:**
- Consumes: Task 3's host Buzz CLI and the running relay's `buzz-admin`.
- Produces: a directly enrolled Hermes identity with a published profile, a human-owned private channel, and encrypted native-Buzz environment values.

- [ ] **Step 1: Generate and parse the key with failure-safe cleanup**

Run the whole Task 4 workflow from one `umask 077` shell with this local cleanup boundary:

```bash
set -euo pipefail
tmpdir=$(mktemp -d)
chmod 700 "$tmpdir"
cleanup() {
  unset BUZZ_PRIVATE_KEY BUZZ_RELAY_URL || true
  ssh root@orgrimmar 'rm -f /run/hermes-buzz-provision.env' >/dev/null 2>&1 || true
  rm -rf "$tmpdir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
DARWIN_BUZZ=$(nix build --no-link --print-out-paths --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin;
  in pkgs.callPackage ./apps/buzz-cli.nix {inherit pkgs; static = false;}
')
test -x "$DARWIN_BUZZ/bin/buzz"
"$DARWIN_BUZZ/bin/buzz" --help >/dev/null
ssh root@orgrimmar 'podman exec buzz-relay buzz-admin generate-key' > "$tmpdir/key-output"
python3 - "$tmpdir/key-output" "$tmpdir/hermes-pubkey" "$tmpdir/hermes-key" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
pub = re.search(r"^Public key:\s+(.+)$", text, re.M)
secret = re.search(r"^Secret key:\s+(.+)$", text, re.M)
if not pub or not secret:
    raise SystemExit("unexpected buzz-admin key output")
open(sys.argv[2], "w").write(pub.group(1).strip() + "\n")
open(sys.argv[3], "w").write(secret.group(1).strip() + "\n")
PY
chmod 600 "$tmpdir"/*
HERMES_PUBKEY=$(<"$tmpdir/hermes-pubkey")
```

The secret never exists on orgrimmar or in command arguments. Only the public key may be printed.

- [ ] **Step 2: Enroll the identity directly and prove HTTPS/NIP-98**

The relay PID-1 shell constructs DB/Redis URLs dynamically, so a plain `podman exec buzz-admin` is invalid. Run this exact shape, passing the public key as positional argument without interpolating it into the inner shell:

```bash
ssh root@orgrimmar /bin/sh -s -- "$HERMES_PUBKEY" <<'REMOTE'
set -eu
pubkey=$1
test -n "$pubkey"
podman exec buzz-relay /bin/sh -ec '
  test -n "$BUZZ_RELAY_PRIVATE_KEY"
  export DATABASE_URL="postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@buzz-postgres:5432/$POSTGRES_DB"
  export REDIS_URL="redis://:$REDIS_PASSWORD@buzz-redis:6379"
  exec buzz-admin add-member --pubkey "$1" --role member
' sh "$pubkey"
REMOTE
```

Create the root-only Podman exec env file over SSH stdin, not argv:

```bash
{
  printf '%s\n' 'BUZZ_RELAY_URL=https://buzz.internal.freddrake.com'
  printf 'BUZZ_PRIVATE_KEY=%s\n' "$(<"$tmpdir/hermes-key")"
} | ssh root@orgrimmar 'umask 077; cat > /run/hermes-buzz-provision.env'
```

Run the real TLS/NIP-98 operations as UID 10000 inside the exact running Hermes 0.20 image:

```bash
ssh root@orgrimmar 'podman exec --user 10000:10000 --env-file /run/hermes-buzz-provision.env hermes /usr/local/bin/buzz users set-profile --name Hermes --about "Always-on personal Hermes agent"'
ssh root@orgrimmar 'podman exec --user 10000:10000 --env-file /run/hermes-buzz-provision.env hermes /usr/local/bin/buzz users get'
ssh root@orgrimmar 'podman exec --user 10000:10000 --env-file /run/hermes-buzz-provision.env hermes /usr/local/bin/buzz channels list'
```

Expected: direct membership succeeds, profile round-trip returns Hermes, and the exact mounted binary/image/UID completes HTTPS without certificate failure. Because the relay has `BUZZ_REQUIRE_AUTH_TOKEN=true` and no API token/header fallback is supplied, successful REST writes/reads exercise NIP-98. Correlate request timestamps with secret-free `buzz_auth` relay logs. No API token or auth tag is set.

- [ ] **Step 3: Create the private channel as the human Buzz identity**

Extract the existing human identity into the existing trap-managed directory without printing it:

```bash
security find-generic-password -s buzz-desktop -a secrets -w > "$tmpdir/keychain.json"
python3 - "$tmpdir/keychain.json" "$tmpdir/human-identity" <<'PY'
import json, sys
value = json.load(open(sys.argv[1]))["identity"]
open(sys.argv[2], "w").write(value + "\n")
PY
chmod 600 "$tmpdir/human-identity"
```

Use only Task 3's exact-revision `$DARWIN_BUZZ/bin/buzz` in a subshell so the human secret cannot survive in the parent environment:

```bash
(
  set -euo pipefail
  export BUZZ_PRIVATE_KEY=$(<"$tmpdir/human-identity")
  export BUZZ_RELAY_URL=https://buzz.internal.freddrake.com
  "$DARWIN_BUZZ/bin/buzz" users get > "$tmpdir/human-profile.json"
  "$DARWIN_BUZZ/bin/buzz" channels list > "$tmpdir/human-channels.json"
  OWNER_PUBKEY=$(jq -er 'if length == 1 then .[0].pubkey else error("expected one profile") end | select(type == "string" and length > 0)' "$tmpdir/human-profile.json")
  "$DARWIN_BUZZ/bin/buzz" channels create --name hermes-pilot --type stream --visibility private > "$tmpdir/channel-create.json"
  CHANNEL_UUID=$(jq -er '.channel_id | select(type == "string" and length > 0)' "$tmpdir/channel-create.json")
  printf '%s\n' "$CHANNEL_UUID" > "$tmpdir/channel-uuid"
  printf '%s\n' "$OWNER_PUBKEY" > "$tmpdir/owner-pubkey"
  "$DARWIN_BUZZ/bin/buzz" channels add-member --channel "$CHANNEL_UUID" --pubkey "$HERMES_PUBKEY" --role bot
  "$DARWIN_BUZZ/bin/buzz" channels members --channel "$CHANNEL_UUID" > "$tmpdir/channel-members.json"
)
CHANNEL_UUID=$(<"$tmpdir/channel-uuid")
OWNER_PUBKEY=$(<"$tmpdir/owner-pubkey")
```

Then use `/run/hermes-buzz-provision.env` with `podman exec --user 10000:10000` for Hermes-side `channels get`, `channels members`, and `messages get` on that UUID. Expected: human is owner, Hermes is bot, and Hermes reads the channel. The outer Task 4 trap removes both identities and unsets any accidental parent variables on every exit.

- [ ] **Step 4: Add only identity/routing values to the encrypted Hermes environment**

Work in `/Users/fdrake/Source/github.com/fred-drake/nix-secrets` through `nix develop`, reusing the trap-managed `$tmpdir/hermes-key` created locally in Step 1. Write this mode-0700 SOPS editor to `$tmpdir/editor.py`:

```python
#!/usr/bin/env python3
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
key_file = Path(os.environ["HERMES_KEY_FILE"])
values = {
    "BUZZ_RELAY_URL": "https://buzz.internal.freddrake.com",
    "BUZZ_PRIVATE_KEY": key_file.read_text().strip(),
    "BUZZ_CHANNELS": os.environ["CHANNEL_UUID"],
    "BUZZ_HOME_CHANNEL": os.environ["CHANNEL_UUID"],
    "BUZZ_ALLOWED_USERS": os.environ["OWNER_PUBKEY"],
}
lines = path.read_text().splitlines()
if not lines or not lines[0].startswith("data: |"):
    raise SystemExit("unexpected decrypted SOPS shape")
managed = {f"  {name}=" for name in values}
lines = [line for line in lines if not any(line.startswith(prefix) for prefix in managed)]
lines.extend(f"  {name}={value}" for name, value in values.items())
path.write_text("\n".join(lines) + "\n")
```

Invoke it without placing secret values in argv or logs:

```bash
HERMES_KEY_FILE="$tmpdir/hermes-key" CHANNEL_UUID="$CHANNEL_UUID" OWNER_PUBKEY="$OWNER_PUBKEY" \
  SOPS_EDITOR="$tmpdir/editor.py" nix develop -c sops \
  --input-type yaml --output-type yaml secrets/host/orgrimmar/hermes-env.sops
```

This adds only relay URL, private key, channel/home UUID, and owner allowlist. Do not put transport, polling, CLI path, mention policy, allow-all policy, API tokens, or auth tags in the environment; those behavior controls belong exclusively to managed scope in Task 5.

Stage and verify with executable assertions before any cleanup-dependent success:

```bash
secret=secrets/host/orgrimmar/hermes-env.sops
git add "$secret"
nix develop -c ./scripts/check-sops-encryption.sh
nix develop -c python3 - "$secret" <<'PY'
import sys, yaml
expected = {
    "age1g7ta2wz5hsuva5j0eexhcq77smvxl7mw2eaa25u5fsfqpujzfvhsvy7tw2",
    "age1rnarwmx5yqfhr3hxvnnw2rxg3xytjea7dhtg00h72t26dn6csdxqvsryg5",
}
doc = yaml.safe_load(open(sys.argv[1]))
recipients = [entry["recipient"] for entry in doc["sops"]["age"]]
assert len(recipients) == 2 and set(recipients) == expected
print("verified recipient set")
PY
nix develop -c sops --input-type yaml --output-type json -d "$secret" \
  | jq -er '.data' \
  | python3 -c '
import sys
names = [line.split("=", 1)[0] for line in sys.stdin if "=" in line]
expected = {"BUZZ_RELAY_URL", "BUZZ_PRIVATE_KEY", "BUZZ_CHANNELS", "BUZZ_HOME_CHANNEL", "BUZZ_ALLOWED_USERS"}
buzz = [name for name in names if name.startswith("BUZZ_")]
assert len(buzz) == len(expected) and set(buzz) == expected
print("verified Buzz name set:", ",".join(sorted(expected)))
'
ssh root@orgrimmar 'rm -f /run/hermes-buzz-provision.env'
rm -f "$tmpdir/hermes-key" "$tmpdir/human-identity" "$tmpdir/key-output" "$tmpdir/keychain.json"
```

The outer `EXIT` trap remains as failure-safe cleanup for all local plaintext, shell variables, and the remote env file.

- [ ] **Step 5: Commit and publish the secrets revision without updating the main lock**

Commit the encrypted secret in the secrets repository using `feat(hermes): add Buzz identity`, then push it. Do not update the main repository's `flake.lock` and do not deploy this secret-only revision yet; Task 5 makes the secret lock and managed policy one atomic deployable state.

### Task 5: Enable managed native-Buzz policy

**Files:**
- Modify: `modules/services/hermes.nix`
- Modify: `flake.lock`

**Interfaces:**
- Consumes: Task 4's reachable secrets revision and Task 3's mounted CLI.
- Produces: a read-only Hermes managed-scope policy that enables native Buzz without rewriting persistent user configuration.

- [ ] **Step 1: Atomically lock the secret and add managed scope**

Run `nix flake update secrets` so `flake.lock` references Task 4's pushed secrets commit. In the same working tree state, generate JSON-as-YAML with `pkgs.writeTextDir "config.yaml" (builtins.toJSON {...})`. It must contain exactly these policy keys:

```nix
{
  gateway.platforms.buzz = {
    enabled = true;
    extra = {
      transport = "auto";
      poll_interval = 4;
      cli_path = "/usr/local/bin/buzz";
      allow_all_users = false;
      require_mention = true;
    };
  };
  display.platforms.buzz = {
    interim_assistant_messages = false;
    tool_progress = "off";
  };
}
```

Mount that directory read-only at `/etc/hermes`. Keep identity, relay URL, channel, home channel, and allowlist in the SOPS environment only.

Task 4's environment contains only identity/routing values; every behavioral value above exists only in managed scope, so process environment cannot override it.

- [ ] **Step 2: Evaluate the atomic rendered container contract**

Run:

```bash
colmena eval --impure -E '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.volumes'
colmena eval --impure -E '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.environmentFiles'
colmena build --on orgrimmar --impure
```

Expected: volumes contain the read-only Buzz CLI and managed-scope directory, `flake.lock` points to the exact pushed secrets revision, the existing Hermes SOPS env file remains attached, and the target build succeeds. This is the first closure that contains Buzz credentials and enabled policy together; no prior closure contained either combination.

- [ ] **Step 3: Commit the managed policy**

```bash
alejandra modules/services/hermes.nix
git add modules/services/hermes.nix flake.lock
git commit -m "feat(hermes): join Buzz natively"
```

- [ ] **Step 4: Deploy only orgrimmar**

Launch a Pi child using agent definition `generalist`, machine handle `hermes-buzz-deployer`, and a bounded `colmena apply --on orgrimmar --impure` task in the isolated worktree. Expected: activation succeeds and `podman-hermes.service` remains active.

### Task 6: Verify authentication, access control, and independence

**Files:**
- Modify: none

**Interfaces:**
- Consumes: running Hermes 0.20 native Buzz integration.
- Produces: end-to-end evidence for transport, authorization, restart behavior, and laptop independence.

- [ ] **Step 1: Verify startup and transport**

Check `podman-hermes.service` logs and `hermes gateway status` without printing environment values.

Expected: Buzz initializes, NIP-42 WebSocket authentication succeeds, and no CLI/profile/channel error appears. If WebSocket cannot connect, `auto` may fall back to polling; record that explicitly rather than claiming WebSocket success.

- [ ] **Step 2: Verify owner channel and DM behavior**

From the allowlisted human identity:

1. Mention Hermes in the private pilot channel.
2. Send Hermes a direct message.

Expected: each produces one final assistant answer, no intermediate assistant messages, and no tool-progress messages. Hermes's expected `👀` seen reaction is allowed and is not an assistant/progress message.

- [ ] **Step 3: Verify privacy and non-owner denial before model execution**

Create a trap-managed temporary keypair, enroll it directly with the same explicit DB/Redis wrapper as Task 4, and record Hermes log/session baselines. First prove the unrelated relay member cannot list/read the private channel. Then, as the human channel owner, temporarily add that pubkey to the pilot channel as `member`; send a channel mention and a DM as the temporary identity.

Expected: private-channel ACL blocks the identity before membership; after temporary channel membership, both the mention and DM produce no Hermes response, no seen reaction, no new model session/turn, and no tool invocation. The cleanup trap removes channel membership, removes relay membership using the explicit DB/Redis wrapper, and securely deletes the key even if an assertion fails.

- [ ] **Step 4: Verify restart without replay**

Record the exact latest owner channel/DM event IDs, Hermes response count, and session/turn baseline. Restart `podman-hermes.service`, confirm Buzz reconnects, wait at least two poll intervals, and verify there is no new response, session, or model turn tied to those pre-restart IDs.

- [ ] **Step 5: Verify laptop/Desktop independence**

Quit Buzz Desktop completely on the laptop and verify its process is absent. Using the human identity only through the CLI, mention or DM Hermes.

Expected: Hermes remains online and responds from orgrimmar while no Buzz Desktop process is running.

- [ ] **Step 6: Verify focused service endpoints**

Run explicit probes for the Hermes dashboard vhost (expected authenticated/basic-auth response), the Buzz relay HTTPS health/API path, and a WebSocket upgrade/NIP-42 connection evidenced by Hermes status/logs. Do not expand this focused task into unrelated Orgrimmar services.

- [ ] **Step 7: Preserve evidence and rollback state for adversarial review**

Write a redacted evidence report containing command names, timestamps, exit statuses, versions, public identities/channel roles, event IDs, transport mode, and response/session count assertions. Do not include private keys, SOPS plaintext, or full container environments. Keep `/var/hermes-pre-v020` until Task 7 is clean.

### Task 7: Adversarial whole-system review

**Files:**
- Modify only if findings require fixes: files changed by Tasks 1–5

**Interfaces:**
- Consumes: the full branch diff, design/plan, SDD ledger, and Task 6's redacted live evidence.
- Produces: an independently challenged deployment with all load-bearing findings resolved.

- [ ] **Step 1: Dispatch an adversarial reviewer**

Launch a fresh `generalist` child named `hermes-adversary`. Give it the design, plan, merge-base-to-HEAD review package, SDD ledger, and redacted live evidence. Instruct it to try to falsify: rollback safety, state isolation, secret non-disclosure, exact image/source pins, static CLI provenance, NIP-98/NIP-42 claims, private-channel ACLs, pre-model owner filtering for channel and DM events, restart replay protection, and laptop independence. It must inspect live state read-only and must not print secrets.

- [ ] **Step 2: Resolve every Critical/Important finding**

Dispatch one bounded fix child for the complete findings list, rerun the covering build/deploy/live checks, and obtain one scoped adversarial re-review. Do not waive a load-bearing finding. Minor findings may be ledgered only with an explicit technical ruling.

- [ ] **Step 3: Retire rollback copy and take the post-success backup**

Only after the adversarial review and the standard final whole-branch review are clean, remove `/var/hermes-pre-v020`. Trigger one fresh quiesced or application-consistent Hermes Borg backup and confirm the refreshed Hermes timestamp in `backup-status`.
