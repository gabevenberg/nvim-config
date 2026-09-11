return {
  {
    "harper_ls",
    for_cat = "lsp",
    lsp = {
      settings = {
        ["harper-ls"] = {
          -- the same wordlist vim spell uses
          userDictPath = vim.env.HOME .. "/Sync/.spell/en.utf-8.add",
          linters = {
            -- spelling is already covered by vim spell and typos-lsp, and harper
            -- flags every all-caps abbreviation (TRRS, Tx, RP2040) that vim accepts.
            SpellCheck = false,
          },
        },
      },
    },
  },
}
