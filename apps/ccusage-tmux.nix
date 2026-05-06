{pkgs, ...}: let
  claude-usage = pkgs.callPackage ./claude-usage.nix {};
in
  pkgs.writeShellScript "ccusage-tmux" ''
    # ccusage-tmux - Claude Code usage monitor for tmux status bar
    # Fetches usage data, caches for 10 minutes, displays with T-minus reset times

    CACHE_FILE="/tmp/ccusage-tmux-$USER.json"
    CACHE_MAX_AGE=600  # 10 minutes in seconds

    # Check if cache is fresh enough (GNU coreutils stat — pinned for portability)
    fetch=true
    if [ -f "$CACHE_FILE" ]; then
        mtime=$(${pkgs.coreutils}/bin/stat -c %Y "$CACHE_FILE")
        cache_age=$(( $(${pkgs.coreutils}/bin/date +%s) - mtime ))
        if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
            fetch=false
        fi
    fi

    # Fetch new data if needed. The API returns errors as `{"error": {...}}`,
    # so a valid usage response is one where `.error` is absent.
    if [ "$fetch" = true ]; then
        data=$(${claude-usage}/bin/claude-usage 2>/dev/null)
        if [ -n "$data" ] && echo "$data" | ${pkgs.jq}/bin/jq -e 'has("error") | not' >/dev/null 2>&1; then
            echo "$data" > "$CACHE_FILE"
        fi
    fi

    # If no cache exists at all, show placeholder
    if [ ! -f "$CACHE_FILE" ]; then
        echo "CC: --"
        exit 0
    fi

    # Parse and format
    ${pkgs.jq}/bin/jq -r --argjson now "$(date +%s)" '
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

    (.five_hour.utilization // 0) as $u5 |
    (.seven_day.utilization // 0) as $u7 |

    # Calculate seconds until reset
    (if .five_hour.resets_at then
        (.five_hour.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) - $now
    else 0 end) as $t5 |

    (if .seven_day.resets_at then
        (.seven_day.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) - $now
    else 0 end) as $t7 |

    # Format percentages as integers
    ($u5 | floor | tostring) as $p5 |
    ($u7 | floor | tostring) as $p7 |

    "5h:\($p5)% T-\($t5 | tminus) 7d:\($p7)% T-\($t7 | tminus)"
    ' "$CACHE_FILE"
  ''
