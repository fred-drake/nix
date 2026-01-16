{nixpkgs-stable}: let
  # Format: YYYYMMDDHHMMSS -> YYYY-MM-DD HH:MM:SS
  formatDate = dateStr:
    if builtins.stringLength dateStr == 14
    then
      builtins.substring 0 4 dateStr
      + "-"
      + builtins.substring 4 2 dateStr
      + "-"
      + builtins.substring 6 2 dateStr
      + " "
      + builtins.substring 8 2 dateStr
      + ":"
      + builtins.substring 10 2 dateStr
      + ":"
      + builtins.substring 12 2 dateStr
      + " UTC"
    else dateStr;
in
  {pkgs, ...}: {
    # Generate /etc/nixos/version.json with nixpkgs revision info
    environment.etc."nixos/version.json".text = builtins.toJSON {
      nixpkgs = {
        rev = nixpkgs-stable.rev or "unknown";
        shortRev = nixpkgs-stable.shortRev or "unknown";
        lastModified = nixpkgs-stable.lastModified or 0;
        lastModifiedDate = formatDate (nixpkgs-stable.lastModifiedDate or "unknown");
      };
    };

    # jq is required for the colmena-age command
    environment.systemPackages = with pkgs; [
      jq
    ];
  }
