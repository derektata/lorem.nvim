
local vim = vim
local cmd = vim.cmd
local key = vim.api.nvim_set_keymap

local function setup()
  -- This activates the prompt in normal mode
  key('n', 'LI', ':Loremipsum ', {})

  -- This asks the user how many words to insert while in insert mode
  key('i', 'lorem', '<Esc>:Loremipsum ', {})

  -- This prints a paragraph in insert mode
  -- key('i', 'lorem', '<Esc>:lua require"lorem-nvim".lorem()<CR>', {})
end

local function lorem()
  cmd [[
    Loremipsum
  ]]
end

return {
  setup = setup,
  lorem = lorem
}
