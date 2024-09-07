return {
  "alexghergh/nvim-tmux-navigation",
  config = true,
  keys = {
    { "<C-h>", "<cmd>NvimTmuxNavigateLeft<cr>", desc = "Navigate Window Left" },
    { "<C-j>", "<cmd>NvimTmuxNavigateDown<cr>", desc = "Navigate Window Down" },
    { "<C-k>", "<cmd>NvimTmuxNavigateUp<cr>", desc = "Navigate Window Up" },
    { "<C-l>", "<cmd>NvimTmuxNavigateRight<cr>", desc = "Navigate Window Right" },
  },
}
