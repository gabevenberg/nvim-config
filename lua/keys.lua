-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Scroll Down' })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Scroll Up' })
vim.keymap.set("n", "n", "nzzzv", { desc = 'Next Search Result' })
vim.keymap.set("n", "N", "Nzzzv", { desc = 'Previous Search Result' })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- moving between splits
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'move to right split' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'move to below split' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'move to above split' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'move to left split' })

-- You should instead use these keybindings so that they are still easy to use, but dont conflict
vim.keymap.set({ "v", "x", "n" }, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({ "n", "v", "x" }, '<leader>Y', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>p', '"+p', { noremap = true, silent = true, desc = 'Paste from clipboard' })
vim.keymap.set('i', '<C-p>', '<C-r><C-p>+',
    { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })

-- workaround for https://github.com/neovim/neovim/issues/14061
vim.keymap.set("ca", "wqa", "wa | qa")
