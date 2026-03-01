vim.api.nvim_create_user_command("Tree", function(opts)
	local cmd = "fd"
	if opts.args ~= "" then
		cmd = "fd " .. opts.args
	end
	cmd = cmd .. " | tree --fromfile"

	vim.system({ "bash", "-c", cmd }, { text = true }, function(obj)
		vim.schedule(function()
			local lines = vim.split(obj.stdout or "", "\n")

			-- 计算窗口大小
			local width = 0
			for _, line in ipairs(lines) do
				width = math.max(width, #line)
			end
			width = math.min(math.max(width + 2, 40), math.floor(vim.o.columns * 0.8))
			local height = math.min(#lines, math.floor(vim.o.lines * 0.8))

			-- 创建 buffer
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			vim.bo[buf].modifiable = false
			vim.bo[buf].bufhidden = "wipe"

			-- 打开浮动窗口
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				row = math.floor((vim.o.lines - height) / 2),
				col = math.floor((vim.o.columns - width) / 2),
				width = width,
				height = height,
				style = "minimal",
				border = "rounded",
				title = " fd | tree ",
				title_pos = "center",
			})

			-- 按 q 或 Esc 关闭
			vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
			vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
		end)
	end)
end, {
	nargs = "*",
	desc = "Run fd | tree --fromfile in floating window",
})

vim.api.nvim_create_user_command("Fd", function(opts)
	local cmd = "fd"
	if opts.args ~= "" then
		cmd = "fd " .. opts.args
	end
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
			-- 计算窗口大小
			local width = 0
			for _, line in ipairs(lines) do
				width = math.max(width, #line)
			end
			width = math.min(math.max(width + 4, 40), math.floor(vim.o.columns * 0.8))
			local height = math.min(#lines, math.floor(vim.o.lines * 0.8))
			-- 创建 buffer
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			vim.bo[buf].modifiable = false
			vim.bo[buf].bufhidden = "wipe"
			-- 打开浮动窗口
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				row = math.floor((vim.o.lines - height) / 2),
				col = math.floor((vim.o.columns - width) / 2),
				width = width,
				height = height,
				style = "minimal",
				border = "rounded",
				title = " fd results (o: oil  enter: open  q: quit) ",
				title_pos = "center",
			})
			vim.wo[win].cursorline = true
			-- 获取光标所在行的路径
			local function get_path()
				local line = vim.api.nvim_get_current_line()
				return vim.fn.fnamemodify(line, ":p")
			end
			-- o: 用 Oil 打开所在目录
			vim.keymap.set("n", "o", function()
				local path = get_path()
				local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
				vim.api.nvim_win_close(win, true)
				require("oil").open(dir)
			end, { buffer = buf, silent = true })
			-- Enter: 直接打开文件
			vim.keymap.set("n", "<CR>", function()
				local path = get_path()
				vim.api.nvim_win_close(win, true)
				if vim.fn.isdirectory(path) == 1 then
					require("oil").open(path)
				else
					vim.cmd.edit(path)
				end
			end, { buffer = buf, silent = true })
			-- q / Esc: 关闭
			vim.keymap.set("n", "q", function()
				vim.api.nvim_win_close(win, true)
			end, { buffer = buf, silent = true })
			vim.keymap.set("n", "<Esc>", function()
				vim.api.nvim_win_close(win, true)
			end, { buffer = buf, silent = true })
		end)
	end)
end, {
	nargs = "*",
	desc = "fd results in float, o to open Oil",
})
-- 【自定义命令 (Commands)】
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

vim.api.nvim_create_user_command("Session", function(opts)
	if #opts.fargs == 0 then
		return
	end
	local args = opts.fargs[1]
	local name = nil
	if #opts.fargs >= 2 then
		name = opts.fargs[2]
	end

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
			return {
				"load",
				"save",
				"delete",
			}
		end
	end,
	desc = "Session管理",
})
