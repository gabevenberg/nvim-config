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
      { "<leader>v", "<cmd>VenvSelect<CR>", mode = { "n", }, noremap = true, desc = "Venv selector" },
    },
    after=function()
      require("venv-selector").setup()
    end
  }
}
