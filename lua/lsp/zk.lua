return {
  {
    "zk-nvim",
    for_cat = "zk",
    ft = "markdown",
    after = function()
      require("zk").setup({ picker = "snacks_picker" })

      vim.api.nvim_set_keymap("n", "<leader>zb", "<Cmd>ZkBackLinks<CR>", { desc = "Show [B]acklinkgs" })
      vim.api.nvim_set_keymap("n", "<leader>zl", "<Cmd>ZkLinks<CR>", { desc = "Show [L]inks" })
      vim.api.nvim_set_keymap("n", "<leader>zi", ":'<,'>ZkInsertLink<CR>", { desc = "[I]nsert link" })
      vim.api.nvim_set_keymap("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>",
        { desc = "[N]ew note" })
      vim.api.nvim_set_keymap("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = "[O]pen notes" })
      vim.api.nvim_set_keymap("n", "<leader>zt", "<Cmd>ZkTags<CR>", { desc = "Search [T]ags" })
      vim.api.nvim_set_keymap("v", "<leader>zf", ":'<,'>ZkMatch<CR>", { desc = "[F]ind note from selection" })
      vim.api.nvim_set_keymap("v", "<leader>zn", ":'<,'>ZkNewFromTitleSelection<CR>", {
        desc =
        "[N]ew note from selection"
      })
    end
  },
}
