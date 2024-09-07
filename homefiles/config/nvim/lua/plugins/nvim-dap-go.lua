return {
  "leoluz/nvim-dap-go",
  config = true,
  opts = {
    dap_configurations = {
      {
        type = "go",
        name = "Attach remote",
        mode = "remote",
        request = "attach",
      },
    },
    -- delve = {
    --   initialize_timeout_sec = 20,
    --   port = "${port}",
    -- },
  },
}
