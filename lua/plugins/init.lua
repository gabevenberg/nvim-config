local colorschemeName = nixInfo("retrobox", "settings", "colorscheme")

vim.cmd.colorscheme(colorschemeName)

require("plugins.lualine")
require("plugins.oil")
require("plugins.snacks")

require('lze').load {
  { import = "plugins.treesitter", },
  { import = "plugins.gitsigns", },
  { import = "plugins.which-key", },
  { import = "plugins.completion", },
  { import = "plugins.preview.markdown", },
  { import = "plugins.preview.typst", },
  {
    "leap.nvim",
    for_cat = 'always',
    event = "DeferredUIEnter",
    keys = {
      { "s", "<Plug>(leap)", mode = { "n", "x", "o", "v" }, noremap = true, desc = "leap to char sequence" }
    },
  },
  {
    "nvim-surround",
    for_cat = 'always',
    event = "DeferredUIEnter",
    after = function()
      require('nvim-surround').setup()
    end,
  },
  {
    "marks.nvim",
    for_cat = "always",
    after = function()
      require('marks').setup({})
    end
  },
}
