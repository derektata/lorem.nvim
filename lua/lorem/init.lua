-- init.lua
--     __                                       _
--    / /___  ________  ____ ___    ____ _   __(_)___ ___
--   / / __ \/ ___/ _ \/ __ `__ \  / __ \ | / / / __ `__ \
--  / / /_/ / /  /  __/ / / / / / / / / / |/ / / / / / / /
-- /_/\____/_/   \___/_/ /_/ /_(_)_/ /_/|___/_/_/ /_/ /_/

local api = vim.api
local words = require "lorem.ipsum"()

-- Initialize the pseudo random number generator
math.randomseed(os.time())
math.random()

-- @module lorem
local M = {}

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Configuration Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Default configuration table for sentence and paragraph generation.
--- @class Config
--- @field sentenceLength string|table Sentence length configuration. Can be "short", "medium", "long", "mixedShort", "mixed", or a custom table.
--- @field comma_chance number Chance of inserting a comma in a sentence.
--- @field max_commas_per_sentence number Maximum number of commas allowed in a sentence.
--- @field format_defaults table Default sentence and paragraph structure for various length settings.

--- Default configuration
local _config = {
  sentenceLength = "medium", -- default sentence length
  comma_chance = 0.2, -- default 20% chance to insert a comma
  max_commas_per_sentence = 2, -- default maximum number of commas per sentence
  format_defaults = {
    short = { words_per_sentence = 5, sentences_per_paragraph = 3 },
    medium = { words_per_sentence = 10, sentences_per_paragraph = 5 },
    long = { words_per_sentence = 14, sentences_per_paragraph = 7 },
    mixedShort = { words_per_sentence = 8, sentences_per_paragraph = 4 },
    mixed = { words_per_sentence = 12, sentences_per_paragraph = 6 },
    mixedLong = { words_per_sentence = 16, sentences_per_paragraph = 8 },
  },
}

--- Update configuration with user settings.
--- @param user_config table User-provided configuration to merge with default settings.
--- @return nil
function M.opts(user_config)
  if user_config then
    _config = vim.tbl_deep_extend("force", _config, user_config)
  end
end

