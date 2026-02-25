-- lua/tree/fold.lua
-- 折叠状态管理：维护 path → closed 的映射
-- 折叠/展开后触发 renderer 重渲染并刷新 buf

local utils = require('tree.utils')
local M = {}
local renderer = require("tree.renderer")

---@class FoldState
---@field fold_state  table<string, boolean>  path → closed
---@field trie_root   TrieNode
---@field abs_root    string
---@field buf         integer
---@field win         integer
---@field on_refresh  function   重渲染后的回调(file_map, is_dir_map)

-- buf → FoldState
local store = {}

--- 注册一个 buf 的折叠上下文
---@param buf       integer
---@param win       integer
---@param trie_root TrieNode
---@param abs_root  string
---@param on_refresh function
function M.init(buf, win, trie_root, abs_root, on_refresh)
    store[buf] = {
        fold_state = {},
        trie_root  = trie_root,
        abs_root   = abs_root,
        buf        = buf,
        win        = win,
        on_refresh = on_refresh,
    }
end

local function restore_cursor(st, cur_path, file_map)
    if not cur_path then return end

    -- 1. 精确匹配
    for lnum, path in pairs(file_map) do
        if path == cur_path then
            pcall(vim.api.nvim_win_set_cursor, st.win, { lnum, 0 })
            return
        end
    end

    -- 2. 找最近的父路径
    local best_lnum, best_len = 1, 0
    for lnum, path in pairs(file_map) do
        if vim.startswith(cur_path, path .. "/") and #path > best_len then
            best_lnum = lnum
            best_len  = #path
        end
    end
    pcall(vim.api.nvim_win_set_cursor, st.win, { best_lnum, 0 })
end

--- 重渲染 buf 并调用回调更新 ctx
---@param st FoldState
local function refresh(st)
    local result = renderer.render(st.trie_root, st.abs_root, st.fold_state)

    -- 记住光标行对应的路径，渲染后恢复
    local cur_lnum = vim.api.nvim_win_get_cursor(st.win)[1]
    local cur_path = result.file_map[cur_lnum]

    vim.bo[st.buf].modifiable = true
    vim.api.nvim_buf_set_lines(st.buf, 0, -1, false, result.lines)
    vim.bo[st.buf].modifiable = false

    -- 回调：让 keymaps / preview 拿到最新的 file_map / is_dir_map
    st.on_refresh(result.file_map, result.is_dir_map)

    -- 恢复光标到同一路径的行（折叠后行号会变）
    if cur_path then
        for _, path in pairs(result.file_map) do
            if path == cur_path then
                restore_cursor(st, cur_path, result.file_map)
                break
            end
        end
    end
end

--- 切换当前行的折叠状态
---@param buf  integer
---@param lnum integer   当前光标行号（基于最新 file_map）
---@param file_map   table<integer, string>
---@param is_dir_map table<integer, boolean>
function M.toggle(buf, lnum, file_map, is_dir_map)
    local st = store[buf]
    if not st then return end

    -- 找到要折叠的目录：优先当前行（若是目录），否则向上找父目录
    local target_path = nil

    if is_dir_map[lnum] and file_map[lnum] then
        -- 第一行（根目录）不允许折叠
        if lnum == 1 then return end
        target_path = file_map[lnum]
    else
        local deep = utils.safe_length(vim.split(file_map[lnum], "/"))
        -- 当前行是文件，向上找最近的目录行
        for l = lnum - 1, 2, -1 do
            local cur_deep = utils.safe_length(vim.split(file_map[l], "/"))

            if is_dir_map[l] and file_map[l] and cur_deep < deep then
                target_path = file_map[l]
                break
            end
        end
    end

    if not target_path then return end

    st.fold_state[target_path] = not st.fold_state[target_path]
    refresh(st)
end

--- 折叠所有目录
---@param buf integer
---@param file_map   table<integer, string>
---@param is_dir_map table<integer, boolean>
function M.close_all(buf, file_map, is_dir_map)
    local st = store[buf]
    if not st then return end

    -- 清空旧状态，只标记顶层可见目录
    st.fold_state = {}

    -- 找顶层目录：父路径是 abs_root 的直接子目录
    for lnum, is_dir in pairs(is_dir_map) do
        if is_dir and lnum ~= 1 then
            local path = file_map[lnum]
            if path then
                local parent = vim.fn.fnamemodify(path, ":h")
                -- 只折叠根目录的直接子目录
                if parent == st.abs_root then
                    st.fold_state[path] = true
                end
            end
        end
    end

    refresh(st)
end

--- 展开所有目录
---@param buf integer
function M.open_all(buf)
    local st = store[buf]
    if not st then return end

    st.fold_state = {}
    refresh(st)
end

--- 清理
---@param buf integer
function M.cleanup(buf)
    store[buf] = nil
end

return M
