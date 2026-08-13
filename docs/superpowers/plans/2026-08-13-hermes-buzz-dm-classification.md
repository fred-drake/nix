# Hermes Buzz DM Classification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an allowlisted owner’s valid mention-free one-to-one Buzz DM reach Hermes without weakening ordinary-channel mention gating or adapter-level non-owner denial.

**Architecture:** Patch only Hermes’s Buzz adapter at the source revision embedded in the deployed image. The adapter will classify a fallback conversation as a DM only from relay-authored `dm/private` metadata, an exact two-member `member` roster containing Hermes and one allowlisted owner, and an event authored and channel-bound by that owner. Nix will checksum the unpatched source, apply one focused patch, compile and install only `adapter.py`, then mount that file read-only over the unchanged digest-pinned image.

**Tech Stack:** Python/pytest/uv, Nix `stdenvNoCC`, generated `fetchFromGitHub` pins, Podman, Colmena, Buzz CLI, Hermes Agent 0.20.

## Global Constraints

- Hermes source revision: `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` (tag `v2026.8.3`).
- Hermes source fetch hash: `sha256-S6TSGgpf37N8YgbTv70dT+LaPiiaQ4/lJV+js2hnCPk=`.
- Unpatched `plugins/platforms/buzz/adapter.py` SHA-256: `8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b`.
- Runtime image: `docker.io/nousresearch/hermes-agent@sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e`.
- Buzz CLI/source revision remains `4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc`; do not change it.
- Ordinary channels continue to require an explicit Hermes mention.
- A non-allowlisted author must be rejected before DM classification, gateway dispatch, model execution, or tool execution.
- Mention-free DM classification requires `dm/private`, exactly two distinct `member` pubkeys, Hermes plus one member in a non-empty `_allowed_pubkeys`, matching event author, and exactly one matching `h` channel tag.
- Missing, malformed, duplicate, conflicting, stale, or unsuccessful evidence fails closed to `group` and remains mention-gated.
- Group DMs remain out of scope and mention-gated.
- Keep the image digest, `/var/hermes`, secrets, managed configuration, CLI mount, transport, discovery cadence, high-water marks, de-duplication, and dispatch API unchanged.
- Do not add configuration, direct database access, a generic Nostr client, a background cache, a global overlay, or a derived mutable image.
- Do not use `podman cp`, edit a running `/opt/hermes`, mutate persistent state, or mount the host Nix store wholesale.
- Add exactly one new read-only file mount and deploy only Orgrimmar; never run `just switch`.
- Deployment remains separately authorized. Implementation and preflight do not authorize activation.
- Never record private keys, SOPS plaintext, full environments, or message bodies.

## File Map

- Modify `apps/fetcher/repos.toml`: declare the exact Hermes source revision.
- Modify generated `apps/fetcher/repos-src.nix`: add only `hermes-agent-v2026.8.3-src` with the exact revision/hash above.
- Create `apps/hermes-buzz-owner-dm.patch`: unified diff for only upstream `plugins/platforms/buzz/adapter.py` and `tests/gateway/test_buzz_adapter.py`.
- Create `apps/hermes-buzz-adapter.nix`: checksum, patch, compile, and install only `$out/adapter.py`.
- Modify `modules/services/hermes.nix`: instantiate the package and add the single read-only adapter mount.

---

### Task 1: Pin the exact Hermes source and establish a clean patch workspace

**Files:**
- Modify: `apps/fetcher/repos.toml`
- Modify (generated): `apps/fetcher/repos-src.nix`

**Interfaces:**
- Consumes: NousResearch Hermes commit `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`.
- Produces: `repos-src.hermes-agent-v2026.8.3-src` with fetch hash `sha256-S6TSGgpf37N8YgbTv70dT+LaPiiaQ4/lJV+js2hnCPk=`.

- [ ] **Step 1: Prove the implementation worktree and baseline are clean**

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
cd "$WORKTREE"
test "$(pwd -P)" = "$WORKTREE"
test "$(git rev-parse --show-toplevel)" = "$WORKTREE"
test "$(git branch --show-current)" = feat/hermes-native-buzz
test -z "$(git status --porcelain --untracked-files=all)"
git merge-base --is-ancestor 65768718ed043f467aab046700e5941f77681f98 HEAD
```

Expected: every assertion succeeds. Review the commits after `65768718ed043f467aab046700e5941f77681f98` and require them to contain only this approved plan before implementation; do not proceed with unrelated changes.

- [ ] **Step 2: Add the exact source declaration**

Append this stanza to `apps/fetcher/repos.toml`:

```toml
[[repos]]
name = "hermes-agent-v2026.8.3-src"
url = "https://github.com/NousResearch/hermes-agent"
rev = "3c27eb6234bf91b8ceee9e9071591b31e9b148cb"
```

- [ ] **Step 3: Regenerate and retain only the intended generated entry**

```bash
just update-repos
git diff -- apps/fetcher/repos.toml apps/fetcher/repos-src.nix
```

Restore every unrelated moving repository entry in `apps/fetcher/repos-src.nix` from `HEAD`. The retained generated entry must be exactly:

```nix
hermes-agent-v2026.8.3-src = pkgs.fetchFromGitHub {
  owner = "NousResearch";
  repo = "hermes-agent";
  rev = "3c27eb6234bf91b8ceee9e9071591b31e9b148cb";
  hash = "sha256-S6TSGgpf37N8YgbTv70dT+LaPiiaQ4/lJV+js2hnCPk=";
};
```

- [ ] **Step 4: Materialize a disposable editable source tree and prove provenance**

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
cd "$WORKTREE"
HERMES_SRC=$(nix eval --raw --impure --expr '
  let
    pkgs = import <nixpkgs> {};
    sources = import ./apps/fetcher/repos-src.nix {inherit pkgs;};
  in toString sources.hermes-agent-v2026.8.3-src
')
PATCH_TREE=$(mktemp -d "${TMPDIR:-/tmp}/hermes-buzz-dm.XXXXXX")
cp -R "$HERMES_SRC"/. "$PATCH_TREE"/
chmod -R u+w "$PATCH_TREE"
test "$(sha256sum "$PATCH_TREE/plugins/platforms/buzz/adapter.py" | cut -d' ' -f1)" = \
  8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b
(
  cd "$PATCH_TREE"
  git init -q
  git config user.name "Hermes patch builder"
  git config user.email "hermes-patch@invalid.local"
  git add plugins/platforms/buzz/adapter.py tests/gateway/test_buzz_adapter.py
  git commit -qm "baseline Hermes v2026.8.3 Buzz adapter"
  uv run --locked --extra dev python -m pytest tests/gateway/test_buzz_adapter.py -q
)
printf '%s\n' "$PATCH_TREE"
```

