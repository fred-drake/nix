{pkgs, ...}: let
  claude-usage = pkgs.callPackage ./claude-usage.nix {};
in
  pkgs.writeShellScript "ccusage-bar" ''
    # ccusage-bar - Claude Code usage monitor for status bars (tmux + ccstatusline)
    # Renders cached usage with T-minus reset times. The refresh is NON-BLOCKING:
    # if the cache is stale it spawns a detached fetch and renders whatever exists,
    # so callers with tight timeouts (e.g. ccstatusline's 1s default) never hang.
    # Reads (and ignores) any JSON piped on stdin by ccstatusline.

    CACHE_FILE="/tmp/ccusage-tmux-$USER.json"   # shared between tmux and ccstatusline
    LOCK_DIR="/tmp/ccusage-bar-$USER.lock"
    CACHE_MAX_AGE=600   # 10 minutes
    LOCK_MAX_AGE=120    # reap a stuck refresh after 2 minutes

    now=$(${pkgs.coreutils}/bin/date +%s)

    # Is the cache stale (or missing)?
    stale=true
    if [ -f "$CACHE_FILE" ]; then
        mtime=$(${pkgs.coreutils}/bin/stat -c %Y "$CACHE_FILE")
        if [ "$(( now - mtime ))" -lt "$CACHE_MAX_AGE" ]; then
            stale=false
        fi
    fi

    # Reap a stale lock left by a crashed refresh.
    if [ -d "$LOCK_DIR" ]; then
        lock_mtime=$(${pkgs.coreutils}/bin/stat -c %Y "$LOCK_DIR" 2>/dev/null || echo "$now")
        if [ "$(( now - lock_mtime ))" -ge "$LOCK_MAX_AGE" ]; then
            ${pkgs.coreutils}/bin/rmdir "$LOCK_DIR" 2>/dev/null || true
        fi
    fi

    # Kick off a detached refresh if stale and no refresh is already running.
    # mkdir is atomic, so only one refresher wins the race. stdout/stderr are
    # redirected away from any inherited pipe so the caller returns immediately.
    if [ "$stale" = true ] && ${pkgs.coreutils}/bin/mkdir "$LOCK_DIR" 2>/dev/null; then
        (
            data=$(${claude-usage}/bin/claude-usage 2>/dev/null)
            if [ -n "$data" ] && echo "$data" | ${pkgs.jq}/bin/jq -e 'has("error") | not' >/dev/null 2>&1; then
                printf '%s' "$data" > "$CACHE_FILE.tmp" && ${pkgs.coreutils}/bin/mv "$CACHE_FILE.tmp" "$CACHE_FILE"
            fi
            ${pkgs.coreutils}/bin/rmdir "$LOCK_DIR" 2>/dev/null || true
        ) >/dev/null 2>&1 &
    fi

    # Nothing cached yet — show a placeholder.
    if [ ! -f "$CACHE_FILE" ]; then
        echo "CC: --"
        exit 0
    fi

    # Render from cache.
    ${pkgs.jq}/bin/jq -r --argjson now "$now" '
    # T-minus formatter: seconds -> "Xd Yh" or "Xh Ym" or "Ym"
    def tminus:
      if . <= 0 then "now"
      else
        (. / 86400 | floor) as $d |
        ((. % 86400) / 3600 | floor) as $h |
        ((. % 3600) / 60 | floor) as $m |
        if $d > 0 then "\($d)d\($h)h"
        elif $h > 0 then "\($h)h\($m)m"
        else "\($m)m"
        end
      end;

    # Nudge an epoch that lands at :59 up to the next whole hour, so a reset a few
    # seconds shy of the hour reads "6am" instead of "5:59am". Done in epoch space
    # so hour/day/month rollover is handled by strflocaltime.
    def roundup:
      . as $e |
      ($e | strflocaltime("%M") | tonumber) as $M |
      ($e | strflocaltime("%S") | tonumber) as $S |
      if $M >= 59 then $e + (3600 - $M * 60 - $S) else $e end;

    # Local wall-clock time of an epoch -> "8pm" or "8:15pm" (no GNU strftime extensions)
    def clock:
      (strflocaltime("%H") | tonumber) as $H |
      (strflocaltime("%M") | tonumber) as $M |
      (if $H == 0 then 12 elif $H > 12 then $H - 12 else $H end) as $h12 |
      (if $H < 12 then "am" else "pm" end) as $ap |
      if $M == 0 then "\($h12)\($ap)"
      else "\($h12):\(if $M < 10 then "0\($M)" else "\($M)" end)\($ap)" end;

    # Local date + time of an epoch -> "Jun 4 3pm"
    def daytime:
      (["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]) as $months |
      (strflocaltime("%m") | tonumber) as $mon |
      (strflocaltime("%d") | tonumber) as $day |
      "\($months[$mon - 1]) \($day) \(clock)";

    (.five_hour.utilization // 0) as $u5 |
    (.seven_day.utilization // 0) as $u7 |

    # Absolute reset epochs (0 when missing)
    (if .five_hour.resets_at then
        (.five_hour.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601)
    else 0 end) as $r5 |

    (if .seven_day.resets_at then
        (.seven_day.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601)
    else 0 end) as $r7 |

    # Seconds until reset
    ($r5 - $now) as $t5 |
    ($r7 - $now) as $t7 |

    # Format percentages as integers
    ($u5 | floor | tostring) as $p5 |
    ($u7 | floor | tostring) as $p7 |

    # Local reset times: 5h is same-day so time only; 7d shows date too
    (if $r5 > 0 then " (\($r5 | roundup | clock))" else "" end) as $c5 |
    (if $r7 > 0 then " (\($r7 | roundup | daytime))" else "" end) as $c7 |

    "5h:\($p5)% T-\($t5 | tminus)\($c5) 7d:\($p7)% T-\($t7 | tminus)\($c7)"
    ' "$CACHE_FILE"
  ''
