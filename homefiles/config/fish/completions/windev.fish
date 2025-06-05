# Completion for windev function

# Define the completion function for project names
function __windev_complete_names
    set config_file "$HOME/.config/windev/config.json"

    # Check if the JSON file exists
    if test -f $config_file
        # Parse JSON and extract names with their directories as descriptions
        # Format: "name\tdirectory" (tab-separated)
        jq -r '.[] | "\(.name)\t\(.desc)"' $config_file 2>/dev/null
    end
    # No completions if config file doesn't exist
end

# Define completion for directory paths (second argument)
function __windev_complete_dirs
    # Use fish's built-in directory completion
    __fish_complete_directories
end

# Register completions for windev
# First argument: project names from JSON or fallback list
complete -c windev -f -n '__fish_is_first_token' -a '(__windev_complete_names)' -d 'Project name'

# Second argument: directory paths
complete -c windev -f -n 'not __fish_is_first_token' -a '(__windev_complete_dirs)' -d 'Custom directory path'
