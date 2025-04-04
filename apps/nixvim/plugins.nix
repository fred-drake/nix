{pkgs, ...}: let
  repos-src = import ../fetcher/repos-src.nix {inherit pkgs;};
  outline-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "outline-nvim";
    src = repos-src.outline-nvim-src;
    nvimSkipModule = "outline.providers.norg";
  };
  augment-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "augment-nvim";
    src = repos-src.augment-nvim-src;
    nvimSkipModule = "outline.providers.norg";
  };
in {
  extraPlugins = with pkgs; [
    vimPlugins.vim-dadbod # DB client
    vimPlugins.vim-dadbod-completion # DB completion
    vimPlugins.vim-dadbod-ui # DB UI
    vimPlugins.vim-tmux-navigator # tmux navigation
    outline-nvim # Document outliner
    augment-nvim # AI code completion
  ];

  extraConfigLua = ''
    require("notify").setup({
      background_colour = "#000000",
    })

    require("outline").setup {}
  '';
}
