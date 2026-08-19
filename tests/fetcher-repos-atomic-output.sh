#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
shell_nix=${1:-$repo_root/shell.nix}
shell_nix=$(cd "$(dirname "$shell_nix")" && pwd)/$(basename "$shell_nix")

tmp=$(mktemp -d "$repo_root/.fetcher-repos-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fixture_bin="$tmp/fixture-bin"
project_root="$tmp/project with spaces"
destination="$project_root/apps/fetcher/repos-src.nix"
mkdir -p "$fixture_bin" "$(dirname "$destination")"
: > "$project_root/apps/fetcher/repos.toml"

cat > "$fixture_bin/tq" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
expected_file=${PROJECT_ROOT:?}/apps/fetcher/repos.toml
if [[ $# -ne 5 || $1 != --file || $2 != "$expected_file" || $3 != --output || $4 != json || $5 != .repos ]]; then
  printf 'unexpected tq arguments:' >&2
  printf ' <%s>' "$@" >&2
  printf '\n' >&2
  exit 40
fi
if [[ ${FAIL_TQ:-0} == 1 ]]; then
  exit 41
fi
printf '[{"name":"fixture-src","url":"https://example.invalid/fixture","rev":"%s"}]\n' "${FIXTURE_REV:-success}"
SCRIPT

cat > "$fixture_bin/nurl" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${FAIL_NURL:-0} == 1 ]]; then
  exit 42
fi
if [[ -n ${FIXTURE_DELAY:-} ]]; then
  sleep "$FIXTURE_DELAY"
fi
rev=${2:-HEAD}
printf 'fetchFromGitHub{owner="fixture";repo="repo";rev="%s";hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";}\n' "$rev"
SCRIPT

real_alejandra=$(command -v alejandra)
cat > "$fixture_bin/alejandra" <<SCRIPT
#!/usr/bin/env bash
set -euo pipefail
last=\${!#}
case "\$last" in
  *.nix) ;;
  *) printf 'formatter input does not end in .nix: %s\n' "\$last" >&2; exit 43 ;;
esac
if [[ \${FAIL_FORMATTER:-0} == 1 ]]; then
  exit 44
