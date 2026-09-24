--- Finds the prose in a scanned range and reflows it, without asking the editor anything.
---
--- The scan is plain data, the lines and the treesitter captures that matter,
--- so every decision here runs under the plain luajit tests.
--- Prose rows come from the `@spell` captures,
--- the leaders of each row come from its language's `'comments'`,
--- and regions are cut from the rows.
local languages = require("sembr.languages")
local leaders = require("sembr.leaders")
local prose = require("sembr.prose")

local M = {}

---@class sembr.Capture
---@field name string   "spell", "nospell", "comment" or "string.documentation",
---                     or a "markup.heading*", "markup.raw*",
---                     "markup.link*" or "markup.math" name, without the "@"
---@field lang string   language of the tree it came from
---@field depth integer 0 for the buffer's own tree, +1 per injection level
---@field sr integer    start row, 0-based
---@field sc integer    start column, byte offset
---@field er integer    end row, 0-based
---@field ec integer    end column, byte offset, exclusive

---@class sembr.Scan
---@field srow integer                   first row of the range, 0-based
---@field erow integer                   last row, inclusive
---@field lines table<integer, string>   0-based row to line, for the range
---                                      and every row a prose capture reaches
---@field lang string                    the root parser's language,
---                                      else "text" or the filetype
---@field trees boolean                  a highlights query existed for some tree in range
---@field captures sembr.Capture[]
---@field comments table<string, string> lang to `'comments'`

---@class sembr.Opts
---@field target integer
---@field hard_max integer
---@field preserve_semantic_breaks boolean
---@field abbreviations table<string, boolean>
---@field tabstop integer

---@class sembr.Edit
---@field lo integer      first row, 0-based
---@field hi integer      last row, inclusive
---@field lines string[]
---@field lang string
---@field prefix string   the first line's prefix
---@field changed boolean

--- A copy of `capture` ending on the row it really ends on,
--- since a line comment's node runs to column 0 of the next row.
---@param capture sembr.Capture
---@param lines table<integer, string>
---@return sembr.Capture
local function normalized(capture, lines)
  local c = {
    name = capture.name,
    lang = capture.lang,
    depth = capture.depth,
    sr = capture.sr,
    sc = capture.sc,
    er = capture.er,
    ec = capture.ec,
  }
  if c.ec == 0 and c.er > c.sr then
    c.er = c.er - 1
    c.ec = #(lines[c.er] or "")
  end
  return c
end

local function at_or_before(ar, ac, br, bc)
  return ar < br or (ar == br and ac <= bc)
end

---@return boolean
local function contains(outer, inner)
  return at_or_before(outer.sr, outer.sc, inner.sr, inner.sc) and at_or_before(inner.er, inner.ec, outer.er, outer.ec)
end

--- The owner of a row two captures share: the host before an injection,
--- then by position, and fully determined, since `table.sort` is not stable.
local function precedes(a, b)
  for _, field in ipairs({ "depth", "sr", "sc", "er", "ec" }) do
    if a[field] ~= b[field] then
      return a[field] < b[field]
    end
  end
  return a.lang < b.lang
end

local function blank(s)
  return s == nil or s:find("^%s*$") ~= nil
end

