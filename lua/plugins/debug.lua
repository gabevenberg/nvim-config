return {
  {
    "nvim-dap",
    for_cat = "debug",
    on_require = { "dap" },
    cmd = {
      "DapSetLogLevel",
      "DapShowLog",
      "DapContinue",
      "DapToggleBreakpoint",
      "DapClearBreakpoints",
      "DapToggleRepl",
      "DapStepOver",
      "DapStepInto",
      "DapStepOut",
      "DapPause",
      "DapTerminate",
      "DapDisconnect",
      "DapRestartFrame",
      "DapNew",
      "DapEval",
    },
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "toggle [b]reakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("condition: "))
        end,
        desc = "conditional [B]reakpoint",
      },
      {
        "<leader>dl",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("log message: "))
        end,
        desc = "[l]og point",
      },
      {
        "<leader>dx",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "clear breakpoints",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "[c]ontinue / start",
      },
      {
        "<leader>dr",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "[r]un to cursor",
      },
      {
        "<leader>dR",
        function()
          require("dap").run_last()
        end,
        desc = "[R]un last",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "[p]ause",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "[t]erminate",
      },
      {
        "<leader>du",
        function()
          require("dap").up()
        end,
        desc = "frame [u]p",
      },
      {
        "<leader>dd",
        function()
          require("dap").down()
        end,
        desc = "frame [d]own",
      },
      {
        "<leader>ds",
        function()
          require("dap").step_over()
        end,
        desc = "[s]tep over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "step [i]nto",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "step [o]ut",
      },
      {
        "<leader>dv",
        function()
          require("dap-view").toggle()
        end,
        desc = "toggle dap-[v]iew",
      },
      {
        "<leader>dw",
        function()
          require("dap-view").add_expr()
        end,
        desc = "[w]atch expression",
      },
      -- add_expr reads charwise and linewise selections, a blockwise one falls back to the word under the cursor
      {
        "<leader>dw",
        function()
          require("dap-view").add_expr()
        end,
        mode = "x",
        desc = "[w]atch selection",
      },
      {
        "<leader>dh",
        function()
          require("dap-view").hover()
        end,
        desc = "[h]over value",
      },
    },
    after = function()
      -- rust uses the rust-gdb adapter from lsp/rust.lua instead
      require("dap").adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }
    end,
  },
  {
    "nvim-dap-view",
    for_cat = "debug",
    on_plugin = { "nvim-dap" },
    on_require = { "dap-view" },
    cmd = { "DapViewOpen", "DapViewToggle", "DapViewWatch", "DapViewHover" },
    after = function()
      require("dap-view").setup({
        winbar = {
          sections = { "scopes", "watches", "breakpoints", "threads", "repl", "console" },
          default_section = "scopes",
          controls = { enabled = true },
        },
        virtual_text = { enabled = true },
        -- without a border the hover of a scalar is a single grey cell
        hover = { border = "single" },
        -- closing with the session hides the output of a program that exits early, ;dv toggles it
        auto_toggle = false,
      })
      -- lze loads on_plugin dependents before this after hook runs,
      -- and dap-disasm only registers with dap-view once dap-view is loaded.
      -- its auto_enable drops the spec out of lze's state when nix did not install it,
      -- and trigger_load on an unknown name is an error.
      if require("lze").state("nvim-dap-disasm") ~= nil then
        require("lze").trigger_load("nvim-dap-disasm")
      end
    end,
  },
  {
    "nvim-dap-disasm",
    auto_enable = true,
    lazy = true,
    after = function()
      require("dap-disasm").setup({ dapview_register = true })
      -- register_view does not add the section to the winbar
      table.insert(require("dap-view.setup").config.winbar.sections, "disassembly")
    end,
  },
}
