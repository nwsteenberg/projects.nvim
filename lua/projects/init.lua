local M = {}
local ui = require("projects.utils.ui")
local search = require("projects.utils.search")
local config = require("projects.utils.config")
local constants = require("projects.utils.constants")
local keymaps = require("projects.utils.keymaps")

local Menu = require("nui.menu")
local Input = require("nui.input")
local Text = require("nui.text")
local Layout = require("nui.layout")

function M.merge_text_nodes(...)
  local final = Text("", "")
  local nodes = { ... }

  for _, node in ipairs(nodes) do
    if not type(node) == "string" then
      for _, chunk in ipairs(node:content()) do
        local value = chunk[1]
        local hl = chunk[2]
        -- Reconstruct each chunk into the final node
        table.insert(final._content, { value, hl }) -- direct insert
      end
    else
      table.insert(final._content, { Text(node, "") })
    end
  end

  return final
end

function M.open_folder_from_menu(menu)
  local pos = vim.api.nvim_win_get_cursor(menu.winid)[1]
  local selected_project = vim.api.nvim_buf_get_lines(menu.bufnr, 0, -1, false)[pos]
  vim.cmd("cd " .. selected_project)
  print(vim.fn.getcwd())
end

function M.open_dialogue(projects)
  -- Projects menu
  local menu = Menu(config.menu_options, {
    lines = projects,
  })

  -- Search input
  local search_input = Input(config.search_options, {
    prompt = constants.view_query_prompt,
    on_change = function(value)
      vim.schedule(function()
        if not menu.bufnr or not vim.api.nvim_buf_is_valid(menu.bufnr) then
          return
        end
        if menu.bufnr then
          -- The buffer needs to be modifiable to change its content
          vim.api.nvim_buf_set_option(menu.bufnr, "modifiable", true)
          vim.api.nvim_buf_set_lines(menu.bufnr, 0, -1, false, search.search_table(projects, value))
          -- render text
          ui.highlight_match(value, menu)
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
  -- unmount input by pressing `<Esc>` in normal mode
  search_input:map("n", "<Esc>", function()
    search_input:unmount()
  end, { noremap = true })
  search_input:map("n", "j", function()
    local pos = vim.api.nvim_win_get_cursor(menu.winid)[1] + 1
    local max = #vim.api.nvim_buf_get_lines(menu.bufnr, 0, -1, false)
    if pos >= max then
      pos = max
    end
    vim.api.nvim_win_set_cursor(menu.winid, { pos, 0 })
  end, { noremap = true })
  search_input:map("n", "k", function()
    local pos = vim.api.nvim_win_get_cursor(menu.winid)[1] - 1
    if pos <= 1 then
      pos = 1
    end
    print(pos)
    vim.api.nvim_win_set_cursor(menu.winid, { pos, 0 })
  end, { noremap = true })
  -- submit
  search_input:map("n", "<CR>", function()
    M.open_folder_from_menu(menu)
    search_input:unmount()
  end, { noremap = true })
  search_input:map("i", "<CR>", function()
    M.open_folder_from_menu(menu)
    search_input:unmount()
  end, { noremap = true })

  -- mount layout
  layout:mount()
end

function M.setup(opts)
  opts = opts or {}
  -- Read options (Which folders to search for)
  -- @TODO fix options. Move over to config.lua
  local directories = opts.directories
  local depth = opts.depth or 1
  local ignore_hidden = opts.ignore_hidden or true
  local skip_parent = opts.skip_parent or true
  -- If no directories defined then exit
  if directories == nil then
    do return end
  end

  -- Check if file/directory starts with . (is hidden)
  local function is_dir_hidden(path)
    local basename = vim.fs.basename(path)
    if basename:sub(1, #".") == "." then
      return true
    end
    return false
  end
  -- use find to get all directories
  local projects = {}
  for _, directory in ipairs(directories) do
    local find_result = io.popen('find ' .. directory .. ' -maxdepth ' .. depth .. ' -type d')
    if find_result == nil then
      do return end
    end

    -- Populate projects table with found directories
    for project in find_result:lines() do
      repeat
        -- Dont add hidden files if flag is provided
        if ignore_hidden and is_dir_hidden(project) then
          do break end
        end
        -- print(project .. ":" .. directory)
        if skip_parent and project == directory then
          do break end
        end
        table.insert(projects, Menu.item(project))
      until true
    end
  end
  -- Create user commands
  vim.api.nvim_create_user_command(
    "ProjectsOpen",
    function()
      M.open_dialogue(projects)
    end, {})
end

return M
