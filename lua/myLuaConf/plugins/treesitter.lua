-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
return {
  {
    "nvim-treesitter",
    for_cat = 'treesitter',
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("rainbow-delimiters.nvim")
    end,
    after = function(plugin)
      -- [[ Configure Treesitter ]]
      -- See `:help nvim-treesitter`
      require('nvim-treesitter').setup {
        highlight = { enable = true, },
        indent = { enable = false, },
      }
    end,
  },
  {
    "comment.nvim",
    for_cat = 'treesitter',
    after = function(plugin)
      require('Comment').setup()
    end,
  },
  {
    "treesj",
    for_cat = 'treesitter',
    keys = { { "<leader>j", "<cmd>TSJToggle<CR>", mode = { "n" }, desc = "Treesitter join" }, },
    after = function(_)
      require("treesj").setup({
        use_default_keymaps = false
      })
    end
  },
}
