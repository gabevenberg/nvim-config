-- NOTE: These 2 should be set up before any plugins with keybinds are loaded.
vim.g.mapleader = ";"
vim.g.maplocalleader = ";"

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- allow .nvim.lua in current dir and parents (project config)
vim.o.exrc = false -- can be toggled off in that file to stop it from searching further

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help "list"`
--  and `:help "listchars"`
--  and `:help "showbreak"`
vim.opt.list = true
vim.opt.listchars = { eol = "↲", extends = "⟩", nbsp = "␣", precedes = "⟨", tab = ">-", trail = "•" }
vim.opt.showbreak = "↪"

-- Set highlight on search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Automatically load changed files
vim.opt.autoread = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Make line numbers default
vim.opt.number = true
vim.opt.numberwidth = 3

-- Enable mouse mode
vim.opt.mouse = "a"

-- no hard wrapping
vim.opt.textwidth = 0
vim.opt.wrapmargin = 0

-- get nice visual guides for 80, 100, and 120 cols.
vim.opt.colorcolumn = { "90", "100", "120" }

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
vim.opt.signcolumn = "yes"
vim.opt.relativenumber = true

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { "menu", "preview", "noselect" }

vim.opt.termguicolors = true

-- disable unneded files
vim.opt.swapfile = false

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions

-- set options for auto-commenting and using gq
vim.opt.formatoptions = "rojq"

vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0

vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