--- Determine sentence configuration based on current settings.
--- @return table Configuration table for sentence length and paragraphs.
local function sentence_conf()
  local sentenceLength = _config.sentenceLength
  if type(sentenceLength) == "string" then
    local format = _config.format_defaults[sentenceLength]
    return format or _config.format_defaults["medium"]
  end
  if type(sentenceLength) == "table" then
    return sentenceLength
  end
  error("Invalid sentenceLength configuration. Expected a string or table, got: " .. type(sentenceLength))
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Utility Functions Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Get a random word from the Words table.
-- @return string A randomly selected word from the Words list.
local function random_word()
  return words[math.random(#words)]
end

--- Capitalize the first letter of a word.
--- @param word string The word to capitalize.
--- @return string The capitalized word.
local function capitalize(word)
  return word:sub(1, 1):upper() .. word:sub(2)
end

--- Determine if a comma should be added to a sentence.
--- @param ctx table The context for the current word (index, comma chance, etc.).
--- @return boolean Whether a comma should be added.
local function should_add_comma(ctx)
  local random_chance = math.random(100) <= (ctx.comma_chance * 100)
  local under_max = ctx.comma_count < ctx.max_commas
  return random_chance and under_max
end

--- Filter options based on a prefix.
--- @param options table The list of options to filter.
--- @param prefix string The prefix to filter by.
--- @return table The filtered options.
local function filter_opts(options, prefix)
  local filtered_opts = {}
  for _, opt in ipairs(options) do
    if opt:find("^" .. prefix) then
      table.insert(filtered_opts, opt)
    end
  end
  return filtered_opts
end

--- Autocomplete suggestions for the LoremIpsum command.
--- @param arg_lead string The leading part of the current argument.
--- @param cmd_line string The entire command line.
--- @return table A list of suggestions based on the input.
local function format_completion(arg_lead, cmd_line)
  local args = vim.split(cmd_line, "%s+")
  local complete_opts = {
    words = { "10", "20", "50", "100" },
    paragraphs = { "1", "2", "3", "5" },
  }

  if #args == 2 then
    return filter_opts({ "words", "paragraphs" }, arg_lead)
  elseif #args == 3 then
    return filter_opts(complete_opts[args[2]] or {}, arg_lead)
  end

  return {}
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Core Functions Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Build a sentence with the specified number of words.
--- @param w_per_sentence number Number of words in the sentence.
--- @return string The generated sentence.
local function build_sentence(w_per_sentence)
  local s = {}
  local comma_count = 0
  local comma_chance = _config.comma_chance
  local max_commas = _config.max_commas_per_sentence
  local w_until_comma = math.floor(w_per_sentence / ((max_commas or 0) + 1))

  for i = 1, w_per_sentence do
    local w = random_word()
    if i == 1 then
      w = capitalize(w)
    end

    local ctx = {
      index = i,
      comma_chance = comma_chance,
      words_until_comma = w_until_comma,
      comma_count = comma_count,
      max_commas = max_commas,
    }

    if i < w_per_sentence and should_add_comma(ctx) then
      w = w .. ","
      comma_count = comma_count + 1
    end

    table.insert(s, w)
  end

  return table.concat(s, " ") .. "."
end

--- Build a paragraph with the specified number of sentences.
--- @param w_per_sentence number Number of words per sentence.
--- @param s_per_paragraph number Number of sentences per paragraph.
--- @return string The generated paragraph.
local function build_paragraph(w_per_sentence, s_per_paragraph)
  local paragraph = {}
  for _ = 1, s_per_paragraph do
    table.insert(paragraph, build_sentence(w_per_sentence))
  end
  return table.concat(paragraph, " ")
end

--- Generate a specific number of words.
--- @param amount number|nil The total number of words to generate. Defaults to 100 if not provided.
--- @return string The generated text containing the requested number of words.
function M.words(amount)
  amount = amount or 100

  local result = {}
  local total_w_generated = 0
  local s_config = sentence_conf()
  local w_per_sentence = s_config.words_per_sentence

  while total_w_generated < amount do
    local w_to_generate = math.min(amount - total_w_generated, w_per_sentence)
    table.insert(result, build_sentence(w_to_generate))
    total_w_generated = total_w_generated + w_to_generate
  end

  return table.concat(result, " ")
end

--- Generate a specific number of paragraphs.
--- @param amount number The total number of paragraphs to generate.
--- @return string The generated text containing the requested number of paragraphs.
function M.paragraphs(amount)
  amount = amount or 1

  local result = {}
  local s_config = sentence_conf()
  local w_per_sentence = s_config.words_per_sentence
  local s_per_paragraph = s_config.sentences_per_paragraph

  for _ = 1, amount do
    table.insert(result, build_paragraph(w_per_sentence, s_per_paragraph))
  end
  return table.concat(result, "\n\n")
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Command Handler Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Handle the generation and insertion of lorem ipsum text.
--- @param format string The format of the text to generate ("words" or "paragraphs").
--- @param amount number The amount of text to generate (number of words or paragraphs).
--- @return nil
local function handle_command(format, amount)
  if format ~= "words" and format ~= "paragraphs" then
    error "Invalid format. Use 'words' or 'paragraphs'."
  end

  local result
  if format == "words" then
    result = M.words(amount)
  else
    result = M.paragraphs(amount)
  end

  local lines = vim.split(result, "\n")
  local buf = api.nvim_get_current_buf()
  local row, col = unpack(api.nvim_win_get_cursor(0))
  api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, lines)
end

--                          ┌────────────┐
--                          │            │
--                          │    Menu    │
--                          │depending on│
--           ┌────────────┐ │  previous  │
--           │   words    │ │ selection  │
--           │ paragraphs │ │            │
--           └────────────┘ └────────────┘
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- :LoremIpsum   <TAB>          <TAB>

api.nvim_create_user_command("LoremIpsum", function(opts)
  local args = vim.split(opts.args, " ")
  if #args < 2 then
    print "Invalid number of arguments. Usage: LoremIpsum <words|paragraphs> <amount>"
    return
  end

  local format = args[1]
  local amount = tonumber(args[2]) or 100

  handle_command(format, amount)
end, {
  nargs = "+",
  complete = format_completion,
})

return M
