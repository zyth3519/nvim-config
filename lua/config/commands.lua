-- 辅助函数：创建浮动窗口
local function create_float_win(buf, width, height, title)
	return vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center",
	})
end

-- 辅助函数：显示帮助窗口
local function show_fd_help()
	local lines = {
		" Fd 命令帮助 ",
		"",
		" 快捷键:",
		"   <CR>  - 打开文件",
		"   o     - 在 Oil 中打开所在目录",
		"   q     - 关闭",
		"   <Esc> - 关闭",
		"   ?     - 显示此帮助",
		"",
		" 按任意键关闭帮助",
	}
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"

	local win = create_float_win(buf, 40, #lines, " 帮助 ")

	-- 按任意键关闭
	local close_keys = { "<CR>", "q", "<Esc>", "?", "o", "j", "k", "h", "l", "g", "G" }
	for _, key in ipairs(close_keys) do
		vim.keymap.set("n", key, function()
			vim.api.nvim_win_close(win, true)
		end, { buffer = buf, silent = true })
	end
end

-- 辅助函数：设置 Fd 窗口的按键映射
local function setup_fd_keymaps(buf, win)
	local function get_path()
		return vim.fn.fnamemodify(vim.api.nvim_get_current_line(), ":p")
	end

	vim.keymap.set("n", "?", show_fd_help, { buffer = buf, silent = true })
	vim.keymap.set("n", "o", function()
		local path = get_path()
		local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
		vim.api.nvim_win_close(win, true)
		require("oil").open(dir)
	end, { buffer = buf, silent = true })
	vim.keymap.set("n", "<CR>", function()
		local path = get_path()
		vim.api.nvim_win_close(win, true)
		if vim.fn.isdirectory(path) == 1 then
			require("oil").open(path)
		else
			vim.cmd.edit(path)
		end
	end, { buffer = buf, silent = true })
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })
end

-- 辅助函数：查找目标行（优先完整路径匹配，然后文件名）
local function find_target_line(lines, current_file)
	if current_file == "" then
		return 1
	end
	-- 优先完整匹配相对路径
	for i, line in ipairs(lines) do
		if line == current_file then
			return i
		end
	end
	-- 退回到文件名匹配
	local current_name = vim.fn.fnamemodify(current_file, ":t")
	for i, line in ipairs(lines) do
		if vim.fn.fnamemodify(line, ":t") == current_name then
			return i
		end
	end
	return 1
end

-- 辅助函数：计算窗口尺寸
local function calc_window_size(lines, min_width, max_width_ratio, max_height_ratio)
	local width = min_width
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end
	width = math.min(width + 4, math.floor(vim.o.columns * max_width_ratio))
	local height = math.min(#lines, math.floor(vim.o.lines * max_height_ratio))
	return width, height
end

-- 辅助函数：构建标题文本
local function build_title(cwd, max_width)
	local title = " " .. cwd .. " "
	if #title > max_width - 4 then
		title = " ..." .. title:sub(-(max_width - 7)) .. " "
	end
	return title
end

------------------------------------------------------------
-- Fd 命令
------------------------------------------------------------

-- 辅助函数：获取当前参考文件路径（支持普通文件和Oil）
-- 仅在文件/目录位于当前工作目录下时返回路径
local function get_reference_file()
	local cwd = vim.fn.getcwd()
	local reference_path = nil

	local buftype = vim.bo.filetype
	if buftype == "oil" then
		-- 在Oil窗口中，获取光标下的条目
		local ok, oil = pcall(require, "oil")
		if ok then
			local entry = oil.get_cursor_entry()
			if entry then
				local dir = oil.get_current_dir()
				if dir then
					reference_path = dir .. entry.name
				end
			end
		end
	else
		-- 默认使用当前文件
		reference_path = vim.fn.expand("%:p")
	end

	-- 检查文件是否在当前工作目录下
	if reference_path and reference_path:sub(1, #cwd) == cwd then
		return vim.fn.fnamemodify(reference_path, ":.")
	end

	-- 不在当前目录下，返回空字符串（不定位）
	return ""
end

vim.api.nvim_create_user_command("Fd", function(opts)
	local current_file = get_reference_file()
	local cmd = opts.args ~= "" and "fd " .. opts.args or "fd"

	vim.system({ "bash", "-c", cmd }, { text = true }, function(obj)
		vim.schedule(function()
			local lines = {}
			for _, line in ipairs(vim.split(obj.stdout or "", "\n")) do
				if line ~= "" then
					table.insert(lines, line)
				end
			end
			if #lines == 0 then
				vim.notify("No results", vim.log.levels.WARN)
				return
			end

			local width, height = calc_window_size(lines, 40, 0.8, 0.8)
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			vim.bo[buf].modifiable = false
			vim.bo[buf].bufhidden = "wipe"

			local title = build_title(vim.fn.getcwd(), width)
			local win = create_float_win(buf, width, height, title)

			vim.wo[win].cursorline = true
			vim.api.nvim_win_set_cursor(win, { find_target_line(lines, current_file), 0 })
			setup_fd_keymaps(buf, win)
		end)
	end)
end, {
	nargs = "*",
	desc = "fd results in float, o to open Oil",
})

------------------------------------------------------------
-- Tree 命令
------------------------------------------------------------
vim.api.nvim_create_user_command("Tree", function(opts)
	local cmd = "fd"
	if opts.args ~= "" then
		cmd = "fd " .. opts.args
	end
	cmd = cmd .. " | tree --fromfile"

	vim.system({ "bash", "-c", cmd }, { text = true }, function(obj)
		vim.schedule(function()
			local lines = vim.split(obj.stdout or "", "\n")
			local width, height = calc_window_size(lines, 40, 0.8, 0.8)

			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			vim.bo[buf].modifiable = false
			vim.bo[buf].bufhidden = "wipe"

			create_float_win(buf, width, height, " fd | tree ")

			vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
			vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
		end)
	end)
end, {
	nargs = "*",
	desc = "Run fd | tree --fromfile in floating window",
})

------------------------------------------------------------
-- Run 命令
------------------------------------------------------------
vim.api.nvim_create_user_command("Run", function(opts)
	if opts.args ~= "" then
		vim.cmd("OverseerShell " .. opts.args)
		vim.cmd("OverseerOpen!")
	end
end, {
	nargs = "+",
	complete = "shellcmd",
	desc = "运行命令",
})

------------------------------------------------------------
-- Session 命令
------------------------------------------------------------
vim.api.nvim_create_user_command("Session", function(opts)
	if #opts.fargs == 0 then
		return
	end
	local args = opts.fargs[1]
	local name = #opts.fargs >= 2 and opts.fargs[2] or nil

	local resession = require("resession")
	if args == "save" then
		resession.save(name)
	elseif args == "delete" then
		resession.delete(name)
	elseif args == "load" then
		resession.load(name)
	end
end, {
	nargs = 1,
	complete = function(_, CmdLine)
		local args = vim.split(CmdLine, "%s+")
		if #args == 2 then
			return { "load", "save", "delete" }
		end
	end,
	desc = "Session管理",
})
