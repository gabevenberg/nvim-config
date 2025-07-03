local catUtils = require('nixCatsUtils')
if (catUtils.isNixCats and nixCats('lspDebugMode')) then
  vim.lsp.set_log_level("debug")
end
-- we create a function that lets us more easily define mappings specific
-- for LSP related items. It sets the mode, buffer and description for us each time.

local lspmap = function(keys, func, desc)
  if desc then
    desc = 'LSP: ' .. desc
  end

  -- all of our LSP keybindings will be namespaced under <leader>l
  keys = '<leader>l' .. keys

  vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
end

lspmap('r', vim.lsp.buf.rename, '[R]ename')
lspmap('a', vim.lsp.buf.code_action, '[C]ode Action')

lspmap('d', vim.lsp.buf.definition, 'Goto [D]efinition')

-- NOTE: why are these functions that call the telescope builtin?
-- because otherwise they would load telescope eagerly when this is defined.
-- due to us using the on_require handler to make sure it is available.
if nixCats('telescope') then
  lspmap('R', function() require('telescope.builtin').lsp_references() end, 'Goto [R]eferences')
  lspmap('I', function() require('telescope.builtin').lsp_implementations() end, 'Goto [I]mplementation')
  lspmap('s', function() require('telescope.builtin').lsp_document_symbols() end, 'Document [S]ymbols')
  lspmap('ws', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, '[W]orkspace [S]ymbols')
end   -- TODO: Investigate whether I can replace these with snacsk.nvim.

lspmap('D', vim.lsp.buf.type_definition, 'Type [D]efinition')
lspmap('h', vim.lsp.buf.hover, 'Hover Documentation')
lspmap('s', vim.lsp.buf.signature_help, 'Signature Documentation')
lspmap('f', vim.lsp.buf.format, 'Format buffer')

-- Lesser used LSP functionality
lspmap('D', vim.lsp.buf.declaration, 'Goto [D]eclaration')
lspmap('wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
lspmap('wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
lspmap('wl', function()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, '[W]orkspace [L]ist Folders')

-- NOTE: This file uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- This is a slightly more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- nixCats gives us the paths, which is faster than searching the rtp!
local old_ft_fallback = require('lze').h.lsp.get_ft_fallback()
require('lze').h.lsp.set_ft_fallback(function(name)
  local lspcfg = nixCats.pawsible({ "allPlugins", "opt", "nvim-lspconfig" }) or
      nixCats.pawsible({ "allPlugins", "start", "nvim-lspconfig" })
  if lspcfg then
    local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
    if not ok then
      ok, cfg = pcall(dofile, lspcfg .. "/lua/lspconfig/configs/" .. name .. ".lua")
    end
    return (ok and cfg or {}).filetypes or {}
  else
    return old_ft_fallback(name)
  end
end)
require('lze').load {
  {
    "nvim-lspconfig",
    for_cat = "lsp",
    on_require = { "lspconfig" },
    -- NOTE: define a function for lsp,
    -- and it will run for all specs with type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
  },
  {
    "mason.nvim",
    -- only run it when not on nix
    enabled = not catUtils.isNixCats,
    on_plugin = { "nvim-lspconfig" },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("mason-lspconfig.nvim")
      require('mason').setup()
      -- auto install will make it install servers when lspconfig is called on them.
      require('mason-lspconfig').setup { automatic_installation = true, }
    end,
  },
  {
    -- lazydev makes your lsp way better in your config without needing extra lsp configuration.
    "lazydev.nvim",
    for_cat = "lua",
    cmd = { "LazyDev" },
    ft = "lua",
    after = function(_)
      require('lazydev').setup({
        library = {
          { words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. '/lua' },
        },
      })
    end,
  },
  {
    -- name of the lsp
    "lua_ls",
    enabled = nixCats('lua'),
    -- provide a table containing filetypes,
    -- and then whatever your functions defined in the function type specs expect.
    -- in our case, it just expects the normal lspconfig setup options,
    -- but with a default on_attach and capabilities
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      filetypes = { 'lua' },
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          formatters = {
            ignoreComments = true,
          },
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "nixCats", "vim", },
            disable = { 'missing-fields' },
          },
          telemetry = { enabled = false },
        },
      },
    },
    -- also these are regular specs and you can use before and after and all the other normal fields
  },
  {
    "nixd",
    enabled = catUtils.isNixCats and nixCats('lsp.nix'),
    lsp = {
      filetypes = { "nix" },
      settings = {
        nixd = {
          -- nixd requires some configuration.
          -- luckily, the nixCats plugin is here to pass whatever we need!
          -- we passed this in via the `extra` table in our packageDefinitions
          -- for additional configuration options, refer to:
          -- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
          nixpkgs = {
            -- in the extras set of your package definition:
            -- nixdExtras.nixpkgs = ''import ${pkgs.path} {}''
            expr = nixCats.extra("nixdExtras.nixpkgs")
          },
          options = {
            -- If you integrated with your system flake,
            -- you should use inputs.self as the path to your system flake
            -- that way it will ALWAYS work, regardless
            -- of where your config actually was.
            nixos = {
              -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
              expr = nixCats.extra("nixdExtras.nixos_options")
            },
            -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
            -- You can override the correct one into your package definition on import in your main configuration,
            -- or just put an absolute path to where it usually is and accept the impurity.
            ["home-manager"] = {
              -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
              expr = nixCats.extra("nixdExtras.home_manager_options")
            }
          },
          formatting = {
            command = { "alejandra" }
          },
          diagnostic = {
            suppress = {
              "sema-escaping-with"
            }
          }
        }
      },
    },
  },
  {
    "rustaceanvim",
    for_cat = "lsp.rust",
  },
}
