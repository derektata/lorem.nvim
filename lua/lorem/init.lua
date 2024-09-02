-- @module lorem
local M = {}

-- Default configuration
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

--@param user_config table
--@return nil
function M.setup(user_config)
  if user_config then
    _config = vim.tbl_deep_extend("force", _config, user_config)
  end
  M.create_command()
end

-- Load the words from ipsum.lua
local ipsum_words = require "lorem.ipsum"()

--@return string
local function random_word()
  return ipsum_words[math.random(#ipsum_words)]
end

--@param word string
--@return string
local function capitalize(word)
  return word:sub(1, 1):upper() .. word:sub(2)
end

--@param words_per_sentence number
--@param comma_chance number
--@param max_commas number
--@return string
local function generate_sentence(words_per_sentence, comma_chance, max_commas)
  local sentence = {}
  local comma_count = 0
  local words_until_comma = math.floor(words_per_sentence / (max_commas + 1))

  for i = 1, words_per_sentence do
    local word = random_word()
    if i == 1 then
      word = capitalize(word)
    end

    -- Insert comma if conditions are met
    if i % words_until_comma == 0 and comma_count < max_commas then
      word = word .. ","
      comma_count = comma_count + 1
    end

    table.insert(sentence, word)
  end

  return table.concat(sentence, " ") .. "."
end

--@param sentences_per_paragraph number
--@param words_per_sentence number
--@param comma_chance number
--@param max_commas number
--@return string
local function generate_paragraph(sentences_per_paragraph, words_per_sentence, comma_chance, max_commas)
  local paragraph = {}
  for _ = 1, sentences_per_paragraph do
    table.insert(paragraph, generate_sentence(words_per_sentence, comma_chance, max_commas))
  end
  return table.concat(paragraph, " ")
end

--@return table
local function get_sentence_config()
  if type(_config.sentenceLength) == "string" then
    return _config.format_defaults[_config.sentenceLength] or _config.format_defaults["medium"]
  elseif type(_config.sentenceLength) == "table" then
    return _config.sentenceLength
  else
    error "Invalid sentenceLength configuration."
  end
end

--@param number number
--@param format string
--@param words_per_sentence number
--@param sentences_per_paragraph number
--@param comma_chance number
--@param max_commas number
--@return string
function M.generate_lorem_ipsum(number, format, words_per_sentence, sentences_per_paragraph, comma_chance, max_commas)
  local result = {}

  if format == "words" then
    -- Generate enough sentences to cover the number of words requested
    local total_words_generated = 0
    while total_words_generated < number do
      local words_remaining = number - total_words_generated
      local words_to_generate = math.min(words_remaining, words_per_sentence)
      local sentence = generate_sentence(words_to_generate, comma_chance, max_commas)
      table.insert(result, sentence)
      total_words_generated = total_words_generated + words_to_generate
    end
    return table.concat(result, " ")
  elseif format == "paragraphs" then
    for _ = 1, number do
      table.insert(result, generate_paragraph(sentences_per_paragraph, words_per_sentence, comma_chance, max_commas))
    end
    return table.concat(result, "\n\n")
  else
    error "Invalid format. Use 'words' or 'paragraphs'."
  end
end

--@param number number
--@return string
function M.gen_words(number)
  number = number or 100
  local format = "words"

  -- Get the sentence length configuration
  local sentence_config = get_sentence_config()

  -- Use custom values if provided, otherwise use the defaults
  local words_per_sentence = sentence_config.words_per_sentence
  local sentences_per_paragraph = sentence_config.sentences_per_paragraph
  local comma_chance = _config.comma_chance
  local max_commas = _config.max_commas_per_sentence

  return M.generate_lorem_ipsum(number, format, words_per_sentence, sentences_per_paragraph, comma_chance, max_commas)
end

--- Filter options based on a prefix.
-- @param options table<string>: The list of options to filter.
-- @param prefix string: The prefix to filter by.
-- @return table<string>: The filtered options.
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
-- @param arg_lead string: The leading part of the current argument.
-- @param cmd_line string: The entire command line.
-- @param cursor_pos number: The position of the cursor in the command line.
-- @return table<string>: A list of suggestions based on the input.
function M.format_completion(arg_lead, cmd_line, cursor_pos)
  local args = vim.split(cmd_line, "%s+")
  if #args == 2 then
    return filter_opts({ "words", "paragraphs" }, arg_lead)
  elseif #args == 3 then
    local textType = args[2]
    local options = {
      words = { "10", "20", "50", "100" },
      paragraphs = { "1", "2", "3", "5" },
    }
    return filter_opts(options[textType] or {}, arg_lead)
  end
end

--- Create the "LoremIpsum" user command.
-- @param opts table: The options table provided by Neovim for user commands.
-- @return nil
vim.api.nvim_create_user_command("LoremIpsum", function(opts)
  local args = vim.split(opts.args, " ")

  -- Ensure there are at least 2 arguments
  if #args < 2 then
    print "Invalid number of arguments. Usage: LoremIpsum <words|paragraphs> amount>"
    return
  end

  local format = args[1] or "words"
  local number = tonumber(args[2]) or 100

  -- Validate format
  if format ~= "words" and format ~= "paragraphs" then
    error "Invalid format. Use 'words' or 'paragraphs'."
  end

  -- Get the sentence length configuration
  local sentence_config = get_sentence_config()

  -- Use custom values if provided, otherwise use the defaults
  local words_per_sentence = sentence_config.words_per_sentence
  local sentences_per_paragraph = sentence_config.sentences_per_paragraph
  local comma_chance = _config.comma_chance
  local max_commas = _config.max_commas_per_sentence

  local text =
    M.generate_lorem_ipsum(number, format, words_per_sentence, sentences_per_paragraph, comma_chance, max_commas)
  local lines = vim.split(text, "\n")

  -- Get the current buffer
  local buf = vim.api.nvim_get_current_buf()
  -- Get the current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Insert the text at the current cursor position
  vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, lines)
end, {
  nargs = "+",
  complete = M.format_completion,
})
