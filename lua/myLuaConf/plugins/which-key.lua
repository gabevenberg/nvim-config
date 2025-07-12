return {
  "which-key.nvim",
  for_cat = 'always',
  after = function()
    require('which-key').setup({
    })
    require('which-key').add {
      { "<leader>g",  group = "[g]it" },
      { "<leader>z",  group = "[z]ettelkasten" },
      { "<leader>gt", group = "[t]oggle" },
      { "<leader>m",  group = "[m]arkdown" },
      { "<leader>f",  group = "[f]ind" },
      { "<leader>t",  group = "[t]ree" },
      { "<leader>c",  group = "[c]heck" },
      { "<leader>l",  group = "[l]sp" },
      { "<leader>lw", group = "[l]sp [w]orkspace" },
    }
  end,
}
