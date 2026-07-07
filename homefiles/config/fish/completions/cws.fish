# Completions for cws (dev workspace for a project)

function __cws_complete_names
    set config_file "$HOME/.config/windev/config.json"
    if test -f $config_file
        # name<TAB>description, from the same registry windev uses
        jq -r '.[] | "\(.name)\t\(.desc)"' $config_file 2>/dev/null
    end
end

# 1st token: project name from the registry
complete -c cws -f -n '__fish_is_first_token' -a '(__cws_complete_names)' -d 'Project'
# 2nd token: optional directory override
complete -c cws -f -n 'test (count (commandline -opc)) -eq 2' -a '(__fish_complete_directories)' -d 'Custom directory'
# 3rd token: optional color override (cmux named colors)
complete -c cws -f -n 'test (count (commandline -opc)) -eq 3' -a 'Red Crimson Orange Amber Olive Green Teal Aqua Blue Navy Indigo Purple Magenta Rose Brown Charcoal' -d 'Color'
