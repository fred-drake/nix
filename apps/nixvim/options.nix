{
  config = {
    autoCmd = [
      {
        event = [ "BufEnter" "CursorHold" "CursorHoldI" "FocusGained" ];
        pattern = "*";
        command = "if mode() != 'c' | checktime | endif";
      }
      {
        event = [ "BufRead" "BufNewFile" ];
        pattern = "*.tf";
        command = "set filetype=terraform";
      }
      {
        event = [ "BufRead" "BufNewFile" ];
        pattern = "*.tfvars";
        command = "set filetype=terraform";
      }
    ];

    opts = {
      updatetime = 100; # faster completion
      autoread = true; # automatically read file when changed outside vim
      number = true;
      relativenumber = true;

      autoindent = true;
      autowrite = true;
      confirm = true;
      clipboard = "unnamedplus";
      cursorline = true;
      list = true;
      expandtab = true;
      shiftround = true;
      shiftwidth = 2;
      # showmode = false;
      signcolumn = "yes";
      smartcase = true;
      smartindent = true;
      tabstop = 2;

      ignorecase = true;
      incsearch = true;
      completeopt = "menu,menuone,noselect";
      wildmode = "longest:full,full";

      swapfile = false;
      undofile = true; # Build-in persistent undo
      undolevels = 10000;

      conceallevel = 2;
    };
  };
}
