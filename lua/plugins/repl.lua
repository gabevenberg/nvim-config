return {
  {
    "conjure",
    ft = { "lua", "fennel", "python", "rust", "scheme", },
    for_cat = "repl",
    after = function()
      vim.g["conjure#extract#tree_sitter#enableasd"] = true
      vim.g["conjure#mapping#log_split"] = "Ls"
      vim.g["conjure#mapping#log_vsplit"] = "Lv"
      vim.g["conjure#mapping#log_tab"] = "Lt"
      vim.g["conjure#mapping#log_buf"] = "Lb"
      vim.g["conjure#mapping#log_toggle"] = "Lg"
      vim.g["conjure#mapping#log_reset_soft"] = "Lr"
      vim.g["conjure#mapping#log_reset_hard"] = "LR"
      vim.g["conjure#mapping#log_jump_to_latest"] = "Ll"
      vim.g["conjure#mapping#log_close_visible"] = "Lq"
      vim.g["conjure#client#lua#neovim#mapping#reset_env"] = "Rr"
      vim.g["conjure#client#lua#neovim#mapping#reset_all_envs"] = "Ra"
    end
  },
  {
    "iron.nvim",
    ft = {
      "lua",
      "fennel",
      "python",
      "scheme",
      "zsh",
      "sh",
      "forth",
      "fish",
      "haskell",
      "lisp",
      "uiua",
    },
    after = function()
      local iron = require("iron.core")
      local view = require("iron.view")

      iron.setup {
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          -- Your repl definitions come here
          repl_definition = {
            uiua={
              command = {"uiua", "repl"}
            }
          },
          repl_filetype = function(bufnr, ft)
            return ft
          end,
          -- Send selections to the DAP repl if an nvim-dap session is running.
          dap_integration = true,
          -- How the repl window will be displayed
          -- See below for more information
          repl_open_cmd = view.split.botright(.3),

          -- repl_open_cmd can also be an array-style table so that multiple
          -- repl_open_commands can be given.
          -- When repl_open_cmd is given as a table, the first command given will
          -- be the command that `IronRepl` initially toggles.
          -- Moreover, when repl_open_cmd is a table, each key will automatically
          -- be available as a keymap (see `keymaps` below) with the names
          -- toggle_repl_with_cmd_1, ..., toggle_repl_with_cmd_k
          -- For example,
          --
          -- repl_open_cmd = {
          --   view.split.vertical.rightbelow("%40"), -- cmd_1: open a repl to the right
          --   view.split.rightbelow("%25")  -- cmd_2: open a repl below
          -- }

        },
        -- Iron doesn't set keymaps by default anymore.
        -- You can set them here or manually add keymaps to the functions in iron.core
        keymaps = {
          toggle_repl = "<leader>rr",  -- toggles the repl open and closed.
          restart_repl = "<leader>rR", -- calls `IronRestart` to restart the repl
          send_motion = "<leader>rc",
          visual_send = "<leader>rc",
          send_file = "<leader>rf",
          send_line = "<leader>rl",
          -- send_paragraph = "<leader>rp",
          -- send_until_cursor = "<leader>ru",
          send_mark = "<leader>rm",
          -- send_code_block = "<leader>rb",
          send_code_block_and_move = "<leader>rn",
          mark_motion = "<leader>mc",
          mark_visual = "<leader>mc",
          remove_mark = "<leader>md",
          cr = "<leader>r<cr>",
          interrupt = "<leader>r<leader>",
          exit = "<leader>rq",
          clear = "<leader>l",
        },
        -- If the highlight is on, you can change how it looks
        -- For the available options, check nvim_set_hl
        highlight = {
          italic = true
        },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      }
    end,
  }
}
