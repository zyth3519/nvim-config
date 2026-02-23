vim.api.nvim_create_user_command('Tree', function(opts)
    if vim.fn.executable("fd") == 0 or vim.fn.executable("tree") == 0 then
        vim.notify("⚠️ 必须安装 'fd' 和 'tree'", vim.log.levels.ERROR)
        return
    end

    local path = opts.args
    local target_path = path == "" and "." or path
    local abs_root = vim.fn.fnamemodify(target_path, ":p"):gsub("/$", "")

    -- ==========================================
    -- 1. 浮窗
    -- ==========================================
    local width = math.ceil(vim.o.columns * 0.8)
    local height = math.ceil(vim.o.lines * 0.8)
    local row = math.ceil((vim.o.lines - height) / 2 - 1)
    local col = math.ceil((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "⏳ 正在扫描 [" .. target_path .. "] ..." })

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
    vim.bo[buf].filetype = "mytree"
    vim.bo[buf].modifiable = false

    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf, silent = true })

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = buf,
        once = true,
        callback = function()
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
                if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
            end)
        end,
    })

    -- ==========================================
    -- 2. 语法高亮
    -- ==========================================
    vim.api.nvim_buf_call(buf, function()
        vim.cmd([[syntax match TreeLines /^[│├└─ ]\+/]])
        vim.cmd([[highlight default link TreeLines Comment]])
        vim.cmd([[syntax match TreeDir /[^│├└─ ]\S*\/$/]])
        vim.cmd([[highlight default link TreeDir Directory]])
        vim.cmd([[syntax match TreeExt /\.\w\+$/]])
        vim.cmd([[highlight default link TreeExt Type]])
    end)

    -- ==========================================
    -- 3. fd 获取所有路径
    -- ==========================================
    local fd_paths = {}
    local fd_cmd = { "fd", "--type", "f", "--type", "d",
        "--hidden", "--exclude", ".git",
        ".", target_path }

    local fd_job = vim.fn.jobstart(fd_cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    line = line:gsub("\r$", ""):gsub("/$", "")
                    if line ~= "" then
                        table.insert(fd_paths, line)
                    end
                end
            end
        end,
        on_exit = function(_, fd_code)
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end
                if fd_code ~= 0 or #fd_paths == 0 then
                    vim.bo[buf].modifiable = true
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "⚠️ 未找到任何文件。" })
                    vim.bo[buf].modifiable = false
                    return
                end

                -- ==========================================
                -- 4. 构建 trie
                -- ==========================================
                local trie = { children = {}, full_path = abs_root, is_dir = true }

                for _, p in ipairs(fd_paths) do
                    local rel = p
                    local prefix1 = target_path .. "/"
                    local prefix2 = "./"
                    if vim.startswith(rel, prefix1) then
                        rel = rel:sub(#prefix1 + 1)
                    elseif vim.startswith(rel, prefix2) then
                        rel = rel:sub(3)
                    end
                    rel = rel:gsub("/$", "")
                    if rel == "" then goto continue end

                    local parts = vim.split(rel, "/", { plain = true })
                    local node = trie
                    for pi, part in ipairs(parts) do
                        if not node.children[part] then
                            node.children[part] = { children = {}, full_path = nil, is_dir = false }
                        end
                        node = node.children[part]
                        -- 中间节点一定是目录
                        if pi < #parts then
                            node.is_dir = true
                        end
                    end
                    node.full_path = p:gsub("/$", "")
                    -- 如果有子节点，说明是目录
                    if next(node.children) then
                        node.is_dir = true
                    end
                    ::continue::
                end

                -- 标记所有有children的节点为目录
                local function mark_dirs(node)
                    if next(node.children) then
                        node.is_dir = true
                    end
                    for _, child in pairs(node.children) do
                        mark_dirs(child)
                    end
                end
                mark_dirs(trie)

                -- ==========================================
                -- 5. tree 渲染
                -- ==========================================
                local tree_lines = {}
                local raw_paths = {}
                for _, p in ipairs(fd_paths) do
                    table.insert(raw_paths, p)
                end

                local tree_job = vim.fn.jobstart(
                    { "tree", "-F", "--fromfile", "--noreport" },
                    {
                        stdout_buffered = true,
                        on_stdout = function(_, data)
                            if data then
                                for _, line in ipairs(data) do
                                    if line ~= "" then
                                        table.insert(tree_lines, line)
                                    end
                                end
                            end
                        end,
                        on_exit = function(_, tree_code)
                            vim.schedule(function()
                                if not vim.api.nvim_buf_is_valid(buf) then return end

                                vim.bo[buf].modifiable = true
                                if tree_code ~= 0 then
                                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "❌ tree 失败" })
                                    vim.bo[buf].modifiable = false
                                    return
                                end

                                -- ==========================================
                                -- 6. 从 tree 输出构建 行号→路径 映射
                                -- ==========================================
                                local file_map = {}   -- 行号 → 完整路径
                                local is_dir_map = {} -- 行号 → 是否目录
                                local stack = { [0] = trie }

                                for line_idx, line in ipairs(tree_lines) do
                                    if line_idx == 1 then
                                        file_map[line_idx] = abs_root
                                        is_dir_map[line_idx] = true
                                        goto next_line
                                    end

                                    local depth = 0
                                    local name = nil

                                    local i = 1
                                    local len = #line
                                    local connector_byte_pos = nil

                                    while i <= len do
                                        local b = string.byte(line, i)
                                        if b == 0xE2 and i + 2 <= len then
                                            local c3 = line:sub(i, i + 2)
                                            if c3 == "├" or c3 == "└" then
                                                connector_byte_pos = i
                                                break
                                            end
                                            i = i + 3
                                        else
                                            i = i + 1
                                        end
                                    end

                                    if connector_byte_pos then
                                        local before = line:sub(1, connector_byte_pos - 1)
                                        depth = vim.fn.strdisplaywidth(before) / 4 + 1

                                        local name_start = connector_byte_pos + 10
                                        if name_start <= len then
                                            name = line:sub(name_start)
                                        end
                                    end

                                    if not name or name == "" then
                                        file_map[line_idx] = nil
                                        is_dir_map[line_idx] = false
                                        goto next_line
                                    end

                                    local clean_name = name:gsub("[/*=>|@]$", "")
                                    if clean_name == "" then
                                        file_map[line_idx] = nil
                                        is_dir_map[line_idx] = false
                                        goto next_line
                                    end

                                    local parent = stack[depth - 1]
                                    if parent and parent.children[clean_name] then
                                        local node = parent.children[clean_name]
                                        stack[depth] = node
                                        for d = depth + 1, #stack do
                                            stack[d] = nil
                                        end
                                        file_map[line_idx] = node.full_path
                                        is_dir_map[line_idx] = node.is_dir
                                    else
                                        file_map[line_idx] = nil
                                        is_dir_map[line_idx] = false
                                    end

                                    ::next_line::
                                end

                                vim.api.nvim_buf_set_lines(buf, 0, -1, false, tree_lines)
                                vim.bo[buf].modifiable = false

                                -- ==========================================
                                -- 7. 获取当前行路径的辅助函数
                                -- ==========================================
                                local function resolve_path(fpath)
                                    if not fpath then return nil end
                                    local try = { fpath }
                                    if not vim.startswith(fpath, "/") then
                                        table.insert(try, abs_root .. "/" .. fpath)
                                    end
                                    for _, tp in ipairs(try) do
                                        if vim.fn.filereadable(tp) == 1 or vim.fn.isdirectory(tp) == 1 then
                                            return tp
                                        end
                                    end
                                    return nil
                                end

                                -- 获取路径所在的目录
                                local function get_dir(fpath, is_dir)
                                    if not fpath then return nil end
                                    local resolved = resolve_path(fpath)
                                    if not resolved then return nil end
                                    if is_dir then
                                        return resolved
                                    else
                                        return vim.fn.fnamemodify(resolved, ":h")
                                    end
                                end

                                -- ==========================================
                                -- 8. 快捷键
                                -- ==========================================
                                local function open_file(open_cmd)
                                    local lnum = vim.fn.line('.')
                                    local fpath = file_map[lnum]
                                    if not fpath then return end

                                    local resolved = resolve_path(fpath)
                                    if not resolved then
                                        vim.notify("⚠️ 找不到: " .. fpath, vim.log.levels.WARN)
                                        return
                                    end

                                    if vim.fn.isdirectory(resolved) == 1 then
                                        vim.notify("📁 目录: " .. resolved, vim.log.levels.INFO)
                                        return
                                    end

                                    vim.cmd("close")
                                    vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(resolved))
                                end

                                -- 用 Oil 打开当前条目所在目录
                                local function open_oil()
                                    local lnum = vim.fn.line('.')
                                    local fpath = file_map[lnum]
                                    local is_dir = is_dir_map[lnum]
                                    local dir = get_dir(fpath, is_dir)

                                    if not dir then
                                        vim.notify("⚠️ 无法确定目录", vim.log.levels.WARN)
                                        return
                                    end

                                    -- 检查 Oil 是否可用
                                    local ok, oil = pcall(require, "oil")
                                    if not ok then
                                        vim.notify("⚠️ Oil 未安装", vim.log.levels.ERROR)
                                        return
                                    end

                                    vim.cmd("close")
                                    oil.open(dir)
                                end

                                vim.keymap.set('n', '<CR>', function() open_file('edit') end,
                                    { buffer = buf, silent = true, desc = '打开文件' })
                                vim.keymap.set('n', 'v', function() open_file('vsplit') end,
                                    { buffer = buf, silent = true, desc = '垂直分屏' })
                                vim.keymap.set('n', 's', function() open_file('split') end,
                                    { buffer = buf, silent = true, desc = '水平分屏' })
                                vim.keymap.set('n', 't', function() open_file('tabedit') end,
                                    { buffer = buf, silent = true, desc = '新标签页' })
                                vim.keymap.set('n', 'o', function() open_oil() end,
                                    { buffer = buf, silent = true, desc = 'Oil 打开目录' })
                            end)
                        end,
                    }
                )

                local stdin_data = table.concat(raw_paths, "\n") .. "\n"
                vim.fn.chansend(tree_job, stdin_data)
                vim.fn.chanclose(tree_job, "stdin")
            end)
        end,
    })

    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = function()
            if fd_job and fd_job > 0 then pcall(vim.fn.jobstop, fd_job) end
        end,
    })
end, { nargs = '?', complete = 'dir', desc = '浮动目录树' })
