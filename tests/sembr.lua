-- Tests for the pure core of sembr, run from the repo root:
--
--     luajit tests/sembr.lua
--
-- Every case goes through `core.format`, text in and text out.
-- The captures a real editor would hand over are written by hand,
-- in the shapes nvim's highlights queries give.

package.path = "lua/?.lua;" .. package.path

local core = require("sembr.core")

local passed, failed = 0, 0

-- the 'comments' values nvim gives each filetype
local COMMENTS = {
  default = "s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-,fb:\u{2022}",
  markdown = "fb:*,fb:-,fb:+,n:>",
  typst = "s1:/*,mb:*,ex:*/,://",
  lua = ":---,:--",
  c = "sO:* -,mO:*  ,exO:*/,s1:/*,mb:*,ex:*/,:///,://",
  rust = "s0:/*!,ex:*/,s1:/*,mb:*,ex:*/,:///,://!,://",
  latex = "sO:% -,mO:%  ,eO:%%,:%",
  gitcommit = ":#",
  python = "b:#,fb:-",
  rst = "fb:..",
}
COMMENTS.text = COMMENTS.default
COMMENTS.markdown_inline = COMMENTS.markdown
COMMENTS.cpp = COMMENTS.c
COMMENTS.go = "s1:/*,mb:*,ex:*/,://"

-- the repeating leaders of each language, as the whitespace invariant strips them
local LEADERS = {
  lua = { "---", "--" },
  c = { "///", "//", "*" },
  rust = { "///", "//!", "//", "*" },
  typst = { "//", "*" },
  python = { "#" },
  go = { "//", "*" },
  -- a fenced lua block's comments are in markdown too
  markdown = { ">", "--" },
}

--- A `sembr.Scan` over `lines`, which are keyed from row 0.
--- `spec.captures` is a list of `{ name, lang, depth, sr, sc, er, ec }` tuples,
--- or a function of the lines that returns one,
--- for shapes that change when the lines do.
---@param lines string[]
---@param spec table|nil
---@return sembr.Scan
local function doc(lines, spec)
  spec = spec or {}
  local lang = spec.lang or "text"
  local rows = {}
  for i, line in ipairs(lines) do
    rows[i - 1] = line
  end
  local tuples = spec.captures or {}
  if type(tuples) == "function" then
    tuples = tuples(lines)
  end
  local captures = {}
  local comments = { [lang] = (spec.comments or {})[lang] or COMMENTS[lang] or COMMENTS.default }
  for i, t in ipairs(tuples) do
    captures[i] = { name = t[1], lang = t[2], depth = t[3], sr = t[4], sc = t[5], er = t[6], ec = t[7] }
    comments[t[2]] = (spec.comments or {})[t[2]] or COMMENTS[t[2]] or COMMENTS.default
  end
  local trees = spec.trees
  if trees == nil then
    trees = true
  end
  return {
    srow = spec.srow or 0,
    erow = spec.erow or #lines - 1,
    lines = rows,
    lang = lang,
    trees = trees,
    captures = captures,
    comments = comments,
    spec = spec,
  }
end

--- A plain text buffer, which has no grammar and so no captures.
local function text(lines, spec)
  spec = spec or {}
  spec.lang = spec.lang or "text"
  spec.trees = false
  return doc(lines, spec)
end

---@param t table|nil
---@return sembr.Opts
local function opts(t)
  local o = { target = 80, hard_max = 100, preserve_semantic_breaks = true, abbreviations = {}, tabstop = 8 }
  for k, v in pairs(t or {}) do
    o[k] = v
  end
  return o
end

