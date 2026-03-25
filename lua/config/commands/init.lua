require("config.commands.session")

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
