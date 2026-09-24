--- The leaders at the front of one row:
--- indent, comment leaders, quotes, a list marker.
---
--- They are consumed left to right,
--- with any whitespace between two of them kept as part of the prefix,
--- so `  - `, `>   - ` and `--   - ` are all an item at depth.
local M = {}

---@class sembr.Leaders
---@field first string    what this row starts with
---@field rest string     what a continuation of it starts with
---@field body_col integer 1-based byte where the text starts
---@field key string      the repeating leaders, trimmed and joined with `|`
---@field kind "text"|"blank"|"item"|"opener"|"closer"
---@field form sembr.BlockForm|nil the block this row opens or closes
---@field stop_at integer|nil      1-based byte where the closer starts
---@field gap string|nil           the blanks before the closer

--- True when byte `at` of `s` is a blank or past the end.
local function blank_at(s, at)
  return at > #s or s:find("^%s", at) ~= nil
end

--- The repeating leader of `leaders` starting at `at`, honouring `b`.
---@param s string
---@param at integer
---@param leaders sembr.Leader[]
---@return sembr.Leader|nil
local function leader_at(s, at, leaders)
  for _, leader in ipairs(leaders) do
    if s:sub(at, at + #leader.text - 1) == leader.text and (not leader.blank or blank_at(s, at + #leader.text)) then
      return leader
    end
  end
  return nil
end

--- The last byte of the item marker starting at `at`,
--- which needs a blank or the end of the line after it,
--- or `at - 1` for a tag, which consumes nothing.
---@param s string
---@param at integer
---@param rules sembr.Rules
---@param list_only boolean|nil only the markers a list is made of
---@return integer|nil stop, sembr.Item|nil item
local function item_at(s, at, rules, list_only)
  for _, item in ipairs(rules.items) do
    if item.list or not list_only then
      local stop
      if item.text then
        if s:sub(at, at + #item.text - 1) == item.text then
          stop = at + #item.text - 1
        end
      elseif item.ordered then
        local digits = s:match("^%d+[%.%)]", at)
        stop = digits and at + #digits - 1
      elseif item.tag and s:find("^@[%w_]", at) then
        return at - 1, item
      end
      if stop and blank_at(s, stop + 1) then
        return stop, item
      end
    end
  end
  return nil
end

--- True when a line starting at byte `at` of `s` would be read as opening a unit or carrying a leader.
--- No break may leave such a line,
--- and the joiner never joins one onto the line before it.
---@param s string
---@param at integer
---@param rules sembr.Rules
---@return boolean
function M.opens(s, at, rules)
  return item_at(s, at, rules) ~= nil or leader_at(s, at, rules.leaders) ~= nil
end

--- Every character but a tab as a space,
--- so a continuation lines up under text that followed a marker.
local function blank_out(s)
  return (s:gsub("[\128-\191]", ""):gsub("[^\t]", " "))
end

--- The opener of one of `forms` at `at`, with any decoration it carries,
--- which is never allowed to swallow the closer of a one-line comment.
---@param s string
---@param at integer
---@param forms sembr.BlockForm[]
---@return string|nil opener, sembr.BlockForm|nil form
local function opener_at(s, at, forms)
  for _, form in ipairs(forms) do
    if s:sub(at, at + #form.start - 1) == form.start then
      local stop = at + #form.start - 1
      if form.decorated then
        local decoration = s:match("^%p*", stop + 1)
        local cut = decoration:find(form.stop, 1, true)
        if cut then
          decoration = decoration:sub(1, cut - 1)
        end
        stop = stop + #decoration
      end
      return s:sub(at, stop), form
    end
  end
  return nil
end

--- Where a row sits in a comment or docstring:
--- only its first row can open the block, and only its last row can close it.
---@class sembr.Place
---@field first boolean
---@field last boolean
---@field form sembr.BlockForm|nil a docstring's own quotes, in place of the comment forms
---@field indent string|nil        a docstring's continuation indent, as its lines already have it

---@param line string
---@param rules sembr.Rules
---@param place sembr.Place|nil nil outside a comment or docstring
---@return sembr.Leaders
function M.parse(line, rules, place)
  local indent = line:match("^%s*")
  local first, rest, key = { indent }, { indent }, {}
  local at = #indent + 1
  local item = false
  local opener, form = nil, nil
  local forms = place and (place.form and { place.form } or rules.blocks) or {}
  if place and place.first then
    opener, form = opener_at(line, at, forms)
  end
  if opener then
    local space = line:sub(at + #opener, at + #opener) == " " and " " or ""
    first[#first + 1] = opener .. space
    rest[#rest + 1] = string.rep(" ", form.offset) .. (form.middle and form.middle .. " " or "")
    if place.indent then
      rest = { place.indent }
    end
    key[#key + 1] = form.middle and (form.middle:gsub("^%s+", ""):gsub("%s+$", "")) or nil
    at = at + #opener + #space
  end
  -- a docstring is a string, and nothing in it is a comment leader
  local repeating = rules.leaders
  if place then
    repeating = place.form and {} or rules.gutters
  end
  while not opener do
    local gap = line:match("^%s*", at)
    local from = at + #gap
    local leader = leader_at(line, from, repeating)
    if leader then
      local stop = from + #leader.text
      -- one optional space after a repeating leader, the rest is indent
      local space = line:sub(stop, stop) == " " and " " or ""
      local piece = gap .. leader.text .. space
      first[#first + 1] = piece
      rest[#rest + 1] = piece
      key[#key + 1] = (leader.text:gsub("^%s+", ""):gsub("%s+$", ""))
      at = stop + #space
    else
      local stop, found = item_at(line, from, rules, true)
      if found then
        local piece = line:sub(from, stop) .. line:match("^%s*", stop + 1)
        first[#first + 1] = gap .. piece
        rest[#rest + 1] = gap .. blank_out(piece)
        at = from + #piece
        item = true
      end
      break
    end
  end
  if not item and not opener then
    local gap = line:match("^%s*", at)
    first[#first + 1] = gap
    rest[#rest + 1] = gap
    at = at + #gap
  end
  key = table.concat(key, "|")

  -- the closer, on a row whose only leaders are a gutter,
  -- so a line comment that happens to end in `*/` keeps it
  local stop_at, gap = nil, nil
  if place and place.last then
    local body = line:gsub("%s+$", "")
    for _, candidate in ipairs(forms) do
      local stop = candidate.stop
      local gutter = candidate.middle and (candidate.middle:gsub("^%s+", ""):gsub("%s+$", ""))
      local from = #body - #stop + 1
      if (key == "" or key == gutter) and from >= at and body:sub(from) == stop then
        gap = body:sub(1, from - 1):match("%s*$")
        stop_at = from
        form = form or candidate
        break
      end
    end
  end

  local kind = "text"
  if opener then
    kind = "opener"
  elseif stop_at then
    kind = "closer"
  elseif item or M.opens(line, at, rules) then
    kind = "item"
  elseif at > #line then
    kind = "blank"
  end
  return {
    first = table.concat(first),
    rest = table.concat(rest),
    body_col = at,
    key = key,
    kind = kind,
    form = form,
    stop_at = stop_at,
    gap = gap,
  }
end

return M
