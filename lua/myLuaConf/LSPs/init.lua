local catUtils = require('nixCatsUtils')
if (catUtils.isNixCats and nixCats('lspDebugMode')) then
  vim.lsp.set_log_level("debug")
end

local Snacks = require("snacks")

vim.keymap.set("n", "<leader>lI", Snacks.picker.lsp_implementations, { desc = "Goto [I]mplementation" })
vim.keymap.set("n", "<leader>lR", Snacks.picker.lsp_references, { desc = "Goto [R]eferences" })
vim.keymap.set("n", "<leader>li", Snacks.picker.diagnostics, { desc = "D[i]agnostics" })
vim.keymap.set("n", "<leader>ls", Snacks.picker.lsp_symbols, { desc = "Document [S]ymbols" })
vim.keymap.set("n", "<leader>lws", Snacks.picker.lsp_workspace_symbols, { desc = "[W]orkspace [S]ymbols" })

vim.keymap.set("n", "<leader>lD", vim.lsp.buf.declaration, { desc = "Goto [D]eclaration" })
vim.keymap.set("n", "<leader>lD", vim.lsp.buf.type_definition, { desc = "Type [D]efinition" })
vim.keymap.set({"n", "v",}, "<leader>la", vim.lsp.buf.code_action, { desc = "[C]ode Action" })
vim.keymap.set("n", "<leader>ld", vim.lsp.buf.definition, { desc = "Goto [D]efinition" })
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>lh", vim.lsp.buf.hover, { desc = "Hover Documentation" })
vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "[R]ename" })
vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "Signature Documentation" })
vim.keymap.set("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "[W]orkspace [A]dd Folder" })
vim.keymap.set("n", "<leader>lwl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
  { desc = "[W]orkspace [L]ist Folders" })
vim.keymap.set("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "[W]orkspace [R]emove Folder" })

-- setup lsp progress notifications
local progress = vim.defaulttable()
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params
        .value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    if not client or type(value) ~= "table" then
      return
    end
    local p = progress[client.id]

    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ("[%3d%%] %s%s"):format(
            value.kind == "end" and 100 or value.percentage or 100,
            value.title or "",
            value.message and (" **%s**"):format(value.message) or ""
          ),
          done = value.kind == "end",
        }
        break
      end
    end

    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)

    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(table.concat(msg, "\n"), "info", {
      id = "lsp_progress",
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and " "
            or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

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
    -- rustaceanvim and zk-nvim dont require("lspconfig")
    ft = { "markdown", "rust" },
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
    for_cat = "lsp.lua",
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
    enabled = nixCats('lsp.lua'),
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
    "basedpyright",
    enabled = nixCats("lsp.python"),
    lsp = {},
  },
  {
    "bashls",
    enabled = nixCats("lsp.bash"),
    lsp = {},
  },
  {
    "clangd",
    enabled = nixCats("lsp.c"),
    lsp = {},
  },
  {
    "ruff",
    enabled = nixCats("lsp.python"),
    lsp = {},
  },
  {
    "tinymist",
    enabled = nixCats("lsp.tinymist"),
    lsp = {
      filetypes = { "typst" },
      settings = {
        formatterMode = "typstyle",

      },
    },
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
  {
    "zk-nvim",
    for_cat = "lsp.zk",
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
