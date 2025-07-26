local M = {}
local Layout = require("nui.layout")
local Namespace = vim.api.nvim_create_namespace('Projects')

-- Render menu highlighting
function M.highlight_match(search, menu)
  local buf = menu.bufnr
  local ns_id = Namespace
  for i, item in ipairs(vim.api.nvim_buf_get_lines(menu.bufnr, 0, -1, false)) do
    local line = i - 1
    for j = 1, #item do
      local col_start = j - 1
      local col_end = j
      local ch = item:sub(j, j)
      if search:find(ch, 1, true) then
        -- Highlight match
        vim.api.nvim_buf_set_extmark(buf, ns_id, line, col_start, { end_col = col_end, hl_group = "Character" })
      end
    end
  end
end


return M
