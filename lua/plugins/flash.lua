return {
  {
    "flash.nvim",
    for_cat = 'lazy',
    keys = {
      { "s",     function() require("flash").jump() end,              mode = { "n", "x", "o" }, noremap = true, desc = "Flash" },
      { "S",     function() require("flash").treesitter() end,        mode = { "n", "x", "o" }, noremap = true, desc = "Flash Treesitter" },
      { "r",     function() require("flash").remote() end,            mode = "o",               noremap = true, desc = "Remote Flash" },
      { "R",     function() require("flash").treesitter_search() end, mode = { "o", "x" },      noremap = true, desc = "Treesitter Search" },
      { "<c-s>", function() require("flash").toggle() end,            mode = { "c" },           noremap = true, desc = "Toggle Flash Search" },
    },
  }
}
