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
        { "<leader>P",  group = "[p]review" },
        { "<leader>Pt", group = "[p]review [t]ypst" },
        { "<leader>Pm", group = "[p]review [m]arkdown" },
        { "<leader>f",  group = "[f]ind" },
        { "<leader>t",  group = "[t]ree" },
        { "<leader>l",  group = "[l]sp" },
        { "<leader>L",  group = "Conjure [L]og" },
        { "<leader>b",  group = "[b]uffer" },
        { "<leader>e",  group = "[e]valuate" },
        { "<leader>r",  group = "io[r]n" },
        { "<leader>a",  group = "surround" },
        { "<leader>lw", group = "[l]sp [w]orkspace" },
      }
    end,
  },
}
