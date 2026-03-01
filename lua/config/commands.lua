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
			vim.api.nvim_open_win(buf, true, {
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
