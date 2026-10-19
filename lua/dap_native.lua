-- configurations for, gdb's own DAP or lldb-dap, for C, C++, and Rust.
-- the adapters are set up in plugins/debug.lua and lsp/rust.lua.
local M = {}

-- "gdb" or "lldb", lldb on darwin since gdb cannot debug native programs on apple silicon.
M.debugger = nixInfo("gdb", "settings", "debugger")

local function pick_program()
  local program = require("dap.utils").pick_file({
    -- pick_file strips the prefix from its labels with a lua pattern,
    -- so an absolute cwd containing a - would be listed in full
    path = ".",
    -- strip out hidden files.
    filter = function(path)
      return not path:find("/.", 1, true)
    end,
  })
  return type(program) == "string" and vim.fn.fnamemodify(program, ":p") or program
end

local function pick_remote()
  local target = vim.fn.input("gdbserver host:port: ", "localhost:")
  if target == "" or target == "localhost:" then
    return require("dap").ABORT
  end
  return target
end

-- adapter is "gdb", "rust-gdb", or "lldb".
-- init_commands is a list or a function returning one
function M.configurations(adapter, init_commands)
  adapter = adapter or M.debugger
  local configurations = {
    {
      type = adapter,
      request = "launch",
      name = "Launch (" .. adapter .. ")",
      program = pick_program,
      cwd = "${workspaceFolder}",
    },
    {
      type = adapter,
      request = "launch",
      name = "Launch with arguments (" .. adapter .. ")",
      program = pick_program,
      args = function()
        return require("dap.utils").splitstr(vim.fn.input("arguments: "))
      end,
      cwd = "${workspaceFolder}",
    },
    {
      type = adapter,
      request = "attach",
      name = "Attach to process (" .. adapter .. ")",
      pid = function()
        return require("dap.utils").pick_process()
      end,
    },
  }

  if adapter == "lldb" then
    table.insert(configurations, {
      type = adapter,
      request = "attach",
      name = "Attach to gdbserver (" .. adapter .. ")",
      program = pick_program,
      -- lldb-dap creates the target from program, then hands the connection to these
      attachCommands = function()
        local target = pick_remote()
        if target == require("dap").ABORT then
          return target
        end
        return { "gdb-remote " .. target }
      end,
    })
    for _, configuration in ipairs(configurations) do
      configuration.initCommands = init_commands
    end
  else
    table.insert(configurations, {
      type = adapter,
      request = "attach",
      name = "Attach to gdbserver (" .. adapter .. ")",
      program = pick_program,
      target = pick_remote,
    })
  end

  return configurations
end

return M
