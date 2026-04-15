return {
  {
    "conjure",
    ft = { "lua", "fennel", "python", "rust", "scheme", },
    for_cat = "conjure",
    after=function()
      vim.g["conjure#extract#tree_sitter#enabled"] = true
      vim.g["conjure#mapping#log_split"]="Ls"
      vim.g["conjure#mapping#log_vsplit"]="Lv"
      vim.g["conjure#mapping#log_tab"]="Lt"
      vim.g["conjure#mapping#log_buf"]="Lb"
      vim.g["conjure#mapping#log_toggle"]="Lg"
      vim.g["conjure#mapping#log_reset_soft"]="Lr"
      vim.g["conjure#mapping#log_reset_hard"]="LR"
      vim.g["conjure#mapping#log_jump_to_latest"]="Ll"
      vim.g["conjure#mapping#log_close_visible"]="Lq"
    end
  },
}
