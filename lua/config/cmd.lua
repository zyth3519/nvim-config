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
