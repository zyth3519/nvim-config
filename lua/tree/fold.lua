-- lua/tree/fold.lua
-- 折叠状态管理：维护 path → closed 的映射
-- 折叠/展开后触发 renderer 重渲染并刷新 buf

local M = {}
local renderer = require("tree.renderer")
local utils = require("tree.utils")
local log = require("tree.log")

---@class FoldState
---@field fold_state  table<string, boolean>  path → closed
---@field tree_json   table
---@field abs_root    string
---@field buf         integer
---@field win         integer
---@field on_refresh  function   重渲染后的回调(file_map, is_dir_map)

-- buf → FoldState
local store = {}

--- 注册一个 buf 的折叠上下文
---@param buf       integer
---@param win       integer
---@param tree_json table
---@param abs_root  string
---@param on_refresh function
function M.init(buf, win, tree_json, abs_root, on_refresh)
	store[buf] = {
		fold_state = {},
		tree_json = tree_json,
		abs_root = abs_root,
		buf = buf,
		win = win,
		on_refresh = on_refresh,
	}
end

local function restore_cursor(st, cur_path, file_map)
	if not cur_path then
		return
	end

	-- 1. 精确匹配
	for lnum, path in pairs(file_map) do
		if path == cur_path then
			pcall(vim.api.nvim_win_set_cursor, st.win, { lnum, 0 })
			vim.schedule(function()
				local col = utils.get_cur_col_pos(cur_path)
				pcall(vim.api.nvim_win_set_cursor, st.win, { lnum, col })
			end)
			return
		end
	end

	-- 2. 找最近的父路径
	local best_lnum, best_len = 1, 0
	for lnum, path in pairs(file_map) do
		if vim.startswith(cur_path, path .. "/") and #path > best_len then
			best_lnum = lnum
			best_len = #path
		end
	end
	local col = utils.get_cur_col_pos(cur_path)
	pcall(vim.api.nvim_win_set_cursor, st.win, { best_lnum, col })
end

--- 重渲染 buf 并调用回调更新 ctx
---@param st FoldState
local function refresh(st, target_path)
	local result = renderer.render(st.tree_json, st.abs_root, st.fold_state)

	if not result then
		return
	end

	vim.bo[st.buf].modifiable = true
	vim.api.nvim_buf_set_lines(st.buf, 0, -1, false, result.lines)
	vim.bo[st.buf].modifiable = false

	-- 回调：让 keymaps / preview 拿到最新的 file_map / is_dir_map / icon_hl_map
	st.on_refresh(result)
	vim.schedule(function()
		restore_cursor(st, target_path, result.file_map)
	end)
end

--- 切换当前行的折叠状态
---@param buf  integer
---@param lnum integer   当前光标行号（基于最新 file_map）
---@param file_map   table<integer, string>
---@param is_dir_map table<integer, boolean>
function M.toggle(buf, lnum, file_map, is_dir_map, parent_name)
	-- 第一行（根目录）不允许折叠
	if lnum == 1 then
		return
	end

	local st = store[buf]
	if not st then
		return
	end

	local target_path = nil
	if is_dir_map[lnum] and file_map[lnum] then
		target_path = file_map[lnum]
	else
		target_path = file_map[parent_name[lnum]]
	end

	if not target_path then
		return
	end

	st.fold_state[target_path] = not st.fold_state[target_path]
	refresh(st, target_path)
end

--- 折叠所有目录
---@param buf integer
---@param file_map   table<integer, string>
---@param is_dir_map table<integer, boolean>
function M.close_all(buf, file_map, is_dir_map)
	local st = store[buf]
	if not st then
		return
	end

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
	if not st then
		return
	end

	st.fold_state = {}
	refresh(st)
end

--- 清理
---@param buf integer
function M.cleanup(buf)
	store[buf] = nil
end

return M
