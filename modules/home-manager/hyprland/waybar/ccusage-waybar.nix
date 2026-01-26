{pkgs, ...}: let
  claude-usage = pkgs.callPackage ../../../../apps/claude-usage.nix {};
in
  pkgs.writeShellScript "claude-usage-waybar" ''
    # claude-usage-waybar.sh - Claude Code usage monitor for Waybar
    # Fetches Claude Code usage data from Anthropic API and formats it for Waybar display

    # Get the usage data
    data=$(${claude-usage}/bin/claude-usage 2>/dev/null)

    # Check if command failed or returned empty/error
    if [ -z "$data" ] || echo "$data" | ${pkgs.jq}/bin/jq -e '.type == "error"' >/dev/null 2>&1; then
        echo '{"text":"CC: No Data","tooltip":"Unable to fetch Claude usage data","percentage":0,"class":""}'
        exit 0
    fi

    # Parse the JSON and generate output
    echo "$data" | ${pkgs.jq}/bin/jq --unbuffered --compact-output '
    # Extract utilization values (default to 0 if null)
    (.five_hour.utilization // 0) as $fiveHour |
    (.seven_day.utilization // 0) as $sevenDay |

    # Parse reset times - short format for bar, longer for tooltip
    (if .five_hour.resets_at then
        (.five_hour.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601 | strflocaltime("%l%p") | gsub("^ +"; "") | ascii_downcase)
    else "?" end) as $fiveHourResetShort |

    (if .seven_day.resets_at then
        (.seven_day.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601 | strflocaltime("%b %d") | gsub("  +"; " "))
    else "?" end) as $sevenDayResetShort |

    (if .five_hour.resets_at then
        (.five_hour.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601 | strflocaltime("%l:%M%p") | gsub("^ +"; "") | ascii_downcase)
    else "?" end) as $fiveHourResetLong |

    (if .seven_day.resets_at then
        (.seven_day.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601 | strflocaltime("%a %b %d %l%p") | gsub("  +"; " ") | ascii_downcase)
    else "?" end) as $sevenDayResetLong |

    # Format percentages with 1 decimal place
    ($fiveHour | tostring | split(".") | if .[1] then .[0] + "." + .[1][0:1] else .[0] end) as $fiveHourStr |
    ($sevenDay | tostring | split(".") | if .[1] then .[0] + "." + .[1][0:1] else .[0] end) as $sevenDayStr |

    # Use the higher utilization for status class
    ([$fiveHour, $sevenDay] | max) as $maxUtil |

    # Build the output object
    {
        text: ("5h:" + $fiveHourStr + "% " + $fiveHourResetShort + ", 7d:" + $sevenDayStr + "% " + $sevenDayResetShort),
        tooltip: ("5-hour: " + $fiveHourStr + "% (resets " + $fiveHourResetLong + ")\n7-day: " + $sevenDayStr + "% (resets " + $sevenDayResetLong + ")"),
        percentage: $maxUtil,
        class: (if $maxUtil >= 90 then "critical" elif $maxUtil >= 70 then "warning" else "" end)
    }'
  ''
