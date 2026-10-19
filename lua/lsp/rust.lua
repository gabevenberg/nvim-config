-- load rust's pretty printers from the toolchain on PATH for lldb.
-- rustaceanvim does the same for its own debuggables.
local function rust_lldb_commands()
  local sysroot = vim.trim(vim.fn.system({ "rustc", "--print", "sysroot" }))
  local etc = vim.fs.joinpath(sysroot, "lib", "rustlib", "etc")
  if vim.v.shell_error ~= 0 or not vim.uv.fs_stat(vim.fs.joinpath(etc, "lldb_lookup.py")) then
    return {}
  end
  return {
    ('command script import "%s"'):format(vim.fs.joinpath(etc, "lldb_lookup.py")),
    ('command source -s 0 "%s"'):format(vim.fs.joinpath(etc, "lldb_commands")),
  }
end

return {
  {
    "rustaceanvim",
    for_cat = "rust",
    before = function()
      if nixInfo(false, "settings", "cats", "debug") then
        local dap_config
        if require("dap_native").debugger == "lldb" then
          dap_config = {
            adapter = { type = "executable", command = "lldb-dap", name = "lldb" },
            configuration = { type = "lldb", name = "Rust debug (lldb)", request = "launch" },
          }
        else
          dap_config = {
            adapter = { type = "executable", command = "rust-gdb" },
            configuration = { type = "rust-gdb", name = "Rust debug (rust-gdb)", request = "launch" },
            add_dynamic_library_paths = false,
          }
        end
        -- autoload runs cargo build for every target on each rust-analyzer attach, ;dL runs it on demand
        dap_config.autoload_configurations = false
        vim.g.rustaceanvim = { dap = dap_config }
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
      if require("dap_native").debugger == "lldb" then
        dap.configurations.rust = require("dap_native").configurations("lldb", rust_lldb_commands)
      else
        dap.adapters["rust-gdb"] = {
          type = "executable",
          command = "rust-gdb",
          args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
        }
        dap.configurations.rust = require("dap_native").configurations("rust-gdb")
      end

      dap.adapters["probe-rs-debug"] = {
        type = "server",
        port = "${port}",
        executable = { command = "probe-rs", args = { "dap-server", "--port", "${port}" } },
      }
      dap.listeners.before["event_probe-rs-rtt-channel-config"]["dap-rust"] = function(session, body)
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
