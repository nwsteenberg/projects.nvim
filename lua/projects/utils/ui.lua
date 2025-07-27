local M = {}
local Namespace = vim.api.nvim_create_namespace('Projects')
local constants = require("projects.utils.constants")
local search = require("projects.utils.search")

-- NUI modules
local Menu = require("nui.menu")
local Input = require("nui.input")
local Layout = require("nui.layout")

function M.create_menu(projects)
  local items = {}
  for _, entry in ipairs(projects) do
    table.insert(items, Menu.item(entry))
  end

  return Menu(M.menu_options, {
    lines = items,
  })
end

function M.open_folder_from_menu(menu, options)
  local pos = vim.api.nvim_win_get_cursor(menu.winid)[1]
  local selected_project = vim.api.nvim_buf_get_lines(menu.bufnr, 0, -1, false)[pos]
  vim.cmd("cd " .. selected_project)
  -- Run function from config if specified:
  if options.on_open then
    options.on_open(selected_project)
  end

  print("Jumped to: " .. vim.fn.getcwd())
end

-- Setup layout
function M.open_dialogue(projects, options)
  local menu = M.create_menu(projects)

  -- Search input
  local search_input = Input(M.search_options, {
    prompt = constants.view_query_prompt,
    on_change = function(search_input)
      vim.schedule(function()
        if not menu.bufnr or not vim.api.nvim_buf_is_valid(menu.bufnr) then
          return
        end
        if menu.bufnr then
          -- The buffer needs to be modifiable to change its content
          vim.api.nvim_buf_set_option(menu.bufnr, "modifiable", true)

          -- Filter projects based on search input
          vim.api.nvim_buf_set_lines(menu.bufnr, 0, -1, false,
            search.search_table(projects, search_input))
          -- hightlight matches
          M.highlight_match(search_input, menu)

          -- Set unmodifiable to prevent further changes
          vim.api.nvim_buf_set_option(menu.bufnr, "modifiable", false)
        end
      end)
    end,
  })

  -- Layout
  local layout = Layout(
    {
      position = "50%",
      size = {
        width = "50%",
        height = "25%",
      },
    },
    Layout.Box({
      Layout.Box(menu, { size = "100%" }),
      Layout.Box(search_input, {
        size = {
          height = 1,
          width = "100%",
        }
      }),
    }, { dir = "col" })
  )

  -- Change keybinds
  -- close on esc
  search_input:map("n", "<Esc>", function()
    search_input:unmount()
  end, { noremap = true })
  -- next item in menu on j
  search_input:map("n", "j", function()
    local pos = vim.api.nvim_win_get_cursor(menu.winid)[1] + 1
    local max = #vim.api.nvim_buf_get_lines(menu.bufnr, 0, -1, false)
    if pos >= max then
      pos = max
    end
    vim.api.nvim_win_set_cursor(menu.winid, { pos, 0 })
  end, { noremap = true })
  -- prev item in menu on k
  search_input:map("n", "k", function()
    local pos = vim.api.nvim_win_get_cursor(menu.winid)[1] - 1
    if pos <= 1 then
      pos = 1
    end
    vim.api.nvim_win_set_cursor(menu.winid, { pos, 0 })
  end, { noremap = true })

  -- submit on CR both in normal and insert mode
  search_input:map("n", "<CR>", function()
    M.open_folder_from_menu(menu, options)
    search_input:unmount()
  end, { noremap = true })
  search_input:map("i", "<CR>", function()
    M.open_folder_from_menu(menu, options)
    search_input:unmount()
  end, { noremap = true })

  -- mount layout
  layout:mount()
end


-- Render menu highlighting
-- @param search: string to search for
-- @param menu: the menu object containing the buffer to highlight
function M.highlight_match(pattern, menu)
  local buf = menu.bufnr
  local ns_id = Namespace
  for i, item in ipairs(vim.api.nvim_buf_get_lines(menu.bufnr, 0, -1, false)) do
    local line = i - 1
    for j = 1, #item do
      local col_start = j - 1
      local col_end = j
      local ch = item:sub(j, j)
      if pattern:find(ch, 1, true) then
        -- Highlight match
        local hl_group = "Search" -- @TODO make this configurable from defaults. Get from config.lua
        vim.api.nvim_buf_set_extmark(buf, ns_id, line, col_start, { end_col = col_end, hl_group = hl_group })
      end
    end
  end
end

-- Default options for the menu
M.menu_options = {
  position = "50%",
  size = {
    height = "100%",
    width = "50%"
  },
  border = {
    style = "rounded",
    text = {
      top_align = "left",
      top = constants.view_results_title,
    },
  },
  win_options = {
    winhighlight = "Normal:Normal",
  },
}

-- Default options for the search input
M.search_options = {
  border = {
    style = "rounded",
    text = {
      top = constants.view_query_title,
      top_align = "left",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal",
  },
}
return M
