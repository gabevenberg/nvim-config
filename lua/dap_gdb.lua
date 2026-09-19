-- configurations for gdb's native DAP, shared by C, C++ and Rust.
-- the adapters are set up in plugins/debug.lua and lsp/rust.lua.
local M = {}

-- a function, so the picker opens when the configuration runs, not when nvim-dap loads
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

-- adapter is "gdb", or "rust-gdb" for rust's pretty printers.
function M.configurations(adapter)
  adapter = adapter or "gdb"
  return {
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
    {
      type = adapter,
      request = "attach",
      name = "Attach to gdbserver (" .. adapter .. ")",
      program = pick_program,
      target = function()
        local target = vim.fn.input("gdbserver host:port: ", "localhost:")
        if target == "" or target == "localhost:" then
          return require("dap").ABORT
        end
        return target
      end,
    },
  }
end

return M
