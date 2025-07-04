local colorschemeName = nixCats('colorscheme')
if not require('nixCatsUtils').isNixCats then
  colorschemeName = 'gruvbox'
end
-- Could I lazy load on colorscheme with lze?
-- sure. But I was going to call vim.cmd.colorscheme() during startup anyway
-- this is just an example, feel free to do a better job!
vim.cmd.colorscheme(colorschemeName)

local ok, notify = pcall(require, "notify")
if ok then
  notify.setup({
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { focusable = false })
    end,
  })
  vim.notify = notify
  vim.keymap.set("n", "<Esc>", function()
    notify.dismiss({ silent = true, })
  end, { desc = "dismiss notify popup and clear hlsearch" })
end

-- NOTE: you can check if you included the category with the thing wherever you want.
if nixCats('always') then
  -- I didnt want to bother with lazy loading this.
  -- I could put it in opt and put it in a spec anyway
  -- and then not set any handlers and it would load at startup,
  -- but why... I guess I could make it load
  -- after the other lze definitions in the next call using priority value?
  -- didnt seem necessary.
  vim.g.loaded_netrwPlugin = 1
  require("oil").setup({
    default_file_explorer = false,
    view_options = {
      show_hidden = true
    },
    columns = {
      "icon",
      "permissions",
      "size",
      -- "mtime",
    },
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-s>"] = "actions.select_vsplit",
      ["<C-h>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["<C-l>"] = "actions.refresh",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      ["g\\"] = "actions.toggle_trash",
    },
  })
  vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = 'Open Parent Directory' })
  vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", { noremap = true, desc = 'Open nvim root directory' })
end

if nixCats("always") then
  -- Potentially checkout the lazygit module.
  local Snacks = require("snacks")
  Snacks.setup({
    bufdelete = { enable = true },
    dim = { enable = true },
    git = { enable = true },
    image = { enable = true },
    input = { enable = true },
    lazygit = { enable = true },
    notifier = { enable = true },
    scroll = { enable = true },
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
  })

  -- setup keybinds.
  vim.keymap.set("n", "<leader>bd", Snacks.bufdelete.delete, { desc = "delete buffer" })
  vim.keymap.set("n", "<leader>t", function() Snacks.explorer() end, { desc = "File [T]ree" })
  vim.keymap.set("n", "<leader>gb", Snacks.git.blame_line, { desc = "[G]it [B]lame" })
  vim.keymap.set("n", "<leader>gl", Snacks.git.blame_line, { desc = "[L]azy[G]it" })

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
  vim.keymap.set("n", "<leader>gb", Snacks.picker.git_branches, { desc = "[G]it [B]ranch" })
  vim.keymap.set("n", "<leader>gl", Snacks.picker.git_log, { desc = "[G]it [L]og" })
  vim.keymap.set("n", "<leader>gd", Snacks.picker.git_diff, { desc = "[G]it [D]iff" })

  -- setup toggles
  Snacks.toggle.option("spell", { name = "spelling" }):map("<leader>cs")
  Snacks.toggle.option("relativenumber", { name = "Relative Numbering" }):map("<leader>n")
  Snacks.toggle.dim():map("<leader>d")

  -- terminal keybinds
  vim.keymap.set("n", "<leader>s", function()
    Snacks.terminal.toggle(nil, { win = { position = "float" } })
  end, { desc = "terminal" })

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

  -- setup rename autocmds
  local prev = { new_name = "", old_name = "" } -- Prevents duplicate events
  vim.api.nvim_create_autocmd("User", {
    pattern = "OilActionsPost",
    callback = function(event)
      if event.data.actions.type == "move" then
        Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      end
    end,
  })
end

