-- lua/tree/fold.lua
-- Tree 主窗口的折叠功能
-- 根据 is_dir_map / file_map 计算目录的子内容范围，实现手动折叠

local M = {}

-- ── 折叠状态 ────────────────────────────────────────────────────
-- key: buf_handle
-- value: table<lnum, { start, end_, closed }>
local state = {}

--- 初始化某个 buf 的折叠状态（全部展开）
---@param buf        integer
---@param tree_lines string[]
---@param is_dir_map table<integer, boolean>
---@param file_map   table<integer, string>
function M.init(buf, tree_lines, is_dir_map, file_map)
    -- 计算每个目录行的子内容范围
    -- 利用路径前缀关系：某目录行 d，其子行 = 紧随其后、
    -- 路径以 d 的路径为前缀的所有行，直到遇到非子路径行为止
    local folds = {} -- lnum → { start, end_, closed }
    local total = #tree_lines

    for lnum, is_dir in pairs(is_dir_map) do
        if not is_dir then goto continue end

        local dir_path = file_map[lnum]
        if not dir_path then goto continue end

        -- 去掉路径末尾 /，统一比较
        local dir_prefix = dir_path:gsub("/$", "")

        -- 向下扫描，找到所有属于该目录的行
        local fold_end = lnum -- 至少包含自身
        for i = lnum + 1, total do
            local p = file_map[i]
            if p then
                local p_clean = p:gsub("/$", "")
                -- 判断是否是子路径
                if vim.startswith(p_clean, dir_prefix .. "/") then
                    fold_end = i
                else
                    -- 遇到不属于该目录的行则停止
                    break
                end
            else
                -- file_map[i] 为 nil（空行/报告行），继续向下找
                -- 但如果连续多行都是 nil 且后续也无子路径，也应停止
                -- 简单处理：nil 行算作子范围内（tree 底部统计行）
                fold_end = i
            end
        end

        -- 只有目录下有内容才值得折叠
        if fold_end > lnum then
            folds[lnum] = {
                start  = lnum,
                end_   = fold_end,
                closed = false, -- 默认展开
            }
        end

        ::continue::
    end

    state[buf] = folds
    return folds
end

--- 获取某 buf 的折叠表
---@param buf integer
---@return table
function M.get_state(buf)
    return state[buf] or {}
end

--- 切换指定行的折叠状态
---@param buf  integer
---@param win  integer
---@param lnum integer
function M.toggle(buf, win, lnum)
    local folds = state[buf]
    if not folds then return end

    -- 找到覆盖当前行的折叠
    -- 优先找以当前行为 start 的折叠；
    -- 若当前行在某折叠内部，则操作最内层的父折叠
    local target = folds[lnum]

    if not target then
        -- 当前行不是目录行，向上找最近的父目录折叠
        for l = lnum - 1, 1, -1 do
            if folds[l] and folds[l].end_ >= lnum then
                target = folds[l]
                break
            end
        end
    end

    if not target then return end

    if target.closed then
        M._open_fold(buf, win, target)
    else
        M._close_fold(buf, win, target)
    end
end

--- 关闭折叠：隐藏 start+1 ~ end_ 的行
---@param buf    integer
---@param win    integer
---@param fold   table
function M._close_fold(buf, win, fold)
    if fold.closed then return end
    fold.closed = true

    vim.bo[buf].modifiable = true

    -- 用 conceal 模拟隐藏：替换为空，不实际删除行
    -- 实际方案：直接操作 nvim_buf_set_lines 替换隐藏行为空
    -- 更好方案：使用 extmark + conceal 隐藏行内容，
    --           但跨行隐藏需要 virtual_lines，这里用 folding 原语

    -- ── 使用 Neovim 原生 fold 命令（在目标 win 内执行）──────
    vim.api.nvim_win_call(win, function()
        -- 确保 foldmethod 是 manual
        if vim.wo.foldmethod ~= "manual" then
            vim.wo.foldmethod = "manual"
        end
        -- 创建折叠区间
        vim.cmd(string.format("%d,%dfold", fold.start, fold.end_))
    end)

    vim.bo[buf].modifiable = false
end

--- 展开折叠
---@param buf    integer
---@param win    integer
---@param fold   table
function M._open_fold(buf, win, fold)
    if not fold.closed then return end
    fold.closed = false

    vim.api.nvim_win_call(win, function()
        -- 将光标移到折叠行再 zd 删除该折叠
        vim.fn.cursor(fold.start, 1)
        -- zo 展开当前行的折叠
        pcall(vim.cmd, "normal! zo")
    end)
end

--- 展开所有折叠
---@param buf integer
---@param win integer
function M.open_all(buf, win)
    local folds = state[buf]
    if not folds then return end

    vim.api.nvim_win_call(win, function()
        pcall(vim.cmd, "normal! zR")
    end)

    for _, fold in pairs(folds) do
        fold.closed = false
    end
end

--- 关闭所有折叠
---@param buf integer
---@param win integer
function M.close_all(buf, win)
    local folds = state[buf]
    if not folds then return end

    vim.bo[buf].modifiable = true

    vim.api.nvim_win_call(win, function()
        if vim.wo.foldmethod ~= "manual" then
            vim.wo.foldmethod = "manual"
        end
        -- 先清除所有旧折叠
        pcall(vim.cmd, "normal! zE")
        -- 只折叠顶层目录（depth 最浅的，避免重叠折叠）
        local top_folds = M._get_top_level_folds(buf)
        for _, fold in ipairs(top_folds) do
            vim.cmd(string.format("%d,%dfold", fold.start, fold.end_))
            fold.closed = true
        end
    end)

    vim.bo[buf].modifiable = false
end

--- 获取顶层（不被任何其他折叠包含）的折叠列表，按行号排序
---@param buf integer
---@return table[]
function M._get_top_level_folds(buf)
    local folds = state[buf]
    if not folds then return {} end

    -- 收集所有折叠，按 start 排序
    local list = {}
    for _, f in pairs(folds) do
        table.insert(list, f)
    end
    table.sort(list, function(a, b) return a.start < b.start end)

    -- 过滤：只保留不被其他折叠包含的顶层折叠
    local top = {}
    local covered_until = 0
    for _, f in ipairs(list) do
        if f.start > covered_until then
            table.insert(top, f)
            covered_until = f.end_
        end
    end
    return top
end

--- 清理 buf 对应的折叠状态（关闭浮窗时调用）
---@param buf integer
function M.cleanup(buf)
    state[buf] = nil
end

return M
