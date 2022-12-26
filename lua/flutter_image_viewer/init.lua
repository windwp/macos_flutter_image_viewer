local M = {}
local uv_run = require("flutter_image_viewer.uv_run").uv_run

local default_config = {
    x = 2,
    y = 2,
    width = 601,
    height = 401
}
M.base_directory = ""
M.config = {}


M.setup = function(opts)
    M.config = vim.tbl_extend('force', default_config, opts)
    local sourced_file = require('plenary.debug_utils').sourced_filepath()
    M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h:h:h")
    print(vim.inspect(M.base_directory))
end

M.show = function(media, opts)
    local pos = vim.tbl_extend('force', M.config, opts.pos or {})
    uv_run(
        M.base_directory .. "/main.py", {
            media,
            pos.x,
            pos.y,
            pos.width,
            pos.height,
        },
        M.base_directory,
        function() end
    )

end


return M
