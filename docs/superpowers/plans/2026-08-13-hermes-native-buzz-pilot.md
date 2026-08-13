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
- Modify: `modules/services/hermes.nix`
- Modify: `docs/superpowers/plans/2026-08-13-hermes-native-buzz-pilot.md`

**Interfaces:**
- Consumes: Task 1's image/configuration commit.
- Produces: a running and migration-validated Hermes 0.20 instance plus two quiesced rollback sources: a local full-state copy and a verified Borg archive.

- [ ] **Step 1: Select fresh mode and verify Gitea authorization**

This retry must be a fresh attempt from the current guarded Hermes 0.17/schema-30 state. Set `PRIOR_EVIDENCE_DIR=''`; do not reuse a prior evidence directory, rollback directory, Borg archive, or any quarantined schema-33 tree. The marker must be absent, and this run creates a new evidence directory, quiesce epoch, local schema-30 rollback copy, and Borg archive. The retained continuation implementation remains documented for forensic reproducibility but is not an authorized retry mode here.

Use a trap-cleaned temporary Gitea admin user/token/config to verify repository-key metadata through the supported API without printing credentials or key material. Fresh mode repeats `ls-remote` and push dry-run with the current key and runs the vault-sync oneshot:

```bash
set -euo pipefail
PRIOR_EVIDENCE_DIR=''
test "${PRIOR_EVIDENCE_DIR+x}" = x
test -z "$PRIOR_EVIDENCE_DIR"
EVIDENCE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hermes-v020-evidence.XXXXXX")
chmod 700 "$EVIDENCE_DIR"
PINNED_PRIOR_EVIDENCE_DIR=/var/folders/f3/q3jm4tkn503425prctrd8pkw0000gn/T/hermes-v020-evidence.nuyljV
assert_no_control_bytes() {
  original_bytes=$(printf '%s' "$1" | LC_ALL=C wc -c | tr -d ' ')
  safe_bytes=$(printf '%s' "$1" | LC_ALL=C tr -d '\000-\037\177' | wc -c | tr -d ' ')
  test "$original_bytes" = "$safe_bytes"
}
import_prior_value() {
  name=$1
  pattern=$2
  source="$PINNED_PRIOR_EVIDENCE_DIR/$name"
  destination="$EVIDENCE_DIR/prior-$name"
  test ! -L "$source"
  test -f "$source"
  test "$(stat -c '%u %a' "$source")" = "$(id -u) 600"
  source_inode=$(stat -c '%d:%i' "$source")
  source_sha256=$(sha256sum "$source" | cut -d' ' -f1)
  cp -pP "$source" "$destination"
  test ! -L "$source"
  test -f "$source"
  test "$(stat -c '%d:%i' "$source")" = "$source_inode"
  test "$(stat -c '%u %a' "$source")" = "$(id -u) 600"
  test "$(sha256sum "$source" | cut -d' ' -f1)" = "$source_sha256"
  test "$(sha256sum "$destination" | cut -d' ' -f1)" = "$source_sha256"
  test ! -L "$destination"
  test -f "$destination"
  test "$(stat -c '%u %a' "$destination")" = "$(id -u) 600"
  test "$(wc -l < "$destination" | tr -d ' ')" = 1
  test "$(tail -c 1 "$destination" | od -An -tu1 | tr -d ' ')" = 10
  grep -Ex "$pattern" "$destination" >/dev/null
  chmod 400 "$destination"
}
assert_no_control_bytes "$PRIOR_EVIDENCE_DIR"
case "$PRIOR_EVIDENCE_DIR" in
  '')
    MIGRATION_MODE=fresh
    PRIOR_GUARDED_017_CLOSURE=none
    PRIOR_MARKER_INODE=none
    PRIOR_VAULT_EXEC_TIMESTAMP=none
    PRIOR_QUARANTINED_STATE=none
    ;;
  "$PINNED_PRIOR_EVIDENCE_DIR")
    MIGRATION_MODE=continuation
    assert_no_control_bytes "$PRIOR_EVIDENCE_DIR"
    PINNED_PRIOR_EVIDENCE_CANONICAL=$(realpath -e "$PINNED_PRIOR_EVIDENCE_DIR")
    test ! -L "$PRIOR_EVIDENCE_DIR"
    test -d "$PRIOR_EVIDENCE_DIR"
    test "$(realpath -e "$PRIOR_EVIDENCE_DIR")" = "$PINNED_PRIOR_EVIDENCE_CANONICAL"
    test "$(stat -c '%u %a' "$PRIOR_EVIDENCE_DIR")" = "$(id -u) 700"
    prior_dir_inode=$(stat -c '%d:%i' "$PRIOR_EVIDENCE_DIR")
    import_prior_value guarded-017-closure \
      '/nix/store/[0-9a-z]{32}-nixos-system-orgrimmar-[0-9A-Za-z._+-]+'
    import_prior_value vault-gate-marker-inode '[0-9]+:[0-9]+'
    import_prior_value vault-exec-timestamp '[0-9]+'
    test ! -L "$PRIOR_EVIDENCE_DIR"
    test -d "$PRIOR_EVIDENCE_DIR"
    test "$(stat -c '%d:%i' "$PRIOR_EVIDENCE_DIR")" = "$prior_dir_inode"
    test "$(stat -c '%u %a' "$PRIOR_EVIDENCE_DIR")" = "$(id -u) 700"
    PRIOR_GUARDED_017_CLOSURE=$(grep -Ex \
      '/nix/store/[0-9a-z]{32}-nixos-system-orgrimmar-[0-9A-Za-z._+-]+' \
      "$EVIDENCE_DIR/prior-guarded-017-closure")
    PRIOR_MARKER_INODE=$(grep -Ex '[0-9]+:[0-9]+' \
      "$EVIDENCE_DIR/prior-vault-gate-marker-inode")
    PRIOR_VAULT_EXEC_TIMESTAMP=$(grep -Ex '[0-9]+' \
      "$EVIDENCE_DIR/prior-vault-exec-timestamp")
    PRIOR_QUARANTINED_STATE=/var/hermes.failed-20260813T074821Z
    printf '%s\n' "$PINNED_PRIOR_EVIDENCE_DIR" > "$EVIDENCE_DIR/prior-evidence-dir"
    printf '%s\n' "$PRIOR_QUARANTINED_STATE" > "$EVIDENCE_DIR/prior-quarantined-state"
    grep -Ex '/var/hermes\.failed-[0-9]{8}T[0-9]{6}Z' \
      "$EVIDENCE_DIR/prior-quarantined-state" >/dev/null
    test "$(wc -l < "$EVIDENCE_DIR/prior-evidence-dir" | tr -d ' ')" = 1
    test "$(tail -c 1 "$EVIDENCE_DIR/prior-evidence-dir" | od -An -tu1 | tr -d ' ')" = 10
    grep -Fx "$PINNED_PRIOR_EVIDENCE_DIR" "$EVIDENCE_DIR/prior-evidence-dir" >/dev/null
    test "$(wc -l < "$EVIDENCE_DIR/prior-quarantined-state" | tr -d ' ')" = 1
    test "$(tail -c 1 "$EVIDENCE_DIR/prior-quarantined-state" | od -An -tu1 | tr -d ' ')" = 10
    chmod 400 "$EVIDENCE_DIR/prior-evidence-dir" \
      "$EVIDENCE_DIR/prior-quarantined-state"
    ;;
  *)
    printf 'PRIOR_EVIDENCE_DIR is not the pinned failed-safe attempt\n' >&2
    exit 1
    ;;
esac
readonly MIGRATION_MODE PRIOR_GUARDED_017_CLOSURE PRIOR_MARKER_INODE \
  PRIOR_VAULT_EXEC_TIMESTAMP PRIOR_QUARANTINED_STATE
encode_ssh_arg() { printf '%s' "$1" | base64 | tr -d '\n'; }
ssh root@orgrimmar bash -s -- \
  "$(encode_ssh_arg "$MIGRATION_MODE")" \
  "$(encode_ssh_arg "$PRIOR_GUARDED_017_CLOSURE")" \
  "$(encode_ssh_arg "$PRIOR_MARKER_INODE")" \
  "$(encode_ssh_arg "$PRIOR_VAULT_EXEC_TIMESTAMP")" \
  "$(encode_ssh_arg "$PRIOR_QUARANTINED_STATE")" \
  > "$EVIDENCE_DIR/gitea-preflight.log" <<'REMOTE'
set -euo pipefail
decode_ssh_arg() { printf '%s' "$1" | base64 -d; }
mode=$(decode_ssh_arg "$1")
prior_closure=$(decode_ssh_arg "$2")
prior_marker_inode=$(decode_ssh_arg "$3")
prior_exec=$(decode_ssh_arg "$4")
prior_quarantined_state=$(decode_ssh_arg "$5")
marker=/var/lib/hermes-migration/vault-sync.inhibit
condition="ConditionPathExists=!$marker"
case "$mode" in
  fresh)
    test "$prior_closure:$prior_marker_inode:$prior_exec:$prior_quarantined_state" = \
      'none:none:none:none'
    test ! -e "$marker"
    test "$(systemctl is-active podman-hermes.service)" = active
    case "$(podman exec hermes hermes --version | head -n 1)" in
      'Hermes Agent v0.17.0 (2026.6.19)'*) ;;
      *) exit 1 ;;
    esac
    test "$(podman exec hermes python -c 'from hermes_cli.config import check_config_version; print(check_config_version())')" = '(30, 30)'
    ;;
  continuation)
    test -x "$prior_closure/bin/switch-to-configuration"
    test "$(readlink -f /run/current-system)" = "$prior_closure"
    test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'
    test "$(stat -c '%d:%i' "$marker")" = "$prior_marker_inode"
    test -d "$prior_quarantined_state"
    test "$(systemctl is-active podman-hermes.service)" = active
    case "$(podman exec hermes hermes --version | head -n 1)" in
      'Hermes Agent v0.17.0 (2026.6.19)'*) ;;
      *) exit 1 ;;
    esac
    test "$(podman exec hermes python -c 'from hermes_cli.config import check_config_version; print(check_config_version())')" = '(30, 30)'
    podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
    test "$(curl --connect-timeout 2 --max-time 5 -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:9119/)" = 302
    for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
      test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
      test "$(systemctl show "$unit" -p ConditionResult --value)" = no
      test "$(systemctl is-active "$unit" || true)" = inactive
    done
    test "$(systemctl show hermes-vault-sync.service \
      -p ExecMainStartTimestampMonotonic --value)" = "$prior_exec"
    ;;
  *) exit 1 ;;
esac

umask 077
tmpdir=$(mktemp -d /run/hermes-gitea-preflight.XXXXXX)
username="hermes-preflight-$(date +%s)-$$"
created=false
cleanup() {
  rc=$?
  trap - EXIT INT TERM
  if "$created"; then
    if podman exec --user git gitea gitea admin user delete --username "$username" >/dev/null 2>&1; then
      printf 'temporary_admin_token_and_user_cleanup=success\n'
    else
      rc=1
    fi
  fi
  rm -rf "$tmpdir"
  exit "$rc"
}
trap cleanup EXIT INT TERM

password=$(dd if=/dev/urandom bs=32 count=1 status=none | base64)
podman exec --user git gitea gitea admin user create \
  --username "$username" --password "$password" \
  --email "$username@invalid.local" --admin --must-change-password=false >/dev/null
created=true
unset password
podman exec --user git gitea gitea admin user generate-access-token \
  --username "$username" --token-name hermes-migration-preflight \
  --scopes all --raw > "$tmpdir/token"
token=$(<"$tmpdir/token")
test -n "$token"
printf 'header = "Authorization: token %s"\n' "$token" > "$tmpdir/curl.conf"
unset token
rm -f "$tmpdir/token"
chmod 600 "$tmpdir/curl.conf"

expected_fingerprint='SHA256:B4BXKRGVhiHqXIFAn2ezZliklKg/3Jvoeg50GCaFKkM'
ssh-keygen -y -f /run/secrets/hermes-vault-ssh-key > "$tmpdir/hermes.pub"
test "$(ssh-keygen -lf "$tmpdir/hermes.pub" -E sha256 | awk '{print $2}')" = "$expected_fingerprint"
rm -f "$tmpdir/hermes.pub"
api=https://gitea.internal.freddrake.com/api/v1
fetch_all_pages() {
  endpoint=$1
  output=$2
  limit=50
  page=1
  printf '[]\n' > "$output"
  while test "$page" -le 100; do
    page_file="$tmpdir/page-$page.json"
    curl --fail --silent --show-error --config "$tmpdir/curl.conf" \
      "$api/$endpoint?page=$page&limit=$limit" > "$page_file"
    jq -e 'type == "array"' "$page_file" >/dev/null
    count=$(jq 'length' "$page_file")
    test "$count" -le "$limit"
    jq -s '.[0] + .[1]' "$output" "$page_file" > "$output.next"
    mv "$output.next" "$output"
    rm -f "$page_file"
    test "$count" -eq "$limit" || return 0
    page=$((page + 1))
  done
  printf 'Gitea pagination exceeded 100 pages\n' >&2
  return 1
}
fetch_all_pages 'repos/fdrake/PKM-Personal/keys' "$tmpdir/repository-keys.json"
fetch_all_pages 'users/hermes/keys' "$tmpdir/hermes-user-keys.json"
jq -e --arg fp "$expected_fingerprint" '
  [.[] | select(.title == "Hermes" and .fingerprint == $fp and .read_only == false)] | length == 1
' "$tmpdir/repository-keys.json" >/dev/null
jq -e --arg fp "$expected_fingerprint" '
  [.[] | select(.title == "Hermes" or .fingerprint == $fp)] | length == 1
' "$tmpdir/repository-keys.json" >/dev/null
jq -e --arg fp "$expected_fingerprint" '
  [.[] | select(.title == "Hermes" or .fingerprint == $fp)] | length == 0
' "$tmpdir/hermes-user-keys.json" >/dev/null
printf 'gitea_metadata=all_pages_one_matching_write_deploy_key_no_matching_user_key\n'

script=$(systemctl show hermes-vault-sync.service -p ExecStart --value \
  | sed -n 's/.*path=\([^ ;}]*\).*/\1/p')
git=$(grep '^git=' "$script" | cut -d= -f2-)
sshbin=$(grep '^export GIT_SSH_COMMAND=' "$script" \
  | sed -n 's#.*="\([^ ]*/ssh\) .*#\1#p')
key=/run/secrets/hermes-vault-ssh-key
command_env="GIT_SSH_COMMAND=$sshbin -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/var/hermes/.ssh/known_hosts"
sudo -u hermes env "$command_env" "$git" ls-remote \
  git@gitea.internal.freddrake.com:fdrake/PKM-Personal.git HEAD >/dev/null
printf 'git_ls_remote=success\n'
sudo -u hermes env "$command_env" "$git" -C /var/hermes/vault push --dry-run >/dev/null 2>&1
printf 'git_push_dry_run=success\n'
case "$mode" in
  fresh)
    test ! -e "$marker"
    systemctl reset-failed hermes-vault-sync.service
    systemctl start --wait hermes-vault-sync.service
    test "$(systemctl show hermes-vault-sync.service -p Result --value)" = success
    test "$(systemctl show hermes-vault-sync.service -p ExecMainStatus --value)" = 0
    printf 'mode=fresh\nvault_sync_preflight=success\n'
    ;;
  continuation)
    test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'
    test "$(stat -c '%d:%i' "$marker")" = "$prior_marker_inode"
    for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
      test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
      test "$(systemctl show "$unit" -p ConditionResult --value)" = no
      test "$(systemctl is-active "$unit" || true)" = inactive
    done
    test "$(systemctl show hermes-vault-sync.service \
      -p ExecMainStartTimestampMonotonic --value)" = "$prior_exec"
    printf 'mode=continuation\nmarker_inode=%s\nwriter_timestamp=%s\n' \
      "$(stat -c '%d:%i' "$marker")" "$prior_exec"
    printf 'vault_sync_preflight=skipped_gate_retained\n'
    ;;
esac
REMOTE
chmod 600 "$EVIDENCE_DIR/gitea-preflight.log"
printf '%s\n' "$MIGRATION_MODE" > "$EVIDENCE_DIR/migration-mode"
if test "$MIGRATION_MODE" = continuation; then
  CURRENT_MARKER_INODE=$(sed -n 's/^marker_inode=\([0-9][0-9]*:[0-9][0-9]*\)$/\1/p' \
    "$EVIDENCE_DIR/gitea-preflight.log")
  CURRENT_VAULT_EXEC_TIMESTAMP=$(sed -n 's/^writer_timestamp=\([0-9][0-9]*\)$/\1/p' \
    "$EVIDENCE_DIR/gitea-preflight.log")
  test "$CURRENT_MARKER_INODE" = "$PRIOR_MARKER_INODE"
  test "$CURRENT_VAULT_EXEC_TIMESTAMP" = "$PRIOR_VAULT_EXEC_TIMESTAMP"
  printf '%s\n' "$CURRENT_MARKER_INODE" > "$EVIDENCE_DIR/vault-gate-marker-inode"
  printf '%s\n' "$CURRENT_VAULT_EXEC_TIMESTAMP" > "$EVIDENCE_DIR/vault-exec-timestamp"
  chmod 600 "$EVIDENCE_DIR/vault-gate-marker-inode" \
    "$EVIDENCE_DIR/vault-exec-timestamp"
fi
chmod 600 "$EVIDENCE_DIR/migration-mode"
```

