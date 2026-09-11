local M = {}

-- a comma only earns a break if the clause before it is substantial,
-- otherwise "Rust, Go, and Zig" becomes three lines.
M.min_clause = 32

-- periods that end an abbreviation are not sentence ends.
local abbrev = {
  ["e.g."] = true,
  ["i.e."] = true,
  ["etc."] = true,
  ["vs."] = true,
  ["approx."] = true,
  ["Mr."] = true,
  ["Mrs."] = true,
  ["Dr."] = true,
  ["St."] = true,
  ["Fig."] = true,
  ["No."] = true,
  ["cf."] = true,
}

local function ends_sentence(buf)
  local last = buf:match("(%S+)%s*$") or ""
  if abbrev[last:lower()] then
    return false
  end
  -- single letter or digit before the dot: initials, version numbers
  if last:match("^%a%.$") or last:match("%d%.$") then
    return false
  end
  return true
end

function M.split(text)
  local out, buf = {}, ""
  local i = 1
  while i <= #text do
    local c = text:sub(i, i)
    buf = buf .. c
    local nxt = text:sub(i + 1, i + 1)
    if nxt == " " or nxt == "" then
      local brk = false
      if c:match("[.!?]") then
        brk = ends_sentence(buf)
      elseif c == ";" or c == ":" then
        brk = true
      elseif c == "," then
        brk = #vim.trim(buf) >= M.min_clause
      end
      if brk and vim.trim(buf) ~= "" then
        table.insert(out, vim.trim(buf))
        buf = ""
        i = i + 1
      end
    end
    i = i + 1
  end
  if vim.trim(buf) ~= "" then
    table.insert(out, vim.trim(buf))
  end
  return out
end

function M.formatexpr()
  -- let neovim handle auto-wrap while typing; this is for explicit gq only.
  -- if vim.v.char ~= "" then
  --   return 1
  -- end
  local first = vim.v.lnum
  local last = first + vim.v.count - 1
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  if #lines == 0 then
    return 0
  end

  -- keep the first line's indent and any list marker or comment leader.
  local prefix = lines[1]:match("^(%s*[%*%-%+>]?%s*)") or ""
  local joined = table.concat(vim.tbl_map(vim.trim, lines), " "):gsub("%s+", " ")
  local split = M.split(vim.trim(joined))

  local outlines = {}
  for n, l in ipairs(split) do
    table.insert(outlines, (n == 1 and prefix or (" "):rep(#prefix)) .. l)
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, outlines)
  return 0
end

return M
