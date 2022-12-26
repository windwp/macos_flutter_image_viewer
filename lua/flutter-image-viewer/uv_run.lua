local uv = vim.loop
local M = {}
M.uv_run = function(cmd, args, cwd, action)
    action = action or function() end
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local function handler(_, data)
        if data then
            data = vim.split(data, '\n')
            if #data == 2 then
                data = data[1]
            end
            action(data)
        end
    end

    uv.spawn(
        cmd,
        {
            args = args,
            cwd = cwd or vim.loop.cwd(),
            stdio = { nil, stdout, stderr, },
        },
        vim.schedule_wrap(function()
            stderr:close()
            stdout:close()
        end)
    )
    stdout:read_start(vim.schedule_wrap(handler))
    stderr:read_start(vim.schedule_wrap(function(_, data)
        if data then
            action(data, true)
        else
            action(data, false)
        end
    end))
end

return M