Expected: every API page is aggregated before the supported API assertions report one unambiguous write-enabled repository deploy key and no former matching user key. Both modes prove current Git read and dry-run write authorization. Fresh mode also proves the marker absent and runs one successful vault-sync oneshot. Continuation mode accepts only the pinned, canonical retained directory with exact controller ownership/modes and non-symlink artifacts. It copies and validates each single newline-terminated value once before any live check, makes those imported copies mode 0400, and never rereads the prior path. It never removes or replaces the marker or starts either vault unit; current re-baselined inode and writer timestamp files are mode 0600. The trap removes the temporary token with its temporary admin user and all root-only files.

- [ ] **Step 2: Prepare guarded closures, record state, quiesce all writers, and make a uniquely named local rollback copy**

Before stopping anything, capture the currently running 0.17 image digest and build a guarded 0.17 rollback closure without modifying this worktree's 0.20 state. The detached temporary worktree starts from the exact reviewed 0.20 commit, changes only the container image and the 0.17 OCI user contract, and is always removed locally; no remote state is changed until its closure has built and passed inspection:

```bash
set -euo pipefail
GATE_CONDITION='ConditionPathExists=!/var/lib/hermes-migration/vault-sync.inhibit'
HERMES_017_IMAGE=$(ssh root@orgrimmar "podman inspect hermes --format '{{.ImageName}}'")
printf '%s\n' "$HERMES_017_IMAGE" | grep -Eq '^docker.io/nousresearch/hermes-agent@sha256:[0-9a-f]{64}$'
printf '%s\n' "$HERMES_017_IMAGE" > "$EVIDENCE_DIR/hermes-017-image"
chmod 600 "$EVIDENCE_DIR/hermes-017-image"

ROLLBACK_BUILD_TREE=$(mktemp -d "${TMPDIR:-/tmp}/hermes-017-guarded.XXXXXX")
rmdir "$ROLLBACK_BUILD_TREE"
cleanup_rollback_tree() {
  git worktree remove --force "$ROLLBACK_BUILD_TREE" >/dev/null 2>&1 || true
}
trap cleanup_rollback_tree EXIT INT TERM
git worktree add --detach "$ROLLBACK_BUILD_TREE" HEAD
module="$ROLLBACK_BUILD_TREE/modules/services/hermes.nix"
tmp="$module.tmp"
awk -v image="$HERMES_017_IMAGE" '
  $0 == "          autoStart = true;" {
    print
    print "          user = \"${toString hermesUid}:${toString hermesGid}\";"
    user++
    next
  }
  $0 == "          image = containers-sha.\"docker.io\".\"nousresearch/hermes-agent\".\"v2026.8.3\".\"linux/amd64\";" {
    print "          image = \"" image "\";"
    image_line++
    next
  }
  { print }
  END { if (user != 1 || image_line != 1) exit 1 }
' "$module" > "$tmp"
mv "$tmp" "$module"

(
  cd "$ROLLBACK_BUILD_TREE"
  colmena eval --impure -E \
    '{nodes, ...}: { service = nodes.orgrimmar.config.systemd.services.hermes-vault-sync.unitConfig.ConditionPathExists; timer = nodes.orgrimmar.config.systemd.timers.hermes-vault-sync.unitConfig.ConditionPathExists; }' \
    | jq -e --arg expected '!/var/lib/hermes-migration/vault-sync.inhibit' \
      '.service == $expected and .timer == $expected' >/dev/null
  colmena build --on orgrimmar --impure 2>&1 \
    | tee "$EVIDENCE_DIR/guarded-017-build.log"
)
grep -Eo '/nix/store/[0-9a-z]{32}-nixos-system-orgrimmar-[^" ]+' \
  "$EVIDENCE_DIR/guarded-017-build.log" | grep -v '\.drv' | tr -d "'" | sort -u \
  > "$EVIDENCE_DIR/guarded-017-closures"
test "$(wc -l < "$EVIDENCE_DIR/guarded-017-closures" | tr -d ' ')" = 1
GUARDED_017_CLOSURE=$(<"$EVIDENCE_DIR/guarded-017-closures")
printf '%s\n' "$GUARDED_017_CLOSURE" > "$EVIDENCE_DIR/guarded-017-closure"
chmod 600 "$EVIDENCE_DIR/guarded-017-build.log" \
  "$EVIDENCE_DIR/guarded-017-closures" "$EVIDENCE_DIR/guarded-017-closure"
cleanup_rollback_tree
trap - EXIT INT TERM

ssh root@orgrimmar /bin/sh -s -- "$GUARDED_017_CLOSURE" "$GATE_CONDITION" <<'REMOTE'
set -eu
closure=$1
condition=$2
test -x "$closure/bin/switch-to-configuration"
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  fragment=$(readlink -f "$closure/etc/systemd/system/$unit")
  test -f "$fragment"
  test "$(grep -Fxc "$condition" "$fragment")" = 1
done
REMOTE
```

