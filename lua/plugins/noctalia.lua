-- noctalia renders its palette as a base16 table into this file, and signals SIGUSR1 when it changes
local noctaliaPalette = (os.getenv("XDG_CACHE_HOME") or vim.fn.expand("~/.cache")) .. "/noctalia/nvim.lua"

local function loadNoctalia()
  local ok, palette = pcall(dofile, noctaliaPalette)
  local valid = ok and type(palette) == "table"
  if valid then
    for i = 0, 15 do
      local key = string.format("base%02X", i)
      if type(palette[key]) ~= "string" or not palette[key]:match("^#%x%x%x%x%x%x$") then
        valid = false
        break
      end
    end
  end

  if not valid then
    vim.cmd.colorscheme("gruvbox")
    return
  end

  require("mini.base16").setup({ palette = palette })
  -- mini.base16 leaves :terminal on its default ANSI colours
  local ansi = { "00", "08", "0B", "0A", "0D", "0E", "0C", "05", "03", "08", "0B", "0A", "0D", "0E", "0C", "07" }
  for i, base in ipairs(ansi) do
    vim.g["terminal_color_" .. (i - 1)] = palette["base" .. base]
  end
  vim.g.colors_name = "noctalia"
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "noctalia" })
end

loadNoctalia()
vim.api.nvim_create_autocmd("Signal", {
  group = vim.api.nvim_create_augroup("noctalia", { clear = true }),
  pattern = "SIGUSR1",
  callback = loadNoctalia,
})
