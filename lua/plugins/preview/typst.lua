return {
  "typst-preview.nvim",
  for_cat = "typst",
  ft = "typst",
  cmd = { "TypstPreview", "TypstPreviewStop", "TypstPreviewToggle", },
  keys = {
    { "<leader>ptp", "<cmd>TypstPreview <CR>",       mode = { "n" }, noremap = true, desc = "typst preview" },
    { "<leader>pts", "<cmd>TypstPreviewStop <CR>",   mode = { "n" }, noremap = true, desc = "typst preview stop" },
    { "<leader>ptt", "<cmd>TypstPreviewToggle <CR>", mode = { "n" }, noremap = true, desc = "typst preview toggle" },
  },
  after = function()
    require('typst-preview').setup {}
  end
}
