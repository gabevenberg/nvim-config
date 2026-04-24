-- mini.nvim setup
require("mini.ai").setup()
require("mini.align").setup()
require("mini.basics").setup({
  -- Options. Set field to `false` to disable.
  options = {
    -- Basic options ('number', 'ignorecase', and many more)
    basic = false,
    -- Extra UI features ('winblend', 'listchars', 'pumheight', ...)
    extra_ui = false,
    -- Presets for window borders ('single', 'double', ...)
    -- Default 'auto' infers from 'winborder' option
    win_borders = 'single',
  },
  -- Mappings. Set field to `false` to disable.
  mappings = {
    -- Basic mappings (better 'jk', save with Ctrl+S, ...)
    basic = true,
    -- Prefix for mappings that toggle common options ('wrap', 'spell', ...).
    -- Supply empty string to not create these mappings.
    option_toggle_prefix = [[\]],
    -- Window navigation with <C-hjkl>, resize with <C-arrow>
    windows = true,
    -- Move cursor in Insert, Command, and Terminal mode with <M-hjkl>
    move_with_alt = false,
  },
  -- Autocommands. Set field to `false` to disable
  autocommands = {
    -- Basic autocommands (highlight on yank, start Insert in terminal, ...)
    basic = true,
    -- Set 'relativenumber' only in linewise and blockwise Visual mode
    relnum_in_visual_mode = false,
  },
})
require("mini.bracketed").setup()
require("mini.comment").setup()
require("mini.diff").setup({
  view = {
    style = "sign",
    signs = { add = '+', change = '~', delete = '-' },
  },
  mappings = {
    -- Apply hunks inside a visual/operator region
    apply = 'gh',
    -- Reset hunks inside a visual/operator region
    reset = 'gH',
    -- Hunk range textobject to be used inside operator
    -- Works also in Visual mode if mapping differs from apply and reset
    textobject = 'gh',
    -- Go to hunk range in corresponding direction
    goto_first = '[H',
    goto_prev = '[h',
    goto_next = ']h',
    goto_last = ']H',
  },
})
require("mini.git").setup()
require("mini.hipatterns").setup({
  highlighters = {
    -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
    fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
    hack      = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
    todo      = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
    note      = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

    -- Highlight hex color strings (`#rrggbb`) using that color
    hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
  },
})
require("mini.move").setup({
  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
    left = '<M-h>',
    right = '<M-l>',
    down = '<M-j>',
    up = '<M-k>',

    -- Move current line in Normal mode
    line_left = '<M-h>',
    line_right = '<M-l>',
    line_down = '<M-j>',
    line_up = '<M-k>',
  },
  -- Options which control moving behavior
  options = {
    -- Automatically reindent selection during linewise vertical move
    reindent_linewise = true,
  },
})
require("mini.pairs").setup()
require("mini.surround").setup({
  -- Add custom surroundings to be used on top of builtin ones. For more
  -- information with examples, see `:h MiniSurround.config`.
  custom_surroundings = nil,
  -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
  highlight_duration = 500,
  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    add = '<leader>aa',       -- Add surrounding in Normal and Visual modes
    delete = '<leader>ad',    -- Delete surrounding
    find = '<leader>af',      -- Find surrounding (to the right)
    find_left = '<leader>aF', -- Find surrounding (to the left)
    highlight = '<leader>ah', -- Highlight surrounding
    replace = '<leader>ar',   -- Replace surrounding

    suffix_last = 'l',        -- Suffix to search with "prev" method
    suffix_next = 'n',        -- Suffix to search with "next" method
  },
  -- Number of lines within which surrounding is searched
  n_lines = 50,
  -- Whether to respect selection type:
  -- - Place surroundings on separate lines in linewise mode.
  -- - Place surroundings on each line in blockwise mode.
  respect_selection_type = false,
  -- How to search for surrounding (first inside current line, then inside
  -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
  -- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
  -- see `:h MiniSurround.config`.
  search_method = 'cover',
  -- Whether to disable showing non-error feedback
  -- This also affects (purely informational) helper messages shown after
  -- idle time if user input is required.
  silent = false,
})

vim.keymap.set("n", "<leader>go", require("mini.diff").toggle_overlay, { desc = "git overlay" })
vim.keymap.set("n", "<leader>gr", require("mini.git").show_range_history, { desc = "git range history" })
vim.keymap.set("n", "<leader>go", require("mini.git").show_diff_source, { desc = "git diff source" })
vim.keymap.set("n", "<leader>gi", require("mini.git").show_at_cursor, { desc = "git show info at cursor" })
