return {
  "typst-preview.nvim",
  for_cat = "typst",
  ft = "typst",
  cmd = { "TypstPreview", "TypstPreviewStop", "TypstPreviewToggle" },
  keys = {
    { "<leader>Ptp", "<cmd>TypstPreview <CR>", mode = { "n" }, noremap = true, desc = "typst preview" },
    { "<leader>Pts", "<cmd>TypstPreviewStop <CR>", mode = { "n" }, noremap = true, desc = "typst preview stop" },
    { "<leader>Ptt", "<cmd>TypstPreviewToggle <CR>", mode = { "n" }, noremap = true, desc = "typst preview toggle" },
  },
  after = function()
    require("typst-preview").setup({
      dependencies_bin = {
        ["tinymist"] = "tinymist",
        ["websocat"] = "websocat",
      },
    })
  end,
}