Expected: the unpatched focused module reports `23 passed`; preserve `PATCH_TREE` in the current shell for Tasks 2–3.

### Task 2: Add focused RED fixtures for the complete security invariant

**Files:**
- Modify in disposable `PATCH_TREE`: `tests/gateway/test_buzz_adapter.py`
- Final artifact produced in Task 3: `apps/hermes-buzz-owner-dm.patch`

**Interfaces:**
- Consumes: the existing `_ScriptedCli`, captured `_dispatch_message`, `_tagged_event`, `SELF_PUBKEY`, `OTHER_PUBKEY`, `CHANNEL`, and `DM_CHANNEL` fixtures.
- Produces: deterministic fixtures for authoritative discovery, owner-only latching, unchanged mentions, and every fail-closed case.

- [ ] **Step 1: Make the owner identity and authoritative relay projections explicit**

In `tests/gateway/test_buzz_adapter.py`, keep `OTHER_PUBKEY` as the allowlisted owner and add these exact helpers after `_tagged_event`:

```python
def _dm_search(channel_id=DM_CHANNEL, *, channel_type="dm", visibility="private"):
    return [{
        "channel_id": channel_id,
        "name": "DM",
        "channel_type": channel_type,
        "visibility": visibility,
        "archived": False,
        "about": None,
        "topic": None,
        "purpose": None,
    }]


def _dm_members(owner=OTHER_PUBKEY, *, self_role="member", owner_role="member"):
    return [
        {"pubkey": SELF_PUBKEY, "role": self_role},
        {"pubkey": owner, "role": owner_role},
    ]


async def _discover_fallback_dm(adapter, *, search=None, members=None,
                                search_code=0, members_code=0):
    cli = _ScriptedCli()
    cli.script("dms", "list", [])
    cli.script("channels", "list", [
        {"channel_id": DM_CHANNEL, "name": "DM", "description": "", "created_at": 1},
    ])
    cli.script("channels", "search", _dm_search() if search is None else search,
               code=search_code, stderr="search failed" if search_code else "")
    cli.script("channels", "members", _dm_members() if members is None else members,
               code=members_code, stderr="members failed" if members_code else "")
    adapter._run_cli = cli
    await adapter._discover_dms(seed=False)
    return cli
```

Update `TestDmClassification.adapter` so `a._allowed_pubkeys = {OTHER_PUBKEY}`. Use only public test keys.

- [ ] **Step 2: Replace the p-tag regression with the load-bearing mention-free fixture**

Add `test_valid_owner_dm_without_p_tag_dispatches_once_as_dm`. It must:

1. call `_discover_fallback_dm(adapter)`;
2. pass `_tagged_event("e-owner-dm", DM_CHANNEL, content="owner dm without mention")`, whose tags are only `[["h", DM_CHANNEL]]`;
3. call `_handle_event` against the discovered state;
4. assert state `chat_type == "dm"`;
5. assert exactly one dispatch with `message_id == "e-owner-dm"`, `user_id == OTHER_PUBKEY`, and `chat_type == "dm"`; and
6. assert the scripted CLI made exactly one call whose prefix is `channels search --query DM --exact --include-archived` and exactly one `channels members --channel DM_CHANNEL` call.

- [ ] **Step 3: Add the anti-misclassification and authorization fixtures**

Add these tests with the exact outcomes:

- `test_private_stream_named_dm_remains_mention_gated`: search returns `_dm_search(channel_type="stream")`; an owner event with only the matching `h` tag leaves `chat_type == "group"` and dispatches zero times.
- `test_unauthorized_event_is_rejected_before_latch`: authoritative evidence names `OTHER_PUBKEY` as the owner, `_allowed_pubkeys == {OTHER_PUBKEY}`, but the event author is `"b" * 64`; state remains `group` and dispatch count is zero.
- `test_empty_allowlist_never_unlocks_mention_free_dm`: clear `_allowed_pubkeys`, use valid metadata/members, send the owner’s mention-free event, and assert `group` plus zero dispatches.

- [ ] **Step 4: Add unchanged-mentioned-path fixtures**

Add one parametrized test covering these exact rows:

| Author | Conversation evidence | Content | Expected dispatch | Expected `chat_type` |
|---|---|---|---:|---|
| owner | ordinary `stream/private` | `@Chip owner channel mention` | 1 | `group` |
| owner | verified `dm/private` | `@Chip owner DM mention` | 1 | `dm` |
| `"b" * 64` | ordinary `stream/private` | `@Chip non-owner mention` | 0 | `group` |
| `"b" * 64` | verified `dm/private` | `@Chip non-owner DM mention` | 0 | `group` |

The verified owner DM event may contain a `p` tag or omit it; add both forms and assert identical classification to prove `p` tags are irrelevant.

- [ ] **Step 5: Add the complete fail-closed matrix**

