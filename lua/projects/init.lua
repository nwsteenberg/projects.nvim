local M = {}

local ui = require("projects.utils.ui")
local config = require("projects.utils.config")

function M.setup(options)
  -- Merge user options with defaults
  options = vim.tbl_deep_extend("force", config.defaults, options or {})

  -- If no directories defined then exit
  if options.directories == nil then
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

  local projects = {}
  for _, directory in ipairs(options.directories) do
    -- If directory is a string then add it directly
    if type(directory) == "string" then
      -- convert relative path to absolute path
      -- :p returns the absolute path and :h removes the last component
      local absolute = vim.fn.fnamemodify(directory, ":p:h")
      table.insert(projects, absolute)
    else
      -- If directory is a table then check for properties
      -- use find to get all directories
      local find_result = io.popen('find ' .. directory.dir .. ' -maxdepth ' .. directory.search_depth .. ' -type d')
      if find_result == nil then
        do return end
      end
      -- Populate projects table with found directories
      for project in find_result:lines() do
        repeat
          -- Dont add hidden files if flag is provided
          if directory.ignore_hidden and is_dir_hidden(project) then
            do break end
          end
          -- :p returns the absolute path and :h removes the last component
          local absolute = vim.fn.fnamemodify(directory.dir, ":p:h")
          if directory.ignore_parent and project == absolute then
            do break end
          end
          table.insert(projects, project)
        until true
      end
    end
  end
  -- Create user commands
  vim.api.nvim_create_user_command(
    "ProjectsOpen",
    function()
      ui.open_dialogue(projects, options)
    end, {})
end

return M
