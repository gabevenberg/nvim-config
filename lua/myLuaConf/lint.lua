require('lze').load {
  {
    "nvim-lint",
    for_cat = 'lint',
    -- cmd = { "" },
    event = "FileType",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('lint').linters_by_ft = {
        -- NOTE: download some linters in lspsAndRuntimeDeps
        -- and configure them here
        -- markdown = {'vale',},
        -- javascript = { 'eslint' },
        -- typescript = { 'eslint' },
      }
    end,
  },
}
