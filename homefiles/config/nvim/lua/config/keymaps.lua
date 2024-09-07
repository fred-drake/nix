-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<cmd>noh<cr><esc>", { desc = "Normal mode and clear highlight" })
vim.keymap.set("n", "<F5>", ":lua require'dap'.continue()<CR>", { desc = "Debug - Continue" })
vim.keymap.set("n", "<F10>", ":lua require'dap'.step_over()<CR>", { desc = "Debug - Step Over" })
vim.keymap.set("n", "<F11>", ":lua require'dap'.step_into()<CR>", { desc = "Debug - Step Into" })
vim.keymap.set("n", "<F12>", ":lua require'dap'.step_out()<CR>", { desc = "Debug - Step Out" })
vim.keymap.set("n", "<leader>cb", ":lua require'dap'.toggle_breakpoint()<CR>", { desc = "Debug - Set Breakpoint" })
vim.keymap.set(
  "n",
  "<leader>cB",
  ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition:'))<CR>",
  { desc = "Debug - Set Conditional Breakpoint" }
)
vim.keymap.set("n", "<leader>cR", ":lua require'dap'.repl.open()<CR>", { desc = "Debug - Repl Open" })
vim.keymap.set("n", "<leader>o", "", { desc = "+SOPS" })
vim.keymap.set("n", "<leader>od", "<cmd>!sops -d -i %<CR><CR>", { desc = "Decrypt SOPS File" })
vim.keymap.set("n", "<leader>oe", "<cmd>!sops -e -i %<CR><CR>", { desc = "Encrypt SOPS File" })
