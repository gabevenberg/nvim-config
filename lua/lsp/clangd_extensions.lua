return {
  {
    "clangd_extensions.nvim",
    on_require = { "clangd_extensions" },
    auto_enable = true,
    for_cat = "C",
    after = function()
      require("clangd_extensions").setup({})
    end,
  },
}
