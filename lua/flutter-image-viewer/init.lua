local M = {}
local uv_run = require("flutter-image-viewer.uv_run").uv_run
local uv = vim.loop

local path_join = function(tbl)
  local os_name = vim.loop.os_uname().sysname
  local path_sep = os_name == 'Windows' and '\\' or '/'
  for index, value in ipairs(tbl) do
    tbl[index] = value:gsub('%/', path_sep)
  end
  return table.concat(tbl, path_sep)
end

local default_config = {
  window = {
    x = 2,
    y = 2,
    width = 600,
    height = 400,
    backgroundColor = "#000000",
  },
  time_hide = 3000, -- time to hide process
  youtube = true,
  autocmd = {
    enable = true,
    filetypes = { "markdown" },
    extensions = { "png", "jpg", "mp4" }
  }
}

M.base_directory = ""
M.config = {}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', default_config, opts)
  local sourced_file = require('plenary.debug_utils').sourced_filepath()
  M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h:h")
  if vim.loop.os_uname().sysname == "Darwin" then
    M.config.youtube = false
  end
  if M.config.autocmd.enable then
    vim.api.nvim_create_autocmd("Filetype", {
      pattern = M.config.autocmd.filetypes,
      callback = function()
        M.auto_cmd_filetype()
      end
    })
  end
end

local timer = nil
local last_image = ""

local function debounce(timeout, callback)
  if timer then return end
  timer = uv.new_timer()
  timer:start(timeout, 0, function()
    timer:stop()
    timer = nil
    callback()
  end)
end

local is_show = false
local show_media = function(media, opts)
  if last_image == media then return end
  is_show = true
  opts = opts or {}
  last_image = media
  local window = vim.tbl_extend('force', M.config.window, opts.window or {})
  print(vim.inspect(window.backgroundColor))
  uv_run(
    path_join({ M.base_directory, "main.py" }), {
      "update",
      media,
      window.x,
      window.y,
      window.width,
      window.height,
      window.backgroundColor
    },
    M.base_directory,
    function() end
  )
end

M.auto_cmd_filetype = function()
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = vim.api.nvim_create_augroup("flutter_image_viewer", { clear = true }),
    callback = function()
      local path = M.get_current_line_path()
      if path then
        show_media(path)
      elseif last_image ~= "" then
        debounce(M.config.time_hide, M.kill)
      end
    end,
    buffer = vim.api.nvim_get_current_buf()
  })
end

local get_file_extension = function(filename)
  local parts = vim.split(filename, "%.")
  return parts[#parts]
end

M.get_current_line_path = function()
  local line = vim.api.nvim_get_current_line()
  local inline_link = line:match('!%[.-%]%(.-%)')
  if inline_link then
    local source = inline_link:match('%((.+)%)')
    if M.config.youtube and source:match('^http.*youtube') then
      return source
    end
    if source then
      local extension = get_file_extension(source)
      if not vim.tbl_contains(M.config.autocmd.extensions, extension) then
        return
      end
      local path = path_join({ vim.loop.cwd(), source })
      if string.sub(source, 1, 1) == "/" then
        path = source
      end

      if string.sub(source, 1, 2) == "./" then
        path = path_join({ vim.loop.cwd(), string.sub(source, 3) })
      end
      if vim.fn.filereadable(path) then
        return path
      end
    end
  end
end

M.show = function(media, opts)
  show_media(media, opts)
  debounce(M.config.time_hide, M.kill)
end

M.toggle = function()
  if is_show then
    M.kill()
    return
  end
  local path = M.get_current_line_path()
  if path then
    show_media(path)
  end
end

M.kill = function()
  if last_image ~= "" then
    uv_run(path_join({ M.base_directory, "main.py" }), { "kill" }, M.base_directory)
  end
  last_image = ""
  is_show = false
end


return M
