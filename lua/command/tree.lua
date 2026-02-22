vim.api.nvim_create_user_command('Tree', function(opts)
    local path = opts.args
    local target_path = path == "" and "." or path
    local cmd = string.format("fd . %s | tree -F --fromfile --noreport", vim.fn.shellescape(target_path))

    -- 1. 浮窗设置
    local width = math.ceil(vim.o.columns * 0.8)
    local height = math.ceil(vim.o.lines * 0.8)
    local row = math.ceil((vim.o.lines - height) / 2 - 1)
    local col = math.ceil((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "⏳ 正在拼命扫描 [" .. target_path .. "] 的目录树..." })

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' Directory Tree ',
        title_pos = 'center',
    })

    vim.bo[buf].buftype = "nofile"
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, silent = true, desc = '关闭浮窗' })

    -- 2. 语法高亮
    vim.bo[buf].filetype = "mytree"
    vim.api.nvim_buf_call(buf, function()
        vim.cmd([[syntax match TreeLines /^[ │├─└]\+/]])
        vim.cmd([[highlight default link TreeLines Comment]])
        vim.cmd([[syntax match TreeDir /[^ │├─└].*\/$/]])
        vim.cmd([[highlight default link TreeDir Directory]])
        vim.cmd([[syntax match TreeExt /\.\w\+$/]])
        vim.cmd([[highlight default link TreeExt Type]])
        vim.cmd([[syntax match TreeExec /[^ │├─└].*\*$/]])
        vim.cmd([[highlight default link TreeExec String]])
    end)

    -- ==========================================
    -- 🧠 模块化：提取“获取光标所在文件路径”的核心逻辑
    -- ==========================================
    local function get_filepath_under_cursor()
        local lnum = vim.fn.line('.')
        local lines = vim.api.nvim_buf_get_lines(buf, 0, lnum, false)
        if #lines == 0 then return nil end

        local path_parts = {}
        local target_depth = -1

        for i = #lines, 1, -1 do
            local line = lines[i]
            local prefix_end = vim.fn.matchend(line, "^[ │├─└]*")
            local prefix = string.sub(line, 1, prefix_end)
            local raw_name = string.sub(line, prefix_end + 1)

            local name = raw_name:gsub("[/*=>|]$", "")
            if name == "" then goto continue end

            local depth = math.floor(vim.fn.strdisplaywidth(prefix) / 4)

            if target_depth == -1 then target_depth = depth end

            if depth == target_depth then
                table.insert(path_parts, 1, name)
                target_depth = target_depth - 1
            end
            ::continue::
        end

        local full_path = table.concat(path_parts, "/")
        if full_path == "" or full_path == "." or full_path == target_path then return nil end
        return full_path
    end

    -- ==========================================
    -- 🚀 终极武器：各种花式打开文件的快捷键
    -- ==========================================
    local function open_file(open_cmd)
        local full_path = get_filepath_under_cursor()
        if not full_path then return end

        if vim.fn.filereadable(full_path) == 1 then
            vim.cmd("close")                                          -- 先关闭浮窗
            vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(full_path)) -- 执行传进来的命令
        elseif vim.fn.isdirectory(full_path) == 1 then
            print("📁 这是一个目录: " .. full_path)
        else
            print("⚠️ 找不到文件: " .. full_path)
        end
    end

    -- 绑定快捷键 (仅在当前浮窗内生效)
    vim.keymap.set('n', '<CR>', function() open_file('edit') end, { buffer = buf, silent = true, desc = '当前窗口打开' })
    vim.keymap.set('n', 'v', function() open_file('vsplit') end, { buffer = buf, silent = true, desc = '垂直分屏打开' })
    vim.keymap.set('n', 's', function() open_file('split') end, { buffer = buf, silent = true, desc = '水平分屏打开' })
    -- ==========================================

    -- 3. 异步执行
    local output = {}
    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" then table.insert(output, line) end
                end
            end
        end,
        on_exit = function(_, code)
            if not vim.api.nvim_buf_is_valid(buf) then return end
            if code == 0 then
                if #output == 0 then table.insert(output, "⚠️ 未找到任何文件。") end
                vim.bo[buf].modifiable = true
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
                vim.bo[buf].modifiable = false
            else
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "❌ 命令执行失败！" })
            end
        end
    })
end, { nargs = '?', complete = 'dir', desc = '带完美路径解析及分屏的目录树' })
