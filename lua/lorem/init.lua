-- init.lua
--     __                                       _
--    / /___  ________  ____ ___    ____ _   __(_)___ ___
--   / / __ \/ ___/ _ \/ __ `__ \  / __ \ | / / / __ `__ \
--  / / /_/ / /  /  __/ / / / / / / / / / |/ / / / / / / /
-- /_/\____/_/   \___/_/ /_/ /_(_)_/ /_/|___/_/_/ /_/ /_/

---@module lorem

local api = vim.api

math.randomseed(os.time())
math.random()
---@type string[]
local words = require "lorem.ipsum"

---@class LoremConfig
---@field sentence_length string|string[]  # "short", "medium", etc.
---@field comma_chance number
---@field max_commas integer
---@field format_defaults table<string, {w_per_sentence: integer, s_per_paragraph: integer}>
--- Module configuration
---@type LoremConfig
local _config = {
  sentence_length = "medium",
  comma_chance    = 0.2,
  max_commas      = 2,
  format_defaults = {
    short      = { w_per_sentence = 5, s_per_paragraph = 3 },
    medium     = { w_per_sentence = 10, s_per_paragraph = 5 },
    long       = { w_per_sentence = 14, s_per_paragraph = 7 },
    mixedShort = { w_per_sentence = 8, s_per_paragraph = 4 },
    mixed      = { w_per_sentence = 12, s_per_paragraph = 6 },
    mixedLong  = { w_per_sentence = 16, s_per_paragraph = 8 },
  },
}

---@class lorem
local M = {}

--- Merge user options
---@param user_config LoremConfig?  # partial override
---@return nil
function M.setup(user_config)
  if user_config then
    _config = vim.tbl_deep_extend("force", _config, user_config)
  end
end

M.opts = M.setup

local generate_text

-- ┏━━━━━━━━━━━━━━┓
-- ┃  Public API  ┃
-- ┗━━━━━━━━━━━━━━┛
--- Generate a certain number of words
---@param n integer?  # number of words
---@return string
function M.words(n)
  return generate_text({ format = "words", amount = n or 100 })
end

--- Generate a certain number of paragraphs
---@param n integer?  # number of paragraphs
---@return string
function M.paragraphs(n)
  return generate_text({ format = "paragraphs", amount = n or 1 })
end