In fresh mode, activate and validate that exact guarded 0.17 closure before quiesce. The marker must still be absent, so the permanent condition is inert and one normal vault synchronization must succeed. In continuation mode, do not reactivate or run either vault unit: require the freshly rebuilt closure to equal the prior active guarded closure and re-prove the retained gate instead.

```bash
MIGRATION_MODE=$(grep -Ex 'fresh|continuation' "$EVIDENCE_DIR/migration-mode")
GUARDED_017_CLOSURE=$(grep -E '^/nix/store/[0-9a-z]+-nixos-system-orgrimmar-' \
  "$EVIDENCE_DIR/guarded-017-closure")
case "$MIGRATION_MODE" in
  fresh)
    ssh root@orgrimmar /bin/sh -s -- "$GUARDED_017_CLOSURE" \
      > "$EVIDENCE_DIR/guarded-017-activation.log" <<'REMOTE'
set -eu
closure=$1
marker=/var/lib/hermes-migration/vault-sync.inhibit
test ! -e "$marker"
nix-env --profile /nix/var/nix/profiles/system --set "$closure"
"$closure/bin/switch-to-configuration" switch
test "$(readlink -f /run/current-system)" = "$closure"
case "$(podman exec hermes hermes --version | head -n 1)" in
  'Hermes Agent v0.17.0 (2026.6.19)'*) ;;
  *) exit 1 ;;
esac
test "$(podman exec hermes python -c 'from hermes_cli.config import check_config_version; print(check_config_version())')" = '(30, 30)'
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc 'ConditionPathExists=!/var/lib/hermes-migration/vault-sync.inhibit')" = 1
done
systemctl reset-failed hermes-vault-sync.service
systemctl start --wait hermes-vault-sync.service
test "$(systemctl show hermes-vault-sync.service -p Result --value)" = success
test "$(systemctl show hermes-vault-sync.service -p ExecMainStatus --value)" = 0
systemctl start hermes-vault-sync.timer
test "$(systemctl is-active hermes-vault-sync.timer)" = active
printf 'mode=fresh\nguarded_017_closure=%s\nnormal_vault_sync=success\n' "$closure"
REMOTE
    ;;
  continuation)
    PRIOR_GUARDED_017_CLOSURE=$(grep -Ex \
      '/nix/store/[0-9a-z]{32}-nixos-system-orgrimmar-[0-9A-Za-z._+-]+' \
      "$EVIDENCE_DIR/prior-guarded-017-closure")
    test "$GUARDED_017_CLOSURE" = "$PRIOR_GUARDED_017_CLOSURE"
    GATE_MARKER_INODE=$(grep -Ex '[0-9]+:[0-9]+' \
      "$EVIDENCE_DIR/vault-gate-marker-inode")
    VAULT_EXEC_TIMESTAMP=$(grep -Ex '[0-9]+' \
      "$EVIDENCE_DIR/vault-exec-timestamp")
    ssh root@orgrimmar /bin/sh -s -- \
      "$GUARDED_017_CLOSURE" "$GATE_MARKER_INODE" "$VAULT_EXEC_TIMESTAMP" \
      > "$EVIDENCE_DIR/guarded-017-activation.log" <<'REMOTE'
set -eu
closure=$1
expected_marker_inode=$2
expected_exec=$3
marker=/var/lib/hermes-migration/vault-sync.inhibit
condition="ConditionPathExists=!$marker"
test "$(readlink -f /run/current-system)" = "$closure"
test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'
test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
  test "$(systemctl show "$unit" -p ConditionResult --value)" = no
  test "$(systemctl is-active "$unit" || true)" = inactive
done
test "$(systemctl show hermes-vault-sync.service \
  -p ExecMainStartTimestampMonotonic --value)" = "$expected_exec"
printf 'mode=continuation\nguarded_017_closure=%s\nvault_gate=retained_no_exec\n' "$closure"
REMOTE
    ;;
esac
chmod 600 "$EVIDENCE_DIR/guarded-017-activation.log"
```

Build the guarded 0.20 target from the untouched migration worktree, evaluate both option values, inspect both generated units, and record its exact closure path before downtime:

```bash
colmena eval --impure -E \
  '{nodes, ...}: { service = nodes.orgrimmar.config.systemd.services.hermes-vault-sync.unitConfig.ConditionPathExists; timer = nodes.orgrimmar.config.systemd.timers.hermes-vault-sync.unitConfig.ConditionPathExists; }' \
  | tee "$EVIDENCE_DIR/vault-gate-eval.json" \
  | jq -e --arg expected '!/var/lib/hermes-migration/vault-sync.inhibit' \
    '.service == $expected and .timer == $expected' >/dev/null
colmena build --on orgrimmar --impure 2>&1 \
  | tee "$EVIDENCE_DIR/guarded-020-build.log"
grep -Eo '/nix/store/[0-9a-z]{32}-nixos-system-orgrimmar-[^" ]+' \
  "$EVIDENCE_DIR/guarded-020-build.log" | grep -v '\.drv' | tr -d "'" | sort -u \
  > "$EVIDENCE_DIR/guarded-020-closures"
test "$(wc -l < "$EVIDENCE_DIR/guarded-020-closures" | tr -d ' ')" = 1
TARGET_CLOSURE=$(<"$EVIDENCE_DIR/guarded-020-closures")
printf '%s\n' "$TARGET_CLOSURE" > "$EVIDENCE_DIR/guarded-020-closure"
ssh root@orgrimmar /bin/sh -s -- "$TARGET_CLOSURE" "$GATE_CONDITION" <<'REMOTE'
set -eu
closure=$1
condition=$2
test -x "$closure/bin/switch-to-configuration"
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  fragment=$(readlink -f "$closure/etc/systemd/system/$unit")
  test -f "$fragment"
  test "$(grep -Fxc "$condition" "$fragment")" = 1
done
REMOTE
chmod 600 "$EVIDENCE_DIR/vault-gate-eval.json" \
  "$EVIDENCE_DIR/guarded-020-build.log" "$EVIDENCE_DIR/guarded-020-closures" \
  "$EVIDENCE_DIR/guarded-020-closure"
```

Capture an executable, redacted baseline before stopping anything. Record only provider/model identifiers and a normalized authenticated/healthy outcome—never status output, credential values, or the environment. The memory, sessions, configured Obsidian vault, and synchronized vault paths are checked inside `/opt/data` and translated to host paths only for counting:

```bash
ssh root@orgrimmar /bin/sh -s > "$EVIDENCE_DIR/pre-upgrade-state.tsv" <<'REMOTE'
set -eu
tmpdir=$(mktemp -d /run/hermes-v020-baseline.XXXXXX)
trap 'rm -rf "$tmpdir"' EXIT
version=$(podman exec hermes hermes --version | head -n 1)
schema=$(podman exec hermes python -c 'from hermes_cli.config import check_config_version; print(check_config_version())')
podman exec hermes hermes status > "$tmpdir/status"
jq -Rers '
  gsub("\u001b\\[[0-9;]*[A-Za-z]"; "") as $text |
  ($text | capture("(?m)^\\s*Model:\\s*(?<v>\\S.*?)\\s*$").v) as $model |
  ($text | capture("(?m)^\\s*Provider:\\s*(?<v>\\S.*?)\\s*$").v) as $provider |
  [$text | splits("\\n") |
    select((ascii_downcase | contains($provider | ascii_downcase)) and contains("✓"))
  ] as $affirmative |
  ($affirmative | length > 0) as $healthy |
  ($affirmative | any(test("(?i)(logged in|configured|authenticated)"))) as $authenticated |
  select(($model | length) > 0 and ($provider | length) > 0 and $healthy and $authenticated) |
  [$provider, $model, "healthy", "authenticated"] | @tsv
' "$tmpdir/status" > "$tmpdir/provider.tsv"
IFS=$(printf '\t') read -r provider model provider_health provider_auth < "$tmpdir/provider.tsv"
test -n "$provider" -a -n "$model"
test "$provider_health" = healthy
test "$provider_auth" = authenticated
vault_path=$(podman exec hermes printenv OBSIDIAN_VAULT_PATH)
memory_path=/opt/data/memories
session_path=/opt/data/sessions
sync_vault_path=/opt/data/vault
host_path() {
  case "$1" in /opt/data/*) printf '/var/hermes/%s' "${1#/opt/data/}" ;; *) exit 1 ;; esac
}
count_files() { find "$(host_path "$1")" -type f | wc -l | tr -d ' '; }
for path in "$vault_path" "$memory_path" "$session_path" "$sync_vault_path"; do
  test -d "$(host_path "$path")"
done
vault_count=$(count_files "$vault_path")
memory_count=$(count_files "$memory_path")
session_count=$(count_files "$session_path")
sync_vault_count=$(count_files "$sync_vault_path")
assert_tsv_field() {
  original_bytes=$(printf '%s' "$1" | LC_ALL=C wc -c | tr -d ' ')
  safe_bytes=$(printf '%s' "$1" | LC_ALL=C tr -d '\011\012' | wc -c | tr -d ' ')
  test "$original_bytes" = "$safe_bytes"
}
for value in \
  "$version" "$schema" "$provider" "$model" "$provider_health" "$provider_auth" \
  "$vault_path" "$vault_count" "$memory_path" "$memory_count" \
  "$session_path" "$session_count" "$sync_vault_path" "$sync_vault_count"; do
  assert_tsv_field "$value"
done
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$version" "$schema" "$provider" "$model" "$provider_health" "$provider_auth" \
  "$vault_path" "$vault_count" "$memory_path" "$memory_count" \
  "$session_path" "$session_count" "$sync_vault_path" "$sync_vault_count"
REMOTE
chmod 600 "$EVIDENCE_DIR/pre-upgrade-state.tsv"
IFS=$'\t' read -r PRE_VERSION PRE_SCHEMA PRE_PROVIDER PRE_MODEL PRE_PROVIDER_HEALTH PRE_PROVIDER_AUTH \
  PRE_VAULT_PATH PRE_VAULT_COUNT PRE_MEMORY_PATH PRE_MEMORY_COUNT \
  PRE_SESSION_PATH PRE_SESSION_COUNT PRE_SYNC_VAULT_PATH PRE_SYNC_VAULT_COUNT \
  < "$EVIDENCE_DIR/pre-upgrade-state.tsv"
case "$PRE_VERSION" in 'Hermes Agent v0.17.0 (2026.6.19)'*) ;; *) exit 1 ;; esac
test "$PRE_SCHEMA" = '(30, 30)'
test -n "$PRE_PROVIDER" -a -n "$PRE_MODEL"
test "$PRE_PROVIDER_HEALTH" = healthy
test "$PRE_PROVIDER_AUTH" = authenticated
for value in "$PRE_VAULT_COUNT" "$PRE_MEMORY_COUNT" "$PRE_SESSION_COUNT" "$PRE_SYNC_VAULT_COUNT"; do
  printf '%s\n' "$value" | grep -Eq '^[0-9]+$'
done
```

