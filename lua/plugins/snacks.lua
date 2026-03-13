-- snacks.nvim setup
require("snacks").setup({
  bufdelete = { enable = true },
  dim = { enable = true },
  git = { enable = true },
  input = { enable = true },
  notifier = { enable = true },
  terminal = { enable = true },
  toggle = { enable = true },
  quickfile = { enable = true },
  scope = { enable = true },
  statuscolumn = { enable = true },

  explorer = { replace_netrw = true },
  picker = {
    enabled = true,
    ui_select = true,
    matcher = {
      fuzzy = true,
      frecency = true,
    },
    previewers = {
      diff = {
        builtin = true,    -- use Neovim for previewing diffs (true) or use an external tool (false)
        cmd = { "delta" }, -- example to show a diff with delta
      },
      git = {
        builtin = true, -- use Neovim for previewing git output (true) or use git (false)
      },
    },
  },
  indent = {
    enabled = true,
    animate = { enabled = false },
    scope = { enabled = true },
    chunk = { enabled = true },
  },
  image = { enabled = false, inline = false, float = false },
  lazygit = { enabled = true, configure = false },
})
-- setup keybinds.
vim.keymap.set("n", "<leader>bd", Snacks.bufdelete.delete, { desc = "delete buffer" })
vim.keymap.set("n", "<leader>t", function() Snacks.explorer() end, { desc = "File [T]ree" })
vim.keymap.set("n", "<leader>i", Snacks.image.hover, { desc = "[I]mage preview" })

-- picker keybinds
vim.keymap.set("n", "<leader>fGb", Snacks.picker.grep_buffers, { desc = "[G]rep buffers" })
vim.keymap.set("n", "<leader>fGl", Snacks.picker.lines, { desc = "[L]ines in buffer" })
vim.keymap.set("n", "<leader>fb", Snacks.picker.buffers, { desc = "[B]uffers" })
vim.keymap.set("n", "<leader>ff", Snacks.picker.files, { desc = "[F]iles" })
vim.keymap.set("n", "<leader>fg", Snacks.picker.grep, { desc = "[G]rep all" })
vim.keymap.set("n", "<leader>fh", Snacks.picker.help, { desc = "[H]elp" })
vim.keymap.set("n", "<leader>fi", Snacks.picker.icons, { desc = "[I]cons" })
vim.keymap.set("n", "<leader>fm", Snacks.picker.marks, { desc = "[M]arks" })
vim.keymap.set("n", "<leader>fs", Snacks.picker.spelling, { desc = "[S]pelling" })
vim.keymap.set("n", "<leader>ft", Snacks.picker.treesitter, { desc = "[T]reesitter" })
vim.keymap.set("n", "<leader>fu", Snacks.picker.undo, { desc = "[U]ndo" })
vim.keymap.set("n", "<leader>fz", Snacks.picker.zoxide, { desc = "[Z]oxide" })

-- picker git keybinds
vim.keymap.set("n", "<leader>gB", Snacks.git.blame_line, { desc = "[G]it [B]lame" })
vim.keymap.set("n", "<leader>gb", Snacks.picker.git_branches, { desc = "[G]it [B]ranch" })
vim.keymap.set("n", "<leader>gl", Snacks.picker.git_log, { desc = "[G]it [L]og" })
vim.keymap.set("n", "<leader>gd", Snacks.picker.git_diff, { desc = "[G]it [D]iff" })
vim.keymap.set("n", "<leader>gt", Snacks.lazygit.open, { desc = "lazy[G]it [T]UI" })

-- setup toggles
Snacks.toggle.option("spell", { name = "spelling" }):map("<leader>cs")
Snacks.toggle.option("relativenumber", { name = "Relative Numbering" }):map("<leader>n")
Snacks.toggle.dim():map("<leader>d")

-- terminal keybinds
vim.keymap.set("n", "<leader>s", function()
  Snacks.terminal.toggle(nil, { win = { position = "float" } })
end, { desc = "terminal" })

-- double tap escape leaves terminal mode
vim.keymap.set("t", "<esc>", function(self)
  self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
  if self.esc_timer:is_active() then
    self.esc_timer:stop()
    vim.cmd("stopinsert")
  else
    self.esc_timer:start(200, 0, function() end)
    return "<esc>"
  end
end, { expr = true, desc = "Double tap to escape terminal" })
