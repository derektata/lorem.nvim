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
  local words = require "lorem.ipsum"
  local defaultLen = 100
  local output = ""

  if number == nil then
    for i = 1, defaultLen do
      output = output .. words()[i] .. " "
    end
  elseif number > 500 then
    while number > 500 do
      for i = 1, 500 do
        output = output .. words()[i] .. " "
      end
      number = number - 500
    end
    for i = 1, number do
      output = output .. words()[i] .. " "
    end
  else
    for i = 1, number do
      output = output .. words()[i] .. " "
    end
  end

  return output
end

-- TODO
-- source.complete = function(self, params, callback)
-- end

vim.api.nvim_create_user_command("LoremIpsum", function(opts)
  local number = tonumber(opts.args)
  vim.api.nvim_paste(source.gen_words(number), {}, -1)
end, { nargs = "*" })

return source
