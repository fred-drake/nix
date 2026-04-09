{pkgs, ...}: {
  programs = {
    atuin.enable = true;
    direnv.enable = true;
    nix-index.enable = true;
    nix-index-database.comma.enable = true;

    git = {
      enable = true;
      signing.format = null;
      settings = {
        core.pager = "delta";
        credential.helper = "store";
        delta = {
          features = "decorations";
          interactive.keep-plus-minus-markers = false;
          decorations = {
            commit-decoration-style = "blue ol";
            commit-style = "raw";
            file-style = "omit";
            hunk-header-decoration-style = "blue box";
            hunk-header-file-style = "red";
            hunk-header-line-number-style = "#067a00";
            hunk-header-style = "file line-number syntax";
          };
        };
        diff.tool = "meld";
        difftool.prompt = false;
        "difftool \"meld\"".cmd = ''meld "$LOCAL" "$REMOTE"'';
        init.defaultBranch = "master";
        interactive.diffFilter = "delta --color-only --features=interactive";
        pull.rebase = true;
        user = {
          email = "fred.drake@gmail.com";
          name = "Fred Drake";
        };
      };
      ignores = ["*~" ".DS_Store" "*.swp"];
      lfs.enable = true;
    };
  };

  home.packages = with pkgs; [
    # Language servers
    nil
    nixd
    rust-analyzer
    basedpyright
    ruff
    gopls
    clang-tools
    vscode-langservers-extracted
    yaml-language-server
    prettier
    taplo
    jdt-language-server
    marksman
    markdown-oxide
    # Dev tools
    delta
    devenv
    docker-compose
    ghq
    jaq
    kind
    kubectl
    lazydocker
    meld
    tokei
    yq-go
  ];
}
