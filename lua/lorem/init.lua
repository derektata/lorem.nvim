-- init.lua
--     __                                       _
--    / /___  ________  ____ ___    ____ _   __(_)___ ___
--   / / __ \/ ___/ _ \/ __ `__ \  / __ \ | / / / __ `__ \
--  / / /_/ / /  /  __/ / / / / / / / / / |/ / / / / / / /
-- /_/\____/_/   \___/_/ /_/ /_(_)_/ /_/|___/_/_/ /_/ /_/

local api = vim.api
local words = require "lorem.ipsum"()

-- Initialize the pseudo-random number generator
math.randomseed(os.time())
math.random()

-- @module lorem
local M = {}

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Configuration Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Configuration for sentence and paragraph generation.
--- @class Config
--- @field sentenceLength string|table Specifies the sentence length format.
--- @field comma_chance number Probability of adding a comma in a sentence.
--- @field max_commas number Maximum number of commas allowed in a sentence.
--- @field format_defaults table Predefined formats for sentence and paragraph structure.

--- Default configuration
local _config = {
  sentenceLength = "medium", -- default sentence length
  comma_chance = 0.2, -- default 20% chance to insert a comma
  max_commas = 2, -- default maximum number of commas per sentence
  format_defaults = {
    short = { words_per_sentence = 5, sentences_per_paragraph = 3 },
    medium = { words_per_sentence = 10, sentences_per_paragraph = 5 },
    long = { words_per_sentence = 14, sentences_per_paragraph = 7 },
    mixedShort = { words_per_sentence = 8, sentences_per_paragraph = 4 },
    mixed = { words_per_sentence = 12, sentences_per_paragraph = 6 },
    mixedLong = { words_per_sentence = 16, sentences_per_paragraph = 8 },
  },
}

--- Update configuration with user-defined settings.
--- @param user_config Config Configuration table with user-specific overrides.
function M.opts(user_config)
  if user_config then
    _config = vim.tbl_deep_extend("force", _config, user_config)
  end
end

