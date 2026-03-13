return {
  {
    "which-key.nvim",
    for_cat = 'lazy',
    after = function()
      require('which-key').setup({})
      require('which-key').add {
        { "<leader>g",  group = "[g]it" },
        { "<leader>z",  group = "[z]ettelkasten" },
        { "<leader>gt", group = "[t]oggle" },
        { "<leader>p",  group = "[p]review" },
        { "<leader>pt", group = "[p]review [t]ypst" },
        { "<leader>pm", group = "[p]review [m]arkdown" },
        { "<leader>f",  group = "[f]ind" },
        { "<leader>t",  group = "[t]ree" },
        { "<leader>c",  group = "[c]heck" },
        { "<leader>l",  group = "[l]sp" },
        { "<leader>lw", group = "[l]sp [w]orkspace" },
      }
    end,
  },
}