fi
exec "$real_alejandra" "\$@"
SCRIPT
chmod +x "$fixture_bin"/*

nix_string() {
  jq -Rn --arg value "$1" '$value'
}

shell_string=$(nix_string "$shell_nix")
tq_string=$(nix_string "$fixture_bin/tq")
nurl_string=$(nix_string "$fixture_bin/nurl")
alejandra_string=$(nix_string "$fixture_bin/alejandra")
cat > "$tmp/updater.nix" <<NIX
let
  base = import <nixpkgs> {};
  fixturePackage = name: executable: base.runCommand "fixture-\${name}" {} ''
    mkdir -p "\$out/bin"
    cp \${executable} "\$out/bin/\${name}"
    chmod +x "\$out/bin/\${name}"
  '';
  pkgs = base.extend (_final: _prev: {
    tomlq = fixturePackage "tq" (builtins.path {path = builtins.toPath $tq_string; name = "fixture-tq-script";});
    nurl = fixturePackage "nurl" (builtins.path {path = builtins.toPath $nurl_string; name = "fixture-nurl-script";});
    alejandra = fixturePackage "alejandra" (builtins.path {path = builtins.toPath $alejandra_string; name = "fixture-alejandra-script";});
  });
  shell = import (builtins.toPath $shell_string) {inherit pkgs;};
  inputs = shell.nativeBuildInputs ++ shell.buildInputs;
in
  builtins.head (builtins.filter (input: (input.name or "") == "update-fetcher-repos") inputs)
NIX
updater_package=$(nix build --impure --no-link --print-out-paths --file "$tmp/updater.nix")
updater="$updater_package/bin/update-fetcher-repos"

write_expected() {
  local output=$1
  local rev=$2
  cat > "$output" <<EOF
####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "fixture-src" = pkgs.fetchFromGitHub {
    owner = "fixture";
    repo = "repo";
    rev = "$rev";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
EOF
}

assert_no_temps() {
  local leftovers
  leftovers=$(find "$(dirname "$destination")" -maxdepth 1 -name "$(basename "$destination").*" -print)
  if [[ -n $leftovers ]]; then
    printf 'temporary files were not cleaned up:\n%s\n' "$leftovers" >&2
    return 1
  fi
}

assert_unchanged_after_failure() {
  local failure_variable=$1
  local sentinel="$tmp/sentinel"
  printf 'existing destination\n' > "$sentinel"
  cp "$sentinel" "$destination"

  if env PROJECT_ROOT="$project_root" "$failure_variable=1" "$updater"; then
    printf '%s failure unexpectedly succeeded\n' "$failure_variable" >&2
    return 1
  fi
  if ! cmp -s "$sentinel" "$destination"; then
    printf '%s failure replaced the existing destination\n' "$failure_variable" >&2
    return 1
  fi
  assert_no_temps
}

# A path containing spaces exercises TOML path quoting. The deliberately compact
# nurl output must be formatted before it becomes visible at the destination.
expected_success="$tmp/expected-success.nix"
write_expected "$expected_success" success
env PROJECT_ROOT="$project_root" "$updater"
cmp "$expected_success" "$destination"
assert_no_temps

# Failures at both pipeline and per-record generation boundaries, and at the
# formatter boundary, must preserve the old destination and clean temporary files.
assert_unchanged_after_failure FAIL_TQ
assert_unchanged_after_failure FAIL_NURL
assert_unchanged_after_failure FAIL_FORMATTER

# While two writers overlap, readers may observe the old file or either complete
# new file, but never a partially generated file.
expected_old="$tmp/expected-old"
expected_a="$tmp/expected-a.nix"
expected_b="$tmp/expected-b.nix"
printf 'existing destination\n' > "$expected_old"
write_expected "$expected_a" concurrent-a
write_expected "$expected_b" concurrent-b
cp "$expected_old" "$destination"

env PROJECT_ROOT="$project_root" FIXTURE_REV=concurrent-a FIXTURE_DELAY=0.5 "$updater" &
pid_a=$!
env PROJECT_ROOT="$project_root" FIXTURE_REV=concurrent-b FIXTURE_DELAY=0.5 "$updater" &
pid_b=$!

for _ in $(seq 1 500); do
  temp_count=$(find "$(dirname "$destination")" -maxdepth 1 -name "$(basename "$destination").*.nix" | wc -l | tr -d ' ')
  if [[ $temp_count -eq 2 ]]; then
    break
  fi
  sleep 0.01
done
if [[ ${temp_count:-0} -ne 2 ]]; then
  printf 'concurrent writers did not create two same-directory .nix temporary files\n' >&2
  kill "$pid_a" "$pid_b" 2>/dev/null || true
  wait "$pid_a" "$pid_b" 2>/dev/null || true
  exit 1
fi

while kill -0 "$pid_a" 2>/dev/null || kill -0 "$pid_b" 2>/dev/null; do
  snapshot="$tmp/snapshot"
  cp "$destination" "$snapshot"
  if ! cmp -s "$snapshot" "$expected_old" &&
     ! cmp -s "$snapshot" "$expected_a" &&
     ! cmp -s "$snapshot" "$expected_b"; then
    printf 'reader observed an incomplete destination during concurrent generation\n' >&2
    kill "$pid_a" "$pid_b" 2>/dev/null || true
    wait "$pid_a" "$pid_b" 2>/dev/null || true
    exit 1
  fi
done
wait "$pid_a"
wait "$pid_b"
if ! cmp -s "$destination" "$expected_a" && ! cmp -s "$destination" "$expected_b"; then
  printf 'concurrent generation did not leave a complete destination\n' >&2
  exit 1
fi
assert_no_temps

printf 'fetcher repository updater atomic-output tests passed\n'
