local M = {}

-- default values for projects.nvim
M.defaults = {
  -- directories to search for projects
  directories = {
    {
      dir = "~/development",
      ignore_hidden = true,
      ignore_parent = true,
      search_depth = 1,
    },
  },

  -- specify a custom function to run on project selection
  on_open = function(project)
    vim.cmd(":Neotree")
  end,

  -- highlight group matched characters
  layout = {
    highlight_group = "Character",
  }
}

return M
