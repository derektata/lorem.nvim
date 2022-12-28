local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

source.get_trigger_characters = function()
  return { "lorem" }
end

source.get_keyword_pattern = function()
  return "^lorem%s+(%d+)$"
end

source.gen_words = function(number)
  local words = require "lorem.ipsum" ()
  local length = 100

  if number ~= nil then
    length = number
  end

  local output = ""

  -- Initialize the pseudo random number generator
  math.randomseed( os.time() )
  math.random(); math.random(); math.random()

  for i = 1, length do
    output = output .. words[math.random(1, #words)] .. " "
  end

  return output
end

-- TODO
-- source.complete = function(self, params, callback)
-- end

return source
