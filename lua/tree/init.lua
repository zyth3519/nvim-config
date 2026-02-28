-- lua/tree/init.lua
local ui = require("tree.ui")
local hl = require("tree.highlight")
local renderer = require("tree.renderer")
local keymaps = require("tree.keymaps")
local fold = require("tree.fold")
local cfg = require("tree.config").defaults
local log = require("tree.log")

local tree = {
	tree_output = {},
	tree_job = nil,
}

local function check_deps()
	if vim.fn.executable("tree") == 0 then
		vim.notify("⚠️ 必须安装 'tree' 并且支持 -J 参数", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function build_tree_cmd()
	local cmd = { "tree", "-J", "-a", "--noreport", "--gitignore" }
	for _, ex in ipairs(cfg.fd_exclude) do
		vim.list_extend(cmd, { "-I", ex })
	end
	return cmd
end

local function tree_on_stdout(_, data)
	if not data then
		return
	end
	for _, line in ipairs(data) do
		if line ~= "" then
			table.insert(tree.tree_output, line)
		end
	end
end

local function tree_on_exit(exit_code, abs_root, target)
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(tree.buf) then
			return
		end
		if exit_code ~= 0 or #tree.tree_output == 0 then
			ui.set_loading(tree.buf, "⚠️ 未找到任何文件或扫描出错。")
			return
		end

		local json_str = table.concat(tree.tree_output, "")
		local ok, tree_json = pcall(vim.json.decode, json_str)

		if not ok or not tree_json then
			ui.set_loading(tree.buf, "⚠️ 解析 JSON 失败。")
			return
		end

		-- ── 1. 首次渲染 ─────────────────────────────────
		local result = renderer.render(tree_json, abs_root, {})

		if not result then
			ui.set_loading(tree.buf, "⚠️ 渲染树结构失败。")
			return
		end

		-- ctx 用闭包共享
		local ctx = {
			buf = tree.buf,
			win = tree.win,
			file_map = result.file_map,
			is_dir_map = result.is_dir_map,
			abs_root = abs_root,
			parent_map = result.parent_map,
		}

		-- ── 2. 写入 buffer ──────────────────────────────
		vim.bo[tree.buf].modifiable = true
		vim.api.nvim_buf_set_lines(tree.buf, 0, -1, false, result.lines)
		vim.bo[tree.buf].modifiable = false

		-- 应用图标颜色高亮
		if result.icon_hl_map then
			hl.apply_icons(tree.buf, result.icon_hl_map)
		end

		-- ── 3. 初始化折叠模块 ───────────────────────────
		fold.init(tree.buf, tree.win, tree_json, abs_root, function(res)
			ctx.file_map = res.file_map
			ctx.is_dir_map = res.is_dir_map
			ctx.parent_map = res.parent_map
			if result.icon_hl_map then
				hl.apply_icons(tree.buf, res.icon_hl_map)
			end
		end)

		-- ── 4. 绑定快捷键 ───────────────────────────────
		keymaps.setup(ctx, fold)

		-- 设置光标位置
		for index, value in ipairs(result.file_map) do
			if value == target then
				local name = vim.fn.fnamemodify(value, ":t")
				local col = string.len(result.lines[index]) - string.len(name)
				if result.is_dir_map[index] then
					col = col - 1
				end
				pcall(vim.api.nvim_win_set_cursor, ctx.win, { index, col })
				break
			end
		end
	end)
end

local function run(root, target)
	tree.layout = ui.create_layout(root)
	tree.buf, tree.win = tree.layout.buf, tree.layout.win
	ui.set_loading(tree.buf, "⏳ 正在扫描 [" .. root .. "] ...")
	ui.setup_close_autocmd(tree.layout)
	hl.apply(tree.buf)

	tree.tree_output = {}
	tree.tree_job = vim.fn.jobstart(build_tree_cmd(), {
		stdout_buffered = true,
		on_stdout = tree_on_stdout,
		on_exit = function(_, exit_code)
			tree_on_exit(exit_code, root, target)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = tree.buf,
		once = true,
		callback = function()
			fold.cleanup(tree.buf)
			if tree.tree_job and tree.tree_job > 0 then
				pcall(vim.fn.jobstop, tree.tree_job)
			end
		end,
	})
end

local function is_path_inside_cwd(input_path)
	if input_path == "." then
		return true
	end
	local cwd = vim.fn.getcwd():gsub("/$", "")
	local abs_path = vim.fn.fnamemodify(input_path, ":p"):gsub("/$", "")

	return vim.startswith(abs_path .. "/", cwd .. "/")
end

-- 注册Tree命令，插件的入口
vim.api.nvim_create_user_command("Tree", function(opts)
	if not check_deps() then
		return
	end

	-- 获取当前文件路径
	local target = vim.fn.expand("%:p")
	-- 如果拥有输入的参数，就按照参数来
	if string.len(opts.args) > 0 then
		target = vim.fn.fnamemodify(opts.args, ":p")
	end

	local is_oil = false
	if vim.startswith(target, "oil://") then
		is_oil = true
	end
	target = target:gsub("^oil://", ""):gsub("/+$", "")
	-- 判断当前是不是oil插件，如果是就将光标定位到oil插件所在的路径
	if is_oil then
		local ok, oil = pcall(require, "oil")
		if ok then
			local name = oil.get_cursor_entry().name
			target = vim.fs.joinpath(target, name)
		end
	end

	local root = vim.fn.getcwd()
	if not is_path_inside_cwd(target) then
		target = root
	end

	run(root, target)
end, { nargs = "?", complete = "dir", desc = "浮动目录树" })
