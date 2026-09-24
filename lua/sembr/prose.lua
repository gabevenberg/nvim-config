--- Joining a region's rows into logical lines,
--- and splitting them at semantic breaks.
---
--- Joining heals a hard wrap, a break that landed wherever the column ran out.
--- Splitting breaks after every sentence, then at clause boundaries until the line fits.
--- A break already on a boundary survives both, because the joiner keeps it.
local leaders = require("sembr.leaders")

local M = {}

---@param words string[]
---@return table<string, boolean>
local function set(words)
  local t = {}
  for _, word in ipairs(words) do
    t[word] = true
  end
  return t
end

-- words whose period ends an abbreviation, without the final period
local ABBREVIATIONS = set({
  -- titles
  "mr",
  "mrs",
  "ms",
  "dr",
  "prof",
  "rev",
  "hon",
  "sr",
  "jr",
  "capt",
  "col",
  "gen",
  "lt",
  "sgt",
  -- latin
  "e.g",
  "i.e",
  "etc",
  "cf",
  "viz",
  "vs",
  "al",
  "ibid",
  -- months and days
  "jan",
  "feb",
  "mar",
  "apr",
  "jun",
  "jul",
  "aug",
  "sep",
  "sept",
  "oct",
  "nov",
  "dec",
  "mon",
  "tue",
  "tues",
  "wed",
  "thu",
  "thur",
  "thurs",
  "fri",
  "sat",
  "sun",
  -- organisations
  "inc",
  "ltd",
  "corp",
  "co",
  "dept",
  "univ",
  "assn",
  "bros",
  -- addresses
  "ave",
  "blvd",
  "rd",
  "st",
  "mt",
  "ft",
})

-- reference forms, an abbreviation only before a number: `see no. 5`,
-- but `the answer is no.`
local NUMBERED = set({
  "fig",
  "figs",
  "eq",
  "eqs",
  "no",
  "nos",
  "vol",
  "vols",
  "p",
  "pp",
  "ch",
  "sec",
  "sect",
  "app",
  "ref",
  "refs",
})

-- what turns a comma into a clause boundary
local CONJUNCTIONS = set({ "for", "and", "nor", "but", "or", "yet", "so" })

local DASHES = { "-", "\u{2013}", "\u{2014}" }

-- closing brackets and quotes, which may follow the punctuation ending a sentence or clause
local CLOSERS = "[%)%]}\"'\u{bb}\u{201d}\u{2019}]*"

-- the rank of a bare comma, a last resort
local COMMA = 4

local URL = "%a[%w+.-]*://%S+"

local function rtrim(s)
  return (s:gsub("%s+$", ""))
end

--- Columns `s` takes, one per character, with a tab advancing to the next multiple of `tabstop`.
---@param s string
---@param tabstop integer
---@return integer
function M.width(s, tabstop)
  local col = 0
  -- every UTF-8 continuation byte is in 0x80..0xBF, the rest start a character
  for c in s:gmatch("[^\128-\191]") do
    if c == "\t" then
      col = col + tabstop - col % tabstop
    else
      col = col + 1
    end
  end
  return col
end