require('lze').load {
  { import = "myLuaConf.plugins.treesitter", },
  { import = "myLuaConf.plugins.completion", },
  {
    "markdown-preview.nvim",
    -- NOTE: for_cat is a custom handler that just sets enabled value for us,
    -- based on result of nixCats('cat.name') and allows us to set a different default if we wish
    -- it is defined in luaUtils template in lua/nixCatsUtils/lzUtils.lua
    -- you could replace this with enabled = nixCats('cat.name') == true
    -- if you didnt care to set a different default for when not using nix than the default you already set
    for_cat = 'markdown',
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle", },
    ft = "markdown",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreview <CR>",       mode = { "n" }, noremap = true, desc = "markdown preview" },
      { "<leader>ms", "<cmd>MarkdownPreviewStop <CR>",   mode = { "n" }, noremap = true, desc = "markdown preview stop" },
      { "<leader>mt", "<cmd>MarkdownPreviewToggle <CR>", mode = { "n" }, noremap = true, desc = "markdown preview toggle" },
    },
    before = function()
      vim.g.mkdp_auto_close = 0
    end,
  },
  {
    "leap.nvim",
    for_cat = 'always',
    event = "DeferredUIEnter",
    after = function()
      require('leap').set_default_mappings()
    end,
  },
  {
    "nvim-surround",
    for_cat = 'always',
    event = "DeferredUIEnter",
    -- keys = "",
    after = function()
      require('nvim-surround').setup()
    end,
  },
  {
    "marks.nvim",
    for_cat = "always",
    after = function()
      require('marks').setup({})
    end
  },
  {
    "vim-startuptime",
    for_cat = 'extra',
    cmd = { "StartupTime" },
    before = function(_)
      vim.g.startuptime_event_width = 0
      vim.g.startuptime_tries = 10
      vim.g.startuptime_exe_path = nixCats.packageBinPath
    end,
  },
  {
    "lualine.nvim",
    for_cat = 'always',
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function()
      require('lualine').setup({
        options = {
          alwaysDivideMiddle = true,
          icons_enabled = true,
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "filetype" },
          lualine_y = {},
          lualine_z = {},
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        tabline = {
          lualine_a = { { "buffers", mode = 4 } },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { { "tabs", mode = 2 } }
        },
      })
    end,
  },
  {
    "gitsigns.nvim",
    for_cat = 'always',
    event = "DeferredUIEnter",
    -- cmd = { "" },
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function()
      require('gitsigns').setup({
        -- See `:help gitsigns.txt`
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map({ 'n', 'v' }, ']c', function()
            if vim.wo.diff then
              return ']c'
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to next hunk' })

          map({ 'n', 'v' }, '[c', function()
            if vim.wo.diff then
              return '[c'
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to previous hunk' })

          -- Actions
          -- visual mode
          map('v', '<leader>hs', function()
            gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'stage git hunk' })
          map('v', '<leader>hr', function()
            gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'reset git hunk' })
          -- normal mode
          map('n', '<leader>gs', gs.stage_hunk, { desc = 'git stage hunk' })
          map('n', '<leader>gr', gs.reset_hunk, { desc = 'git reset hunk' })
          map('n', '<leader>gS', gs.stage_buffer, { desc = 'git Stage buffer' })
          map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
          map('n', '<leader>gR', gs.reset_buffer, { desc = 'git Reset buffer' })
          map('n', '<leader>gp', gs.preview_hunk, { desc = 'preview git hunk' })
          map('n', '<leader>gb', function()
            gs.blame_line { full = false }
          end, { desc = 'git blame line' })
          map('n', '<leader>gd', gs.diffthis, { desc = 'git diff against index' })
          map('n', '<leader>gD', function()
            gs.diffthis '~'
          end, { desc = 'git diff against last commit' })

          -- Toggles
          map('n', '<leader>gtb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
          map('n', '<leader>gtd', gs.toggle_deleted, { desc = 'toggle git show deleted' })

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
        end,
      })
      vim.cmd([[hi GitSignsAdd guifg=#04de21]])
      vim.cmd([[hi GitSignsChange guifg=#83fce6]])
      vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
    end,
  },
  {
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
  },
}