--- A docstring as prose, with its quotes and continuation indent read off its own lines,
--- or nil when it is not prose.
--- One written on a single row stays there, since not every language's quote may hold a newline.
--- One that holds another language's prose leaves it to that language, as julia's markdown.
---@param docstring sembr.Capture
---@param lines table<integer, string>
---@param spells sembr.Capture[]
---@return sembr.Capture|nil
local function docstring_prose(docstring, lines, spells)
  if docstring.sr == docstring.er then
    return nil
  end
  for _, spell in ipairs(spells) do
    if spell.lang ~= docstring.lang and contains(docstring, spell) then
      return nil
    end
  end

  -- a prefix such as a raw string's `r`, then a triple quote or a single one
  local head = (lines[docstring.sr] or ""):sub(docstring.sc + 1)
  local prefix, mark = head:match("^(%a*)([\"'])")
  if not mark then
    return nil
  end
  local quote = head:sub(#prefix + 1, #prefix + 3) == mark:rep(3) and mark:rep(3) or mark
  local tail = (lines[docstring.er] or ""):sub(1, docstring.ec)
  if tail:sub(-#quote) ~= quote then
    return nil
  end

  -- the indent the docstring's own continuations already have, else its closer's, else its opener's
  local indent = nil
  for row = docstring.sr + 1, docstring.er do
    local line = lines[row] or ""
    local text = line:match("^%s*(.-)%s*$")
    if text ~= "" and (text ~= quote or row ~= docstring.er) then
      indent = line:match("^%s*")
      break
    end
  end
  indent = indent or (lines[docstring.er] or ""):match("^%s*")

  return {
    lang = docstring.lang,
    depth = docstring.depth,
    sr = docstring.sr,
    sc = docstring.sc,
    er = docstring.er,
    ec = docstring.ec,
    kind = "docstring",
    form = { start = prefix .. quote, stop = quote, offset = 0 },
    indent = indent,
  }
end

--- Rows `srow..erow` that hold prose, each mapped to the capture that owns it.
---@param scan sembr.Scan
---@param rules fun(lang: string): sembr.Rules
---@return table<integer, { lang: string }>
local function prose_rows(scan, rules)
  local lines = scan.lines
  if scan.lang == "text" and not scan.trees then
    local owners = {}
    for row = scan.srow, scan.erow do
      if not blank(lines[row]) then
        owners[row] = { lang = "text", kind = "document", depth = 0, sr = row, sc = 0, er = row, ec = 0 }
      end
    end
    return owners
  end

  local spells, comments, docstrings, excluders = {}, {}, {}, {}
  for _, capture in ipairs(scan.captures) do
    local c = normalized(capture, lines)
    if c.name == "spell" then
      spells[#spells + 1] = c
    elseif c.name == "comment" then
      comments[#comments + 1] = c
    elseif c.name == "string.documentation" then
      docstrings[#docstrings + 1] = c
    end
    -- a heading is structure however long it runs,
    -- and `@nospell` over a whole `@spell` is what the grammar means by it
    if c.name == "nospell" or c.name:find("^markup%.heading") then
      excluders[#excluders + 1] = c
    end
  end

  local function excluded(spell)
    for _, c in ipairs(excluders) do
      if contains(c, spell) then
        return true
      end
    end
    return false
  end

  --- The first of `list` in the language of `spell` that holds it.
  local function holder(list, spell)
    for _, c in ipairs(list) do
      if c.lang == spell.lang and contains(c, spell) then
        return c
      end
    end
    return nil
  end

  --- True when `c` has nothing but blanks before it and after it on its own rows.
  local function alone(c)
    return blank((lines[c.sr] or ""):sub(1, c.sc)) and blank((lines[c.er] or ""):sub(c.ec + 1))
  end

  local candidates = {}
  for _, spell in ipairs(spells) do
    local comment = holder(comments, spell)
    if excluded(spell) or holder(docstrings, spell) then
      -- a docstring's own `@spell` is prose through the docstring below
      spell.kind = nil
    elseif comment then
      -- a comment with code before or after it is left alone
      spell.kind = alone(spell) and "comment" or nil
    elseif rules(spell.lang).document then
      spell.kind = "document"
    end
    if spell.kind then
      candidates[#candidates + 1] = spell
    end
  end
  for _, docstring in ipairs(docstrings) do
    local prose = docstring_prose(docstring, lines, spells)
    if prose and alone(docstring) then
      candidates[#candidates + 1] = prose
    end
  end

  local owners = {}
  for _, capture in ipairs(candidates) do
    for row = math.max(capture.sr, scan.srow), math.min(capture.er, scan.erow) do
      if not owners[row] or precedes(capture, owners[row]) then
        owners[row] = capture
      end
    end
  end

  -- a comment that is not prose itself takes out every row it wholly covers,
  -- a gitcommit `#` line inside the body's `@spell`
  for _, c in ipairs(comments) do
    local prose_comment = false
    for _, spell in ipairs(spells) do
      if spell.lang == c.lang and contains(spell, c) and contains(c, spell) then
        prose_comment = true
        break
      end
    end
    if not prose_comment then
      for row = math.max(c.sr, scan.srow), math.min(c.er, scan.erow) do
        local line = lines[row] or ""
        local from = line:find("%S") or 1
        local to = line:find("%S%s*$") or 0
        if at_or_before(c.sr, c.sc, row, from - 1) and at_or_before(row, to, c.er, c.ec) then
          owners[row] = nil
        end
      end
    end
  end
  return owners
end

--- The captures no break may land inside: code, links, math,
--- and a `@nospell` that covers only part of the prose.
---@param scan sembr.Scan
---@return sembr.Span[]
local function protected_spans(scan)
  local spans = {}
  for _, capture in ipairs(scan.captures) do
    local name = capture.name
    if name == "nospell" or name == "markup.math" or name:find("^markup%.raw") or name:find("^markup%.link") then
      spans[#spans + 1] = normalized(capture, scan.lines)
    end
  end
  return spans
end

---@class sembr.Region
---@field lo integer
---@field hi integer
---@field lang string
---@field rules sembr.Rules
---@field key string
---@field rows (sembr.Row|sembr.Leaders)[]

--- Cuts the prose rows into regions.
--- A new one starts at every item, wherever the language or the repeating leaders change,
--- and at a row whose text is not at the region's text column.
--- An item's continuation may sit left of its text column, where it comes back aligned,
--- unless a blank row comes between them,
--- but a row further right is an indented block, a table or code,
--- and keeps its layout.
---@param scan sembr.Scan
---@param owners table<integer, { lang: string }>
---@param rules fun(lang: string): sembr.Rules
---@param tabstop integer
---@return sembr.Region[]
local function cut(scan, owners, rules, tabstop)
  local regions = {}
  local region = nil
  for row = scan.srow, scan.erow do
    local owner = owners[row]
    if not owner then
      region = nil
    else
      local line = scan.lines[row]
      local place = nil
      if owner.kind ~= "document" then
        place = { first = row == owner.sr, last = row == owner.er, form = owner.form, indent = owner.indent }
      end
      local info = leaders.parse(line, rules(owner.lang), place)
      info.row = row
      info.line = line
      local col = info.kind ~= "blank" and prose.width(line:sub(1, info.body_col - 1), tabstop) or nil
      local misplaced = col
        and region
        and region.col
        and (
          region.item and not region.blank and col > region.col
          or (not region.item or region.blank) and col ~= region.col
        )
      -- a closer belongs to the block it closes, whatever its leaders
      local closes = info.kind == "closer" and region and region.lang == owner.lang and not region.closed
      if
        not closes
        and (
          not region
          or region.closed
          or region.lang ~= owner.lang
          or info.kind == "item"
          or info.kind == "opener"
          or info.key ~= region.key
          or misplaced
        )
      then
        region = {
          lo = row,
          lang = owner.lang,
          depth = owner.depth,
          docstring = owner.kind == "docstring",
          rules = rules(owner.lang),
          key = info.key,
          rows = {},
        }
        regions[#regions + 1] = region
      end
      if col and not region.col then
        -- the column every continuation sits at, past an opener's decoration or an item's marker
        region.col = prose.width(info.rest, tabstop)
        region.item = info.kind == "item"
      end
      region.closed = info.stop_at ~= nil
      -- a lazy continuation never reaches an item across a blank row
      region.blank = region.blank or info.kind == "blank"
      region.rows[#region.rows + 1] = info
      region.hi = row
    end
  end
  return regions
end

---@param a string[]
---@param b string[]
---@return boolean
local function same_text(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i]:gsub("%s+$", "") ~= b[i]:gsub("%s+$", "") then
      return false
    end
  end
  return true
end

---@param region sembr.Region
---@param spans sembr.Span[]
---@param opts sembr.Opts
---@return sembr.Edit
local function render(region, spans, opts)
  local original = {}
  for i, row in ipairs(region.rows) do
    original[i] = row.line
  end

  -- the closer is lifted off the prose and put back after it
  local rows = { unpack(region.rows) }
  local last = rows[#rows]
  local stop, verbatim = nil, nil
  if last.stop_at then
    rows[#rows] = nil
    local body = last.line:sub(1, last.stop_at - 1):gsub("%s+$", "")
    if #body >= last.body_col then
      local lifted = setmetatable({ line = body }, { __index = last })
      rows[#rows + 1] = lifted
      stop = last.line:sub(last.stop_at):gsub("%s+$", "")
    else
      -- a closer alone on its row stays as it was written
      verbatim = last.line
    end
  end

  local head = nil
  for _, row in ipairs(rows) do
    if row.kind ~= "blank" then
      head = row
      break
    end
  end

  -- a span from a shallower tree holds the prose rather than sitting in it,
  -- as a fence holds the comments of the code in it
  local protected = {}
  for _, span in ipairs(spans) do
    if span.depth >= region.depth and span.er >= region.lo and span.sr <= region.hi then
      protected[#protected + 1] = span
    end
  end

  local out = {}
  if head then
    local prefix = { first = head.first, rest = head.rest }
    out = prose.reflow(rows, prefix, region.rules, protected, opts)
  else
    for i, row in ipairs(rows) do
      out[i] = row.line
    end
  end
  if verbatim then
    out[#out + 1] = verbatim
  elseif stop then
    if region.docstring or (#original == 1 and #out == 1) then
      -- a docstring's closer stays where it was written, since moving it changes the string,
      -- and a comment written on one line that still fits on one keeps its closer there
      out[#out] = out[#out] .. last.gap .. stop
    else
      local indent = head.first:match("^%s*")
      if head.kind == "opener" then
        indent = indent .. string.rep(" ", head.form.offset)
      end
      out[#out + 1] = indent .. stop
    end
  end
  -- a region that only differs in trailing blanks is already right,
  -- and comes back byte for byte
  if same_text(out, original) then
    out = original
  end
  return {
    lo = region.lo,
    hi = region.hi,
    lines = out,
    lang = region.lang,
    prefix = head and head.first or "",
    changed = out ~= original,
  }
end

--- The reflowed regions of the scanned range, or why there are none.
---@param scan sembr.Scan
---@param opts sembr.Opts
---@return { edits: sembr.Edit[] }|{ none: "code"|"unknown" }
function M.format(scan, opts)
  local function rules(lang)
    return languages.rules(lang, scan.comments[lang] or scan.comments[scan.lang] or "")
  end
  local owners = prose_rows(scan, rules)
  if next(owners) == nil then
    return { none = scan.trees and "code" or "unknown" }
  end
  local spans = protected_spans(scan)
  local edits = {}
  for _, region in ipairs(cut(scan, owners, rules, opts.tabstop)) do
    edits[#edits + 1] = render(region, spans, opts)
  end
  return { edits = edits }
end

return M
