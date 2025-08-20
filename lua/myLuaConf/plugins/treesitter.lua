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
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true, },
        indent = { enable = false, },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<M-space>',
          },
        },
      }
    end,
  },
  {
    "comment.nvim",
    for_cat = 'telescope',
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