Add parametrized fixtures for all of the following, each sending an allowlisted owner’s mention-free kind-9 event and asserting zero dispatches plus `chat_type == "group"`:

```python
FAIL_CLOSED_CASES = [
    pytest.param({"search_code": 2}, id="search-failure"),
    pytest.param({"search": _dm_search(channel_type=None)}, id="missing-type"),
    pytest.param({"search": _dm_search(channel_type="forum")}, id="wrong-type"),
    pytest.param({"search": _dm_search(visibility=None)}, id="missing-visibility"),
    pytest.param({"search": _dm_search(visibility="public")}, id="wrong-visibility"),
    pytest.param({"members_code": 2}, id="members-failure"),
    pytest.param({"members": _dm_members() + [{"pubkey": "c" * 64, "role": "member"}]}, id="group-dm"),
    pytest.param({"members": _dm_members() + [{"pubkey": OTHER_PUBKEY, "role": "member"}]}, id="duplicate-member"),
    pytest.param({"members": _dm_members() + [{"pubkey": OTHER_PUBKEY, "role": "owner"}]}, id="conflicting-member"),
    pytest.param({"members": _dm_members(self_role="bot")}, id="wrong-self-role"),
    pytest.param({"members": _dm_members(owner_role="owner")}, id="wrong-owner-role"),
    pytest.param({"members": [{"pubkey": SELF_PUBKEY, "role": "member"}]}, id="missing-owner"),
    pytest.param({"members": [{"pubkey": OTHER_PUBKEY, "role": "member"}, {"pubkey": "c" * 64, "role": "member"}]}, id="missing-self"),
]
```

Add separate event-binding rows for missing `tags`, no `h` tag, wrong `h`, duplicate matching `h`, and one matching plus one conflicting `h`. All remain `group` with zero dispatches.

Add a stale-evidence test: discover valid evidence, dispatch one owner event and observe `dm`, then make the next discovery’s `channels search` fail; assert the state is demoted to `group` and a subsequent mention-free owner event does not dispatch.

- [ ] **Step 6: Preserve discovery and delivery regressions**

Adjust only the minimum setup needed by existing tests:

- `dms list` success is watched initially as `group` and gains mention-free `dm` behavior only after the same authoritative evidence and owner-event predicate succeeds.
- Startup seeding still records history and never dispatches it.
- WebSocket membership discovery and polling discovery still add subscriptions/state once.
- De-duplication, high-water marks, and restart/no-replay expectations remain unchanged.

- [ ] **Step 7: Run the decisive fixture RED**

```bash
cd "$PATCH_TREE"
uv run --locked --extra dev python -m pytest \
  tests/gateway/test_buzz_adapter.py::TestDmClassification::test_valid_owner_dm_without_p_tag_dispatches_once_as_dm \
  -q
```

Expected: FAIL because the unpatched adapter neither collects authoritative search/member evidence nor classifies an event without a `p` tag. A collection error is not an acceptable RED; fix the test itself until it fails only on the missing behavior.

### Task 3: Implement authoritative classification and export one focused patch

**Files:**
- Modify in disposable `PATCH_TREE`: `plugins/platforms/buzz/adapter.py`
- Create: `apps/hermes-buzz-owner-dm.patch`

**Interfaces:**
- Consumes: `channels search` projection `{channel_id, channel_type, visibility}` and `channels members` projection `[{pubkey, role}]` from Buzz revision `4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc`.
- Produces: `_normalize_dm_members(value)`, `_is_verified_owner_dm(...)`, bounded evidence refresh, early author rejection, and the unchanged `_dispatch_message` call signature.

- [ ] **Step 1: Add two pure fail-closed helpers**

Add module-level helpers near the identity normalization helpers with these exact interfaces:

```python
def _normalize_dm_members(value: Any) -> Optional[Tuple[Tuple[str, str], ...]]:
    """Return two unique normalized (pubkey, role) pairs or fail closed."""


def _is_verified_owner_dm(
    channel_id: str,
    metadata: Optional[dict],
    event: dict,
    self_pubkey: str,
    allowed_pubkeys: set,
) -> bool:
    """Pure authoritative one-to-one owner-DM predicate."""
```

`_normalize_dm_members` must reject non-lists, non-dicts, missing/invalid pubkeys, missing roles, every duplicate pubkey (including identical duplicates), every role other than exactly `member`, and every cardinality other than two. Return a sorted tuple only for two distinct normalized pubkeys with `member` roles.

`_is_verified_owner_dm` must return true only when all of these exact assertions hold:

- `metadata["_relay_channel_type"] == "dm"` and `metadata["_relay_visibility"] == "private"`;
- `metadata["_relay_dm_members"]` is the validated two-member tuple;
- `self_pubkey` normalizes and is one member;
- the sole other member belongs to a non-empty normalized `allowed_pubkeys` set;
- event kind is 9 and its normalized author equals that other member, not Hermes;
- event tags are a list containing exactly one `h` tag, with exactly one value, equal to `channel_id`; and
- no value is inferred from channel name, description, content, or `p` tags.

- [ ] **Step 2: Add bounded per-cycle evidence refresh**

Add this method:

```python
async def _refresh_dm_evidence(self, candidate_ids: set[str]) -> None:
    """Replace cached relay DM evidence for this discovery cycle."""
```

Its behavior is exact:

1. For every candidate, remove `_relay_channel_type`, `_relay_visibility`, and `_relay_dm_members` from `_channel_meta`; demote an existing state from `dm` to `group` before doing I/O. This makes failed and stale refreshes fail closed.
2. If `candidate_ids` is empty, return without CLI calls.
3. Execute exactly one `buzz channels search --query DM --exact --include-archived` call.
4. Parse only a JSON list. Index by exact `channel_id`; duplicate rows make that ID invalid rather than last-write-wins.
5. For each candidate with exactly one row, copy only normalized `channel_type` and `visibility` into the internal keys above.
6. Only when those values are exactly `dm` and `private`, execute one `buzz channels members --channel candidate_id` call, substituting that candidate’s actual UUID.
7. Store `_relay_dm_members` only when `_normalize_dm_members` succeeds. Never retain an older roster on any error.
8. Log lookup failures without membership content, keys, full events, or secrets.

