local source = {}
local _config = { sentenceLength = "mixedShort", comma = 0.1 }

local sentenceLengths = {
  mixed = { 3, 100 },
  mixedLong = { 30, 100 },
  mixedShort = { 1, 30 },
  long = { 40, 60 },
  medium = { 20, 40 },
  short = { 1, 20 },
}

-- Initialize the pseudo random number generator
math.randomseed(os.time())
math.random()
math.random()
math.random()

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

source.setup = function(config)
  _config = config
end

source.get_trigger_characters = function()
  return { "lorem" }
end

source.get_keyword_pattern = function()
  return "^lorem%s+(%d+)$"
end

source.gen_sentence = function(length)
  local words = require "lorem.ipsum"()

  local output = ""

  -- Index of the last comma added to the sentence
  local lastComma = 0
  for i = 1, length do
    output = output .. words[math.random(1, #words)] .. " "

    if (i - lastComma) > 2 and _config["comma"] and math.random() < _config["comma"] then
      output = output:sub(1, -2) .. ", "
      lastComma = i
    end
  end

  -- Format by:
  --	Capitalizing the first letter of the string
  --	Removing the last space
  --	Add a dot
  output = (output:gsub("^%l", string.upper))
  output = output:sub(1, -2) .. "."

  return output
end

source.gen_words = function(length)
  if length == nil then
    length = 100
  end

  local bounds = sentenceLengths[_config["sentenceLength"]]

  local lowerBound = bounds[1]
  local upperBound = bounds[2]

  local text = ""
  local textLength = 0

  while (textLength + upperBound) <= length do
    text = text .. source.gen_sentence(math.random(lowerBound, upperBound)) .. " "
    -- Counting the number of words
    _, textLength = text:gsub("%S+", "")
  end

  local remainingSpace = length - textLength
  if remainingSpace > 0 then
    if remainingSpace < lowerBound then
      -- Generate exactly the number of words needed
      for i = 1, remainingSpace do
        text = text .. require("lorem.ipsum")()[math.random(1, #require("lorem.ipsum")())] .. " "
      end
      text = text:sub(1, -2) .. "."
    else
      text = text .. source.gen_sentence(remainingSpace)
    end
  end

  return text
end

-- TODO
-- source.complete = function(self, params, callback)
-- end

return source
