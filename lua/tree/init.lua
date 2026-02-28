-- lua/tree/init.lua
local ui = require("tree.ui")
local hl = require("tree.highlight")
local trie_mod = require("tree.trie")
local renderer = require("tree.renderer")
local preview = require("tree.preview")
local keymaps = require("tree.keymaps")
local fold = require("tree.fold")
local cfg = require("tree.config").defaults
local log = require("tree.log")

local tree = {
	fd_paths = {},
	fd_job = nil,
}

local function check_deps()
	if vim.fn.executable("fd") == 0 then
		vim.notify("⚠️ 必须安装 'fd'", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function build_fd_cmd(target)
	local cmd = { "fd", "--type", "f", "--type", "d", "--hidden" }
	for _, ex in ipairs(cfg.fd_exclude) do
		vim.list_extend(cmd, { "--exclude", ex })
	end
	vim.list_extend(cmd, { ".", target })
	return cmd
end

local function fd_on_stdout(_, data)
	if not data then
		return
	end
	for _, line in ipairs(data) do
		if line ~= "" then
			table.insert(tree.fd_paths, line)
		end
	end
end

local function fd_on_exit(fd_code, target_path, abs_root, args)
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(tree.buf) then
			return
		end
		if fd_code ~= 0 or #tree.fd_paths == 0 then
			ui.set_loading(tree.buf, "⚠️ 未找到任何文件。")
			return
		end

		-- ── 1. 构建 Trie ────────────────────────────────
		local trie = trie_mod.build(tree.fd_paths, target_path, abs_root)

		-- ── 2. 首次渲染 ─────────────────────────────────
		local result = renderer.render(trie, abs_root, {})

		-- ctx 用闭包共享，折叠刷新后更新 file_map/is_dir_map
		local ctx = {
			buf = tree.buf,
			win = tree.win,
			pbuf = tree.pbuf,
			pwin = tree.pwin,
			file_map = result.file_map,
			is_dir_map = result.is_dir_map,
			abs_root = abs_root,
		}

		-- ── 3. 写入 buffer ──────────────────────────────
		vim.bo[tree.buf].modifiable = true
		vim.api.nvim_buf_set_lines(tree.buf, 0, -1, false, result.lines)
		vim.bo[tree.buf].modifiable = false

		-- 应用图标颜色高亮
		if result.icon_hl_map then
			hl.apply_icons(tree.buf, result.icon_hl_map)
		end

		-- ── 4. 初始化折叠模块 ───────────────────────────
		fold.init(tree.buf, tree.win, trie, abs_root, function(new_file_map, new_is_dir_map, new_icon_hl_map)
			ctx.file_map = new_file_map
			ctx.is_dir_map = new_is_dir_map
			if new_icon_hl_map then
				hl.apply_icons(tree.buf, new_icon_hl_map)
			end
		end)

		-- ── 5. 绑定快捷键 ───────────────────────────────
		keymaps.setup(ctx, preview, fold)

		if cfg.preview then
			-- ── 6. 初始预览 ─────────────────────────────────
			vim.schedule(function()
				preview.update(ctx)
			end)
		end

		-- 设置光标位置
		for index, value in ipairs(result.file_map) do
			if value == args then
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

local function run(target_path, abs_root, args)
	tree.layout = ui.create_layout(target_path)
	tree.buf, tree.win, tree.pbuf, tree.pwin = tree.layout.buf, tree.layout.win, tree.layout.pbuf, tree.layout.pwin

	ui.set_loading(tree.buf, "⏳ 正在扫描 [" .. target_path .. "] ...")
	ui.setup_close_autocmd(tree.layout)
	hl.apply(tree.buf)

	tree.fd_job = vim.fn.jobstart(build_fd_cmd(target_path), {
		stdout_buffered = true,
		on_stdout = fd_on_stdout,
		on_exit = function(_, fd_code)
			fd_on_exit(fd_code, target_path, abs_root, args)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = tree.buf,
		once = true,
		callback = function()
			fold.cleanup(tree.buf)
			if tree.fd_job and tree.fd_job > 0 then
				pcall(vim.fn.jobstop, tree.fd_job)
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
	local file_path = vim.fn.expand("%:p")
	-- 如果拥有输入的参数，就按照参数来
	if string.len(opts.args) > 0 then
		file_path = vim.fn.fnamemodify(opts.args, ":p")
	end

	local is_oil = false
	if vim.startswith(file_path, "oil://") then
		is_oil = true
	end
	file_path = file_path:gsub("^oil://", ""):gsub("/+$", "")
	-- 判断当前是不是oil插件，如果是就将光标定位到oil插件所在的路径
	if is_oil then
		local ok, oil = pcall(require, "oil")
		if ok then
			local name = oil.get_cursor_entry().name
			file_path = vim.fs.joinpath(file_path, name)
		end
	end

	local abs_root = vim.fn.getcwd()
	if not is_path_inside_cwd(file_path) then
		file_path = abs_root
	end
	run(abs_root, abs_root, file_path)
end, { nargs = "?", complete = "dir", desc = "浮动目录树" })
