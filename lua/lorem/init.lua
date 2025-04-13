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

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Configuration Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Configuration table for sentence and paragraph generation.
--- @class Config
--- @field sentence_length string|table Specifies the sentence length format.
--- @field comma_chance number Probability of adding a comma in a sentence.
--- @field max_commas number Maximum number of commas allowed in a sentence.
--- @field format_defaults table Predefined formats for sentence and paragraph structure.
--- @field mappings table List of keys to map for text generation.

--- Default configuration
local _config = {
  sentence_length = "medium", -- default sentence length
  comma_chance = 0.2, -- default 20% chance to insert a comma
  max_commas = 2, -- default maximum number of commas per sentence
  format_defaults = {
    short = { w_per_sentence = 5, s_per_paragraph = 3 },
    medium = { w_per_sentence = 10, s_per_paragraph = 5 },
    long = { w_per_sentence = 14, s_per_paragraph = 7 },
    mixedShort = { w_per_sentence = 8, s_per_paragraph = 4 },
    mixed = { w_per_sentence = 12, s_per_paragraph = 6 },
    mixedLong = { w_per_sentence = 16, s_per_paragraph = 8 },
  },
  mappings = { "<Space>" }, -- default key mapping; add more keys if desired
}

--- @module lorem
local M = {}

--- Override default configurations with user-provided settings.
--- @param user_config Config Configuration table with user-specific overrides.
function M.opts(user_config)
  if user_config then
    _config = vim.tbl_deep_extend("force", _config, user_config)
  end
end

--- Retrieve sentence configuration based on current settings.
--- @return table Configuration table for sentence length and paragraph structure.
local function sentence_conf()
  local sentence_length = _config.sentence_length
  if type(sentence_length) == "string" then
    return _config.format_defaults[sentence_length] or _config.format_defaults["medium"]
  elseif type(sentence_length) == "table" then
    return sentence_length
  else
    error("Invalid sentence_length configuration. Expected a string or table, got: " .. type(sentence_length))
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

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Text Generation Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

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

--- Build sentences based on a count and sentence generation function.
--- @param count number Number of sentences to build.
--- @param generator function A function to generate a sentence.
--- @return table A list of generated sentences.
local function build_sentences(count, generator)
  local sentences = {}
  for _ = 1, count do
    table.insert(sentences, generator())
  end
  return sentences
end

--- Build a paragraph with a specified number of sentences.
--- @param w_per_sentence number Words per sentence.
--- @param s_per_paragraph number Sentences per paragraph.
--- @return string A generated paragraph.
local function build_paragraph(w_per_sentence, s_per_paragraph)
  return table.concat(
    build_sentences(s_per_paragraph, function()
      return build_sentence(w_per_sentence)
    end),
    " "
  )
end

--- Get configuration for text generation.
--- @param config table User-provided config or nil.
--- @return table Merged config with defaults.
local function get_config(config)
  local s_config = sentence_conf()
  config.format = config.format or "words"
  config.amount = config.amount or 1
  config.w_per_sentence = config.w_per_sentence or s_config.w_per_sentence
  config.s_per_paragraph = config.s_per_paragraph or s_config.s_per_paragraph
  return config
end

--- Generate a block of text based on the specified format and configuration.
--- @param config table A table containing configuration options:
---   - format (string): The format of the text, either "words" or "paragraphs" (default is "words").
---   - amount (number): The number of words or paragraphs to generate.
---   - w_per_sentence (number, optional): Number of words per sentence. Defaults to a value from sentence_conf().
---   - s_per_paragraph (number, optional): Number of sentences per paragraph. Defaults to a value from sentence_conf().
--- @return string A generated block of text.
--- @error Invalid format if the format is not "words" or "paragraphs".
local function generate_text(config)
  config = get_config(config)
  local result = {}
  local total_w_generated = 0

  if config.format == "words" then
    -- Generate words until the word limit is reached
    while total_w_generated < config.amount do
      local w_to_generate = math.min(config.amount - total_w_generated, config.w_per_sentence)
      table.insert(result, build_sentence(w_to_generate))
      total_w_generated = total_w_generated + w_to_generate
    end
    -- Return continuous text with no newlines between sentences
    return table.concat(result, " ")
  elseif config.format == "paragraphs" then
    -- Generate paragraphs with sentences and add newlines between paragraphs
    for _ = 1, config.amount do
      table.insert(result, build_paragraph(config.w_per_sentence, config.s_per_paragraph))
    end
    -- Return text with paragraphs separated by newlines
    return table.concat(result, "\n\n")
  else
    error "Invalid format. Use 'words' or 'paragraphs'."
  end
end

--- Generate a specified number of words while building sentences.
--- @param amount number The number of words to generate.
--- @return string The generated words.
function M.words(amount)
  local config = {
    format = "words",
    amount = amount or 100,
  }
  return generate_text(config)
