local M = {}

-- Search through a table of items using fzf
-- @param input: array of strings to search through
-- @param pattern: string to filter the items
function M.search_table(input, pattern)
  -- Write input to a temporary file
  local tmp_input = os.tmpname()
  local f = io.open(tmp_input, "w")
  for _, line in ipairs(input) do
    f:write(line .. "\n")
  end
  f:close()

  -- Run fzf using tmp file and read output
  local cmd = 'fzf --filter="' .. pattern .. '" < "' .. tmp_input .. '"'
  local handle = io.popen(cmd, "r")
  local result_str = handle:read("*a")
  handle:close()

  os.remove(tmp_input)

  -- Parse result into array
  local result = {}
  for line in result_str:gmatch("[^\r\n]+") do
    table.insert(result, line)
  end

  return result
end

return M
