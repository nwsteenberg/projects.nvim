local M = {}
local constants = require("projects.utils.constants")

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
