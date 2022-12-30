local lorem = require "lorem"

vim.api.nvim_create_user_command("LoremIpsum", function(opts)
	local number = tonumber(opts.args)
	vim.api.nvim_paste(lorem.gen_words(number), {}, -1)
end, { nargs = "*" })

-- require("cmp").register_source("lorem", lorem.new())