--- True when a break after `text` reads as one the author made:
--- a sentence or clause mark with any closers after it,
--- or a dash, spaced or not,
--- since joining `well-` or `word—` would put a space in the word.
---@param text string
---@return boolean
local function ends_at_boundary(text)
  if text:find("[%.!%?;:,]" .. CLOSERS .. "$") then
    return true
  end
  for _, dash in ipairs(DASHES) do
    if text:sub(-#dash) == dash then
      return true
    end
  end
  return false
end

--- True when the period at `at` closes an abbreviation, an initial, a number or an ellipsis.
---@param text string
---@param at integer
---@param extra table<string, boolean>
---@return boolean
local function false_stop(text, at, extra)
  if text:sub(at, at) ~= "." then
    return false
  end
  local before = text:sub(at - 1, at - 1)
  if before == "." or before:match("%d") then
    return true
  end
  -- walked back from the stop,
  -- since matching everything before it is quadratic in the length of the paragraph
  local from = at
  while from > 1 and text:find("^[%a%.]", from - 1) do
    from = from - 1
  end
  if from == at then
    return false
  end
  local word = text:sub(from, at - 1)
  if #word == 1 and word:match("%u") then
    return true
  end
  local lower = word:lower()
  if NUMBERED[lower] then
    return text:find("^%s*%d", at + 1) ~= nil
  end
  return ABBREVIATIONS[lower] or extra[lower] or false
end

--- The byte each sentence of `text` ends on, the last one excepted.
---@param text string
---@param extra table<string, boolean>
---@return integer[]
local function sentences(text, extra)
  local ends = {}
  local last = text:find("%S%s*$") or 0
  local i = 1
  while true do
    local start, stop = text:find("[%.!%?]" .. CLOSERS, i)
    if not start then
      break
    end
    i = stop + 1
    if stop < last and text:find("^%s", stop + 1) and not false_stop(text, start, extra) then
      ends[#ends + 1] = stop
    end
  end
  return ends
end

--- Clause boundaries in `line`, each the byte a break goes after,
--- the width of the line it leaves behind, and its rank:
---
--- 1. `;` or `:` before whitespace
--- 2. a spaced dash
--- 3. `,` before a coordinating conjunction
--- 4. a bare `,`
---@param line string
---@param tabstop integer
---@return { pos: integer, col: integer, rank: integer }[]
local function clauses(line, tabstop)
  local found = {}
  for pos in line:gmatch("()[;:]%s") do
    found[#found + 1] = { pos = pos, rank = 1 }
  end
  for _, dash in ipairs(DASHES) do
    local at = 1
    while true do
      local from, to = line:find(" " .. dash .. " ", at, true)
      if not from then
        break
      end
      found[#found + 1] = { pos = to - 1, rank = 2 }
      at = to
    end
  end
  for pos, word in line:gmatch("(),%s+(%a*)") do
    found[#found + 1] = { pos = pos, rank = CONJUNCTIONS[word:lower()] and 3 or COMMA }
  end
  table.sort(found, function(a, b)
    return a.pos < b.pos
  end)
  local last = line:find("%S%s*$") or 0
  local out = {}
  for _, candidate in ipairs(found) do
    if candidate.pos < last then
      candidate.col = M.width(line:sub(1, candidate.pos), tabstop)
      out[#out + 1] = candidate
    end
  end
  return out
end

--- Latest candidate within `target`, else earliest within `hard_max`, else nil.
local function pick(candidates, target, hard_max)
  for i = #candidates, 1, -1 do
    if candidates[i].col <= target then
      return candidates[i]
    end
  end
  for _, candidate in ipairs(candidates) do
    if candidate.col <= hard_max then
      return candidate
    end
  end
  return nil
end

--- Byte ranges of `text` that regexes protect: bare URLs,
--- and code spans where no grammar marks them.
--- `to` is the range's last byte.
---@param text string
---@param code_spans boolean
---@return { from: integer, to: integer }[]
local function matched(text, code_spans)
  local ranges = {}
  local at = 1
  while true do
    local from, to = text:find(URL, at)
    if not from then
      break
    end
    ranges[#ranges + 1] = { from = from, to = to }
    at = to + 1
  end
  if code_spans then
    at = 1
    while true do
      local from, to = text:find("`+", at)
      if not from then
        break
      end
      -- a span closes on a run of exactly as many backticks as opened it
      local fence = text:sub(from, to)
      local close = to + 1
      local closed = nil
      while true do
        local s, e = text:find("`+", close)
        if not s then
          break
        end
        if e - s == #fence - 1 then
          closed = e
          break
        end
        close = e + 1
      end
      if closed then
        ranges[#ranges + 1] = { from = from, to = closed }
        at = closed + 1
      else
        at = to + 1
      end
    end
  end
  return ranges
end

--- Where buffer position `(row, col)` falls in a logical line, clamped to it.
local function locate(segments, length, row, col)
  local first, last = segments[1], segments[#segments]
  if row < first.row or (row == first.row and col <= first.col) then
    return 0
  end
  if row > last.row or (row == last.row and col >= last.col + last.len) then
    return length
  end
  for _, segment in ipairs(segments) do
    if segment.row == row then
      return segment.at + math.max(0, math.min(segment.len, col - segment.col))
    end
  end
  return length
end

--- Sorted, and merged where they touch or overlap.
local function merge(ranges)
  table.sort(ranges, function(a, b)
    return a.from < b.from
  end)
  local out = {}
  for _, range in ipairs(ranges) do
    local last = out[#out]
    if last and range.from <= last.to + 1 then
      last.to = math.max(last.to, range.to)
    else
      out[#out + 1] = { from = range.from, to = range.to }
    end
  end
  return out
end

--- True when a break after byte `pos` falls inside a protected range.
local function inside(ranges, pos)
  for _, range in ipairs(ranges) do
    if range.from <= pos and pos < range.to then
      return true
    end
  end
  return false
end

---@class sembr.Row
---@field row integer      0-based buffer row
---@field line string
---@field body_col integer 1-based byte where the text starts

---@class sembr.Span
---@field sr integer
---@field sc integer
---@field er integer
---@field ec integer

--- The rows of one region, reflowed.
---@param rows sembr.Row[]
---@param prefix { first: string, rest: string }
---@param rules sembr.Rules
---@param protected sembr.Span[] buffer ranges no break may land inside
---@param opts sembr.Opts
---@return string[]
function M.reflow(rows, prefix, rules, protected, opts)
  local preserve = opts.preserve_semantic_breaks

  -- join, keeping for each piece where it came from in the buffer
  local logical = {}
  local current, previous = nil, nil
  for _, row in ipairs(rows) do
    local body = row.line:sub(row.body_col)
    local marker = nil
    for _, pattern in ipairs(rules.hard_breaks) do
      local text, found = body:match(pattern)
      if text then
        body, marker = text, found
        break
      end
    end
    body = rtrim(body)
    if body == "" then
      logical[#logical + 1] = { blank = true, marker = marker }
      current = nil
    else
      local joins = current ~= nil
        and current.marker == nil
        and not leaders.opens(body, 1, rules)
        and (not preserve or not ends_at_boundary(previous))
      local segment = { row = row.row, col = row.body_col - 1, len = #body }
      if joins then
        segment.at = #current.text + 1
        current.text = current.text .. " " .. body
        current.segments[#current.segments + 1] = segment
        current.marker = marker
      else
        segment.at = 0
        current = { text = body, segments = { segment }, marker = marker }
        logical[#logical + 1] = current
      end
    end
    previous = body
  end

  local out = {}
  local function budget(limit)
    return limit - M.width(#out == 0 and prefix.first or prefix.rest, opts.tabstop)
  end

  for _, line in ipairs(logical) do
    if line.blank then
      out[#out + 1] = line.marker or ""
    else
      local text = line.text
      local ranges = matched(text, rules.code_spans == "regex")
      for _, span in ipairs(protected) do
        local from = locate(line.segments, #text, span.sr, span.sc)
        local to = locate(line.segments, #text, span.er, span.ec)
        if from < to then
          ranges[#ranges + 1] = { from = from + 1, to = to }
        end
      end
      ranges = merge(ranges)

      --- True when a break after byte `pos` may be made.
      local function legal(pos)
        if inside(ranges, pos) then
          return false
        end
        local next = text:find("%S", pos + 1)
        return next == nil or not leaders.opens(text, next, rules)
      end

      --- Emits bytes `s` to `e` of the text, breaking at clauses until each line fits.
      local function emit(s, e)
        s = text:find("%S", s) or e + 1
        while e >= s and text:sub(e, e):match("%s") do
          e = e - 1
        end
        if e < s then
          return
        end
        while true do
          local piece = text:sub(s, e)
          local fits, ceiling = budget(opts.target), budget(opts.hard_max)
          local width = M.width(piece, opts.tabstop)
          if width <= fits then
            out[#out + 1] = piece
            return
          end
          local ranked, commas = {}, {}
          for _, candidate in ipairs(clauses(piece, opts.tabstop)) do
            if legal(s - 1 + candidate.pos) then
              local bucket = candidate.rank < COMMA and ranked or commas
              bucket[#bucket + 1] = candidate
            end
          end
          local chosen = pick(ranked, fits, ceiling)
          -- a bare comma only stops a line running past hard_max,
          -- it never tidies one that is merely over target
          if not chosen and width > ceiling then
            chosen = pick(commas, fits, ceiling)
          end
          if not chosen then
            out[#out + 1] = piece
            return
          end
          out[#out + 1] = rtrim(piece:sub(1, chosen.pos))
          s = text:find("%S", s + chosen.pos)
        end
      end

      local from = 1
      for _, stop in ipairs(sentences(text, opts.abbreviations)) do
        -- a refused break keeps its gap as written
        if legal(stop) then
          emit(from, stop)
          from = stop + 1
        end
      end
      emit(from, #text)
      if line.marker then
        out[#out] = out[#out] .. line.marker
      end
    end
  end

  for i, text in ipairs(out) do
    local lead = i == 1 and prefix.first or prefix.rest
    out[i] = text == "" and rtrim(lead) or lead .. text
  end
  return out
end

return M
