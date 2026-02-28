-- lua/tree/keymaps.lua

---@class KeymapCtx
---@field buf        integer
---@field win       integer
---@field file_map   table<integer, string>
---@field is_dir_map table<integer, boolean>
---@field parent_map table<integer, integer>
---@field abs_root   string

local M = {}
local utils = require("tree.utils")

local function resolve(fpath, abs_root)
	if not fpath then
		return nil
	end
	local candidates = { fpath }
	if not vim.startswith(fpath, "/") then
		table.insert(candidates, abs_root .. "/" .. fpath)
	end
	for _, p in ipairs(candidates) do
		if vim.fn.filereadable(p) == 1 or vim.fn.isdirectory(p) == 1 then
			return p
		end
	end
	return nil
end

local function make_open_oil(file_map, is_dir_map, abs_root)
	return function()
		local lnum = vim.fn.line(".")
		local fpath = file_map[lnum]
		local is_d = is_dir_map[lnum]
		local resolved = resolve(fpath, abs_root)
		if not resolved then
			vim.notify("⚠️ 无法确定路径", vim.log.levels.WARN)
			return
		end
		local dir = (is_d and vim.fn.isdirectory(resolved) == 1) and resolved or vim.fn.fnamemodify(resolved, ":h")
		local ok, oil = pcall(require, "oil")
		if not ok then
			vim.notify("⚠️ Oil 未安装", vim.log.levels.ERROR)
			return
		end
		vim.cmd("close")
		oil.open_float(dir)
	end
end

local function make_open(file_map, is_dir_map, abs_root, open_cmd)
	return function()
		local lnum = vim.fn.line(".")
		local fpath = file_map[lnum]
		local resolved = resolve(fpath, abs_root)
		if not resolved then
			vim.notify("⚠️ 找不到: " .. (fpath or "?"), vim.log.levels.WARN)
			return
		end
		if vim.fn.isdirectory(resolved) == 1 then
			make_open_oil(file_map, is_dir_map, abs_root)()
			return
		end
		if not utils.is_text_file(resolved) then
			vim.notify("⚠️无法打开二进制文件: " .. resolved, vim.log.levels.WARN)
			return
		end
		vim.cmd("close")
		vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(resolved))
	end
end

---@param ctx     KeymapCtx
---@param fold    table
function M.setup(ctx, fold)
	local buf = ctx.buf
	local abs_root = ctx.abs_root

	local map = function(key, fn, desc)
		vim.keymap.set("n", key, fn, { buffer = buf, silent = true, desc = desc })
	end

	map("q", "<cmd>close<cr>", "关闭")
	map("<Esc>", "<cmd>close<cr>", "关闭")

	-- 文件打开（通过 ctx 闭包拿最新 file_map）
	map("<CR>", function()
		make_open(ctx.file_map, ctx.is_dir_map, abs_root, "edit")()
	end, "打开文件")
	map("v", function()
		make_open(ctx.file_map, ctx.is_dir_map, abs_root, "vsplit")()
	end, "垂直分屏")
	map("s", function()
		make_open(ctx.file_map, ctx.is_dir_map, abs_root, "split")()
	end, "水平分屏")
	map("t", function()
		make_open(ctx.file_map, ctx.is_dir_map, abs_root, "tabedit")()
	end, "新标签页")
	map("o", function()
		make_open_oil(ctx.file_map, ctx.is_dir_map, abs_root)()
	end, "Oil 打开目录")
	map("a", function()
		make_open_oil(ctx.file_map, ctx.is_dir_map, abs_root)()
	end, "Oil 打开目录")
	map("i", function()
		make_open_oil(ctx.file_map, ctx.is_dir_map, abs_root)()
	end, "Oil 打开目录")

	-- 折叠快捷键
	map("za", function()
		fold.toggle(buf, vim.fn.line("."), ctx.file_map, ctx.is_dir_map, ctx.parent_map)
	end, "折叠/展开当前目录")

	map("zM", function()
		fold.close_all(buf, ctx.file_map, ctx.is_dir_map, ctx.parent_map)
	end, "折叠所有目录")

	map("zR", function()
		fold.open_all(buf)
	end, "展开所有目录")
end

return M