--- Retrieve sentence configuration based on current settings.
--- @return table Configuration table for sentence length and paragraph structure.
local function sentence_conf()
  local sentenceLength = _config.sentenceLength

  if type(sentenceLength) == "string" then
    -- Lookup the format for predefined string types
    return _config.format_defaults[sentenceLength] or _config.format_defaults["medium"]
  elseif type(sentenceLength) == "table" then
    -- Return custom table configuration directly
    return sentenceLength
  else
    -- Provide a better error message
    error("Invalid sentenceLength configuration. Expected a string or table, got: " .. type(sentenceLength))
  end
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Utility Functions Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Get a random word from the list of words.
--- @return string A randomly selected word.
local function random_word()
  return words[math.random(#words)]
end

--- Capitalize the first letter of a word.
--- @param word string The word to capitalize.
--- @return string The capitalized word.
local function capitalize(word)
  return word:sub(1, 1):upper() .. word:sub(2)
end

--- Create context for comma insertion based on index and comma count.
--- @param index number The current word index.
--- @param comma_count number The number of commas already added.
--- @return table A table with context info for comma handling.
local function create_comma_context(index, comma_count)
  return {
    index = index,
    comma_chance = _config.comma_chance,
    comma_count = comma_count,
    max_commas = _config.max_commas,
  }
end

--- Check if a comma should be added to a sentence.
--- @param ctx table Context table containing comma-related info.
--- @return boolean Whether a comma should be inserted.
local function should_add_comma(ctx)
  local random_chance = math.random(100) <= (ctx.comma_chance * 100)
  local under_max = ctx.comma_count < ctx.max_commas
  return random_chance and under_max
end

--- Filter options based on a prefix.
--- @param options table A list of options to filter.
--- @param prefix string The prefix to filter by.
--- @return table Filtered options that match the prefix.
local function filter_opts(options, prefix)
  local filtered_opts = {}
  for _, opt in ipairs(options) do
    if opt:find("^" .. prefix) then
      table.insert(filtered_opts, opt)
    end
  end
  return filtered_opts
end

--- Provide autocomplete suggestions for the LoremIpsum command.
--- @param arg_lead string The argument lead string.
--- @param cmd_line string The entire command line.
--- @return table List of possible completion options.
local function format_completion(arg_lead, cmd_line)
  local complete_opts = {
    words = { "10", "20", "50", "100" },
    paragraphs = { "1", "2", "3", "5" },
  }

  local args = vim.split(cmd_line, "%s+")
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

--- Build a sentence with a specified number of words.
--- @param w_per_sentence number The number of words in the sentence.
--- @return string A generated sentence.
local function build_sentence(w_per_sentence)
  local s = {}
  local comma_count = 0

  for i = 1, w_per_sentence do
    local w = random_word()
    if i == 1 then
      w = capitalize(w)
    end

    local ctx = create_comma_context(i, comma_count)

    if i < w_per_sentence and should_add_comma(ctx) then
      w = w .. ","
      comma_count = comma_count + 1
    end

    table.insert(s, w)
  end

  return table.concat(s, " ") .. "."
end

--- Build a paragraph with a specified number of sentences.
--- @param w_per_sentence number Words per sentence.
--- @param s_per_paragraph number Sentences per paragraph.
--- @return string A generated paragraph.
local function build_paragraph(w_per_sentence, s_per_paragraph)
  local paragraph = {}
  for _ = 1, s_per_paragraph do
    table.insert(paragraph, build_sentence(w_per_sentence))
  end
  return table.concat(paragraph, " ")
end

--- Generate a block of text based on the specified format and configuration.
-- @param config table A table containing configuration options:
--   - format (string): The format of the text, either "words" or "paragraphs" (default is "words").
--   - amount (number): The number of words or paragraphs to generate.
--   - w_per_sentence (number, optional): Number of words per sentence. Defaults to a value from sentence_conf().
--   - s_per_paragraph (number, optional): Number of sentences per paragraph. Defaults to a value from sentence_conf().
-- @return string A generated block of text.
-- @error Invalid format if the format is not "words" or "paragraphs".

--- @class GenConfig
--- @field format string "words" or "paragraphs" (default is "words").
--- @field amount number Number of words or paragraphs to generate.
--- @field w_per_sentence number Optional. Words per sentence (default from sentence_conf()).
--- @field s_per_paragraph number Optional. Sentences per paragraph (default from sentence_conf()).

--- @param config GenConfig A table containing the configuration options for generating text.
--- @return string A block of generated text.
local function generate_text(config)
  local s_config = sentence_conf()

  -- Default values
  config.format = config.format or "words"
  config.amount = config.amount or 1
  config.w_per_sentence = config.w_per_sentence or s_config.words_per_sentence
  config.s_per_paragraph = config.s_per_paragraph or s_config.sentences_per_paragraph

  local result = {}
  local total_w_generated = 0

  -- Generate text based on format
  if config.format == "words" then
    while total_w_generated < config.amount do
      local w_to_generate = math.min(config.amount - total_w_generated, config.w_per_sentence)
      table.insert(result, build_sentence(w_to_generate))
      total_w_generated = total_w_generated + w_to_generate
    end
  elseif config.format == "paragraphs" then
    for _ = 1, config.amount do
      table.insert(result, build_paragraph(config.w_per_sentence, config.s_per_paragraph))
    end
  else
    error "Invalid format. Use 'words' or 'paragraphs'."
  end

  return table.concat(result, "\n\n")
end

--- Generate a specified number of words.
--- @param amount number The number of words to generate.
--- @return string The generated words.
function M.words(amount)
  local s_config = sentence_conf()
  local config = {
    format = "words",
    amount = amount or 100,
    w_per_sentence = s_config.w_per_sentence,
    s_per_paragraph = s_config.s_per_paragraph,
  }
  return generate_text(config)
end

--- Generate a specified number of paragraphs.
--- @param amount number The number of paragraphs to generate.
--- @return string The generated paragraphs.
function M.paragraphs(amount)
  local s_config = sentence_conf()
  local config = {
    format = "paragraphs",
    amount = amount or 1,
    w_per_sentence = s_config.w_per_sentence,
    s_per_paragraph = s_config.s_per_paragraph,
  }
  return generate_text(config)
end

--- Generate Custom Ipsum text based on given arguments.
--- @param args string The input arguments.
--- @return string The generated Ipsum text.
function M.ipsum(args)
  local parts = vim.split(args, "%s+")
  local config = {
    format = parts[1],
    amount = tonumber(parts[2]) or 100,
    w_per_sentence = tonumber(parts[3]) or _config.format_defaults.medium.words_per_sentence,
    s_per_paragraph = tonumber(parts[4]) or _config.format_defaults.medium.sentences_per_paragraph,
  }
  return generate_text(config)
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Command Handler Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Handle the LoremIpsum command to insert generated text into the buffer.
--- Calls the `ipsum` method if args[3] or args[4] are present for custom generation.
--- Otherwise calls `M.words` or `M.paragraphs`.
--- @param args table The arguments for the command.
local function handle_command(args)
  local format = args[1] -- "words" or "paragraphs"
  local amount = tonumber(args[2]) or 100 -- Default to 100 words or 1 paragraph.
  local w_per_sentence = tonumber(args[3]) -- Optional custom words per sentence.
  local s_per_paragraph = tonumber(args[4]) -- Optional custom sentences per paragraph.

  local result = ""

  -- If custom word/sentence configuration is provided (args[3] or args[4]), call ipsum method
  if w_per_sentence or s_per_paragraph then
    result = M.ipsum(table.concat(args, " ")) -- Pass all args to ipsum for custom text generation
  else
    -- Use default word or paragraph generation based on format
    if format == "words" then
      result = M.words(amount) -- Generate words
    elseif format == "paragraphs" then
      result = M.paragraphs(amount) -- Generate paragraphs
    else
      print "Invalid format. Use 'words' or 'paragraphs'."
      return
    end
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

--- @param opts table Command options.
api.nvim_create_user_command("LoremIpsum", function(opts)
  local args = vim.split(opts.args, " ")

  if #args < 2 then
    print "Invalid number of arguments. Usage: LoremIpsum <words|paragraphs> <amount>"
    return
  end

  handle_command(args)
end, {
  nargs = "+",
  complete = format_completion,
})

return M
