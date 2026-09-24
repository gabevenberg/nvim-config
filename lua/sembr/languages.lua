--- What each language changes about reflowing its prose.
---
--- A profile names only the fields it changes from `DEFAULT`:
---
--- - `items`:
---   forms that open a unit, a list marker, a quote, a heading, a doc tag.
---   A row starting with one starts a region,
---   the joiner never joins one onto the line before,
---   and the splitter never leaves one leading a line.
---   Each needs a blank or the end of the line after it, except a tag.
---   A `list` item is also consumed as a leader,
---   and its continuations are padded to its text column.
--- - `hard_breaks`: Lua patterns for a line that ends on purpose,
---   capturing the body and then the marker, which is carried through verbatim
--- - `code_spans`: "tree" when the grammar marks code spans,
---   "regex" when a backtick pattern has to stand in for it
--- - `document`:
---   every `@spell` in the language is prose, not only comments and docstrings
local comments = require("sembr.comments")

local M = {}

local function marker(literal, consumed)
  return { text = literal, list = consumed }
end

local ORDERED = { ordered = true, list = true }
-- a doc tag, `@param`, which opens a unit without a blank after it
local TAG = { tag = true }

local BULLETS = { marker("-", true), marker("*", true), marker("+", true), ORDERED }

local DEFAULT = {
  items = { BULLETS[1], BULLETS[2], BULLETS[3], ORDERED, marker(">"), TAG },
  hard_breaks = {},
  code_spans = "regex",
  document = false,
}

-- a backslash,
-- or two blanks or more in markdown, carried with any blanks before it
local BACKSLASH = "^(.-)(%s*\\+)$"
local SPACES = "^(.-%S)(  +)$"

local PROFILES = {
  text = { document = true },
  markdown = {
    items = { BULLETS[1], BULLETS[2], BULLETS[3], ORDERED, marker(">"), marker("#") },
    code_spans = "tree",
    hard_breaks = { BACKSLASH, SPACES },
    document = true,
  },
  -- `*` is strong emphasis and `@` a reference, so both are prose
  typst = {
    items = { marker("-", true), marker("+", true), marker("/", true), marker("="), ORDERED },
    code_spans = "tree",
    hard_breaks = { BACKSLASH },
    document = true,
  },
  latex = {
    code_spans = "tree",
    hard_breaks = { BACKSLASH },
    document = true,
  },
  gitcommit = { document = true },
  -- `..` opens a directive or a comment,
  -- and comes in as an `f` leader from 'comments'.
  -- `|` opens a line block
  rst = {
    items = { BULLETS[1], BULLETS[2], BULLETS[3], marker("\u{2022}", true), ORDERED, marker("#.", true), marker("|") },
    code_spans = "tree",
    document = true,
  },
}

-- trees that are one language as far as prose is concerned
local ALIASES = {
  markdown_inline = "markdown",
}

for _, profile in pairs(PROFILES) do
  setmetatable(profile, { __index = DEFAULT })
end

---@class sembr.Item
---@field text string|nil     a literal marker
---@field ordered boolean|nil digits, then `.` or `)`
---@field tag boolean|nil     `@` and a word
---@field list boolean|nil    consumed as a list marker

---@class sembr.Leader
---@field text string
---@field blank boolean|nil  needs a blank or the end of the line after it

---@class sembr.BlockForm
---@field start string
---@field middle string|nil   the gutter, repeated on every continuation
---@field stop string
---@field offset integer      columns the gutter sits right of the opener
---@field decorated boolean|nil punctuation straight after the opener belongs to it, `/**`

---@class sembr.Rules
---@field items sembr.Item[]
---@field leaders sembr.Leader[]  the repeating leaders, line leaders then quotes
---@field gutters sembr.Leader[]  the repeating leaders inside a block, with its gutters
---@field blocks sembr.BlockForm[]
---@field hard_breaks string[]
---@field code_spans "tree"|"regex"
---@field document boolean

local cache = {}

--- The rules for prose in `lang`, whose `'comments'` is `value`.
---@param lang string
---@param value string
---@return sembr.Rules
function M.rules(lang, value)
  local key = lang .. "\0" .. value
  if cache[key] then
    return cache[key]
  end
  local profile = PROFILES[ALIASES[lang] or lang] or DEFAULT
  local parsed = comments.parse(value)

  local items = { unpack(profile.items) }
  local known = {}
  for _, item in ipairs(items) do
    if item.text then
      known[item.text] = true
    end
  end
  for _, leader in ipairs(parsed.items) do
    if not known[leader] then
      items[#items + 1] = marker(leader, true)
    end
  end

  local leaders = {}
  for _, leader in ipairs(parsed.line) do
    leaders[#leaders + 1] = { text = leader, blank = parsed.blank[leader] }
  end
  for _, leader in ipairs(parsed.quote) do
    leaders[#leaders + 1] = { text = leader, blank = parsed.blank[leader] }
  end

  local blocks = {}
  local block = parsed.block
  if block then
    blocks[1] = {
      start = block.start,
      middle = block.middle,
      stop = block.stop,
      offset = block.offset,
      decorated = true,
    }
  end
  local gutters = { unpack(leaders) }
  for _, form in ipairs(blocks) do
    if form.middle then
      gutters[#gutters + 1] = { text = form.middle, blank = parsed.blank[form.middle] }
    end
  end

  local rules = {
    items = items,
    leaders = leaders,
    gutters = gutters,
    blocks = blocks,
    hard_breaks = profile.hard_breaks,
    code_spans = profile.code_spans,
    document = profile.document,
  }
  cache[key] = rules
  return rules
end

return M
