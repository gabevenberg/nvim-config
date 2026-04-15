local lspEnabled = nixInfo("settings", "cat", "lsp")

if lspEnabled then
  local Snacks = require("snacks")
  vim.keymap.set("n", "<leader>lI", Snacks.picker.lsp_implementations, { desc = "Goto [I]mplementation" })
  vim.keymap.set("n", "<leader>lR", Snacks.picker.lsp_references, { desc = "Goto [R]eferences" })
  vim.keymap.set("n", "<leader>li", Snacks.picker.diagnostics, { desc = "D[i]agnostics" })
  vim.keymap.set("n", "<leader>ls", Snacks.picker.lsp_symbols, { desc = "Document [S]ymbols" })
  vim.keymap.set("n", "<leader>lws", Snacks.picker.lsp_workspace_symbols, { desc = "[W]orkspace [S]ymbols" })

  vim.keymap.set("n", "<leader>lD", vim.lsp.buf.declaration, { desc = "Goto [D]eclaration" })
  vim.keymap.set("n", "<leader>lt", vim.lsp.buf.type_definition, { desc = "Type [D]efinition" })
  vim.keymap.set({ "n", "v", }, "<leader>la", vim.lsp.buf.code_action, { desc = "[C]ode Action" })
  vim.keymap.set("n", "<leader>ld", vim.lsp.buf.definition, { desc = "Goto [D]efinition" })
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
end

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
    "conform.nvim",
    for_cat = "lsp",
    on_require = { "conform" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>lf", function() require("conform").format({ async = true }) end, mode = { "" }, desc = "Format buffer" },
    },
    after = function()
      require("conform").setup({
        default_format_opts = {
          lsp_format = "fallback",
        },
      })
      -- need to figure out how to properly seperate this.
      if nixInfo("settings", "cat", "config") then
        require("conform").formatters_by_ft.json = { "jaq" }
      end
      if nixInfo("settings", "cat", "lua") then
        require("conform").formatters_by_ft.fennel = { "fnlfmt" }
      end
      if nixInfo("settings", "cat", "nix") then
        require("conform").formatters_by_ft.nix = { "alejandra" }
      end
    end,
  },

  { import = "lsp.C" },
  { import = "lsp.clangd_extensions" },
  { import = "lsp.bash" },
  { import = "lsp.config" },
  { import = "lsp.go" },
  { import = "lsp.jsonnet" },
  { import = "lsp.lua" },
  { import = "lsp.nix" },
  { import = "lsp.nushell" },
  { import = "lsp.python" },
  { import = "lsp.rust" },
  { import = "lsp.typst" },
  { import = "lsp.zig" },
  { import = "lsp.zk" },
}