end

--- Generate a specified number of paragraphs.
--- @param amount number The number of paragraphs to generate.
--- @return string The generated paragraphs.
function M.paragraphs(amount)
  local config = {
    format = "paragraphs",
    amount = amount or 1,
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
    w_per_sentence = tonumber(parts[3]) or _config.format_defaults.medium.w_per_sentence,
    s_per_paragraph = tonumber(parts[4]) or _config.format_defaults.medium.s_per_paragraph,
  }
  return generate_text(config)
end

-- Custom Ipsum
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--      :LoremIpsum  paragraphs  1  10  5
--                        ┃      ┃   ┃  ┃
--          format━━━━━━━━┛      ┃   ┃  ┃
--                               ┃   ┃  ┃
--          amount━━━━━━━━━━━━━━━┛   ┃  ┃
--                                   ┃  ┃
--  w_per_sentence━━━━━━━━━━━━━━━━━━━┛  ┃
--                                      ┃
-- s_per_paragraph━━━━━━━━━━━━━━━━━━━━━━┛

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Command Handler Section  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--- Helper function to insert text into the current buffer.
--- @param text string The text to insert.
local function insert_text(text)
  local lines = vim.split(text, "\n")
  local buf = api.nvim_get_current_buf()
  local row, col = unpack(api.nvim_win_get_cursor(0))
  api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, lines)
end

--- Extract the number and format from the input line.
--- @param line string The line to extract from.
--- @return number|nil, string|nil The number and format, or nil if invalid.
local function get_num_fmt(line)
  local num_str, fmt = line:match "lorem(%d+)(p?)$"
  return tonumber(num_str), fmt
end

--- Check if the number is valid.
--- @param num number The number to check.
--- @return boolean Whether the number is valid.
local function is_valid_num(num)
  if not num or num <= 0 then
    vim.notify("Please provide a positive number.", vim.log.levels.ERROR)
    return false
  elseif num > 1000 then
    vim.notify("Number too large. Max allowed is 1000.", vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Replace the trigger pattern in the current line with generated text.
--- @param line string The current line.
--- @param row number The current row.
--- @param text string The text to insert.
local function replace_text(line, row, text)
  local start_idx, end_idx = line:find "lorem%d+p?$"
  if start_idx and end_idx then
    local lines = vim.split(text, "\n")
    vim.api.nvim_buf_set_text(0, row - 1, start_idx - 1, row - 1, end_idx, lines)
  end
end

--- Handle the keyword trigger to generate and replace text.
local function on_keyword()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Get number and format
  local num, fmt = get_num_fmt(line)
  if not num then
    vim.notify("Invalid format. Use 'lorem<amount>' or 'lorem<amount>p'.", vim.log.levels.WARN)
    return
  end

  -- Validate number
  if not is_valid_num(num) then
    return
  end

  -- Generate and replace text
  local gen_text = fmt == "p" and M.paragraphs(num) or M.words(num)
  replace_text(line, row, gen_text)
end

--- Function to check the current line and perform actions based on patterns
--- @param key string The key that was pressed.
local function check_line(key)
  local line = vim.api.nvim_get_current_line()

  -- Pattern to match 'lorem' followed by digits and optional 'p' at the end
  if line:match "lorem%d+p?$" then
    on_keyword()
  else
    -- If not a trigger pattern, insert the key normally
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), "n", true)
  end
end

--- Function to map a single key in insert mode
--- @param key string The key to map.
local function map_key(key)
  vim.keymap.set("i", key, function()
    check_line(key)
  end, { buffer = true })
end

--- Function to setup all key mappings
local function setup()
  for _, key in ipairs(_config.mappings) do
    map_key(key)
  end
end

--- Handle the LoremIpsum command to insert generated text into the buffer.
--- @param args table The arguments for the command.
local function handle_command(args)
  local format = args[1]
  local amount = tonumber(args[2]) or 100

  if args[3] or args[4] then
    local result = M.ipsum(table.concat(args, " "))
    insert_text(result)
  else
    local result = format == "words" and M.words(amount) or M.paragraphs(amount)
    insert_text(result)
  end
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃  Command and Autocommand Setup  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
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
--
-- Create the LoremIpsum command with autocomplete
api.nvim_create_user_command("LoremIpsum", function(opts)
  local args = vim.split(opts.args, " ")

  if #args < 2 then
    vim.notify("Invalid number of arguments. Usage: LoremIpsum <words|paragraphs> <amount>", vim.log.levels.ERROR)
    return
  end

  handle_command(args)
end, {
  nargs = "+",
  complete = format_completion,
})

-- Setup key mappings on buffer enter
api.nvim_create_autocmd("BufEnter", {
  callback = function()
    setup()
  end,
})

return M
