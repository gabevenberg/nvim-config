return {
  {
    "clangd",
    for_cat = "C",
    lsp = {},
    after=function()
      require("clangd_extensions").setup({})
    end,
  },
}
