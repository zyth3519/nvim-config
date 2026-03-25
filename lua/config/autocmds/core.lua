-- 终端快捷键映射
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		local opts = { buffer = 0 }
		vim.keymap.set(
			"t",
			"<esc>",
			[[<C-\><C-n>]],
			vim.tbl_extend("force", opts, { desc = "终端退出插入模式" })
		)
		vim.keymap.set("t", "jk", [[<C-\><C-n>]], vim.tbl_extend("force", opts, { desc = "终端退出插入模式" }))
		vim.keymap.set(
			"t",
			"<C-h>",
			[[<Cmd>wincmd h<CR>]],
			vim.tbl_extend("force", opts, { desc = "终端跳转到左侧窗口" })
		)
		vim.keymap.set(
			"t",
			"<C-j>",
			[[<Cmd>wincmd j<CR>]],
			vim.tbl_extend("force", opts, { desc = "终端跳转到下方窗口" })
		)
		vim.keymap.set(
			"t",
			"<C-k>",
			[[<Cmd>wincmd k<CR>]],
			vim.tbl_extend("force", opts, { desc = "终端跳转到上方窗口" })
		)
		vim.keymap.set(
			"t",
			"<C-l>",
			[[<Cmd>wincmd l<CR>]],
			vim.tbl_extend("force", opts, { desc = "终端跳转到右侧窗口" })
		)
		vim.keymap.set(
			"t",
			"<C-w>",
			[[<C-\><C-n><C-w>]],
			vim.tbl_extend("force", opts, { desc = "终端窗口命令前缀" })
		)

		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.bufhidden = "hide"
	end,
})
