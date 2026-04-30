return {
  {
    "blink.compat",
    for_cat = "completion",
    dep_of = { "cmp-conjure" },
  },
  {
    "luasnip",
    for_cat = "completion",
    dep_of = { "blink.cmp" },
    after = function(_)
      vim.cmd.packadd("friendly-snippets")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      luasnip.config.setup({})

      local ls = require("luasnip")

      vim.keymap.set({ "i", "s" }, "<M-n>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end)
    end,
  },
  {
    "colorful-menu.nvim",
    for_cat = "completion",
    on_plugin = { "blink.cmp" },
  },
  {
    "blink-emoji.nvim",
    for_cat = "completion",
    on_plugin = { "blink.cmp" },
  },
  {
    "blink.cmp",
    for_cat = "completion",
    event = "DeferredUIEnter",
    after = function(_)
      require("blink.cmp").setup({
        -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
        -- See :h blink-cmp-config-keymap for configuring keymaps
        keymap = { preset = "enter" },
        cmdline = {
          enabled = true,
          completion = {
            menu = {
              auto_show = true,
            },
          },
          sources = function()
            local type = vim.fn.getcmdtype()
            -- Search forward and backward
            if type == "/" or type == "?" then
              return { "buffer" }
            end
            -- Commands
            if type == ":" or type == "@" then
              return { "cmdline" }
            end
            return {}
          end,
        },
        fuzzy = {
          sorts = {
            "exact",
            -- defaults
            "score",
            "sort_text",
          },
        },
        signature = {
          enabled = true,
          window = {
            show_documentation = true,
          },
        },
        completion = {
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          menu = {
            draw = {
              treesitter = { "lsp" },
              components = {
                label = {
                  text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end,
                },
              },
            },
          },
          documentation = {
            auto_show = true,
          },
        },
        snippets = {
          preset = "luasnip",
          active = function(filter)
            local snippet = require("luasnip")
            local blink = require("blink.cmp")
            if snippet.in_snippet() and not blink.is_visible() then
              return true
            else
              if not snippet.in_snippet() and vim.fn.mode() == "n" then
                snippet.unlink_current()
              end
              return false
            end
          end,
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer", "omni", "emoji" },
          providers = {
            path = {
              score_offset = 50,
            },
            lsp = {
              score_offset = 40,
            },
            snippets = {
              score_offset = 40,
            },
            emoji = {
              module = "blink-emoji",
              name = "Emoji",
              score_offset = 15,
              opts = { insert = true },
            },
            conjure = {
              name = "conjure",
              module = "blink.compat.source",
            },
          },
        },
      })
    end,
  },
}
