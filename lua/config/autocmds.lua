-- 终端快捷键映射
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		local opts = { buffer = 0 }
		vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
		vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
		vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
		vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
		vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
		vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
		vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)

		-- 自动隐藏终端中的行号
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		-- 允许终端随着 nvim 退出而自动清理进程（避免 E948）
		vim.opt_local.bufhidden = "hide"
	end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
	pattern = ":",
	callback = function()
		local cmdline = vim.fn.getcmdline()
		-- 匹配以 ! (普通 shell 命令) 或 %! (针对当前文件的过滤命令) 开头的输入
		if cmdline:match("^!") or cmdline:match("^%%!") then
			-- 使用 pcall 包装，防止 noice 还没加载完成时报错而中断你的 ! 命令
			pcall(vim.cmd, "Noice dismiss")
		end
	end,
	desc = "Dismiss Noice messages before executing shell commands",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"typescript",
		"javascript",
		"typescriptreact",
		"javascriptreact",
	},
	callback = function()
		vim.lsp.config("ts_ls", {
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
		})
		vim.lsp.enable("ts_ls")

		-- 设置全局缩进
		vim.opt.tabstop = 2 -- 一个 Tab 显示为 2 个空格宽度
		vim.opt.shiftwidth = 2 -- 自动缩进时使用 2 个空格
		vim.opt.expandtab = true -- 将 Tab 转换为空格
		vim.opt.softtabstop = 2 -- 编辑时按退格键删除 2 个空格
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lua", "rust", "zig" },
	callback = function()
		vim.treesitter.start()
	end,
})
