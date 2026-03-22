-- 【缓冲区管理 (Buffer)】
vim.keymap.set("n", "<C-q>", "<cmd>bd<cr>", { desc = "关闭当前文件(Buffer)" })
vim.keymap.set("n", "<leader>q", "<cmd>bd<cr>", { desc = "关闭当前文件(Buffer)" })
vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "只保留当前编辑的文件" })
vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", { desc = "关闭左边所有缓冲区" })
vim.keymap.set("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", { desc = "关闭右边所有缓冲区" })
vim.keymap.set("n", "<leader>b<", "<cmd>BufferLineMovePrev<cr>", { desc = "向左移动 Buffer" })
vim.keymap.set("n", "<leader>b>", "<cmd>BufferLineMoveNext<cr>", { desc = "向右移动 Buffer" })
vim.keymap.set("n", "<leader>bf", "<cmd>bf<cr>", { desc = "跳转到第一个 Buffer" })
vim.keymap.set("n", "<leader>bF", "<cmd>bl<cr>", { desc = "跳转到最后一个 Buffer" })

-- Bufferline 数字切换 (1-9)
for i = 1, 9 do
	vim.keymap.set(
		"n",
		"<leader>" .. i,
		"<cmd>BufferLineGoToBuffer " .. i .. "<cr>",
		{ desc = "跳转到 Buffer " .. i }
	)
end
