return {
  {
    "ty",
    for_cat = "python",
    lsp = {},
  },
  {
    "ruff",
    for_cat = "python",
    lsp = {},
  },
  {
    "venv-selector.nvim",
    for_cat = "python",
    ft = "python",
    keys = {
      { "<leader>v", "<cmd>VenvSelect<CR>", mode = { "n" }, noremap = true, desc = "Venv selector" },
    },
    after = function()
      require("venv-selector").setup()
    end,
  },
  {
    "nvim-dap-python",
    for_cat = { "python", "debug" },
    on_plugin = { "nvim-dap" },
    on_require = { "dap-python" },
    keys = {
      {
        "<leader>dn",
        function()
          require("dap-python").test_method()
        end,
        ft = "python",
        desc = "debug [n]earest test method",
      },
      {
        "<leader>dN",
        function()
          require("dap-python").test_class()
        end,
        ft = "python",
        desc = "debug [N]earest test class",
      },
      -- debug_selection reads the '< and '> marks, which are only set on leaving visual mode
      {
        "<leader>de",
        "<Esc><Cmd>lua require('dap-python').debug_selection()<CR>",
        mode = "x",
        ft = "python",
        desc = "debug s[e]lection",
      },
    },
    after = function()
      -- the adapter comes from nix, the debuggee python still comes from the active venv
      require("dap-python").setup("debugpy-adapter")
    end,
  },
}