This is one search per existing discovery cycle and at most one member lookup per authoritative `dm/private` candidate; it does not create a new timer or cache subsystem.

- [ ] **Step 3: Refactor discovery without changing cadence**

In `_discover_dms`:

- collect candidate IDs from successful `dms list`, current DM-shaped fallback metadata, and the current successful `channels list` entries whose name is exactly `DM` and description is empty;
- keep the name/description shape only as a discovery hint;
- call `_refresh_dm_evidence(candidate_ids)` once after both listings;
- seed/add every newly discovered candidate as `chat_type="group"`, including `dms list` results;
- preserve existing states, `last_ts`, and `seen` maps except for the deliberate stale-evidence `dm` to `group` demotion;
- leave ordinary listed channels untouched; and
- retain the existing poll cadence and membership-event call to `_discover_dms(seed=False)`.

Update `_seed_channel` comments: history may establish classification only through verified relay evidence and an allowlisted owner event; history still never dispatches.

- [ ] **Step 4: Replace p-tag classification and move denial earlier**

Replace `_is_direct_message_event` with a call to `_is_verified_owner_dm`. `_maybe_latch_dm` keeps its existing signature and latches only when that predicate succeeds. Change its informational reason to:

```text
verified relay DM metadata and owner participant
```

Do not log the roster.

In `_handle_event`, keep basic ID/kind/author/content validation and self-echo suppression first. Move the existing `_allowed_pubkeys` rejection immediately after self-echo suppression and before `_maybe_latch_dm` and mention gating. Keep `_dispatch_message(...)` byte-for-byte compatible.

Update the inaccurate comments that claim structural `p` tags distinguish DMs. State instead that relay metadata, exact membership, allowlist, event author, and `h` binding are the only classifier.

- [ ] **Step 5: Run GREEN on the focused module**

```bash
cd "$PATCH_TREE"
uv run --locked --extra dev python -m pytest tests/gateway/test_buzz_adapter.py -q
python -m py_compile plugins/platforms/buzz/adapter.py
```

Expected: all focused tests pass and compilation exits zero.

- [ ] **Step 6: Export and inspect the unified patch**

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
cd "$PATCH_TREE"
git diff --check
git diff -- plugins/platforms/buzz/adapter.py tests/gateway/test_buzz_adapter.py \
  > "$WORKTREE/apps/hermes-buzz-owner-dm.patch"
cd "$WORKTREE"
test -s apps/hermes-buzz-owner-dm.patch
rg -q '^diff --git a/plugins/platforms/buzz/adapter.py b/plugins/platforms/buzz/adapter.py$' \
  apps/hermes-buzz-owner-dm.patch
rg -q '^diff --git a/tests/gateway/test_buzz_adapter.py b/tests/gateway/test_buzz_adapter.py$' \
  apps/hermes-buzz-owner-dm.patch
test "$(rg -c '^diff --git ' apps/hermes-buzz-owner-dm.patch)" -eq 2
! rg -n 'nsec|private.?key|message body' apps/hermes-buzz-owner-dm.patch
git diff --check -- apps/hermes-buzz-owner-dm.patch
```

Expected: exactly two upstream files are represented and no secret material appears.

### Task 4: Package the patched file and add the single read-only mount

**Files:**
- Create: `apps/hermes-buzz-adapter.nix`
- Modify: `modules/services/hermes.nix`

**Interfaces:**
- Consumes: `repos-src.hermes-agent-v2026.8.3-src` and `apps/hermes-buzz-owner-dm.patch`.
- Produces: immutable `$out/adapter.py` and mount source `${hermesBuzzAdapter}/adapter.py`.

- [ ] **Step 1: Create the single-file derivation**

Create `apps/hermes-buzz-adapter.nix` with this complete derivation:

```nix
{
  lib,
  pkgs,
  python3,
  stdenvNoCC,
}: let
  src = (import ./fetcher/repos-src.nix {inherit pkgs;}).hermes-agent-v2026.8.3-src;
