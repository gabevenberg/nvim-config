--- Semantic line breaks for `gq`, in every filetype.
---
--- This is the only file in the module that touches `vim.`.
--- It scans a range into plain data:
--- the lines, the treesitter captures that matter and each language's `'comments'`.
--- It hands that to `sembr.core`, and writes back what comes out.
---
--- Options, with their defaults:
---
--- - `target = 80`: the column to aim for, overridden by a non-zero 'textwidth'
--- - `hard_max = 100`: the column never to break past when a break exists
--- - `preserve_semantic_breaks = true`: keep a break already on a boundary
--- - `delegate_to_lsp = true`:
---   hand a range with no prose to a range-formatting LSP
--- - `extra_abbreviations = {}`: more words whose period is not a stop
--- - `debug = false`: notify what each region resolved to
---
--- `require("sembr").setup({})` is optional.
local core = require("sembr.core")

local M = {}

M.defaults = {
  target = 80,
  hard_max = 100,
  preserve_semantic_breaks = true,
  delegate_to_lsp = true,
  extra_abbreviations = {},
  debug = false,
}

M.options = vim.deepcopy(M.defaults)

---@param opts table|nil
function M.setup(opts)
  -- `tbl_deep_extend` replaces a list whole,
  -- so a second `setup` can shorten `extra_abbreviations`
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

-- the tex filetypes have no parser of their own,
-- and nothing else registers them.
-- nvim picks plaintex for a .tex file with no \documentclass
vim.treesitter.language.register("latex", { "tex", "plaintex" })

-- what 'comments' holds for a filetype no ftplugin knows, which says nothing about the language
local DEFAULT_COMMENTS = vim.api.nvim_get_option_info2("comments", {}).default

---@param name string
---@return boolean
local function relevant(name)
  return name == "spell"
    or name == "nospell"
    or name == "comment"
    or name == "string.documentation"
    or name == "markup.math"
    or name:find("^markup%.heading") ~= nil
    or name:find("^markup%.raw") ~= nil
    or name:find("^markup%.link") ~= nil
end

--- The `'comments'` of an injected language, which has no buffer of its own to ask.
--- `get_filetypes` names the parser first and its filetypes after (`latex` before `tex`),
--- and `get_option` answers for any name at all, with the global default for one no ftplugin knows.
---@param lang string
---@param own string the buffer's value
---@return string
local function comments_for(lang, own)
  for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
    local ok, value = pcall(vim.filetype.get_option, ft, "comments")
    if ok and type(value) == "string" and value ~= DEFAULT_COMMENTS then
      return value
    end
  end
  return own
end

---@param buf integer
---@param srow integer
---@param erow integer
---@return sembr.Scan
local function scan(buf, srow, erow)
  local filetype = vim.bo[buf].filetype
  local captures = {}
  local trees = false
  local lang

  local parser = vim.treesitter.get_parser(buf, nil, { error = false })
  if parser then
    lang = parser:lang()
    -- a full parse per `gq` is the one cost here that is felt
    parser:parse({ srow, erow + 1 })
    parser:for_each_tree(function(tree, ltree)
      -- markdown holds an inline tree for every paragraph in the file
      local tsr, _, ter = tree:root():range()
      if ter < srow or tsr > erow then
        return
      end
      local query = vim.treesitter.query.get(ltree:lang(), "highlights")
      if not query then
        return
      end
      trees = true
      local depth = 0
      local parent = ltree:parent()
      while parent do
        depth = depth + 1
        parent = parent:parent()
      end
      for id, node in query:iter_captures(tree:root(), buf, srow, erow + 1) do
        local name = query.captures[id]
        if relevant(name) then
          local sr, sc, er, ec = node:range()
          captures[#captures + 1] =
            { name = name, lang = ltree:lang(), depth = depth, sr = sr, sc = sc, er = er, ec = ec }
        end
      end
    end)
  elseif filetype == "text" or filetype == "" then
    lang = "text"
  else
    lang = filetype
  end

  -- the range,
  -- and every row a prose capture reaches for the code and closer checks
  local lo, hi = srow, erow
  for _, c in ipairs(captures) do
    if c.name == "spell" or c.name == "comment" or c.name == "string.documentation" then
      local er = (c.ec == 0 and c.er > c.sr) and c.er - 1 or c.er
      lo = math.min(lo, c.sr)
      hi = math.max(hi, er)
    end
  end
  hi = math.min(hi, vim.api.nvim_buf_line_count(buf) - 1)
  local lines = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, lo, hi + 1, false)) do
    lines[lo + i - 1] = line
  end

  local own = vim.bo[buf].comments
  local comments = { [lang] = own }
  for _, c in ipairs(captures) do
    if not comments[c.lang] then
      comments[c.lang] = comments_for(c.lang, own)
    end
  end

  return {
    srow = srow,
    erow = erow,
    lines = lines,
    lang = lang,
    trees = trees,
    captures = captures,
    comments = comments,
  }
