local colorschemeName = nixInfo("retrobox", "settings", "colorscheme")

if colorschemeName == "noctalia" then
  require("plugins.noctalia")
else
  vim.cmd.colorscheme(colorschemeName)
end

require("plugins.lualine")
require("plugins.oil")
require("plugins.snacks")
require("plugins.mini")

require("lze").load({
  { import = "plugins.treesitter" },
  { import = "plugins.which-key" },
  { import = "plugins.completion" },
  { import = "plugins.preview.markdown" },
  { import = "plugins.preview.typst" },
  { import = "plugins.flash" },
  { import = "plugins.repl" },
  { import = "plugins.debug" },
})