Then establish the persistent root-owned gate before making the fresh quiesced copy. Fresh mode creates the marker exclusively and refuses any pre-existing marker. Continuation mode never creates, removes, replaces, or overwrites it: it receives the re-baselined inode and writer timestamp from Step 1 and requires both to remain exact while stopping Hermes for the new copy. After stopping, daemon-reload and adversarially request both vault starts; a condition-skipped start may return success, so require `ConditionResult=no`, inactivity, exact effective conditions, marker persistence, and no writer execution before copying state:

```bash
MIGRATION_MODE=$(grep -Ex 'fresh|continuation' "$EVIDENCE_DIR/migration-mode")
if test "$MIGRATION_MODE" = continuation; then
  GATE_MARKER_INODE=$(grep -Ex '[0-9]+:[0-9]+' \
    "$EVIDENCE_DIR/vault-gate-marker-inode")
  VAULT_EXEC_TIMESTAMP=$(grep -Ex '[0-9]+' \
    "$EVIDENCE_DIR/vault-exec-timestamp")
else
  GATE_MARKER_INODE=none
  VAULT_EXEC_TIMESTAMP=none
fi
ssh root@orgrimmar /bin/sh -s -- \
  "$MIGRATION_MODE" "$GATE_MARKER_INODE" "$VAULT_EXEC_TIMESTAMP" \
  > "$EVIDENCE_DIR/quiesced-state.tsv" <<'REMOTE'
set -eu
mode=$1
expected_marker_inode=$2
expected_exec=$3
marker=/var/lib/hermes-migration/vault-sync.inhibit
condition="ConditionPathExists=!$marker"
rollback_dir="/var/hermes-pre-v020-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0700 -o root -g root /var/lib/hermes-migration
case "$mode" in
  fresh)
    test "$expected_marker_inode:$expected_exec" = 'none:none'
    test ! -e "$marker"
    umask 077
    set -C
    printf 'attempt=%s created=%s\n' \
      "$(cat /proc/sys/kernel/random/uuid)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$marker"
    set +C
    chown root:root "$marker"
    chmod 0600 "$marker"
    marker_inode=$(stat -c '%d:%i' "$marker")
    before_exec=$(systemctl show hermes-vault-sync.service \
      -p ExecMainStartTimestampMonotonic --value)
    ;;
  continuation)
    test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'
    test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
    marker_inode=$expected_marker_inode
    before_exec=$(systemctl show hermes-vault-sync.service \
      -p ExecMainStartTimestampMonotonic --value)
    test "$before_exec" = "$expected_exec"
    ;;
  *) exit 1 ;;
esac
test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'

systemctl stop hermes-vault-sync.timer hermes-vault-sync.service podman-hermes.service
test "$(systemctl is-active podman-hermes.service || true)" = inactive
test "$(systemctl is-active hermes-vault-sync.timer || true)" = inactive
test "$(systemctl is-active hermes-vault-sync.service || true)" = inactive
systemctl daemon-reload
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
  systemctl start "$unit" >/dev/null 2>&1 || true
  test "$(systemctl show "$unit" -p ConditionResult --value)" = no
  test "$(systemctl is-active "$unit" || true)" = inactive
done
after_exec=$(systemctl show hermes-vault-sync.service \
  -p ExecMainStartTimestampMonotonic --value)
test "$after_exec" = "$before_exec"
test "$(stat -c '%d:%i' "$marker")" = "$marker_inode"

test ! -e "$rollback_dir"
cp -a --reflink=auto /var/hermes "$rollback_dir"
printf '%s\t%s\t%s\t%s\t%s\n' \
  "$(date +%s)" "$(sha256sum /var/hermes/config.yaml | cut -d' ' -f1)" \
  "$rollback_dir" "$marker_inode" "$before_exec"
REMOTE
IFS=$'\t' read -r QUIESCE_EPOCH CONFIG_SHA256 ROLLBACK_DIR GATE_MARKER_INODE VAULT_EXEC_TIMESTAMP \
  < "$EVIDENCE_DIR/quiesced-state.tsv"
test -n "$QUIESCE_EPOCH" -a -n "$CONFIG_SHA256" -a -n "$GATE_MARKER_INODE"
printf '%s\n' "$ROLLBACK_DIR" | grep -Eq '^/var/hermes-pre-v020-[0-9]{8}T[0-9]{6}Z$'
printf '%s\n' "$QUIESCE_EPOCH" > "$EVIDENCE_DIR/quiesce-epoch"
printf '%s\n' "$CONFIG_SHA256" > "$EVIDENCE_DIR/config-sha256"
printf '%s\n' "$ROLLBACK_DIR" > "$EVIDENCE_DIR/rollback-dir"
printf '%s\n' "$GATE_MARKER_INODE" > "$EVIDENCE_DIR/vault-gate-marker-inode"
printf '%s\n' "$VAULT_EXEC_TIMESTAMP" > "$EVIDENCE_DIR/vault-exec-timestamp"
chmod 600 "$EVIDENCE_DIR/quiesced-state.tsv" "$EVIDENCE_DIR/quiesce-epoch" \
  "$EVIDENCE_DIR/config-sha256" "$EVIDENCE_DIR/rollback-dir" \
  "$EVIDENCE_DIR/vault-gate-marker-inode" "$EVIDENCE_DIR/vault-exec-timestamp"
```

Expected: the baseline contains version/schema, exact provider/model identifiers, normalized provider health, and state paths/counts without credentials. Fresh mode installs the gate once; continuation mode preserves and re-baselines the explained gate without overwriting it. In both modes, the freshly rebuilt guarded closure and persistent marker prevent explicit and activation-driven vault starts, no process can write Hermes state or the vault during the copy, and the new uniquely named rollback copy contains validated schema-30 state. There is intentionally no `EXIT` trap that removes the marker; interruption leaves a stale marker and fails safe. The Borg step that follows always creates a fresh archive from this new quiesce epoch while the same gate remains enforced.

