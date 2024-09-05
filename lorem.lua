local lorem = require "lorem"

-- Function to print usage and exit
local function exit_with_error(message)
  print(message)
  os.exit(1)
end

-- Check for arguments
if not _G.arg[1] or not _G.arg[2] then
  exit_with_error "Usage: nvim -l lorem.lua [-w|--words] AMOUNT [-p|--paragraphs] AMOUNT"
end

-- Process arguments
local format, amount = _G.arg[1], tonumber(_G.arg[2])

-- Check if the amount is valid
if not amount then
  exit_with_error "Error: AMOUNT must be a number."
end

-- Create a table mapping format flags to respective functions
local format_map = {
  ["-w"] = lorem.words,
  ["--words"] = lorem.words,
  ["-p"] = lorem.paragraphs,
  ["--paragraphs"] = lorem.paragraphs,
}

-- Use the table to get the correct function
local generate_lorem = format_map[format]

-- Check if the function exists and call it
if generate_lorem then
  print(generate_lorem(amount))
else
  exit_with_error "Error: Invalid format. Use -w for words or -p for paragraphs."
end
