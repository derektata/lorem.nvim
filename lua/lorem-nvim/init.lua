
local vim = vim
local cmd = vim.cmd
local key = vim.api.nvim_set_keymap

local function setup()
  key('n', 'LI', ':Loremipsum ', {})
  key('i', 'lorem', '<Esc>:lua require"lorem-nvim".lorem()<CR>', {})
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
