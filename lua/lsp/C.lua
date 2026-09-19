return {
  {
    "clangd",
    for_cat = "C",
    lsp = {},
    after = function()
      require("clangd_extensions")
    end,
  },
  {
    "dap-gdb-c",
    for_cat = { "C", "debug" },
    on_plugin = { "nvim-dap" },
    after = function()
      local dap = require("dap")
      dap.configurations.c = require("dap_gdb").configurations()
      dap.configurations.cpp = require("dap_gdb").configurations()
    end,
  },
}
