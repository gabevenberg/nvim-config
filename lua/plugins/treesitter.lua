-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
return {
  {
    "nvim-treesitter",
    for_cat = 'lazy',
    event = "DeferredUIEnter",
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("rainbow-delimiters.nvim")
    end,
    after = function()
      require('nvim-treesitter').setup {
        highlight = { enable = true, },
        indent = { enable = false, },
      }
    end,
  },
  {
    "comment.nvim",
    for_cat = 'lazy',
    after = function(plugin)
      require('Comment').setup()
    end,
  },
  {
    "treesj",
    for_cat = 'lazy',
    keys = { { "<leader>j", "<cmd>TSJToggle<CR>", mode = { "n" }, desc = "Treesitter join" }, },
    after = function(_)
      require("treesj").setup({
        use_default_keymaps = false
      })
    end
  },
}
