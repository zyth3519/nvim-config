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

vim.api.nvim_create_user_command("Ter", function()
	local ft = "zyth_terminal"

	-- 底部开 12 行终端
	vim.cmd("sp | ter")

	local buf = vim.api.nvim_get_current_buf()

	-- 终端常用设置
	vim.bo[buf].buflisted = false
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false

	-- 自定义 filetype
	vim.bo[buf].filetype = ft

	-- 可选：记录一个 buffer 变量，后面过滤更稳
	vim.b[buf].bottom_terminal = true

	-- 进入插入模式
	vim.cmd("startinsert")
end, {})
