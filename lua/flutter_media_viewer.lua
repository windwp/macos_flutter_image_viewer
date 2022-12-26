local M = {}
local Job = require "plenary.job"

local default_config = {
  x = 1,
  y = 1,
  width = 600,
  height = 400
}
M.base_directory = ""
M.config = {}


M.setup = function(opts)
  M.config = vim.tbl_extend('force', default_config, opts)
  local sourced_file = require('plenary.debug_utils').sourced_filepath()
  M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h:h:h")
end

M.show = function(opts)
  local pos = vim.tbl_extend('force', M.config, opts)

end


return M
