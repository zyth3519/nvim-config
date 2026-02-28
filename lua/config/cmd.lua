-- 【自定义命令 (Commands)】
vim.api.nvim_create_user_command("Run", function(opts)
	vim.cmd("belowright 10split")
	if opts.args ~= "" then
		vim.cmd("terminal " .. opts.args)
	else
		vim.cmd("terminal")
	end
end, { nargs = "*", desc = "带参数打开底部终端" })