--- One `comment` and one `spell` capture per line holding `leader`,
--- as lua and the other line comment grammars give them.
local function line_comments(lang, leader, depth)
  return function(lines)
    local out = {}
    for i, line in ipairs(lines) do
      local at = line:find(leader, 1, true)
      if at then
        out[#out + 1] = { "comment", lang, depth or 0, i - 1, at - 1, i - 1, #line }
        out[#out + 1] = { "spell", lang, depth or 0, i - 1, at - 1, i - 1, #line }
      end
    end
    return out
  end
end

local function show(lines)
  if type(lines) ~= "table" then
    return "    " .. tostring(lines)
  end
  local out = {}
  for i, line in ipairs(lines) do
    out[i] = string.format("    %q", line)
  end
  return table.concat(out, "\n")
end

local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then
    return a == b
  end
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

local function eq(name, got, want)
  if same(got, want) then
    passed = passed + 1
  else
    failed = failed + 1
    io.write(string.format("FAIL %s\n  got\n%s\n  want\n%s\n", name, show(got), show(want)))
  end
end

local function lines_of(scan)
  local out, n = {}, 0
  while scan.lines[n] do
    out[n + 1] = scan.lines[n]
    n = n + 1
  end
  return out
end

--- The whole document with `result`'s edits applied,
--- and the row the range now ends on.
local function apply(scan, result)
  local all = lines_of(scan)
  local edits = { unpack(result.edits) }
  table.sort(edits, function(a, b)
    return a.lo > b.lo
  end)
  local erow = scan.erow
  for _, edit in ipairs(edits) do
    for _ = edit.lo, edit.hi do
      table.remove(all, edit.lo + 1)
    end
    for i, line in ipairs(edit.lines) do
      table.insert(all, edit.lo + i, line)
    end
    erow = erow + #edit.lines - (edit.hi - edit.lo + 1)
  end
  return all, erow
end

local function range(all, srow, erow)
  local out = {}
  for row = srow, erow do
    out[#out + 1] = all[row + 1]
  end
  return out
end

--- How many non-blank characters come before `(row, col)`.
local function nonblank_before(lines, row, col)
  local n = 0
  for r = 0, row do
    local line = lines[r + 1] or ""
    if r == row then
      line = line:sub(1, col)
    end
    n = n + #line:gsub("%s", "")
  end
  return n
end

--- The position in `lines` just before the `k + 1`th non-blank character,
--- or, with `after`, just after the `k`th.
local function nonblank_at(lines, k, after)
  local n = 0
  for r, line in ipairs(lines) do
    for c = 1, #line do
      if not line:sub(c, c):match("%s") then
        if after and n + 1 == k then
          return r - 1, c
        end
        if not after and n == k then
          return r - 1, c - 1
        end
        n = n + 1
      end
    end
  end
  return #lines - 1, #lines[#lines]
end

--- The capture tuples of `scan`, moved onto `out`.
--- Only whitespace differs between the two,
--- so a position is kept by counting the characters before it.
local function moved(scan, out)
  local before = lines_of(scan)
  local tuples = {}
  for i, c in ipairs(scan.captures) do
    local sr, sc = nonblank_at(out, nonblank_before(before, c.sr, c.sc), false)
    local k = nonblank_before(before, c.er, c.ec)
    local er, ec
    local lead = (before[c.er + 1] or ""):sub(1, c.ec)
    if lead:match("^%s*$") and not (c.ec == 0 and c.er > c.sr) then
      er, ec = nonblank_at(out, k, false)
    else
      er, ec = nonblank_at(out, k, true)
    end
    tuples[i] = { c.name, c.lang, c.depth, sr, sc, er, ec }
  end
  return tuples
end

--- Formats `scan` and asserts the lines of its range come out as `want`,
--- or, for a string `want`, that the core returns `{ none = want }`.
--- A case that rewrites anything is then held to the invariants:
--- only whitespace changed, and formatting the output again changes nothing.
local function check(name, scan, o, want)
  local result = core.format(scan, o)
  if result.none then
    eq(name, "none=" .. result.none, type(want) == "string" and "none=" .. want or want)
    return
  end
  if type(want) == "string" then
    eq(name, "edits", "none=" .. want)
    return
  end

  for _, edit in ipairs(result.edits) do
    if edit.lo < scan.srow or edit.hi > scan.erow then
      eq(name .. ": edit inside the range", { edit.lo, edit.hi }, { scan.srow, scan.erow })
    end
  end
  local all, erow = apply(scan, result)
  local got = range(all, scan.srow, erow)
  eq(name, got, want)

  local input = range(lines_of(scan), scan.srow, scan.erow)
  local rewrote = false
  for _, edit in ipairs(result.edits) do
    rewrote = rewrote or edit.changed
  end
  if not rewrote then
    eq(name .. ": no edit without a change", got, input)
    return
  end

  -- joining drops the leaders of the rows it joins and splitting adds them,
  -- so they come off the front of every line first
  local strip = function(lines)
    local out = {}
    for i, line in ipairs(lines) do
      local again = true
      while again do
        again = false
        line = line:gsub("^%s+", "")
        for _, leader in ipairs(LEADERS[scan.lang] or {}) do
          if line:sub(1, #leader) == leader and line:find("^%s", #leader + 1) or line == leader then
            line = line:sub(#leader + 1)
            again = true
            break
          end
        end
      end
      out[i] = line
    end
    return (table.concat(out):gsub("%s", ""))
  end
  eq(name .. ": only whitespace changed", strip(got), strip(input))

  local spec = {}
  for k, v in pairs(scan.spec) do
    spec[k] = v
  end
  spec.erow = erow
  if type(spec.captures) ~= "function" then
    spec.captures = moved(scan, all)
  end
  local again = core.format(doc(all, spec), o)
  local changed = {}
  for _, edit in ipairs(again.edits or {}) do
    if edit.changed then
      changed[#changed + 1] = edit.lo .. "-" .. edit.hi
    end
  end
  eq(name .. ": idempotent", table.concat(changed, ","), "")
end

local function rep(word, n)
  return (string.rep(word .. " ", n):gsub(" $", ""))
end

-- Plain text -----------------------------------------------------------------

check(
  "plain text: paragraphs and items are regions of their own",
  text({
    "The first paragraph starts here and it",
    "runs on. It has a second sentence.",
    "",
    "- a is an item. It wraps",
    "onto a second line.",
    "1. b one. b two.",
    "1) c one. c two.",
    "\u{2022} d one. d two.",
  }),
  opts(),
  {
    "The first paragraph starts here and it runs on.",
    "It has a second sentence.",
    "",
    "- a is an item.",
    "  It wraps onto a second line.",
    "1. b one.",
    "   b two.",
    "1) c one.",
    "   c two.",
    "\u{2022} d one.",
    "  d two.",
  }
)

check(
  "plain text: nested items pad to their own text column",
  text({
    "- a one. a two",
    "wraps.",
    "  - b one. b two",
    "    wraps.",
    "    1. c one. c",
    "  two.",
  }),
  opts(),
  {
    "- a one.",
    "  a two wraps.",
    "  - b one.",
    "    b two wraps.",
    "    1. c one.",
    "       c two.",
  }
)

check(
  "plain text: a number or emphasis at the start of a line is prose",
  text({
    "Some text here and",
    "1996 was a year to",
    "*emphasis* opens this",
    "line.",
  }),
  opts(),
  { "Some text here and 1996 was a year to *emphasis* opens this line." }
)

check(
  "plain text: # needs a blank after it to be a leader",
  text({
    "This is a line that",
    "#hashtag starts here and",
    "goes on.",
  }),
  opts(),
  { "This is a line that #hashtag starts here and goes on." }
)

check("plain text: a filetype with no grammar is not prose", text({ "a", "b" }, { lang = "conf" }), opts(), "unknown")

check("plain text: reflows", text({ "a", "b" }), opts(), { "a b" })

check(
  "plain text: width counts characters, not bytes",
  text({ "na\u{ef}ve d\u{e9}j\u{e0} vu", "\u{2014} yes" }),
  opts({ target = 19 }),
  { "na\u{ef}ve d\u{e9}j\u{e0} vu \u{2014} yes" }
)

-- Line comments --------------------------------------------------------------

check(
  "lua: nested items keep the leader and pad after it",
  doc({
    "-- - a one. a two",
    "--   - b one. b two",
    "--     cont",
  }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  {
    "-- - a one.",
    "--   a two",
    "--   - b one.",
    "--     b two cont",
  }
)

check(
  "lua: one capture per line heals into one region",
  doc({ "-- one two", "-- three." }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  { "-- one two three." }
)

check(
  "lua: --- beats -- and a doc tag is never joined",
  doc({
    "--- Text that",
    "--- wraps.",
    "---@param x integer",
  }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  { "--- Text that wraps.", "---@param x integer" }
)

check(
  "lua: a row indented past the text column is not joined",
  doc({
    "-- Run it",
    "-- with:",
    "--",
    "--     luajit tests/sembr.lua",
    "--",
    "--   s, m, e  the start of a",
    "--            block comment",
    "--   f        first line",
    "-- Then a paragraph",
    "-- wraps.",
  }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  {
    "-- Run it with:",
    "--",
    "--     luajit tests/sembr.lua",
    "--",
    "--   s, m, e  the start of a",
    "--            block comment",
    "--   f        first line",
    "-- Then a paragraph wraps.",
  }
)

check(
  "lua: a paragraph after a blank row is not an item's continuation",
  doc({ "-- - an item", "--", "-- a paragraph" }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  { "-- - an item", "--", "-- a paragraph" }
)

check(
  "lua: code before a comment",
  doc({ "x = 1 -- note" }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  "code"
)

check(
  "c: a range clamped at the start still sees code after the capture",
  doc({ "/* one", "   two", "   */ int x;" }, {
    lang = "c",
    srow = 1,
    erow = 1,
    captures = { { "comment", "c", 0, 0, 0, 2, 5 }, { "spell", "c", 0, 0, 0, 2, 5 } },
  }),
  opts(),
  "code"
)

check(
  "lua: a capture ending at column 0 of the next row ends on its own row",
  doc({ "-- one. two", "x = 1" }, {
    lang = "lua",
    erow = 0,
    captures = { { "comment", "lua", 0, 0, 0, 1, 0 }, { "spell", "lua", 0, 0, 0, 1, 0 } },
  }),
  opts(),
  { "-- one.", "-- two" }
)

check(
  "lua: only rows in the range are edited",
  doc({ "-- zero", "-- one", "-- two", "-- three" }, {
    lang = "lua",
    srow = 1,
    erow = 2,
    captures = line_comments("lua", "--"),
  }),
  opts(),
  { "-- one two" }
)

check(
  "lua: an already SemBr block is left byte for byte",
  doc({ "-- One sentence here.   ", "-- Another one." }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  { "-- One sentence here.   ", "-- Another one." }
)

check(
  "lua: a break is never made before a bullet",
  doc({ "-- It is shown", "-- below. - and nothing else." }, { lang = "lua", captures = line_comments("lua", "--") }),
  opts(),
  { "-- It is shown below. - and nothing else." }
)

check(
  "c: a tab in the prefix advances to the next tab stop",
  doc({ "\t// " .. rep("word", 8) .. "; " .. rep("more", 6) }, {
    lang = "c",
    captures = line_comments("c", "//"),
  }),
  opts({ tabstop = 8 }),
  { "\t// " .. rep("word", 8) .. ";", "\t// " .. rep("more", 6) }
)

check(
  "c: the same line fits behind a four column prefix",
  doc({ " // " .. rep("word", 8) .. "; " .. rep("more", 6) }, {
    lang = "c",
    captures = line_comments("c", "//"),
  }),
  opts({ tabstop = 8 }),
  { " // " .. rep("word", 8) .. "; " .. rep("more", 6) }
)

check(
  "lua: the prefix counts against the target",
  doc({ "--- " .. rep("word", 8) .. "; " .. rep("more", 8) }, {
    lang = "lua",
    captures = line_comments("lua", "--"),
  }),
  opts(),
  { "--- " .. rep("word", 8) .. ";", "--- " .. rep("more", 8) }
)

-- Sentences ------------------------------------------------------------------

check(
  "sentences: a reference word is a stop unless a digit follows",
  text({ "The answer is", "no. But we tried." }),
  opts(),
  { "The answer is no.", "But we tried." }
)

check(
  "sentences: abbreviations, initials, numbers and ellipses are not stops",
  text({ "See no. 5 for e.g. the case", "A. B. Venberg made in version 1. 5 and wait... then go." }),
  opts(),
  { "See no. 5 for e.g. the case A. B. Venberg made in version 1. 5 and wait... then go." }
)

check(
  "sentences: extra abbreviations are honoured",
  text({ "We met Foo. Bar", "there." }),
  opts({ abbreviations = { foo = true } }),
  { "We met Foo. Bar there." }
)

check("sentences: without them it is a stop", text({ "We met Foo. Bar", "there." }), opts(), {
  "We met Foo.",
  "Bar there.",
})

-- Joining --------------------------------------------------------------------

check(
  "join: a break after a boundary is kept",
  text({
    "ends with a period.",
    "next one!",
    "a question?",
    "semi;",
    "colon:",
    "comma,",
    "closer.)",
    'quote."',
    "well-",
    "known word\u{2014}",
    "dash then",
    "end",
  }),
  opts(),
  {
    "ends with a period.",
    "next one!",
    "a question?",
    "semi;",
    "colon:",
    "comma,",
    "closer.)",
    'quote."',
    "well-",
    "known word\u{2014}",
    "dash then end",
  }
)

check(
  "join: without preserve_semantic_breaks every break heals but a blank line",
  text({ "first part,", "second part", "", "next" }),
  opts({ preserve_semantic_breaks = false }),
  { "first part, second part", "", "next" }
)

-- Clauses --------------------------------------------------------------------

check(
  "clauses: a bare comma is not taken to tidy a line over target",
  text({ "the cat, which was", "grey, sat on the mat." }),
  opts({ target = 20 }),
  { "the cat, which was grey, sat on the mat." }
)

check(
  "clauses: a bare comma is taken to stay under hard_max",
  text({ "the cat, which was", "grey, sat on the mat." }),
  opts({ target = 20, hard_max = 30 }),
  { "the cat,", "which was grey,", "sat on the mat." }
)

check(
  "clauses: the latest candidate that fits",
  text({ "aaaa aaaa; bbbb bbbb; cccc", "cccc cccc cccc" }),
  opts({ target = 22 }),
  { "aaaa aaaa; bbbb bbbb;", "cccc cccc cccc cccc" }
)

check(
  "clauses: else the earliest under hard_max",
  text({ "aaaa aaaa; bbbb bbbb; cccc", "cccc cccc cccc" }),
  opts({ target = 5, hard_max = 30 }),
  { "aaaa aaaa;", "bbbb bbbb;", "cccc cccc cccc cccc" }
)

check(
  "clauses: else the line stays long",
  text({ "aaaa bbbb", "cccc dddd" }),
  opts({ target = 5, hard_max = 10 }),
  { "aaaa bbbb cccc dddd" }
)

-- Protection -----------------------------------------------------------------

check(
  "protect: a url stays whole and its last period still ends the sentence",
  text({ "Go to", "https://example.com/a. Then stop." }),
  opts(),
  { "Go to https://example.com/a.", "Then stop." }
)

check(
  "protect: a code span is never broken inside",
  text({ "Use `a. b` here", "and then more." }),
  opts(),
  { "Use `a. b` here and then more." }
)

check(
  "protect: a double backtick span is never broken inside",
  text({ "Try ``a `b`. c``", "now." }),
  opts(),
  { "Try ``a `b`. c`` now." }
)

check(
  "split guard: a refused break keeps its gap",
  text({ "First line", "wraps. Stop here.  - then more.", "", "- item" }),
  opts(),
  { "First line wraps.", "Stop here.  - then more.", "", "- item" }
)

-- Markdown -------------------------------------------------------------------

local function md(lines, captures, spec)
  spec = spec or {}
  spec.lang = "markdown"
  spec.captures = captures
  return doc(lines, spec)
end

check(
  "markdown: two adjacent items are two regions",
  md({
    "Intro para that",
    "wraps. Next.",
    "",
    "- a one that",
    "  wraps. a two.",
    "- b one that",
    "  wraps.",
  }, {
    { "spell", "markdown", 0, 0, 0, 1, 12 },
    { "markup.list", "markdown", 0, 3, 0, 3, 2 },
    { "spell", "markdown", 0, 3, 2, 4, 15 },
    { "markup.list", "markdown", 0, 5, 0, 5, 2 },
    { "spell", "markdown", 0, 5, 2, 6, 8 },
  }),
  opts(),
  {
    "Intro para that wraps.",
    "Next.",
    "",
    "- a one that wraps.",
    "  a two.",
    "- b one that wraps.",
  }
)

check(
  "markdown: ordered items are separate regions",
  md({ "1. one that", "   wraps. Two.", "2. three that", "   wraps." }, {
    { "spell", "markdown", 0, 0, 3, 1, 14 },
    { "spell", "markdown", 0, 2, 3, 3, 9 },
  }),
  opts(),
  { "1. one that wraps.", "   Two.", "2. three that wraps." }
)

check(
  "markdown: nested items with mixed markers",
  md({
    "- a one that",
    "  wraps. a two.",
    "  * b one that",
    "    wraps. b two.",
    "    1. c one that",
    "       wraps. c two.",
  }, {
    { "spell", "markdown", 0, 0, 2, 1, 15 },
    { "spell", "markdown", 0, 2, 4, 3, 17 },
    { "spell", "markdown", 0, 4, 7, 5, 20 },
  }),
  opts(),
  {
    "- a one that wraps.",
    "  a two.",
    "  * b one that wraps.",
    "    b two.",
    "    1. c one that wraps.",
    "       c two.",
  }
)

check(
  "markdown: nested items inside a quote",
  md({ "> - a one that", ">   wraps. a two.", ">   - b one. b two." }, {
    { "spell", "markdown", 0, 0, 4, 1, 17 },
    { "spell", "markdown", 0, 2, 6, 2, 19 },
  }),
  opts(),
  { "> - a one that wraps.", ">   a two.", ">   - b one.", ">     b two." }
)

check(
  "markdown: a quote keeps its leader, and a nested quote is cut from it",
  md({ "> quote one that", "> wraps. Two.", "> > deep one. deep", "> > two." }, {
    { "spell", "markdown", 0, 0, 2, 1, 13 },
    { "spell", "markdown", 0, 2, 4, 3, 8 },
  }),
  opts(),
  { "> quote one that wraps.", "> Two.", "> > deep one.", "> > deep two." }
)

check(
  "markdown: a link label wrapped across quoted lines is one span",
  md({ "> See [one. two", "> three](u) x. Then." }, {
    { "spell", "markdown", 0, 0, 2, 1, 20 },
    { "markup.link", "markdown_inline", 1, 0, 6, 0, 7 },
    { "markup.link.label", "markdown_inline", 1, 0, 7, 1, 7 },
    { "markup.link", "markdown_inline", 1, 1, 7, 1, 8 },
    { "markup.link", "markdown_inline", 1, 1, 8, 1, 9 },
    { "markup.link.url", "markdown_inline", 1, 1, 9, 1, 10 },
    { "markup.link", "markdown_inline", 1, 1, 10, 1, 11 },
  }),
  opts(),
  { "> See [one. two three](u) x.", "> Then." }
)

check(
  "markdown: reference links and code spans are never broken inside",
  md({ "See [one. two][ref] and `a. b` and ``c `d`. e``", "here. End." }, {
    { "spell", "markdown", 0, 0, 0, 1, 10 },
    { "markup.link", "markdown_inline", 1, 0, 4, 0, 5 },
    { "markup.link.label", "markdown_inline", 1, 0, 5, 0, 13 },
    { "markup.link", "markdown_inline", 1, 0, 13, 0, 14 },
    { "markup.link.label", "markdown_inline", 1, 0, 14, 0, 18 },
    { "markup.raw", "markdown_inline", 1, 0, 24, 0, 30 },
    { "nospell", "markdown_inline", 1, 0, 24, 0, 30 },
    { "markup.raw", "markdown_inline", 1, 0, 35, 0, 47 },
    { "nospell", "markdown_inline", 1, 0, 35, 0, 47 },
  }),
  opts(),
  { "See [one. two][ref] and `a. b` and ``c `d`. e`` here.", "End." }
)

check(
  "markdown: a setext heading is untouched",
  md({ "Setext heading that", "wraps here", "===" }, {
    { "markup.heading.1", "markdown", 0, 0, 0, 2, 0 },
    { "spell", "markdown", 0, 0, 0, 1, 10 },
    { "markup.heading.1", "markdown", 0, 2, 0, 2, 3 },
  }),
  opts(),
  "code"
)

check(
  "markdown: hard breaks are kept verbatim and none is added",
  md({ "Line one   ", "hard break\\", "next line", "wraps here.", "\\", "after that" }, {
    { "spell", "markdown", 0, 0, 0, 5, 10 },
  }),
  opts(),
  { "Line one   ", "hard break\\", "next line wraps here.", "\\", "after that" }
)

check(
  "markdown: a fenced lua comment reflows, and the rest of the fence does not",
  md({ "Para.", "", "```lua", "-- one that", "-- wraps.", "x = 1 -- trailing", "```" }, function(lines)
    local out = line_comments("lua", "--", 1)(lines)
    out[#out + 1] = { "spell", "markdown", 0, 0, 0, 0, 5 }
    out[#out + 1] = { "markup.raw.block", "markdown", 0, 2, 0, #lines, 0 }
    return out
  end),
  opts(),
  { "Para.", "", "```lua", "-- one that wraps.", "x = 1 -- trailing", "```" }
)

local shared = {
  { "spell", "markdown", 0, 0, 2, 1, 6 },
  { "spell", "typst", 1, 0, 2, 1, 6 },
}
check(
  "markdown: the host owns rows it shares with an injection",
  md({ "* a one. a", "  two." }, shared),
  opts(),
  { "* a one.", "  a two." }
)
check(
  "markdown: the host owns them whatever the order of the captures",
  md({ "* a one. a", "  two." }, { shared[2], shared[1] }),
  opts(),
  { "* a one.", "  a two." }
)

-- Typst ----------------------------------------------------------------------

check(
  "typst: word runs are one region, and no line starts a list or heading",
  doc({
    "Some *bold* text and $a, b$ with @ref here and",
    "more. - Not a list. + Nor this. / Nor. = Nor.",
  }, {
    lang = "typst",
    captures = {
      { "spell", "typst", 0, 0, 0, 0, 4 },
      { "markup.strong", "typst", 0, 0, 5, 0, 11 },
      { "spell", "typst", 0, 0, 6, 0, 10 },
      { "spell", "typst", 0, 0, 12, 0, 20 },
      { "markup.math", "typst", 0, 0, 21, 0, 27 },
      { "spell", "typst", 0, 0, 28, 0, 32 },
      { "markup.link", "typst", 0, 0, 33, 0, 37 },
      { "spell", "typst", 0, 0, 38, 0, 46 },
      { "spell", "typst", 0, 1, 0, 1, 45 },
    },
  }),
  opts(),
  {
    "Some *bold* text and $a, b$ with @ref here and more. -",
    "Not a list. + Nor this. / Nor. = Nor.",
  }
)

check(
  "typst: never a break inside math",
  doc({ "Alpha beta $a, b$ gamma delta", "epsilon zeta." }, {
    lang = "typst",
    captures = {
      { "spell", "typst", 0, 0, 0, 0, 10 },
      { "markup.math", "typst", 0, 0, 11, 0, 17 },
      { "spell", "typst", 0, 0, 18, 0, 29 },
      { "spell", "typst", 0, 1, 0, 1, 13 },
    },
  }),
  opts({ target = 10, hard_max = 20 }),
  { "Alpha beta $a, b$ gamma delta epsilon zeta." }
)

check(
  "typst: items nest and a heading is untouched",
  doc({ "= Heading", "- item one. item", "  cont.", "  - nested one. nested", "    wraps." }, {
    lang = "typst",
    captures = {
      { "markup.heading.1", "typst", 0, 0, 0, 0, 9 },
      { "spell", "typst", 0, 0, 2, 0, 9 },
      { "spell", "typst", 0, 1, 2, 1, 16 },
      { "spell", "typst", 0, 2, 2, 2, 7 },
      { "spell", "typst", 0, 3, 4, 3, 22 },
      { "spell", "typst", 0, 4, 4, 4, 10 },
    },
  }),
  opts(),
  { "= Heading", "- item one.", "  item cont.", "  - nested one.", "    nested wraps." }
)

-- Latex ----------------------------------------------------------------------

check(
  "latex: a spell wholly under nospell is not prose",
  doc({ "Some words. Here" }, {
    lang = "latex",
    captures = { { "spell", "latex", 0, 0, 0, 0, 16 }, { "nospell", "latex", 0, 0, 0, 0, 16 } },
  }),
  opts(),
  "code"
)

check(
  "latex: a partial nospell is protected",
  doc({ "See \\foo{a. b} and", "more." }, {
    lang = "latex",
    captures = { { "spell", "latex", 0, 0, 0, 1, 5 }, { "nospell", "latex", 0, 0, 4, 0, 14 } },
  }),
  opts(),
  { "See \\foo{a. b} and more." }
)

check(
  "latex: a \\\\ hard break is kept",
  doc({ "words here.\\\\", "Next line", "wraps." }, {
    lang = "latex",
    captures = { { "spell", "latex", 0, 0, 0, 2, 6 }, { "nospell", "latex", 0, 0, 11, 0, 13 } },
  }),
  opts(),
  { "words here.\\\\", "Next line wraps." }
)

-- Code languages -------------------------------------------------------------

check(
  "go: a string literal is not prose",
  doc({ 'x := "A string. With sentences that run long"' }, {
    lang = "go",
    captures = { { "spell", "go", 0, 0, 5, 0, 45 } },
  }),
  opts(),
  "code"
)

check(
  "go: a doc comment heals across its per-line captures",
  doc({ "// Doc comment that wraps in the", "// middle. Second.", "func f() {}" }, {
    lang = "go",
    captures = line_comments("go", "//"),
  }),
  opts(),
  { "// Doc comment that wraps in the middle.", "// Second.", "func f() {}" }
)

check(
  "go: a trailing comment after code is untouched",
  doc({ "\tx := 1 // trailing. note" }, { lang = "go", captures = line_comments("go", "//") }),
  opts(),
  "code"
)

check(
  "go: a tab-indented block comment keeps its gutter and closer",
  doc({ "\t/* block that", "\t * wraps. Two. */" }, {
    lang = "go",
    captures = { { "comment", "go", 0, 0, 1, 1, 18 }, { "spell", "go", 0, 0, 1, 1, 18 } },
  }),
  opts(),
  { "\t/* block that wraps.", "\t * Two.", "\t */" }
)

-- Gitcommit ------------------------------------------------------------------

check(
  "gitcommit: the body reflows, and the subject, comments and scissors do not",
  doc({
    "Subject line that is long enough",
    "",
    "Body text that",
    "wraps here. And more.",
    "# a comment inside",
    "more body",
    "text.",
    "# ------------------------ >8 ------------------------",
    "diff --git a/x b/x",
  }, {
    lang = "gitcommit",
    captures = {
      { "markup.heading", "gitcommit", 0, 0, 0, 0, 32 },
      { "spell", "gitcommit", 0, 0, 0, 0, 32 },
      { "spell", "gitcommit", 0, 2, 0, 7, 0 },
      { "comment", "gitcommit", 0, 4, 0, 5, 0 },
      { "comment", "gitcommit", 0, 7, 0, 8, 0 },
    },
  }),
  opts(),
  {
    "Subject line that is long enough",
    "",
    "Body text that wraps here.",
    "And more.",
    "# a comment inside",
    "more body text.",
    "# ------------------------ >8 ------------------------",
    "diff --git a/x b/x",
  }
)

-- Block comments -------------------------------------------------------------

--- One `comment` and one `spell` capture over rows `sr..er`,
--- from column `sc` to the end of row `er`, as a block comment's node gives them.
local function block(lang, sr, sc, er)
  return function(lines)
    local ec = #lines[er + 1]
    return { { "comment", lang, 0, sr, sc, er, ec }, { "spell", lang, 0, sr, sc, er, ec } }
  end
end

check(
  "c: a doc comment keeps its second *",
  doc({ "/** Note. More.", " */" }, { lang = "c", captures = block("c", 0, 0, 1) }),
  opts(),
  { "/** Note.", " * More.", " */" }
)

check(
  "rust: /*! keeps its decoration, and the s0 group with no middle is not the block",
  doc({ "/*! Note. More.", " */" }, { lang = "rust", captures = block("rust", 0, 0, 1) }),
  opts(),
  { "/*! Note.", " * More.", " */" }
)

check(
  "html: <!--- keeps its decoration",
  doc({ "<!--- Note. More. -->" }, {
    lang = "html",
    comments = { html = "s:<!--,m:    ,e:-->" },
    captures = block("html", 0, 0, 0),
  }),
  opts(),
  { "<!--- Note.", "     More.", "-->" }
)

check(
  "c: a one-line comment that fits keeps its closer",
  doc({ "    /* note */" }, { lang = "c", captures = block("c", 0, 4, 0) }),
  opts(),
  { "    /* note */" }
)

check(
  "c: a comment over several rows gets a gutter and its closer alone",
  doc({ "    /* one that", "     * wraps. Two", "     * more. */" }, { lang = "c", captures = block("c", 0, 4, 2) }),
  opts(),
  { "    /* one that wraps.", "     * Two more.", "     */" }
)

check(
  "c: a range starting on a gutter row still lifts the closer",
  doc({ "/* one", " * two that", " * wraps. */" }, { lang = "c", srow = 1, captures = block("c", 0, 0, 2) }),
  opts(),
  { " * two that wraps.", " */" }
)

check(
  "c: the gutter comes from s1:/*, not the sO:* - list form",
  doc({ "/* one that", " * wraps. Two.", " */" }, { lang = "c", captures = block("c", 0, 0, 2) }),
  opts(),
  { "/* one that wraps.", " * Two.", " */" }
)

check(
  "c: code after a block comment",
  doc({ "/* c. d */ x = 1;" }, {
    lang = "c",
    captures = { { "comment", "c", 0, 0, 0, 0, 10 }, { "spell", "c", 0, 0, 0, 0, 10 } },
  }),
  opts(),
  "code"
)

check(
  "c: code before a block comment",
  doc({ "x = 1; /* c. d */" }, {
    lang = "c",
    captures = { { "comment", "c", 0, 0, 7, 0, 17 }, { "spell", "c", 0, 0, 7, 0, 17 } },
  }),
  opts(),
  "code"
)

-- Python ---------------------------------------------------------------------

check(
  "python: a docstring reflows at the opener's indent",
  doc({
    "def f():",
    '    """Summary line that wraps',
    "    here. More.",
    "",
    "    Second para that",
    "    wraps.",
    '    """',
    "    return 1",
  }, {
    lang = "python",
    captures = function(lines)
      local last
      for i, line in ipairs(lines) do
        if line == '    """' then
          last = i - 1
        end
      end
      return {
        { "string.documentation", "python", 0, 1, 4, last, 7 },
        { "spell", "python", 0, 1, 7, last, 4 },
      }
    end,
  }),
  opts(),
  {
    "def f():",
    '    """Summary line that wraps here.',
    "    More.",
    "",
    "    Second para that wraps.",
    '    """',
    "    return 1",
  }
)

check(
  "python: a one-row docstring is left as written",
  doc({ "    r'''One-line doc.'''" }, {
    lang = "python",
    captures = {
      { "string.documentation", "python", 0, 0, 4, 0, 24 },
      { "spell", "python", 0, 0, 8, 0, 21 },
    },
  }),
  opts(),
  "code"
)

check(
  "python: a comment reflows and a trailing one does not",
  doc({ "# a comment that", "# wraps. Two.", 'x = "a string"  # trailing' }, {
    lang = "python",
    captures = line_comments("python", "#"),
  }),
  opts(),
  { "# a comment that wraps.", "# Two.", 'x = "a string"  # trailing' }
)

-- Docstrings in any grammar --------------------------------------------------

check(
  "graphql: a one-row docstring is never split, since its quote may not hold a newline",
  doc({ '  "Field doc that. Wraps here and runs on long enough to pass the target of the line"' }, {
    lang = "graphql",
    captures = {
      { "string.documentation", "graphql", 0, 0, 2, 0, 86 },
      { "spell", "graphql", 0, 0, 2, 0, 86 },
    },
  }),
  opts(),
  "code"
)

check(
  "graphql: a block string reflows and its quotes stay on their rows",
  doc({ '"""', "A type description that wraps in the", "middle. Second.", '"""', "type Foo {" }, {
    lang = "graphql",
    captures = {
      { "string.documentation", "graphql", 0, 0, 0, 3, 3 },
      { "spell", "graphql", 0, 0, 0, 3, 3 },
    },
  }),
  opts(),
  { '"""', "A type description that wraps in the middle.", "Second.", '"""', "type Foo {" }
)

check(
  "fennel: a docstring with no @spell is prose, continued at column 0 and closed where it was",
  doc({ "(fn f [x]", '  "Docstring that wraps in the', 'middle. Second."', "  x)" }, {
    lang = "fennel",
    captures = { { "string.documentation", "fennel", 0, 1, 2, 2, 16 } },
  }),
  opts(),
  { "(fn f [x]", '  "Docstring that wraps in the middle.', 'Second."', "  x)" }
)

check(
  "fennel: a docstring continued at the opener's column keeps that column",
  doc({ "(fn f [x]", '  "Docstring that wraps in the', '  middle. Second."', "  x)" }, {
    lang = "fennel",
    captures = { { "string.documentation", "fennel", 0, 1, 2, 2, 18 } },
  }),
  opts(),
  { "(fn f [x]", '  "Docstring that wraps in the middle.', '  Second."', "  x)" }
)

check(
  "fennel: code after the closer leaves the docstring alone",
  doc({ '(fn f [x] "Docstring. That', 'wraps." x)' }, {
    lang = "fennel",
    captures = { { "string.documentation", "fennel", 0, 0, 10, 1, 7 } },
  }),
  opts(),
  "code"
)

check(
  "julia: a docstring's injected markdown is the prose, and the quotes are not",
  doc({ '"""', "    f(x)", "", "Docstring that wraps in the middle of a", "clause. Second sentence.", '"""' }, {
    lang = "julia",
    captures = {
      { "string.documentation", "julia", 0, 0, 0, 5, 3 },
      { "spell", "markdown", 1, 3, 0, 4, 24 },
    },
  }),
  opts(),
  { '"""', "    f(x)", "", "Docstring that wraps in the middle of a clause.", "Second sentence.", '"""' }
)

check(
  "python: a closer written after the last words stays there",
  doc({ "def f():", '    """Summary that wraps in the', '    middle. Second."""' }, {
    lang = "python",
    captures = {
      { "string.documentation", "python", 0, 1, 4, 2, 22 },
      { "spell", "python", 0, 1, 7, 2, 19 },
    },
  }),
  opts(),
  { "def f():", '    """Summary that wraps in the middle.', '    Second."""' }
)

-- reStructuredText -----------------------------------------------------------

--- The capture of the first `text` on row `row` of `lines`, named `name`.
local function at(lines, name, lang, row, text)
  local from, to = lines[row + 1]:find(text, 1, true)
  return { name, lang, 0, row, from - 1, row, to }
end

local rst_lines = {
  "Title",
  "=====",
  "",
  "A paragraph with ``literal. code`` and `link. x <http://x.org>`_ that",
  "wraps mid clause. Second.",
  "",
  "- item one that wraps in the",
  "  middle. Two.",
  "",
  ".. note::",
  "",
  "   Directive body that wraps in the",
  "   middle. Two.",
}
check(
  "rst: paragraphs, items and directive bodies reflow, and literals and links stay whole",
  doc(rst_lines, {
    lang = "rst",
    captures = {
      { "markup.heading", "rst", 0, 0, 0, 0, 5 },
      { "markup.heading", "rst", 0, 1, 0, 1, 5 },
      { "spell", "rst", 0, 3, 0, 4, 25 },
      at(rst_lines, "markup.raw", "rst", 3, "``literal. code``"),
      at(rst_lines, "markup.link", "rst", 3, "`link. x <http://x.org>`_"),
      at(rst_lines, "nospell", "rst", 3, "`link. x <http://x.org>`_"),
      { "markup.list", "rst", 0, 6, 0, 6, 1 },
      { "spell", "rst", 0, 6, 2, 7, 14 },
      { "spell", "rst", 0, 11, 3, 12, 16 },
    },
  }),
  opts(),
  {
    "Title",
    "=====",
    "",
    "A paragraph with ``literal. code`` and `link. x <http://x.org>`_ that wraps mid clause.",
    "Second.",
    "",
    "- item one that wraps in the middle.",
    "  Two.",
    "",
    ".. note::",
    "",
    "   Directive body that wraps in the middle.",
    "   Two.",
  }
)

check(
  "rst: no break leaves a directive or a line block leading a line",
  doc({ "It stops. .. not a directive. | nor a", "line block." }, {
    lang = "rst",
    captures = { { "spell", "rst", 0, 0, 0, 1, 11 } },
  }),
  opts(),
  { "It stops. .. not a directive. | nor a line block." }
)

io.write(string.format("%d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
