return {
  {
    "rustaceanvim",
    for_cat = "rust",
    before = function()
      if nixInfo(false, "settings", "cats", "debug") then
        vim.g.rustaceanvim = {
          dap = {
            -- autoload runs cargo build for every target on each rust-analyzer attach, ;dL runs it on demand
            autoload_configurations = false,
            -- only has to be set for rustaceanvim to start, sessions run through dap.adapters["rust-gdb"]
            adapter = { type = "executable", command = "rust-gdb" },
            configuration = { type = "rust-gdb", name = "Rust debug (rust-gdb)", request = "launch" },
            -- sends env as a list of KEY=VALUE strings, which gdb rejects, it wants a map
            add_dynamic_library_paths = false,
          },
        }
      end
    end,
  },
  {
    "dap-rust",
    for_cat = { "rust", "debug" },
    on_plugin = { "nvim-dap" },
    -- not a plugin, only here to add configurations when nvim-dap loads
    load = function() end,
    keys = {
      { "<leader>dg", "<cmd>RustLsp debuggables<CR>", ft = "rust", desc = "debu[g]gables picker" },
      { "<leader>dG", "<cmd>RustLsp! debuggables<CR>", ft = "rust", desc = "last debuggable" },
      { "<leader>dn", "<cmd>RustLsp debug<CR>", ft = "rust", desc = "debug [n]earest target" },
      {
        "<leader>dL",
        function()
          -- the builds run silently in the background
          vim.notify("Building cargo targets for debugging", vim.log.levels.INFO)
          require("rustaceanvim.commands.debuggables").add_dap_debuggables()
        end,
        ft = "rust",
        desc = "[L]oad cargo targets",
      },
    },
    after = function()
      local dap = require("dap")
      -- rust-gdb adds rust's pretty printers, then runs gdb from PATH
      dap.adapters["rust-gdb"] = {
        type = "executable",
        command = "rust-gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }
      dap.configurations.rust = require("dap_gdb").configurations("rust-gdb")

      dap.adapters["probe-rs-debug"] = {
        type = "server",
        port = "${port}",
        executable = { command = "probe-rs", args = { "dap-server", "--port", "${port}" } },
      }
      dap.listeners.before["event_probe-rs-rtt-channel-config"]["dap-rust"] = function(session, body)
        -- probe-rs only sends RTT data for channels the client says are open
        session:request("rttWindowOpened", { body.channelNumber, true })
      end
      dap.listeners.before["event_probe-rs-rtt-data"]["dap-rust"] = function(_, body)
        require("dap.repl").append(("RTT %d: %s"):format(body.channelNumber, (body.data:gsub("\n$", ""))))
      end
      dap.listeners.before["event_probe-rs-show-message"]["dap-rust"] = function(_, body)
        require("dap.repl").append("probe-rs: " .. body.message)
      end
    end,
  },
}
