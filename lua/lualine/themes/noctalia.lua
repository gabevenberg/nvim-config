-- lualine's auto theme reuses the active colours for inactive buffers,
-- so build one from the palette mini.base16 applied, shaped like lualine's gruvbox_dark
local p = MiniBase16.config.palette

local function mode(colour)
  return {
    a = { bg = colour, fg = p.base00, gui = "bold" },
    b = { bg = p.base02, fg = p.base05 },
    c = { bg = p.base01, fg = p.base04 },
  }
end

return {
  normal = mode(p.base04),
  insert = mode(p.base0D),
  visual = mode(p.base0A),
  replace = mode(p.base08),
  command = mode(p.base0B),
  inactive = {
    a = { bg = p.base01, fg = p.base04, gui = "bold" },
    b = { bg = p.base01, fg = p.base04 },
    c = { bg = p.base01, fg = p.base04 },
  },
}