--- Generate text via a command string
---@param args string  # e.g. "words 50"
---@return string
function M.ipsum(args)
  local parts = vim.split(args, "%s+")
  return generate_text({
    format          = parts[1],
    amount          = tonumber(parts[2]),
    w_per_sentence  = tonumber(parts[3]) or _config.format_defaults.medium.w_per_sentence,
    s_per_paragraph = tonumber(parts[4]) or _config.format_defaults.medium.s_per_paragraph,
  })
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Private Helper Functions  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
--- Pick a random word
---@return string
local function random_word()
  return words[math.random(#words)]
end

--- Capitalize a word
---@param word string
---@return string
local function capitalize(word)
  return word:sub(1, 1):upper() .. word:sub(2)
end

--- Provide completion for :LoremIpsum
---@param arg_lead string
---@param cmd_line string
---@return string[]
local function format_completion(arg_lead, cmd_line)
  local choices = { words = { "10", "20", "50", "100" }, paragraphs = { "1", "2", "3", "5" } }
  local parts = vim.split(cmd_line, "%s+")
  local pool = (#parts == 2) and { "words", "paragraphs" } or (#parts == 3) and (choices[parts[2]] or {}) or {}
  return vim.tbl_filter(function(o) return vim.startswith(o, arg_lead) end, pool)
end
M._complete = format_completion

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Core Text Generation  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━┛
--- Build a sentence of given length
---@param wps integer  # words per sentence
---@return string
local function build_sentence(wps)
  local t, commas = {}, 0
  for i = 1, wps do
    local w = random_word()
    if i == 1 then w = capitalize(w) end
    if i < wps and commas < _config.max_commas and math.random() <= _config.comma_chance then
      w = w .. ","; commas = commas + 1
    end
    table.insert(t, w)
  end
  return table.concat(t, " ") .. "."
end

--- Build a paragraph
---@param wps integer
---@param spp integer
---@return string
local function build_paragraph(wps, spp)
  local o = {}
  for _ = 1, spp do table.insert(o, build_sentence(wps)) end
  return table.concat(o, " ")
end

--- Resolve generation config from user overrides and global defaults
---@param cfg table?
---@return {format: string, amount: integer, w_per_sentence: integer, s_per_paragraph: integer}
local function get_config(cfg)
  local sl = _config.sentence_length
  local base = (type(sl) == "table" and sl) or _config.format_defaults[sl] or _config.format_defaults.medium
  cfg = cfg or {}
  return {
    format          = cfg.format or "words",
    amount          = cfg.amount or 1,
    w_per_sentence  = cfg.w_per_sentence or base.w_per_sentence,
    s_per_paragraph = cfg.s_per_paragraph or base.s_per_paragraph,
  }
end

--- Generate text based on config
---@param cfg table
---@return string
generate_text = function(cfg)
  local c = get_config(cfg)
  local res, total = {}, 0
  if c.format == "words" then
    while total < c.amount do
      local n = math.min(c.amount - total, c.w_per_sentence)
      table.insert(res, build_sentence(n)); total = total + n
    end
    return table.concat(res, " ")
  elseif c.format == "paragraphs" then
    for _ = 1, c.amount do
      table.insert(res, build_paragraph(c.w_per_sentence, c.s_per_paragraph))
    end
    return table.concat(res, "\n\n")
  end
  error("Invalid format: use 'words' or 'paragraphs'.")
end

-- ┏━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Command Handling  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━┛
--- Insert text at cursor
---@param txt string
---@return nil
local function insert_text(txt)
  local buf = api.nvim_get_current_buf()
  local r, c = unpack(api.nvim_win_get_cursor(0))
  local lines = vim.split(txt, "\n")
  api.nvim_buf_set_text(buf, r - 1, c, r - 1, c, lines)
  api.nvim_win_set_cursor(0, { r + #lines - 1, c + #lines[#lines] })
end

--- Extract number and paragraph flag, expects a trailing space as trigger
---@param line string
---@return integer?, string?
local function extract_num_fmt(line)
  local num_str, p = line:match("lorem(%d+)(p?) $")
  local num = tonumber(num_str)
  return num, p
end

--- Validate numeric input
---@param n integer?
---@return boolean
local function valid_num(n)
  if not n or n < 1 then
    vim.notify("Give a positive number.", vim.log.levels.ERROR)
    return false
  elseif n > 1000 then
    vim.notify("Max number is 1000.", vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Replace trigger text (including the trailing space) with generated text
---@param line string
---@param row integer
---@param txt string
---@return nil
local function replace_trigger(line, row, txt)
  local s, e = line:find("lorem%d+p? ")
  if not s then return end
  local lines = vim.split(txt, "\n")
  api.nvim_buf_set_text(0, row - 1, s - 1, row - 1, e, lines)
  api.nvim_win_set_cursor(0, { row + #lines - 1, #lines[#lines] })
end

--- Handle inline lorem trigger
---@return nil
local function on_keyword()
  local line = api.nvim_get_current_line()
  local row, col = unpack(api.nvim_win_get_cursor(0))
  local num, p = extract_num_fmt(line:sub(1, col))
  if not num or not valid_num(num) then return end
  local txt = (p == "p") and M.paragraphs(num) or M.words(num)
  replace_trigger(line, row, txt)
end

-- Create :LoremIpsum command
--                               ┌────────────┐
--                               │            │
--                               │    Menu    │
--                               │depending on│
--                 ┌────────────┐│  previous  │
--                 │   words    ││ selection  │
--                 │ paragraphs ││            │
--                 └────────────┘└────────────┘
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- :LoremIpsum         <TAB>         <TAB>
--                  ┗━━━mode━━━┛ ┗━━━amount━━━┛

api.nvim_create_user_command("LoremIpsum", function(opts)
  local a = vim.split(opts.args, "%s+")
  if #a < 2 then
    vim.notify("Usage: LoremIpsum <words|paragraphs> <amount>", vim.log.levels.ERROR)
    return
  end
  if a[3] or a[4] then
    insert_text(M.ipsum(opts.args))
  else
    local fn = (a[1] == "paragraphs") and M.paragraphs or M.words
    insert_text(fn(tonumber(a[2])))
  end
end, { nargs = "+", complete = "customlist,v:lua.require'lorem'._complete" })

-- ┏━━━━━━━━━━━━━━━━━┓
-- ┃  Autocmd Setup  ┃
-- ┗━━━━━━━━━━━━━━━━━┛

-- Watches for lorem<n>[p]<space> in insert mode and expands it in place.
api.nvim_create_augroup("LoremIpsum", { clear = true })
api.nvim_create_autocmd("TextChangedI", {
  group = "LoremIpsum",
  callback = on_keyword,
})

return M