- [ ] **Step 3: Create and verify a quiesced Borg snapshot**

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
archive=$(sudo env TZ=UTC BORG_REPO=/mnt/hetzner-backup/borg-repos/hermes \
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

Use `systemctl start --wait` as the transient job result; do not use `is-active`. Leave Hermes and vault sync stopped with the inhibit marker present if any assertion fails.

- [ ] **Step 4: Relocate the pristine read-only dogfood skill inside the protected boundary**

Only after both rollback sources are verified, run the root-owned same-filesystem move immediately before deployment. Do not move it earlier:

```bash
ssh root@orgrimmar bash -s <<'REMOTE'
set -euo pipefail
src=/var/hermes/skills/dogfood
dst=/var/hermes/skills/software-development/dogfood
manifest=/var/hermes/skills/.bundled_manifest

test -d "$src"
test ! -e "$dst"
test "$(stat -c '%u:%g' "$src")" = 10000:10000
test "$(stat -c '%d' "$src")" = "$(stat -c '%d' "$(dirname "$dst")")"
expected=$(awk -F: '$1 == "dogfood" { print $2 }' "$manifest")
actual=$(
  cd "$src"
  find . -type f -print0 | LC_ALL=C sort -z |
    while IFS= read -r -d '' file; do
      rel=${file#./}
      printf '%s' "$rel"
      cat -- "$file"
    done | md5sum | cut -d' ' -f1
)
test -n "$expected"
test "$actual" = "$expected"

mv -T -- "$src" "$dst"
test ! -e "$src"
test -d "$dst"
test "$(stat -c '%a %u:%g' "$dst")" = '555 10000:10000'
REMOTE
```

Expected: the exact manifest hash matches, the read-only inode tree moves atomically on the same filesystem, no duplicate is created, and the rollback copy retains the original schema-30 layout.

- [ ] **Step 5: Deploy only orgrimmar and prove the persistent gate immediately**

Immediately before launching the forward 0.20 activation, record the current service-journal cursor as a mode-0600 evidence artifact. This cursor is the exclusive lower bound for Step 6's attempt-specific journal inspection:

```bash
ssh root@orgrimmar /bin/sh -s > "$EVIDENCE_DIR/forward-activation-journal-cursor" <<'REMOTE'
set -eu
cursor=$(journalctl -u podman-hermes.service -n 0 --show-cursor --no-pager \
  | sed -n 's/^-- cursor: //p')
test -n "$cursor"
test "$(printf '%s\n' "$cursor" | wc -l | tr -d ' ')" = 1
printf '%s\n' "$cursor"
REMOTE
chmod 600 "$EVIDENCE_DIR/forward-activation-journal-cursor"
```

Launch a Pi child using agent definition `generalist`, machine handle `hermes-upgrade-deployer`, and the bounded task: run `colmena apply --on orgrimmar --impure` from the isolated worktree and return only activation status/root-cause lines. Do not run unrelated commands between cursor capture and activation. Require `/run/current-system` to be the exact guarded 0.20 closure built in Step 2.

Before any Hermes migration or state validation, prove activation preserved the marker and both effective unit conditions. Explicitly request both starts again and compare the service timestamp to the pre-activation value; unit inactivity alone is insufficient:

```bash
TARGET_CLOSURE=$(grep -E '^/nix/store/[0-9a-z]+-nixos-system-orgrimmar-' \
  "$EVIDENCE_DIR/guarded-020-closure")
GATE_MARKER_INODE=$(grep -E '^[0-9]+:[0-9]+$' \
  "$EVIDENCE_DIR/vault-gate-marker-inode")
VAULT_EXEC_TIMESTAMP=$(<"$EVIDENCE_DIR/vault-exec-timestamp")
ssh root@orgrimmar /bin/sh -s -- \
  "$TARGET_CLOSURE" "$GATE_MARKER_INODE" "$VAULT_EXEC_TIMESTAMP" \
  > "$EVIDENCE_DIR/vault-gate-after-upgrade.log" <<'REMOTE'
set -eu
target=$1
expected_marker_inode=$2
expected_exec=$3
marker=/var/lib/hermes-migration/vault-sync.inhibit
condition="ConditionPathExists=!$marker"
test "$(readlink -f /run/current-system)" = "$target"
test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
  systemctl start "$unit" >/dev/null 2>&1 || true
  test "$(systemctl show "$unit" -p ConditionResult --value)" = no
  test "$(systemctl is-active "$unit" || true)" = inactive
done
test "$(systemctl show hermes-vault-sync.service \
  -p ExecMainStartTimestampMonotonic --value)" = "$expected_exec"
printf 'target_closure=%s\ngate=marker_persistent_conditions_exact_condition_result_no_inactive_no_exec\n' "$target"
REMOTE
chmod 600 "$EVIDENCE_DIR/vault-gate-after-upgrade.log"
```

Expected: only Orgrimmar activates the exact inspected target closure; the marker survives activation; both generated/effective units retain the exact condition; and neither activation nor adversarial starts execute the vault writer.

- [ ] **Step 6: Verify migration, runtime readiness, state, and controlled shutdown**

Parse the recorded baseline and run exact post-migration comparisons. The remote command emits only non-secret paths, counts, provider/model names, backup names, and assertion summaries:

```bash
IFS=$'\t' read -r PRE_VERSION PRE_SCHEMA PRE_PROVIDER PRE_MODEL PRE_PROVIDER_HEALTH PRE_PROVIDER_AUTH \
  PRE_VAULT_PATH PRE_VAULT_COUNT PRE_MEMORY_PATH PRE_MEMORY_COUNT \
  PRE_SESSION_PATH PRE_SESSION_COUNT PRE_SYNC_VAULT_PATH PRE_SYNC_VAULT_COUNT \
  < "$EVIDENCE_DIR/pre-upgrade-state.tsv"
QUIESCE_EPOCH=$(grep -E '^[0-9]+$' "$EVIDENCE_DIR/quiesce-epoch")
ROLLBACK_DIR=$(grep -E '^/var/hermes-pre-v020-[0-9]{8}T[0-9]{6}Z$' "$EVIDENCE_DIR/rollback-dir")
test "$(wc -l < "$EVIDENCE_DIR/forward-activation-journal-cursor" | tr -d ' ')" = 1
LC_ALL=C grep -Eq '^[[:graph:]]+$' \
  "$EVIDENCE_DIR/forward-activation-journal-cursor"
ACTIVATION_JOURNAL_CURSOR=$(<"$EVIDENCE_DIR/forward-activation-journal-cursor")
test -n "$ACTIVATION_JOURNAL_CURSOR"
encode_ssh_arg() { printf '%s' "$1" | base64 | tr -d '\n'; }
ssh root@orgrimmar /bin/sh -s -- \
  "$(encode_ssh_arg "$PRE_PROVIDER")" "$(encode_ssh_arg "$PRE_MODEL")" \
  "$(encode_ssh_arg "$PRE_PROVIDER_HEALTH")" "$(encode_ssh_arg "$PRE_PROVIDER_AUTH")" \
  "$(encode_ssh_arg "$PRE_VAULT_PATH")" "$(encode_ssh_arg "$PRE_VAULT_COUNT")" \
  "$(encode_ssh_arg "$PRE_MEMORY_PATH")" "$(encode_ssh_arg "$PRE_MEMORY_COUNT")" \
  "$(encode_ssh_arg "$PRE_SESSION_PATH")" "$(encode_ssh_arg "$PRE_SESSION_COUNT")" \
  "$(encode_ssh_arg "$PRE_SYNC_VAULT_PATH")" "$(encode_ssh_arg "$PRE_SYNC_VAULT_COUNT")" \
  "$(encode_ssh_arg "$QUIESCE_EPOCH")" "$(encode_ssh_arg "$ROLLBACK_DIR")" \
  "$(encode_ssh_arg "$ACTIVATION_JOURNAL_CURSOR")" \
  > "$EVIDENCE_DIR/post-migration-validation.log" <<'REMOTE'
set -eu
step=argument_decode
tmpdir=
cleanup_validation() {
  rc=$?
  trap - EXIT
  if test -n "$tmpdir"; then
    rm -rf "$tmpdir" || {
      cleanup_rc=$?
      test "$rc" -ne 0 || rc=$cleanup_rc
    }
  fi
  if test "$rc" -ne 0; then
    printf 'validation_failed_step=%s rc=%s\n' "$step" "$rc"
  fi
  exit "$rc"
}
trap cleanup_validation EXIT
decode_ssh_arg() { printf '%s' "$1" | base64 -d; }
pre_provider=$(decode_ssh_arg "$1"); pre_model=$(decode_ssh_arg "$2")
pre_provider_health=$(decode_ssh_arg "$3"); pre_provider_auth=$(decode_ssh_arg "$4")
pre_vault_path=$(decode_ssh_arg "$5"); pre_vault_count=$(decode_ssh_arg "$6")
pre_memory_path=$(decode_ssh_arg "$7"); pre_memory_count=$(decode_ssh_arg "$8")
pre_session_path=$(decode_ssh_arg "$9"); pre_session_count=$(decode_ssh_arg "${10}")
pre_sync_vault_path=$(decode_ssh_arg "${11}"); pre_sync_vault_count=$(decode_ssh_arg "${12}")
quiesce_epoch=$(decode_ssh_arg "${13}"); rollback_dir=$(decode_ssh_arg "${14}")
activation_journal_cursor=$(decode_ssh_arg "${15}")
step=validation_workspace
tmpdir=$(mktemp -d /run/hermes-v020-validation.XXXXXX)
host_path() {
  case "$1" in /opt/data/*) printf '/var/hermes/%s' "${1#/opt/data/}" ;; *) exit 1 ;; esac
}
count_files() { find "$(host_path "$1")" -type f | wc -l | tr -d ' '; }
select_fresh_backups() {
  prefix=$1
  name_pattern=$2
  output=$3
  : > "$output"
  for path in /var/hermes/"$prefix".bak-*; do
    test -e "$path" || test -L "$path" || continue
    ctime=$(stat -c %Z -- "$path")
    case "$ctime" in ''|*[!0-9]*) return 1 ;; esac
    test "$ctime" -gt "$quiesce_epoch" || continue
    test ! -L "$path"
    test -f "$path"
    name=${path##*/}
    name_bytes=$(printf '%s' "$name" | LC_ALL=C wc -c | tr -d ' ')
    safe_name_bytes=$(printf '%s' "$name" | LC_ALL=C tr -d '\000-\037\177' \
      | wc -c | tr -d ' ')
    test "$name_bytes" = "$safe_name_bytes" || return 1
    printf '%s\n' "$name" | LC_ALL=C grep -Eq "$name_pattern" || return 1
    stamp=${name#"$prefix.bak-"}
    stamp=${stamp%%.*}
    stamp_iso=$(printf '%s\n' "$stamp" | sed -E \
      's/^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})Z$/\1-\2-\3T\4:\5:\6Z/')
    canonical=$(date -u -d "$stamp_iso" +%Y%m%dT%H%M%SZ) || return 1
    test "$canonical" = "$stamp"
    name_epoch=$(date -u -d "$stamp_iso" +%s) || return 1
    test "$name_epoch" -gt "$quiesce_epoch" || continue
    printf '%s\n' "$name" >> "$output"
  done
  test -s "$output"
}

step=service_version_schema
systemctl is-active podman-hermes.service >/dev/null
version=$(podman exec hermes hermes --version | head -n 1)
case "$version" in 'Hermes Agent v0.20.0 (2026.8.3)'*) ;; *) exit 1 ;; esac
test "$(podman exec hermes python -c 'from hermes_cli.config import check_config_version; print(check_config_version())')" = '(33, 33)'
step=rollback_source
test -d "$rollback_dir"
step=container_stop_contract
test "$(podman inspect hermes --format '{{.Config.StopTimeout}}')" = 90
test "$(podman inspect hermes --format '{{.Config.StopSignal}}')" = SIGTERM
podman exec hermes sh -c 'ps -eo args | grep "[s]6-linux-init-shutdownd" | grep -q -- "-g 30000"'
step=runtime_identities
podman top hermes user args > "$tmpdir/top"
grep -Eq '^root[[:space:]].*s6-svscan' "$tmpdir/top"
grep -Eq '^hermes[[:space:]].*hermes gateway run --replace' "$tmpdir/top"

step=gateway_readiness
for _ in $(seq 1 120); do
  if podman exec hermes /command/s6-svstat /run/service/gateway-default 2>/dev/null | grep -q '^up ' &&
     podman exec hermes python -c 'import json; assert json.load(open("/opt/data/gateway_state.json"))["gateway_state"] == "running"; assert json.load(open("/opt/data/state/gateway.lifecycle.json"))["phase"] == "running"' 2>/dev/null; then
    break
  fi
  sleep 1
done
podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
podman exec hermes python -c 'import json; assert json.load(open("/opt/data/gateway_state.json"))["gateway_state"] == "running"'
podman exec hermes python -c 'import json; assert json.load(open("/opt/data/state/gateway.lifecycle.json"))["phase"] == "running"'

step=state_paths_counts
vault_path=$(podman exec hermes printenv OBSIDIAN_VAULT_PATH)
test "$vault_path" = "$pre_vault_path"
test "$pre_memory_path" = /opt/data/memories
test "$pre_session_path" = /opt/data/sessions
test "$pre_sync_vault_path" = /opt/data/vault
test "$(count_files "$vault_path")" = "$pre_vault_count"
test "$(count_files "$pre_memory_path")" = "$pre_memory_count"
test "$(count_files "$pre_session_path")" = "$pre_session_count"
test "$(count_files "$pre_sync_vault_path")" = "$pre_sync_vault_count"

step=dashboard_readiness
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:9119/)" = 302
step=provider_status_parse
podman exec hermes hermes status > "$tmpdir/status"
jq -Rers '
  gsub("\u001b\\[[0-9;]*[A-Za-z]"; "") as $text |
  ($text | capture("(?m)^\\s*Model:\\s*(?<v>\\S.*?)\\s*$").v) as $model |
  ($text | capture("(?m)^\\s*Provider:\\s*(?<v>\\S.*?)\\s*$").v) as $provider |
  [$text | splits("\\n") |
    select((ascii_downcase | contains($provider | ascii_downcase)) and contains("✓"))
  ] as $affirmative |
  ($affirmative | length > 0) as $healthy |
  ($affirmative | any(test("(?i)(logged in|configured|authenticated)"))) as $authenticated |
  select(($model | length) > 0 and ($provider | length) > 0 and $healthy and $authenticated) |
  [$provider, $model, "healthy", "authenticated"] | @tsv
' "$tmpdir/status" > "$tmpdir/provider.tsv"
IFS=$(printf '\t') read -r provider model provider_health provider_auth < "$tmpdir/provider.tsv"
step=provider_status_compare
test "$provider" = "$pre_provider"
test "$model" = "$pre_model"
test "$pre_provider_health" = healthy
test "$pre_provider_auth" = authenticated
test "$provider_health" = "$pre_provider_health"
test "$provider_auth" = "$pre_provider_auth"

step=backup_config_freshness
select_fresh_backups config.yaml \
  '^config[.]yaml[.]bak-[0-9]{8}T[0-9]{6}Z([.][0-9]+)?$' \
  "$tmpdir/config-backups"
step=backup_env_freshness
select_fresh_backups .env \
  '^[.]env[.]bak-[0-9]{8}T[0-9]{6}Z([.][0-9]+)?$' \
  "$tmpdir/env-backups"
step=dogfood_layout
test ! -e /var/hermes/skills/dogfood
test -d /var/hermes/skills/software-development/dogfood
test "$(find /var/hermes/skills -type d -name dogfood | wc -l | tr -d ' ')" = 1

step=attempt_journal
test -n "$activation_journal_cursor"
journalctl -u podman-hermes.service --after-cursor "$activation_journal_cursor" \
  --no-pager --output=short-iso > "$tmpdir/service-log-attempt"
lines=$(wc -l < "$tmpdir/service-log-attempt" | tr -d ' ')
test "$lines" -gt 0
if grep -Ei 'PermissionError.*dogfood|Could not relocate renamed skill|Traceback|config.*migrat.*failed|resorting to SIGKILL|status=137' "$tmpdir/service-log-attempt"; then
  exit 1
fi
tail -n 150 "$tmpdir/service-log-attempt" > "$tmpdir/service-log-retained"
retained_lines=$(wc -l < "$tmpdir/service-log-retained" | tr -d ' ')
test "$retained_lines" -gt 0 -a "$retained_lines" -le 150

step=summary_output
printf 'version=%s\nschema=(33, 33)\n' "$version"
printf 'vault=%s files=%s\nmemory=%s files=%s\nsessions=%s files=%s\nsync_vault=%s files=%s\n' \
  "$vault_path" "$pre_vault_count" "$pre_memory_path" "$pre_memory_count" \
  "$pre_session_path" "$pre_session_count" "$pre_sync_vault_path" "$pre_sync_vault_count"
printf 'dashboard_http=302\nprovider=%s\nmodel=%s\nprovider_health=%s\nprovider_auth=%s\n' \
  "$provider" "$model" "$provider_health" "$provider_auth"
printf 'config_backups=%s\nenv_backups=%s\n' \
  "$(paste -sd, "$tmpdir/config-backups")" "$(paste -sd, "$tmpdir/env-backups")"
printf 'dogfood_paths=one_canonical\nservice_log_attempt_lines=%s\nservice_log_retained_lines=%s\nservice_log_forbidden_errors=0\n' \
  "$lines" "$retained_lines"
printf 'runtime=SIGTERM podman_timeout=90 s6_grace_ms=30000 gateway_default=running lifecycle=running\n'
REMOTE
chmod 600 "$EVIDENCE_DIR/post-migration-validation.log"
```

Expected: version/schema, provider/model identifiers, authenticated/healthy provider outcome, and every path/count assertion match the baseline exactly; root-owned s6 supervises a UID-10000 gateway; StopSignal is SIGTERM; timeout nesting and gateway lifecycle are ready; dashboard is healthy; fresh migration backups have strict Hermes timestamp names whose encoded UTC time and ctime are both after quiesce; and only the canonical `dogfood` exists. The complete journal slice after the recorded forward-activation cursor contains none of the migration/shutdown failure signatures, while retained diagnostic output remains bounded to 150 lines. Any assertion failure records one static, non-secret `validation_failed_step=<label> rc=<n>` line without values or commands.

Then perform one controlled stop using current-run evidence only. Record the journal cursor, persistent-log inode and byte offsets, and a running lifecycle baseline before stopping. Fail closed if either persistent log rotates or truncates. Inspect only appended bytes and require ordered, context-coherent markers from this stop:

```bash
ssh root@orgrimmar /bin/sh -s > "$EVIDENCE_DIR/controlled-stop.log" <<'REMOTE'
set -eu
step=stop_workspace
tmpdir=
cleanup_controlled_stop() {
  rc=$?
  trap - EXIT
  if test -n "$tmpdir"; then
    rm -rf "$tmpdir" || {
      cleanup_rc=$?
      test "$rc" -ne 0 || rc=$cleanup_rc
    }
  fi
  if test "$rc" -ne 0; then
    printf 'controlled_stop_failed_step=%s rc=%s\n' "$step" "$rc"
  fi
  exit "$rc"
}
trap cleanup_controlled_stop EXIT
tmpdir=$(mktemp -d /run/hermes-v020-stop.XXXXXX)
gateway_log=/var/hermes/logs/gateway.log
exit_log=/var/hermes/logs/gateway-exit-diag.log
lifecycle=/var/hermes/state/gateway.lifecycle.json

step=stop_signal_contract
test "$(podman inspect hermes --format '{{.Config.StopSignal}}')" = SIGTERM
step=stop_gateway_precondition
podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
step=stop_lifecycle_precondition
jq -e '.phase == "running"' "$lifecycle" >/dev/null
step=stop_direct_signal_gate
# A just-created dynamic service can retain a short-lived startup takeover/stop
# marker. Wait until it no longer targets this PID so Podman's SIGTERM exercises
# the intentional direct-signal path rather than a planned gateway stop.
for _ in $(seq 1 65); do
  if podman exec hermes python -c \
    'from gateway.status import planned_stop_marker_targets_self; assert not planned_stop_marker_targets_self()' \
    2>/dev/null; then
    break
  fi
  sleep 1
done
podman exec hermes python -c \
  'from gateway.status import planned_stop_marker_targets_self; assert not planned_stop_marker_targets_self()'
step=stop_evidence_baseline
cp "$lifecycle" "$tmpdir/lifecycle-before.json"
gateway_inode=$(stat -Lc %i "$gateway_log")
gateway_size=$(stat -Lc %s "$gateway_log")
exit_inode=$(stat -Lc %i "$exit_log")
exit_size=$(stat -Lc %s "$exit_log")
step=stop_journal_cursor
cursor=$(journalctl -u podman-hermes.service -n 0 --show-cursor --no-pager | sed -n 's/^-- cursor: //p')
test -n "$cursor"
step=stop_container_identity
container_id=$(podman inspect hermes --format '{{.Id}}')
printf '%s\n' "$container_id" | grep -Eq '^[0-9a-f]{64}$'
step=stop_event_lower_bound
event_since=$(date --iso-8601=ns)
stop_epoch=$(date +%s)

step=stop_systemd_stop
systemctl stop podman-hermes.service
step=stop_event_upper_bound
event_until=$(date --iso-8601=ns)

step=stop_log_identity
test "$(stat -Lc %i "$gateway_log")" = "$gateway_inode"
test "$(stat -Lc %i "$exit_log")" = "$exit_inode"
step=stop_log_growth
test "$(stat -Lc %s "$gateway_log")" -gt "$gateway_size"
test "$(stat -Lc %s "$exit_log")" -gt "$exit_size"
step=stop_current_evidence_slices
tail -c +$((gateway_size + 1)) "$gateway_log" > "$tmpdir/gateway-appended"
tail -c +$((exit_size + 1)) "$exit_log" > "$tmpdir/exit-appended"
journalctl -u podman-hermes.service --after-cursor "$cursor" --no-pager > "$tmpdir/journal-appended"
step=stop_event_capture
podman events --stream=false --since "$event_since" --until "$event_until" \
  --filter "container=$container_id" --format '{{json .}}' \
  > "$tmpdir/podman-events"
event_lines=$(wc -l < "$tmpdir/podman-events" | tr -d ' ')
test "$event_lines" -gt 0 -a "$event_lines" -le 20
step=stop_event_contract
jq -s -e --arg id "$container_id" '
  all(.[]; .Type == "container" and .ID == $id and .Name == "hermes") and
  ([.[] | select(.Status == "died")] | length == 1) and
  ([.[] | select(.Status == "died")][0].ContainerExitCode == 0) and
  all(.[];
    ((.Status | ascii_downcase | test("oom|kill")) | not) and
    ((.ContainerExitCode // 0) != 137)
  )
' "$tmpdir/podman-events" >/dev/null
step=stop_auto_remove
if podman container exists "$container_id"; then
  exit 1
fi

step=stop_gateway_marker_order
sigterm_line=$(grep -n -m1 'Received SIGTERM' "$tmpdir/gateway-appended" | cut -d: -f1)
context_line=$(grep -n -m1 -E 'Shutdown context:.*signal=SIGTERM.*parent_name=s6-supervise.*gateway-default' "$tmpdir/gateway-appended" | cut -d: -f1)
stopped_line=$(grep -n -m1 'Gateway stopped' "$tmpdir/gateway-appended" | cut -d: -f1)
test -n "$sigterm_line" -a -n "$context_line" -a -n "$stopped_line"
test "$sigterm_line" -lt "$context_line" -a "$context_line" -lt "$stopped_line"
step=stop_exit_marker_order
jq -s -e --argjson lifecycle "$(cat "$lifecycle")" '
  to_entries as $records |
  [$records[] | select(.value.tag == "asyncio.run.returned")] as $returned |
  [$records[] | select(
    .value.tag == "gateway.exit_clean" or
    .value.tag == "gateway.exit_nonzero"
  )] as $exit |
  ($returned | length) == 1 and
  ($exit | length) == 1 and
  ($returned[0].value | has("success")) and
  ($returned[0].value.success | type == "boolean") and
  ($returned[0].value | has("pid")) and
  ($returned[0].value.pid | type == "number" and floor == . and . > 0) and
  ($exit[0].value | has("pid")) and
  ($exit[0].value.pid | type == "number" and floor == . and . > 0) and
  ($lifecycle | has("pid")) and
  ($lifecycle.pid | type == "number" and floor == . and . > 0) and
  ($returned[0].key < $exit[0].key) and
  ($returned[0].value.pid == $exit[0].value.pid) and
  ($returned[0].value.pid == $lifecycle.pid) and
  ($lifecycle.phase == "exited") and
  ($lifecycle.exit_reason == "graceful_shutdown") and
  (if $returned[0].value.success
   then $exit[0].value.tag == "gateway.exit_clean" and $lifecycle.exit_code == 0
   else $exit[0].value.tag == "gateway.exit_nonzero" and $lifecycle.exit_code == 1
   end)
' "$tmpdir/exit-appended" >/dev/null
step=stop_lifecycle_freshness
test "$(stat -c %Y "$lifecycle")" -ge "$stop_epoch"
step=stop_lifecycle_transition
jq -e '.phase == "exited" and .exit_reason == "graceful_shutdown" and (.exit_code == 0 or .exit_code == 1)' "$lifecycle" >/dev/null
jq -e '.phase == "running"' "$tmpdir/lifecycle-before.json" >/dev/null

step=stop_journal_forbidden_signatures
if grep -Eqi 'SIGKILL|status=137|code=killed|resorting to SIGKILL|escalat.*kill|oom-kill|Out of memory|Killed process' "$tmpdir/journal-appended"; then
  exit 1
fi
step=stop_static_s6_teardown
for service in legacy-services main-hermes dashboard legacy-cont-init fix-attrs; do
  grep -F "service $service successfully stopped" "$tmpdir/journal-appended" >/dev/null
done
step=stop_summary_output
printf 'stop_signal=SIGTERM\n'
printf 'gateway_appended=sigterm_context_gateway_stopped_ordered\n'
printf 'exit_diag_appended=one_coherent_ordered_variant\n'
printf 'lifecycle_transition=running_to_exited_graceful_coherent_code\n'
printf 'static_s6_stops=legacy-services,main-hermes,dashboard,legacy-cont-init,fix-attrs\n'
printf 'podman_events=current_container_died_code0_no_oom_kill_137\n'
printf 'sigkill_137_or_oom=absent\n'

step=restart_systemd_start
systemctl start podman-hermes.service
step=restart_readiness_wait
for _ in $(seq 1 120); do
  if podman exec hermes /command/s6-svstat /run/service/gateway-default 2>/dev/null | grep -q '^up ' &&
     podman exec hermes python -c 'import json; assert json.load(open("/opt/data/gateway_state.json"))["gateway_state"] == "running"; assert json.load(open("/opt/data/state/gateway.lifecycle.json"))["phase"] == "running"' 2>/dev/null; then
    break
  fi
  sleep 1
done
step=restart_readiness_final
podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
podman exec hermes python -c 'import json; assert json.load(open("/opt/data/gateway_state.json"))["gateway_state"] == "running"; assert json.load(open("/opt/data/state/gateway.lifecycle.json"))["phase"] == "running"'
step=restart_summary_output
printf 'restart_readiness=gateway_default_runtime_lifecycle_running\n'
REMOTE
chmod 600 "$EVIDENCE_DIR/controlled-stop.log"
```

Hermes 0.20 can complete direct-SIGTERM teardown with either of two coherent application outcomes depending on startup state: `success=true`, `gateway.exit_clean`, lifecycle code 0; or `success=false`, `gateway.exit_nonzero`, lifecycle code 1. The current NDJSON slice and lifecycle are parsed together and accept only one exact ordered, same-PID tuple with `phase=exited` and `exit_reason=graceful_shutdown`; duplicates, missing/non-boolean fields, reversed/mixed markers, PID mismatch, or code/reason mismatch fail closed. The pre-stop gate still excludes a planned gateway stop, and both variants still require the same ordered SIGTERM/s6 context and `Gateway stopped`, every static s6 stop, and no SIGKILL, status 137, or OOM. Because the production container is auto-removed, OOM/kill/137 evidence comes from ID-scoped Podman events captured between timestamps surrounding this stop plus the cursor-scoped service journal; the runbook never inspects the removed name. It requires one outer container `died` event with code 0, no OOM/kill event or code 137, and then proves a new container reaches restart readiness. If any current-evidence, lifecycle-transition, complete-static-stop, or restart-readiness assertion fails, invoke Step 8 rollback; neither outer container code 0 nor either application tuple alone is sufficient.

- [ ] **Step 7: Deliberately open the persistent gate and re-enable vault synchronization**

Only after every Step 6 check passes, or after every guarded 0.17 rollback-health check in Step 8 passes, remove the exact marker deliberately. The failure trap below never removes the marker: it only recreates the fail-safe gate if the controlled oneshot or timer start fails after removal.

```bash
ssh root@orgrimmar /bin/sh -s > "$EVIDENCE_DIR/vault-sync-reenable.log" <<'REMOTE'
set -eu
marker=/var/lib/hermes-migration/vault-sync.inhibit
committed=false
restore_gate_on_failure() {
  rc=$?
  trap - EXIT HUP INT TERM
  if ! "$committed"; then
    install -d -m 0700 -o root -g root /var/lib/hermes-migration || true
    install -m 0600 -o root -g root /dev/null "$marker" || true
    systemctl stop hermes-vault-sync.timer hermes-vault-sync.service >/dev/null 2>&1 || true
  fi
  exit "$rc"
}
trap restore_gate_on_failure EXIT HUP INT TERM

test -f "$marker"
test "$(stat -c '%U:%G %a' "$marker")" = 'root:root 600'
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc "ConditionPathExists=!$marker")" = 1
done
rm -- "$marker"
systemctl reset-failed hermes-vault-sync.service
systemctl start --wait hermes-vault-sync.service
test "$(systemctl show hermes-vault-sync.service -p Result --value)" = success
test "$(systemctl show hermes-vault-sync.service -p ExecMainStatus --value)" = 0
systemctl start hermes-vault-sync.timer
test "$(systemctl is-active hermes-vault-sync.timer)" = active
test "$(systemctl is-active podman-hermes.service)" = active
committed=true
trap - EXIT HUP INT TERM
printf 'vault_gate_marker=removed_deliberately\nvault_sync_oneshot=success\nvault_sync_timer=active\nhermes=active\n'
REMOTE
chmod 600 "$EVIDENCE_DIR/vault-sync-reenable.log"
```

Expected: one controlled oneshot succeeds before timer scheduling resumes. The declarative condition remains permanently in both units and is inert while the marker is absent. A stale marker or interrupted cleanup fails safe.

- [ ] **Step 8: Use the exact rollback order on any failure**

If deployment or validation fails and the captured local copy exists, run the complete local restore in one fail-fast boundary:

```bash
(
set -euo pipefail
CONFIG_SHA256=$(grep -E '^[0-9a-f]{64}$' "$EVIDENCE_DIR/config-sha256")
HERMES_017_IMAGE=$(grep -E '^docker.io/nousresearch/hermes-agent@sha256:[0-9a-f]{64}$' "$EVIDENCE_DIR/hermes-017-image")
ROLLBACK_DIR=$(grep -E '^/var/hermes-pre-v020-[0-9]{8}T[0-9]{6}Z$' "$EVIDENCE_DIR/rollback-dir")
test -n "$CONFIG_SHA256" -a -n "$HERMES_017_IMAGE" -a -n "$ROLLBACK_DIR"
ssh root@orgrimmar /bin/sh -s -- "$CONFIG_SHA256" "$HERMES_017_IMAGE" "$ROLLBACK_DIR" <<'REMOTE'
set -eu
config_sha256=$1
old_image=$2
rollback_dir=$3
marker=/var/lib/hermes-migration/vault-sync.inhibit
test -f "$marker"
systemctl stop podman-hermes.service hermes-vault-sync.timer hermes-vault-sync.service
test "$(systemctl is-active podman-hermes.service || true)" = inactive
test "$(systemctl is-active hermes-vault-sync.timer || true)" = inactive
test "$(systemctl is-active hermes-vault-sync.service || true)" = inactive
test -d "$rollback_dir"
mv /var/hermes "/var/hermes.failed-$(date -u +%Y%m%dT%H%M%SZ)"
mv "$rollback_dir" /var/hermes
test "$(sha256sum /var/hermes/config.yaml | cut -d' ' -f1)" = "$config_sha256"
podman run --rm --entrypoint python --user 10000:10000 \
  -e HOME=/var/hermes -v /var/hermes:/var/hermes:ro "$old_image" \
  -c 'from hermes_cli.config import check_config_version; value=check_config_version(); print(value); assert value == (30, 30)'
REMOTE
)
```

Only after this schema-30 proof may the exact prepared guarded 0.17 closure be activated using the common boundary below. Never select a historical generation or infer a generation number.

If the captured local copy is unavailable, pass the captured archive name to this single fail-fast fallback while all writers remain stopped and the persistent marker remains present:

```bash
(
set -euo pipefail
ARCHIVE=$(jq -er '.archives[0].name | select(length > 0)' "$EVIDENCE_DIR/hermes-pre-v020-borg.json")
CONFIG_SHA256=$(grep -E '^[0-9a-f]{64}$' "$EVIDENCE_DIR/config-sha256")
HERMES_017_IMAGE=$(grep -E '^docker.io/nousresearch/hermes-agent@sha256:[0-9a-f]{64}$' "$EVIDENCE_DIR/hermes-017-image")
test -n "$ARCHIVE" -a -n "$CONFIG_SHA256" -a -n "$HERMES_017_IMAGE"
encode_ssh_arg() { printf '%s' "$1" | base64 | tr -d '\n'; }
ssh gnomeregan bash -s -- \
  "$(encode_ssh_arg "$ARCHIVE")" "$(encode_ssh_arg "$CONFIG_SHA256")" \
  "$(encode_ssh_arg "$HERMES_017_IMAGE")" <<'REMOTE'
set -euo pipefail
decode_ssh_arg() { printf '%s' "$1" | base64 -d; }
archive=$(decode_ssh_arg "$1")
config_sha256=$(decode_ssh_arg "$2")
old_image=$(decode_ssh_arg "$3")
restore_dir=$(mktemp -d /var/tmp/hermes-restore.XXXXXX)
trap 'sudo rm -rf "$restore_dir"' EXIT
sudo ssh -i /home/fdrake/.ssh/id_ansible -p 2222 \
  -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new \
  -o UserKnownHostsFile=/var/lib/backup-staging/known_hosts \
  root@10.1.1.4 'set -e; test -f /var/lib/hermes-migration/vault-sync.inhibit; systemctl stop podman-hermes.service hermes-vault-sync.timer hermes-vault-sync.service; test "$(systemctl is-active podman-hermes.service || true)" = inactive; test "$(systemctl is-active hermes-vault-sync.timer || true)" = inactive; test "$(systemctl is-active hermes-vault-sync.service || true)" = inactive; mv /var/hermes "/var/hermes.failed-$(date -u +%Y%m%dT%H%M%SZ)"; install -d -m 0755 -o 10000 -g 10000 /var/hermes'
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

Only after the direct ownership/digest/schema assertion may the exact prepared guarded 0.17 closure be activated. Keep the marker through activation and all rollback health checks. Activate no other 0.17 closure:

```bash
set -euo pipefail
GUARDED_017_CLOSURE=$(grep -E '^/nix/store/[0-9a-z]+-nixos-system-orgrimmar-' \
  "$EVIDENCE_DIR/guarded-017-closure")
GATE_MARKER_INODE=$(grep -E '^[0-9]+:[0-9]+$' \
  "$EVIDENCE_DIR/vault-gate-marker-inode")
VAULT_EXEC_TIMESTAMP=$(<"$EVIDENCE_DIR/vault-exec-timestamp")
IFS=$'\t' read -r PRE_VERSION PRE_SCHEMA PRE_PROVIDER PRE_MODEL PRE_PROVIDER_HEALTH PRE_PROVIDER_AUTH \
  PRE_VAULT_PATH PRE_VAULT_COUNT PRE_MEMORY_PATH PRE_MEMORY_COUNT \
  PRE_SESSION_PATH PRE_SESSION_COUNT PRE_SYNC_VAULT_PATH PRE_SYNC_VAULT_COUNT \
  < "$EVIDENCE_DIR/pre-upgrade-state.tsv"
encode_ssh_arg() { printf '%s' "$1" | base64 | tr -d '\n'; }
ssh root@orgrimmar /bin/sh -s -- \
  "$(encode_ssh_arg "$GUARDED_017_CLOSURE")" "$(encode_ssh_arg "$GATE_MARKER_INODE")" \
  "$(encode_ssh_arg "$VAULT_EXEC_TIMESTAMP")" "$(encode_ssh_arg "$PRE_PROVIDER")" \
  "$(encode_ssh_arg "$PRE_MODEL")" "$(encode_ssh_arg "$PRE_PROVIDER_HEALTH")" \
  "$(encode_ssh_arg "$PRE_PROVIDER_AUTH")" "$(encode_ssh_arg "$PRE_VAULT_PATH")" \
  "$(encode_ssh_arg "$PRE_VAULT_COUNT")" "$(encode_ssh_arg "$PRE_MEMORY_PATH")" \
  "$(encode_ssh_arg "$PRE_MEMORY_COUNT")" "$(encode_ssh_arg "$PRE_SESSION_PATH")" \
  "$(encode_ssh_arg "$PRE_SESSION_COUNT")" "$(encode_ssh_arg "$PRE_SYNC_VAULT_PATH")" \
  "$(encode_ssh_arg "$PRE_SYNC_VAULT_COUNT")" \
  > "$EVIDENCE_DIR/guarded-017-rollback-health.log" <<'REMOTE'
set -eu
decode_ssh_arg() { printf '%s' "$1" | base64 -d; }
closure=$(decode_ssh_arg "$1"); expected_marker_inode=$(decode_ssh_arg "$2")
expected_exec=$(decode_ssh_arg "$3"); pre_provider=$(decode_ssh_arg "$4")
pre_model=$(decode_ssh_arg "$5"); pre_provider_health=$(decode_ssh_arg "$6")
pre_provider_auth=$(decode_ssh_arg "$7"); pre_vault_path=$(decode_ssh_arg "$8")
pre_vault_count=$(decode_ssh_arg "$9"); pre_memory_path=$(decode_ssh_arg "${10}")
pre_memory_count=$(decode_ssh_arg "${11}"); pre_session_path=$(decode_ssh_arg "${12}")
pre_session_count=$(decode_ssh_arg "${13}"); pre_sync_vault_path=$(decode_ssh_arg "${14}")
pre_sync_vault_count=$(decode_ssh_arg "${15}")
marker=/var/lib/hermes-migration/vault-sync.inhibit
condition="ConditionPathExists=!$marker"
tmpdir=$(mktemp -d /run/hermes-v017-rollback-health.XXXXXX)
trap 'rm -rf "$tmpdir"' EXIT
host_path() {
  case "$1" in /opt/data/*) printf '/var/hermes/%s' "${1#/opt/data/}" ;; *) exit 1 ;; esac
}
count_files() { find "$(host_path "$1")" -type f | wc -l | tr -d ' '; }

test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
# The selected local/Borg restore boundary immediately above already proved
# config digest and schema 30 with the captured 0.17 image.
nix-env --profile /nix/var/nix/profiles/system --set "$closure"
"$closure/bin/switch-to-configuration" switch

# This is the first post-activation boundary; prove the gate before health checks.
test "$(readlink -f /run/current-system)" = "$closure"
test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
  systemctl start "$unit" >/dev/null 2>&1 || true
  test "$(systemctl show "$unit" -p ConditionResult --value)" = no
  test "$(systemctl is-active "$unit" || true)" = inactive
done
test "$(systemctl show hermes-vault-sync.service \
  -p ExecMainStartTimestampMonotonic --value)" = "$expected_exec"

command -v timeout >/dev/null
monotonic_centiseconds() {
  IFS=' ' read -r uptime _ < /proc/uptime
  seconds=${uptime%%.*}
  fraction=${uptime#*.}00
  fraction_tail=${fraction#??}
  hundredths=${fraction%"$fraction_tail"}
  printf '%s\n' "$((seconds * 100 + 1$hundredths - 100))"
}
deadline=$(( $(monotonic_centiseconds) + 12000 ))
remaining_centiseconds() {
  remaining=$((deadline - $(monotonic_centiseconds)))
  test "$remaining" -gt 0 || return 1
  printf '%s\n' "$remaining"
}
duration_seconds() {
  printf '%s.%02d\n' "$(( $1 / 100 ))" "$(( $1 % 100 ))"
}
bounded_capture() {
  remaining=$(remaining_centiseconds) || return 1
  duration=$(duration_seconds "$remaining")
  timeout --signal=KILL "${duration}s" "$@"
}
probe_rollback_readiness() {
  service=$(bounded_capture systemctl is-active podman-hermes.service 2>/dev/null) || return 1
  test "$service" = active || return 1
  version=$(bounded_capture podman exec hermes hermes --version 2>/dev/null) || return 1
  case "$version" in
    'Hermes Agent v0.17.0 (2026.6.19)'*) ;;
    *) return 1 ;;
  esac
  schema=$(bounded_capture podman exec hermes python -c \
    'from hermes_cli.config import check_config_version; print(check_config_version())' \
    2>/dev/null) || return 1
  test "$schema" = '(30, 30)' || return 1
  gateway=$(bounded_capture podman exec hermes /command/s6-svstat \
    /run/service/gateway-default 2>/dev/null) || return 1
  case "$gateway" in 'up '*) ;; *) return 1 ;; esac
  remaining=$(remaining_centiseconds) || return 1
  duration=$(duration_seconds "$remaining")
  dashboard=$(timeout --signal=KILL "${duration}s" curl \
    --connect-timeout "$duration" --max-time "$duration" \
    -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:9119/ 2>/dev/null) || return 1
  test "$dashboard" = 302
}
rollback_ready=false
while remaining_centiseconds >/dev/null; do
  if probe_rollback_readiness; then
    rollback_ready=true
    break
  fi
  remaining=$(remaining_centiseconds) || break
  duration=$(duration_seconds "$remaining")
  timeout --signal=KILL "${duration}s" sleep 1 || true
done
if test "$rollback_ready" != true; then
  test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
  exit 1
fi

# Readiness is not permission to open the gate. Re-prove the complete no-writer
# boundary immediately before exact health and state comparisons.
test "$(readlink -f /run/current-system)" = "$closure"
test "$(stat -c '%d:%i' "$marker")" = "$expected_marker_inode"
for unit in hermes-vault-sync.timer hermes-vault-sync.service; do
  test "$(systemctl cat "$unit" | grep -Fxc "$condition")" = 1
  test "$(systemctl show "$unit" -p ConditionResult --value)" = no
  test "$(systemctl is-active "$unit" || true)" = inactive
done
test "$(systemctl show hermes-vault-sync.service \
  -p ExecMainStartTimestampMonotonic --value)" = "$expected_exec"

systemctl is-active podman-hermes.service >/dev/null
case "$(podman exec hermes hermes --version | head -n 1)" in
  'Hermes Agent v0.17.0 (2026.6.19)'*) ;;
  *) exit 1 ;;
esac
test "$(podman exec hermes python -c 'from hermes_cli.config import check_config_version; print(check_config_version())')" = '(30, 30)'
podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
test "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:9119/)" = 302
for pair in \
  "$pre_vault_path:$pre_vault_count" \
  "$pre_memory_path:$pre_memory_count" \
  "$pre_session_path:$pre_session_count" \
  "$pre_sync_vault_path:$pre_sync_vault_count"; do
  path=${pair%:*}
  expected=${pair##*:}
  test "$(count_files "$path")" = "$expected"
done
podman exec hermes hermes status > "$tmpdir/status"
jq -Rers '
  gsub("\u001b\\[[0-9;]*[A-Za-z]"; "") as $text |
  ($text | capture("(?m)^\\s*Model:\\s*(?<v>\\S.*?)\\s*$").v) as $model |
  ($text | capture("(?m)^\\s*Provider:\\s*(?<v>\\S.*?)\\s*$").v) as $provider |
  [$text | splits("\\n") |
    select((ascii_downcase | contains($provider | ascii_downcase)) and contains("✓"))
  ] as $affirmative |
  ($affirmative | length > 0) as $healthy |
  ($affirmative | any(test("(?i)(logged in|configured|authenticated)"))) as $authenticated |
  select(($model | length) > 0 and ($provider | length) > 0 and $healthy and $authenticated) |
  [$provider, $model, "healthy", "authenticated"] | @tsv
' "$tmpdir/status" > "$tmpdir/provider.tsv"
IFS=$(printf '\t') read -r provider model provider_health provider_auth < "$tmpdir/provider.tsv"
test "$provider" = "$pre_provider"
test "$model" = "$pre_model"
test "$provider_health" = "$pre_provider_health"
test "$provider_auth" = "$pre_provider_auth"
printf 'rollback_closure=%s\ngate=condition_false_inactive_no_exec\nversion=0.17\nschema=(30, 30)\ndashboard_http=302\nprovider=%s\nmodel=%s\nstate_counts=matched\n' \
  "$closure" "$provider" "$model"
REMOTE
chmod 600 "$EVIDENCE_DIR/guarded-017-rollback-health.log"
```

Never start 0.17 against schema-33 state. The rollback readiness poll uses `/proc/uptime` for a monotonic 120-second deadline and bounds every service/container/dashboard probe to the remaining time. Timeout reasserts the exact marker inode and fails closed. Success fully re-proves the closure, marker inode, both effective gate conditions, `ConditionResult=no`, inactive vault units, and unchanged writer timestamp before exact health comparisons. Only after this exact closure, gate, version/schema, gateway, dashboard, provider/model, and state-count proof passes may Step 7 deliberately remove the marker, run one successful vault-sync oneshot, and start the timer.

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
