
function __complete_mc
    set -lx COMP_LINE (commandline -cp)
    test -z (commandline -ct)
    and set COMP_LINE "$COMP_LINE "
    /etc/profiles/per-user/fdrake/bin/mc
end
complete -f -c mc -a "(__complete_mc)"

