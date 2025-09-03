{pkgs, ...}:
pkgs.writeShellScript "ccusage-waybar" ''
  # ccusage-waybar.sh - Claude Code usage monitor for Waybar
  # Fetches Claude Code usage data and formats it for Waybar display

  # Get the usage data
  data=$(/etc/profiles/per-user/fdrake/bin/ccusage blocks --json --active 2>/dev/null)

  # Check if command failed or returned empty
  if [ -z "$data" ]; then
      echo '{"text":"Awaiting CC Data","tooltip":"","percentage":0,"class":""}'
      exit 0
  fi

  # Parse the JSON and generate output
  echo "$data" | ${pkgs.jq}/bin/jq --unbuffered --compact-output '
  if .blocks | length == 0 then
      {text: "Awaiting CC Data", tooltip: "", percentage: 0, class: ""}
  else
      .blocks[0] as $block |

      # Calculate percentages
      ($block.totalTokens / 98687500) as $tokenPct |
      ($block.projection.totalTokens / 98687500) as $projectedPct |

      # Parse end time to get hour format (handle both with and without milliseconds)
      ($block.endTime | sub("\\.[0-9]+"; "") | fromdateiso8601 | strflocaltime("%l%p") | gsub("^ +"; "") | ascii_downcase) as $endTime |

      # Format percentage with 1 decimal place
      ($projectedPct * 100 | tostring | split(".") | if .[1] then .[0] + "." + .[1][0:1] else .[0] end) as $projectedPctStr |

      # Build the output object
      {
          text: ($projectedPctStr + "% up to " + $endTime),
          tooltip: "",
          percentage: ($projectedPct * 100),
          class: (if $projectedPct > 1 then "critical" elif $projectedPct > 0.8 then "warning" else "" end)
      }
  end'
''