end

---@param buf integer
---@return sembr.Opts
local function resolve(buf)
  -- a buffer that opts into hard wrapping gets its breaks at its own width
  local textwidth = vim.bo[buf].textwidth
  local target = textwidth > 0 and textwidth or M.options.target
  local abbreviations = {}
  for _, word in ipairs(M.options.extra_abbreviations) do
    abbreviations[word:lower()] = true
  end
  return {
    target = target,
    hard_max = math.max(M.options.hard_max, target),
    preserve_semantic_breaks = M.options.preserve_semantic_breaks,
    abbreviations = abbreviations,
    tabstop = vim.bo[buf].tabstop,
  }
end

--- Writes the changed edits back to front,
--- so earlier rows stay valid, as one undo step.
---@param buf integer
---@param edits sembr.Edit[]
local function apply(buf, edits)
  local joined = false
  for i = #edits, 1, -1 do
    local edit = edits[i]
    if M.options.debug then
      vim.notify(
        ("sembr: ft=%s lang=%s rows=%d-%d prefix=%q lines=%d->%d"):format(
          vim.bo[buf].filetype,
          edit.lang,
          edit.lo,
          edit.hi,
          edit.prefix,
          edit.hi - edit.lo + 1,
          #edit.lines
        ),
        vim.log.levels.INFO
      )
    end
    if edit.changed then
      if joined then
        pcall(vim.cmd.undojoin)
      end
      vim.api.nvim_buf_set_lines(buf, edit.lo, edit.hi + 1, false, edit.lines)
      joined = true
    end
  end
end

--- A range with no prose in it.
---@param buf integer
---@param none "code"|"unknown"
---@return integer
local function no_prose(buf, none)
  if M.options.delegate_to_lsp then
    -- `vim.lsp.formatexpr` returns 0 unconditionally,
    -- so a server that cannot range-format would swallow the `gq` without this check
    local clients = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/rangeFormatting" })
    if #clients > 0 then
      return vim.lsp.formatexpr()
    end
  end
  -- the internal formatter would join code into one greedy line
  if none == "code" then
    return 0
  end
  return 1
end

---@return integer
local function format()
  -- auto-wrap at 'textwidth' comes through here too,
  -- and a line still being typed gets nvim's own wrapping
  local mode = vim.fn.mode(1):sub(1, 1)
  if mode == "i" or mode == "R" then
    return 1
  end

  local buf = vim.api.nvim_get_current_buf()
  local srow = vim.v.lnum - 1
  local erow = math.min(srow + math.max(vim.v.count, 1) - 1, vim.api.nvim_buf_line_count(buf) - 1)
  if erow < srow then
    return 1
  end

  -- every region is rendered before any is written,
  -- so a failure leaves the buffer untouched
  local result = core.format(scan(buf, srow, erow), resolve(buf))
  if result.none then
    return no_prose(buf, result.none)
  end
  apply(buf, result.edits)
  return 0
end

--- The `'formatexpr'`.
--- A failure inside degrades `gq` to the internal formatter.
---@return integer 0 when handled, 1 to hand the range to the internal formatter
function M.formatexpr()
  local ok, result = pcall(format)
  if not ok then
    if M.options.debug then
      vim.notify("sembr: " .. tostring(result), vim.log.levels.ERROR)
    end
    return 1
  end
  return result
end

return M
