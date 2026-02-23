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


    -- 主窗口占左边 40%，预览窗口占右边 60%
    local main_width = math.ceil(width * 0.4)
    local preview_width = width - main_width - 1 -- -1 留边框间隙

    local preview_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[preview_buf].buftype = "nofile"
    vim.bo[preview_buf].modifiable = false

    local preview_win = vim.api.nvim_open_win(preview_buf, false, {
        relative = 'editor',
        width = preview_width,
        height = height,
        row = row,
        col = col + main_width + 1,
        style = 'minimal',
        border = 'rounded',
        title = ' Preview ',
        title_pos = 'center',
    })

    -- 主窗口宽度也要改
    -- 把原来的 width = width 改成：
    -- width = main_width

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = main_width,
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
                -- BufLeave 的 callback 里加：
                if vim.api.nvim_win_is_valid(preview_win) then
                    vim.api.nvim_win_close(preview_win, true)
                end
                if vim.api.nvim_buf_is_valid(preview_buf) then
                    vim.api.nvim_buf_delete(preview_buf, { force = true })
                end
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



                                local preview_ns = vim.api.nvim_create_namespace('tree_preview')

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

                                local function scroll_preview(direction)
                                    if not vim.api.nvim_win_is_valid(preview_win) then return end
                                    local total_lines = vim.api.nvim_buf_line_count(preview_buf)
                                    local win_height = vim.api.nvim_win_get_height(preview_win)
                                    local current_top = vim.fn.getwininfo(preview_win)[1].topline
                                    local step = math.ceil(win_height * 0.8) -- 每次滚动 80% 屏幕高度

                                    if direction == "down" then
                                        local new_top = math.min(current_top + step, total_lines - win_height + 1)
                                        vim.api.nvim_win_set_cursor(preview_win, { math.max(1, new_top), 0 })
                                        vim.api.nvim_win_call(preview_win, function()
                                            vim.fn.winrestview({ topline = math.max(1, new_top) })
                                        end)
                                    else
                                        local new_top = math.max(1, current_top - step)
                                        vim.api.nvim_win_call(preview_win, function()
                                            vim.fn.winrestview({ topline = new_top })
                                        end)
                                    end
                                end

                                local function update_preview()
                                    if not vim.api.nvim_buf_is_valid(preview_buf) then return end
                                    if not vim.api.nvim_win_is_valid(preview_win) then return end

                                    local lnum = vim.fn.line('.')
                                    local fpath = file_map[lnum]
                                    local is_dir = is_dir_map[lnum]
                                    local resolved = fpath and resolve_path(fpath) or nil

                                    vim.bo[preview_buf].modifiable = true
                                    vim.api.nvim_buf_clear_namespace(preview_buf, preview_ns, 0, -1)

                                    -- 目录：列出子条目
                                    if resolved and vim.fn.isdirectory(resolved) == 1 then
                                        local items = vim.fn.readdir(resolved)
                                        local lines = { "📁 " .. resolved, "" }
                                        for _, item in ipairs(items) do
                                            local full = resolved .. "/" .. item
                                            if vim.fn.isdirectory(full) == 1 then
                                                table.insert(lines, "  📂 " .. item .. "/")
                                            else
                                                table.insert(lines, "  📄 " .. item)
                                            end
                                        end
                                        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
                                        vim.bo[preview_buf].filetype = ""

                                        -- 文件：读取内容预览
                                    elseif resolved and vim.fn.filereadable(resolved) == 1 then
                                        -- 限制只读前200行，避免大文件卡顿
                                        local lines = {}
                                        local ok, result = pcall(vim.fn.readfile, resolved, "", 200)
                                        if ok then
                                            lines = result
                                        else
                                            lines = { "⚠️ 无法读取文件" }
                                        end
                                        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
                                        -- 自动检测文件类型以高亮
                                        local ext = vim.fn.fnamemodify(resolved, ":e")
                                        local ft_ok, ft = pcall(vim.filetype.match, { filename = resolved })
                                        vim.bo[preview_buf].filetype = (ft_ok and ft) or ext or ""
                                    else
                                        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "　" })
                                        vim.bo[preview_buf].filetype = ""
                                    end

                                    vim.bo[preview_buf].modifiable = false
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
                                vim.api.nvim_create_autocmd("CursorMoved", {
                                    buffer = buf,
                                    callback = function()
                                        vim.schedule(update_preview)
                                    end,
                                })


                                -- 进入浮窗时立刻触发一次
                                vim.schedule(update_preview)

                                vim.keymap.set('n', '<C-n>', function() scroll_preview("down") end,
                                    { buffer = buf, silent = true, desc = '预览向下翻页' })
                                vim.keymap.set('n', '<C-p>', function() scroll_preview("up") end,
                                    { buffer = buf, silent = true, desc = '预览向上翻页' })
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
