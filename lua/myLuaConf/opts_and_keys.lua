-- NOTE: These 2 need to be set up before any plugins are loaded.
vim.g.mapleader = ';'
vim.g.maplocalleader = ';'

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { eol = "↲", extends = "⟩", nbsp = "␣", precedes = "⟨", tab = ">-", trail = "•" }
vim.opt.showbreak = "↪";

-- Set highlight on search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Automatically load changed files
vim.opt.autoread = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Make line numbers default
vim.opt.number = true

-- Enable mouse mode
vim.opt.mouse = 'a'

-- no hard wrapping
vim.opt.textwidth = 0
vim.opt.wrapmargin = 0

-- get nice visual guides for 80, 100, and 120 cols.
vim.opt.colorcolumn = { "90", "100", "120", }

-- add line numbers
vim.opt.number = true
vim.opt.numberwidth = 3

-- Indent
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.softtabstop = -1
vim.opt.shiftwidth = 4

-- stops line wrapping from being confusing
vim.opt.breakindent = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'
vim.opt.relativenumber = true

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { 'menu', 'preview', 'noselect' }

vim.opt.termguicolors = true

-- disable unneded files
vim.opt.swapfile = false

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions

-- set options for auto-commenting and using gq
vim.opt.formatoptions = "rojq"

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
-- [[ Basic Keymaps ]]

-- make quick system clipboard opts easier
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>p', '"+p', { noremap = true, silent = true, desc = 'Paste from clipboard' })
vim.keymap.set({ "v", "x", "n" }, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({ "n", "v", "x" }, '<leader>Y', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set('i', '<C-p>', '<C-r><C-p>+',
  { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- moving between splits
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'move to right split' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'move to below split' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'move to above split' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'move to left split' })
