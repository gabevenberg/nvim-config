--- Parses vim's `'comments'` option, the one vim's own `J` and `gq` take leaders from.
---
--- The option is a comma separated list of `{flags}:{leader}` items.
--- `\,` is a literal comma, and a leader may contain spaces.
--- The flags that shape a reflowed line:
---
--- - `s`, `m`, `e`: the start, middle and end of a block comment,
---   with an optional signed column offset for the middle after `s` or `m`
--- - `O`: a group that is not the block comment itself, C's `sO:* -` list form
--- - `f`: first line only, which is how a list marker is spelled
--- - `n`: nestable, which is how a quote is spelled
--- - `b`: a blank has to follow, so `#hashtag` is not a `#` comment
---
--- `l`, `r` and `x` only matter to vim's own insertion, and are skipped.
local M = {}

---@class sembr.Block
---@field start string   the opener, `/*`
---@field middle string  the gutter repeated on every continuation, `*`
---@field stop string    the closer, `*/`
---@field offset integer columns the gutter sits right of the opener

---@class sembr.Comments
---@field line string[]                 whole line leaders, longest first
---@field quote string[]                nestable leaders, longest first
---@field items string[]                first line only leaders, longest first
---@field blank table<string, boolean>  leaders that need a blank after them
---@field block sembr.Block|nil

---@param value string
---@return string[]
local function split_items(value)
  local items = {}
  -- escaped commas are parked on a byte no option value holds
  for item in (value:gsub("\\,", "\1") .. ","):gmatch("([^,]*),") do
    items[#items + 1] = (item:gsub("\1", ","))
  end
  return items
end

--- Longest first, so `///` is tried before `//`, and ties in the order written.
---@param leaders string[]
local function by_length(leaders)
  local order = {}
  for i, leader in ipairs(leaders) do
    order[leader] = order[leader] or i
  end
  table.sort(leaders, function(a, b)
    if #a ~= #b then
      return #a > #b
    end
    return order[a] < order[b]
  end)
end

-- one entry per distinct value a session formats, about one per filetype
local cache = {}

--- The result is shared by every caller with the same value,
--- so it must not be mutated.
---@param value string
---@return sembr.Comments
function M.parse(value)
  if cache[value] then
    return cache[value]
  end
  local parsed = { line = {}, quote = {}, items = {}, blank = {} }
  local groups, group = {}, nil
  for _, item in ipairs(split_items(value)) do
    -- a malformed item is dropped rather than guessed at,
    -- since its leader would be written into the buffer
    local flags, leader = item:match("^([nbfsmexOlr%d%-]*):(.+)$")
    if flags then
      if flags:find("b", 1, true) then
        parsed.blank[leader] = true
      end
      local offset = tonumber(flags:match("[sm](%-?%d+)") or "")
      if flags:find("s", 1, true) then
        group = { start = leader, offset = offset or 0, opener = not flags:find("O", 1, true) }
        groups[#groups + 1] = group
      elseif flags:find("m", 1, true) then
        if group then
          group.middle = leader
          group.offset = offset or group.offset
        end
      elseif flags:find("e", 1, true) then
        if group then
          group.stop = leader
        end
        group = nil
      elseif flags:find("f", 1, true) then
        parsed.items[#parsed.items + 1] = leader
      elseif flags:find("n", 1, true) then
        parsed.quote[#parsed.quote + 1] = leader
      else
        parsed.line[#parsed.line + 1] = leader
      end
    end
  end

  for _, candidate in ipairs(groups) do
    if candidate.opener and candidate.middle and candidate.stop then
      parsed.block = {
        start = candidate.start,
        middle = candidate.middle,
        stop = candidate.stop,
        offset = candidate.offset,
      }
      break
    end
  end

  by_length(parsed.line)
  by_length(parsed.quote)
  by_length(parsed.items)
  cache[value] = parsed
  return parsed
end

return M
