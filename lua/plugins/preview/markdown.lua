return {
  {
    "markdown-preview.nvim",
    for_cat = "markdown",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = "markdown",
    keys = {
      { "<leader>Pmw", "<cmd>MarkdownPreviewToggle <CR>", mode = { "n" }, noremap = true, desc = "markdown web preview toggle", },
    },
    before = function()
      vim.g.mkdp_auto_close = 0
    end,
  },
  {
    "render-markdown.nvim",
    for_cat = "markdown",
    cmd = { "RenderMarkdown" },
    ft = "markdown",
    keys = {
      { "<leader>Pmp", function() require("render-markdown").set() end,     mode = { "n" }, noremap = true, desc = "markdown render toggle", },
    },
    after = function()
      require('render-markdown').setup({})
    end,
  }
}
