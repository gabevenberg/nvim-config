return {
  {
    "gopls",
    for_cat = "go",
    lsp = {},
  },
  {
    "nvim-dap-go",
    for_cat = { "go", "debug" },
    on_plugin = { "nvim-dap" },
    on_require = { "dap-go" },
    keys = {
      {
        "<leader>dn",
        function()
          require("dap-go").debug_test()
        end,
        ft = "go",
        desc = "debug [n]earest test",
      },
    },
    after = function()
      require("dap-go").setup()
    end,
  },
}
