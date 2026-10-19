-- snacks.nvim setup

--- takes a snacks term and gives a string with its terminal number and the title if it is not the default.
---@param buf? integer defaults to the current buffer
---@return string
function _G.snacks_term_label(buf)
  buf = buf or 0
  local term = vim.b[buf].snacks_terminal
  local id = term and term.id or ""
  local pos = term and term.env and term.env.snacks_pos
  if pos then
    id = id .. " " .. pos
  end
  local title = vim.b[buf].term_title or ""
  -- neovims default term_title start with a term:// placeholder
  if title == "" or title:find("^term://") then
    return tostring(id)
  else
    return id .. ": " .. title
  end
end

require("snacks").setup({
  bufdelete = { enabled = true },
  dim = { enabled = true },
  git = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  terminal = {
    enabled = true,
    win = {
      -- snacks only gives splits a winbar by default, floats get the id too
      wo = { winbar = "%{v:lua.snacks_term_label()}" },
    },
  },
  toggle = { enabled = true },
  quickfile = { enabled = true },
  scope = {
    enabled = true,
    keys = {
      -- [i and ]i belong to mini.bracketed's indent jumps
      jump = {
        ["[i"] = false,
        ["]i"] = false,
        ["[e"] = {
          min_size = 1,
          bottom = false,
          cursor = false,
          edge = true,
          treesitter = { blocks = { enabled = false } },
          desc = "jump to top edge of scope",
        },
        ["]e"] = {
          min_size = 1,
          bottom = true,
          cursor = false,
          edge = true,
          treesitter = { blocks = { enabled = false } },
          desc = "jump to bottom edge of scope",
        },
      },
    },
  },

  statuscolumn = {
    enabled = true,
    left = { "mark", "sign" }, -- priority of signs on the left (high to low)
    right = { "fold", "git" }, -- priority of signs on the right (high to low)
    folds = {
      open = false, -- show open fold icons
      git_hl = false, -- use Git Signs hl for fold icons
    },
    git = {
      -- patterns to match Git signs
      patterns = { "MiniDiffSign" },
    },
    refresh = 50, -- refresh at most every 50ms
  },

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
        builtin = true, -- use Neovim for previewing diffs (true) or use an external tool (false)
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
    scope = {
      enabled = true,
      underline = false,
    },
    chunk = { enabled = true },
  },
  image = { enabled = false, inline = false, float = false },
  lazygit = { enabled = true, configure = true },
})
-- setup keybinds.
vim.keymap.set("n", "<leader>bd", Snacks.bufdelete.delete, { desc = "delete buffer" })
vim.keymap.set("n", "<leader>bD", Snacks.bufdelete.other, { desc = "delete all other buffers" })
vim.keymap.set("n", "<leader>t", function()
  Snacks.explorer()
end, { desc = "File [T]ree" })
vim.keymap.set("n", "<leader>i", Snacks.image.hover, { desc = "[I]mage preview" })

-- picker keybinds
vim.keymap.set("n", "<leader>fB", Snacks.picker.grep_buffers, { desc = "Grep [b]uffers" })
vim.keymap.set("n", "<leader>fl", Snacks.picker.lines, { desc = "[l]ines in buffer" })
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
vim.keymap.set("n", "<leader>gb", Snacks.git.blame_line, { desc = "[G]it [B]lame" })
vim.keymap.set("n", "<leader>gB", Snacks.picker.git_branches, { desc = "[G]it [B]ranch" })
vim.keymap.set("n", "<leader>gL", Snacks.picker.git_log, { desc = "[G]it [L]og" })
vim.keymap.set("n", "<leader>gd", Snacks.picker.git_diff, { desc = "[G]it [D]iff" })
vim.keymap.set("n", "<leader>gl", Snacks.lazygit.open, { desc = "lazy[G]it [T]UI" })

-- setup toggles
Snacks.toggle.dim():map("<leader>D")

-- terminal keybinds
-- snacks keys terminals on cmd, cwd, env and count, so a distinct env keeps the float and split terminals apart
vim.keymap.set("n", "<leader>s", function()
  Snacks.terminal.toggle(nil, { win = { position = "float" }, env = { snacks_pos = "float" } })
end, { desc = "terminal" })
vim.keymap.set("n", "<leader>S", function()
  Snacks.terminal.toggle(nil, { win = { position = "bottom" }, env = { snacks_pos = "bottom" } })
end, { desc = "terminal" })
-- Terminal picker
vim.keymap.set("n", "<leader>fT", function()
  local items = vim.tbl_map(function(term)
    return {
      text = snacks_term_label(term.buf),
      id = vim.b[term.buf].snacks_terminal.id,
      buf = term.buf,
      term = term,
    }
  end, Snacks.terminal.list())
  table.sort(items, function(a, b)
    return a.id < b.id
  end)
  Snacks.picker.pick({
    title = "Terminals",
    items = items,
    format = "text",
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      item.term:show():focus()
    end,
  })
end, { desc = "[T]erminals" })
