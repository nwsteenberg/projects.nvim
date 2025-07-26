local M = {}

function M.search_table(input, pattern)
  -- Step 1: Extract .text values
  local lines = {}
  for _, item in ipairs(input) do
    table.insert(lines, item.text)
  end

  -- Step 2: Write input to a temporary file
  local tmp_input = os.tmpname()
  local f = io.open(tmp_input, "w")
  for _, line in ipairs(lines) do
    f:write(line .. "\n")
  end
  f:close()

  -- Step 3: Run fzf with --filter and read output
  local cmd = 'fzf --filter="' .. pattern .. '" < "' .. tmp_input .. '"'
  local handle = io.popen(cmd, "r")
  local result_str = handle:read("*a")
  handle:close()

  -- Step 4: Clean up temp file
  os.remove(tmp_input)

  -- Step 5: Parse result into array
  local result = {}
  for line in result_str:gmatch("[^\r\n]+") do
    table.insert(result, line)
  end

  return result
end

return M