in
  stdenvNoCC.mkDerivation {
    pname = "hermes-buzz-adapter";
    version = "2026.8.3-owner-dm";
    inherit src;

    patches = [./hermes-buzz-owner-dm.patch];
    nativeBuildInputs = [python3];
    strictDeps = true;
    dontConfigure = true;

    prePatch = ''
      echo "8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b  plugins/platforms/buzz/adapter.py" \
        | sha256sum -c -
    '';

    buildPhase = ''
      runHook preBuild
      python3 -m py_compile plugins/platforms/buzz/adapter.py
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm0444 plugins/platforms/buzz/adapter.py "$out/adapter.py"
      test "$(find "$out" -type f | wc -l)" -eq 1
      runHook postInstall
    '';

    meta = {
      description = "Hermes v2026.8.3 Buzz adapter with authoritative owner-DM classification";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
```

This derivation intentionally does not execute pytest or pull Hermes’s runtime/test dependency graph into the production artifact.

- [ ] **Step 2: Instantiate the package in the service module**

In `modules/services/hermes.nix`, immediately after `buzzCli`, add:

```nix
hermesBuzzAdapter = pkgs.callPackage ../../apps/hermes-buzz-adapter.nix {};
```

- [ ] **Step 3: Add exactly one mount**

Append this entry to the existing Hermes `volumes` list after the managed config mount:

```nix
"${hermesBuzzAdapter}/adapter.py:/opt/hermes/plugins/platforms/buzz/adapter.py:ro"
```

Do not change the image, Buzz CLI mount, managed configuration mount, data/vault mounts, environment, ports, or options.

- [ ] **Step 4: Stage new files before any flake/Colmena evaluation**

```bash
alejandra apps/hermes-buzz-adapter.nix apps/fetcher/repos-src.nix modules/services/hermes.nix
git add apps/hermes-buzz-owner-dm.patch apps/hermes-buzz-adapter.nix
git add apps/fetcher/repos.toml apps/fetcher/repos-src.nix modules/services/hermes.nix
git diff --check
git diff --cached --check
git diff --cached --stat
```

Expected: Nix can see both new files through the git-backed flake.

### Task 5: Run focused, package, target, evaluation, and exact-image preflights

**Files:**
- Verify only: all Task 1–4 files.

**Interfaces:**
- Consumes: staged candidate implementation.
- Produces: focused test evidence, built adapter, evaluated mount/image, exact Orgrimmar target closure, and a no-network exact-image import proof.

- [ ] **Step 1: Re-run the focused upstream tests from the pinned source and repository patch**

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
cd "$WORKTREE"
HERMES_SRC=$(nix eval --raw --impure --expr '
  let pkgs = import <nixpkgs> {}; sources = import ./apps/fetcher/repos-src.nix {inherit pkgs;};
  in toString sources.hermes-agent-v2026.8.3-src
')
TEST_TREE=$(mktemp -d "${TMPDIR:-/tmp}/hermes-buzz-test.XXXXXX")
trap 'rm -rf "$TEST_TREE"' EXIT
cp -R "$HERMES_SRC"/. "$TEST_TREE"/
chmod -R u+w "$TEST_TREE"
test "$(sha256sum "$TEST_TREE/plugins/platforms/buzz/adapter.py" | cut -d' ' -f1)" = \
  8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b
(
  cd "$TEST_TREE"
  patch --batch --forward --fuzz=0 -p1 < "$WORKTREE/apps/hermes-buzz-owner-dm.patch"
  uv run --locked --extra dev python -m pytest tests/gateway/test_buzz_adapter.py -q
  python -m py_compile plugins/platforms/buzz/adapter.py
)
rm -rf "$TEST_TREE"
trap - EXIT
```

Expected: patch applies with zero fuzz, all focused tests pass, and the patched module compiles.

- [ ] **Step 2: Prove the production artifact is exactly one compiled adapter**

```bash
ADAPTER_OUT=$(nix build --no-link --print-out-paths --impure --expr '
  let pkgs = import <nixpkgs> {};
  in pkgs.callPackage ./apps/hermes-buzz-adapter.nix {}
')
test -r "$ADAPTER_OUT/adapter.py"
test "$(find "$ADAPTER_OUT" -type f | wc -l | tr -d ' ')" -eq 1
python3 -m py_compile "$ADAPTER_OUT/adapter.py"
PATCHED_ADAPTER_SHA=$(sha256sum "$ADAPTER_OUT/adapter.py" | cut -d' ' -f1)
test "$PATCHED_ADAPTER_SHA" != 8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b
printf '%s\n' "$ADAPTER_OUT" > /tmp/hermes-buzz-dm-controller-adapter-out
printf '%s\n' "$PATCHED_ADAPTER_SHA" > /tmp/hermes-buzz-dm-patched-adapter-sha256
```

- [ ] **Step 3: Evaluate the exact image and volume boundary**

```bash
EXPECTED_IMAGE='docker.io/nousresearch/hermes-agent@sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e'
IMAGE=$(colmena eval --impure -E \
  '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.image' \
  | jq -er '.')
test "$IMAGE" = "$EXPECTED_IMAGE"
colmena eval --impure -E \
  '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.volumes' \
  > /tmp/hermes-candidate-volumes.json
jq -e '
  length == 5 and
  ([.[] | select(endswith(":/opt/hermes/plugins/platforms/buzz/adapter.py:ro"))] | length == 1) and
  ([.[] | select(endswith(":/usr/local/bin/buzz:ro"))] | length == 1) and
  ([.[] | select(endswith(":/etc/hermes:ro"))] | length == 1) and
  ([.[] | select(startswith("/var/hermes:/opt/data"))] | length == 1) and
  ([.[] | select(startswith("/var/hermes/vault:/opt/data/vault"))] | length == 1)
' /tmp/hermes-candidate-volumes.json
ADAPTER_MOUNT=$(jq -er '.[] | select(endswith(":/opt/hermes/plugins/platforms/buzz/adapter.py:ro"))' \
  /tmp/hermes-candidate-volumes.json)
ADAPTER_SOURCE=${ADAPTER_MOUNT%%:/opt/hermes/plugins/platforms/buzz/adapter.py:ro}
test "${ADAPTER_SOURCE#/nix/store/}" != "$ADAPTER_SOURCE"
test "${ADAPTER_SOURCE##*/}" = adapter.py
printf '%s\n' "$ADAPTER_SOURCE" > /tmp/hermes-buzz-dm-target-adapter-source
```

Expected: the image digest is unchanged; there is exactly one new adapter file mount; CLI and managed config remain read-only; writable data/vault mounts are unchanged.

- [ ] **Step 4: Build and record the exact Orgrimmar closure**

```bash
set -euo pipefail
colmena build --on orgrimmar --impure 2>&1 | tee /tmp/hermes-buzz-dm-colmena-build.log
grep -Eo '/nix/store/[0-9a-z]{32}-nixos-system-orgrimmar-[^" ]+' \
  /tmp/hermes-buzz-dm-colmena-build.log | grep -v '\.drv' | tr -d "'" | sort -u \
  > /tmp/hermes-buzz-dm-target-closures
test "$(wc -l < /tmp/hermes-buzz-dm-target-closures | tr -d ' ')" -eq 1
TARGET_CLOSURE=$(cat /tmp/hermes-buzz-dm-target-closures)
printf '%s\n' "$TARGET_CLOSURE" > /tmp/hermes-buzz-dm-target-closure
```

Expected: target evaluation/build succeeds and yields one exact Orgrimmar system closure.

- [ ] **Step 5: Run the exact-image import preflight with no network**

```bash
EXPECTED_IMAGE='docker.io/nousresearch/hermes-agent@sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e'
ADAPTER_SOURCE=$(cat /tmp/hermes-buzz-dm-target-adapter-source)
PATCHED_ADAPTER_SHA=$(cat /tmp/hermes-buzz-dm-patched-adapter-sha256)
printf '%s\n' "$PATCHED_ADAPTER_SHA" | grep -Eq '^[0-9a-f]{64}$'
ssh root@orgrimmar /bin/sh -s -- "$EXPECTED_IMAGE" "$ADAPTER_SOURCE" "$PATCHED_ADAPTER_SHA" <<'REMOTE'
set -eu
image=$1
adapter=$2
expected_sha=$3
test -r "$adapter"
test "$(sha256sum "$adapter" | cut -d' ' -f1)" = "$expected_sha"
podman image inspect "$image" >/dev/null
podman run --rm --network=none --pull=never --entrypoint python \
  -v "$adapter:/opt/hermes/plugins/platforms/buzz/adapter.py:ro" \
  "$image" -c '
import hashlib
from pathlib import Path
import plugins.platforms.buzz.adapter as adapter
path = Path(adapter.__file__).resolve()
assert str(path) == "/opt/hermes/plugins/platforms/buzz/adapter.py"
assert hashlib.sha256(path.read_bytes()).hexdigest() != "8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b"
assert hasattr(adapter, "_is_verified_owner_dm")
print("exact-image adapter import: ok")
'
REMOTE
```

Expected: the exact digest-pinned image imports the mounted target file, the patch predicate exists, and `--network=none` guarantees no relay reads or writes.

- [ ] **Step 6: Cross the single implementation commit boundary**

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
cd "$WORKTREE"
test "$(pwd -P)" = "$WORKTREE"
graphify update .
git diff --check
git diff --cached --check
test "$(git diff --cached --name-only | LC_ALL=C sort)" = "$(printf '%s\n' \
  apps/fetcher/repos-src.nix \
  apps/fetcher/repos.toml \
  apps/hermes-buzz-adapter.nix \
  apps/hermes-buzz-owner-dm.patch \
  modules/services/hermes.nix | LC_ALL=C sort)"
test -z "$(git diff --name-only)"
git status --short
git commit -m "fix(hermes): verify Buzz owner DMs"
IMPLEMENTATION_COMMIT=$(git rev-parse HEAD)
test -z "$(git status --porcelain --untracked-files=all)"
printf '%s\n' "$IMPLEMENTATION_COMMIT" > /tmp/hermes-buzz-dm-implementation-commit
```

The commit must contain exactly the source pin, generated pin entry, unified patch, single-file package, and service mount. `graphify update .` must not introduce tracked changes into this commit. Do not deploy from an uncommitted or dirty tree.

### Task 6: Perform the proven-CWD, commit, digest, closure, and disk-gated Orgrimmar-only deployment

**Files:**
- No source changes.
- Runtime evidence directory: controller-local, mode 0700.

**Interfaces:**
- Consumes: explicit deployment authorization and Task 5’s clean implementation commit/target closure.
- Produces: exact target closure active on Orgrimmar, or no activation.

- [ ] **Step 1: Require explicit authorization and capture rollback identity**

Stop here unless the operator explicitly authorizes this deployment. Once authorized:

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
EXPECTED_IMAGE='docker.io/nousresearch/hermes-agent@sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e'
cd "$WORKTREE"
test "$(pwd -P)" = "$WORKTREE"
test "$(git rev-parse --show-toplevel)" = "$WORKTREE"
test -z "$(git status --porcelain --untracked-files=all)"
IMPLEMENTATION_COMMIT=$(cat /tmp/hermes-buzz-dm-implementation-commit)
test "$(git rev-parse HEAD)" = "$IMPLEMENTATION_COMMIT"
TARGET_CLOSURE=$(cat /tmp/hermes-buzz-dm-target-closure)
test -n "$TARGET_CLOSURE"
EVIDENCE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hermes-buzz-dm-deploy.XXXXXX")
chmod 700 "$EVIDENCE_DIR"
printf '%s\n' "$IMPLEMENTATION_COMMIT" > "$EVIDENCE_DIR/implementation-commit"
printf '%s\n' "$TARGET_CLOSURE" > "$EVIDENCE_DIR/target-closure"
printf '%s\n' "$EXPECTED_IMAGE" > "$EVIDENCE_DIR/image-digest"
printf '%s\n' "$EVIDENCE_DIR" > /tmp/hermes-buzz-dm-evidence-dir
chmod 600 /tmp/hermes-buzz-dm-evidence-dir
ssh root@orgrimmar 'readlink -f /run/current-system' > "$EVIDENCE_DIR/previous-closure"
PREVIOUS_CLOSURE=$(cat "$EVIDENCE_DIR/previous-closure")
ssh root@orgrimmar test -x "$PREVIOUS_CLOSURE/bin/switch-to-configuration"
ssh root@orgrimmar \
  'sha256sum /opt/hermes/plugins/platforms/buzz/adapter.py | cut -d" " -f1' \
  > "$EVIDENCE_DIR/previous-adapter-sha256"
test "$(cat "$EVIDENCE_DIR/previous-adapter-sha256")" = \
  8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b
chmod 600 "$EVIDENCE_DIR"/*
```

- [ ] **Step 2: Re-prove configured and running digest plus disk gates immediately before activation**

```bash
set -euo pipefail
WORKTREE=/Users/fdrake/nix/.worktrees/hermes-native-buzz
EXPECTED_IMAGE='docker.io/nousresearch/hermes-agent@sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e'
cd "$WORKTREE"
test "$(pwd -P)" = "$WORKTREE"
CONFIG_IMAGE=$(colmena eval --impure -E \
  '{nodes, ...}: nodes.orgrimmar.config.virtualisation.oci-containers.containers.hermes.image' \
  | jq -er '.')
test "$CONFIG_IMAGE" = "$EXPECTED_IMAGE"
ssh root@orgrimmar /bin/sh -s -- "$EXPECTED_IMAGE" <<'REMOTE'
set -eu
expected_image=$1
test "$(podman inspect hermes --format '{{.ImageName}}')" = "$expected_image"
test "$(systemctl is-active podman-hermes.service)" = active
for path in / /var/lib/containers; do
  available_kb=$(df -Pk "$path" | awk 'NR==2 {print $4}')
  available_inodes=$(df -Pi "$path" | awk 'NR==2 {print $4}')
  test "$available_kb" -ge 3145728
  test "$available_inodes" -ge 3000000
done
REMOTE
```

Failure of any gate aborts before `just colmena`.

- [ ] **Step 3: Activate only Orgrimmar from the proven worktree**

Use the named `generalist` deployment agent with a bounded task that runs only:

```bash
cd /Users/fdrake/nix/.worktrees/hermes-native-buzz
just colmena orgrimmar
```

It must return activation status and root-cause lines, not the full log. It must not change files, branches, hosts, or run `just switch`.

- [ ] **Step 4: Independently prove exact activation and mounted artifact**

```bash
set -euo pipefail
TARGET_CLOSURE=$(cat /tmp/hermes-buzz-dm-target-closure)
EXPECTED_IMAGE='docker.io/nousresearch/hermes-agent@sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e'
PATCHED_ADAPTER_SHA=$(cat /tmp/hermes-buzz-dm-patched-adapter-sha256)
printf '%s\n' "$PATCHED_ADAPTER_SHA" | grep -Eq '^[0-9a-f]{64}$'
ssh root@orgrimmar /bin/sh -s -- \
  "$TARGET_CLOSURE" "$EXPECTED_IMAGE" "$PATCHED_ADAPTER_SHA" <<'REMOTE'
set -eu
target=$1
expected_image=$2
expected_sha=$3
test "$(readlink -f /run/current-system)" = "$target"
test "$(podman inspect hermes --format '{{.ImageName}}')" = "$expected_image"
test "$(systemctl is-active podman-hermes.service)" = active
podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
test "$(podman exec hermes python -c 'import plugins.platforms.buzz.adapter as a; print(a.__file__)')" = \
  /opt/hermes/plugins/platforms/buzz/adapter.py
test "$(podman exec hermes sha256sum /opt/hermes/plugins/platforms/buzz/adapter.py | cut -d' ' -f1)" = "$expected_sha"
test "$(podman inspect hermes --format '{{range .Mounts}}{{if eq .Destination "/opt/hermes/plugins/platforms/buzz/adapter.py"}}{{.Options}}{{end}}{{end}}' | grep -o '\bro\b' | wc -l)" -eq 1
REMOTE
```

If this fails, execute Task 8 rollback immediately.

### Task 7: Run the full bounded live matrix and preserve redacted evidence

**Files:**
- No source changes.
- Write: `$EVIDENCE_DIR/live-matrix.tsv` and bounded supporting logs.

**Interfaces:**
- Consumes: existing allowlisted owner identity, Hermes public identity, existing owner DM, one ordinary private channel named `DM`, and one temporary non-owner identity.
- Produces: response/reaction/session/tool deltas tied to public event IDs without message bodies or secrets.

- [ ] **Step 1: Capture public identities and authoritative topology**

Recover the evidence path with `EVIDENCE_DIR=$(cat /tmp/hermes-buzz-dm-evidence-dir)`. Use the pinned local Buzz CLI for the owner and the mounted CLI for Hermes. Record only pubkeys, UUIDs, type/visibility, and role/count assertions. Resolve the affected DM by exact `channels search --query DM --exact --include-archived`, then require its member output to be exactly Hermes/member plus owner/member. Create a temporary ordinary private stream named `DM`, owned by the owner, add Hermes with its normal bot role, and require its search result to say `stream/private`; remove that stream in the cleanup trap. Create one trap-managed temporary non-owner identity, relay-enroll it, and clean up its channel/relay memberships and key on every exit.

Before each row, record:

- input event ID;
- Hermes-authored response event count in that channel after the input timestamp;
- Hermes reaction count on that input (`buzz reactions get --event "$INPUT_EVENT_ID"`);
- gateway session/message count for the Buzz routing key in `/var/hermes/state.db` using read-only SQLite mode; and
- tool-call count for that session from `messages.tool_calls`/`messages.tool_name`.

After each row, wait for one final response or at least three poll intervals (12 seconds), then record the same counters. Store only numeric deltas and public IDs, never content.

- [ ] **Step 2: Execute the six-row live matrix**

| Row | Input | Required result |
|---|---|---|
| 1 | Allowlisted owner, mention-free one-to-one DM whose kind-9 event has matching `h` and no `p` | Exactly one final Hermes response; exactly one new model turn/session delta; response is in DM; no tool calls for the instruction to reply without tools. |
| 2 | Allowlisted owner, ordinary `stream/private` channel named `DM`, no mention | No Hermes response, reaction, session/message, model-turn, or tool-call delta. |
| 3 | Temporary non-owner, valid DM to Hermes | No Hermes response, reaction, session/message, model-turn, or tool-call delta. |
| 4 | Allowlisted owner mentions Hermes in the ordinary channel | Exactly one final response as group/channel traffic; existing mention behavior unchanged. |
| 5 | Allowlisted owner mentions Hermes in the verified DM | Exactly one final response as DM traffic; no duplicate dispatch. |
| 6 | Non-owner mentions Hermes in either observed conversation | No response, reaction, session/message, model-turn, or tool-call delta. |

For positive rows, use a unique nonce and instruct Hermes to return it without tools; compare the response privately, but record only the input and response event IDs. Hermes’s normal `👀` reaction is acceptable only in positive rows. Negative rows require zero reactions, including `👀`.

- [ ] **Step 3: Prove restart has no historical replay**

Record the latest positive owner DM and channel input IDs and all six counters. Restart only `podman-hermes.service`, wait for gateway readiness and at least three poll intervals, then assert no response, reaction, session/message, model-turn, or tool-call delta tied to pre-restart IDs.

```bash
ssh root@orgrimmar 'systemctl restart podman-hermes.service'
ssh root@orgrimmar /bin/sh -s <<'REMOTE'
set -eu
for _ in $(seq 1 120); do
  if systemctl is-active podman-hermes.service >/dev/null 2>&1 &&
     podman exec hermes /command/s6-svstat /run/service/gateway-default 2>/dev/null | grep -q '^up '; then
    sleep 12
    exit 0
  fi
  sleep 1
done
exit 1
REMOTE
```

- [ ] **Step 4: Verify focused service health and write evidence**

Require Hermes gateway readiness, dashboard’s expected basic-auth redirect/challenge behavior, Buzz HTTPS health, authenticated WebSocket reconnect evidence, active vault-sync timer, and absence of adapter tracebacks or repeated metadata/member failures. Write `live-matrix.tsv` with columns:

```text
row	input_event_id	public_author	channel_id	channel_type	visibility	participant_count	response_delta	reaction_delta	session_message_delta	model_turn_delta	tool_call_delta	result
```

Set evidence files to mode 0600. Do not broaden this focused validation into an unrelated fleet deployment.

### Task 8: Roll back exactly and verify the known prior behavior

**Files:**
- No state restore.
- Optional source rollback: revert the single Task 5 implementation commit.

**Interfaces:**
- Consumes: `$EVIDENCE_DIR/previous-closure` and original adapter SHA-256.
- Produces: prior digest-pinned image with no adapter file mount.

- [ ] **Step 1: Activate the exact recorded previous closure if live validation fails**

```bash
set -euo pipefail
EVIDENCE_DIR=$(cat /tmp/hermes-buzz-dm-evidence-dir)
PREVIOUS_CLOSURE=$(cat "$EVIDENCE_DIR/previous-closure")
ssh root@orgrimmar /bin/sh -s -- "$PREVIOUS_CLOSURE" <<'REMOTE'
set -eu
closure=$1
test -x "$closure/bin/switch-to-configuration"
nix-env --profile /nix/var/nix/profiles/system --set "$closure"
"$closure/bin/switch-to-configuration" switch
test "$(readlink -f /run/current-system)" = "$closure"
REMOTE
```

This rollback changes no schema, secret, relay state, or `/var/hermes` data.

- [ ] **Step 2: Verify removal and prior runtime**

```bash
ssh root@orgrimmar /bin/sh -s <<'REMOTE'
set -eu
! podman inspect hermes --format '{{range .Mounts}}{{println .Destination}}{{end}}' \
  | grep -Fx /opt/hermes/plugins/platforms/buzz/adapter.py
test "$(podman exec hermes sha256sum /opt/hermes/plugins/platforms/buzz/adapter.py | cut -d' ' -f1)" = \
  8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b
test "$(systemctl is-active podman-hermes.service)" = active
podman exec hermes /command/s6-svstat /run/service/gateway-default | grep -q '^up '
REMOTE
```

Then verify an allowlisted owner channel mention still produces one response and a mention-free owner DM returns to the documented blocked behavior. No state restore or image mutation is required.

- [ ] **Step 3: Make declarative rollback durable when required**

Revert the single implementation commit, run the Task 5 focused/eval/target checks for the mount-free configuration, and—only with explicit authorization—run `just colmena orgrimmar` from the proven worktree. Remove the source pin, package, patch, and mount together only when a newly digest-pinned Hermes image contains equivalent authoritative classification and passes the same fixture/live matrix.

## Final Self-Review Checklist

- [ ] Exact Hermes commit, source SRI hash, image digest, and unpatched adapter SHA are literal and mutually consistent.
- [ ] The patch touches only upstream adapter and focused test module.
- [ ] Valid mention-free owner DM goes RED then GREEN without a `p` tag.
- [ ] Ordinary private channel named `DM` is the load-bearing anti-misclassification test.
- [ ] Early unauthorized rejection is tested before latch/dispatch.
- [ ] Search/member failure, malformed metadata, duplicates/conflicts, roles, group DM, channel binding, and stale evidence all fail closed.
- [ ] Existing mention, startup, WebSocket, polling, de-duplication, and restart behavior remains covered.
- [ ] Production package checks pre-patch SHA, applies the exact patch, compiles, and installs one file only.
- [ ] Evaluation proves exactly one new read-only adapter mount and unchanged image/CLI/config mounts.
- [ ] Exact-image preflight imports the mounted target under `--network=none`.
- [ ] One clean implementation commit is the deployment boundary.
- [ ] Deployment proves CWD, commit, digest, target closure, root/container disk space, and inode gates before Orgrimmar-only activation.
- [ ] Live matrix records public IDs and numeric deltas without secrets or message bodies.
- [ ] Rollback activates the exact prior closure and verifies mount absence plus original adapter SHA.
