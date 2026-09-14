return {
  {
    "harper_ls",
    for_cat = "lsp",
    lsp = {
      settings = {
        ["harper-ls"] = {
          -- The same wordlist vim spell uses
          userDictPath = vim.env.HOME .. "/Sync/.spell/en.utf-8.add",
          linters = {
            -- Spelling is already covered by vim spell and typos-lsp
            SpellCheck = false,
            ExpandedConfiguration = false,
          },
        },
      },
    },
  },
}
