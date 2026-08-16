#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
restore="$root/apps/scripts/buzz-agent-restore"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/env" "$tmp/disabled"

cat >"$tmp/bin/flock" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$tmp/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$FAKE_SYSTEMCTL_LOG"
[[ ${FAKE_FAIL_UNIT:-} != "${2:-}" ]]
EOF
chmod +x "$tmp/bin/flock" "$tmp/bin/systemctl"

valid=79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
other=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
printf '%s\n' 'SECRET=must-not-be-read-or-logged' >"$tmp/env/$valid"
printf '%s\n' 'OTHER=also-secret' >"$tmp/env/$other"
printf '%s\n' disabled >"$tmp/disabled/$other"
printf '%s\n' ignored >"$tmp/env/${valid}x"
printf '%s\n' ignored >"$tmp/env/${valid:0:63}"
printf '%s\n' ignored >"$tmp/env/${valid^^}"
printf '%s\n' ignored >"$tmp/env/.hidden"
mkdir "$tmp/env/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
ln -s "$tmp/env/$valid" "$tmp/env/cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

export FAKE_SYSTEMCTL_LOG="$tmp/systemctl.log"
lifecycle_lock="$tmp/lifecycle.lock"
operation_lock="$tmp/operation.lock"
PATH="$tmp/bin:$PATH" "$restore" "$tmp/env" "$tmp/disabled" "$lifecycle_lock" "$operation_lock" \
  >"$tmp/out" 2>"$tmp/err"

[[ ! -s $tmp/out ]]
[[ $(stat -c %a "$lifecycle_lock") == 600 ]]
[[ $(stat -c %a "$operation_lock") == 600 ]]
[[ ! -s $tmp/err ]]
[[ $(wc -l <"$FAKE_SYSTEMCTL_LOG" | tr -d ' ') == 1 ]]
grep -Fx "start buzz-agent@$valid.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null
! grep -Fx "start buzz-agent@$other.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null
! grep -Fq 'must-not-be-read-or-logged' "$tmp/out" "$tmp/err" "$FAKE_SYSTEMCTL_LOG"
! grep -Fq 'also-secret' "$tmp/out" "$tmp/err" "$FAKE_SYSTEMCTL_LOG"

: >"$FAKE_SYSTEMCTL_LOG"
rm "$tmp/disabled/$other"
set +e
PATH="$tmp/bin:$PATH" FAKE_FAIL_UNIT="buzz-agent@$valid.service" \
  "$restore" "$tmp/env" "$tmp/disabled" "$lifecycle_lock" "$operation_lock" \
  >"$tmp/failure.out" 2>"$tmp/failure.err"
rc=$?
set -e
[[ $rc == 0 ]]
[[ ! -s $tmp/failure.out ]]
[[ ! -s $tmp/failure.err ]]
[[ $(wc -l <"$FAKE_SYSTEMCTL_LOG" | tr -d ' ') == 2 ]]
grep -Fx "start buzz-agent@$valid.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null
grep -Fx "start buzz-agent@$other.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null

printf '%s\n' 'boot restoration filtering and failure tests passed'
