-- 【缓冲区管理 (Buffer)】
local function list_normal_buffers()
	local buffers = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
			local bt = vim.bo[bufnr].buftype
			if bt == "" then
				table.insert(buffers, bufnr)
			end
		end
	end
	return buffers
end

local function close_current_buffer()
	local current = vim.api.nvim_get_current_buf()
	local buffers = list_normal_buffers()

	if #buffers <= 1 then
		vim.cmd("enew")
	end

	if vim.api.nvim_buf_is_valid(current) and vim.bo[current].buflisted then
		vim.cmd("bd " .. current)
	end
end

vim.keymap.set("n", "<C-q>", close_current_buffer, { desc = "关闭当前文件(Buffer)" })
vim.keymap.set("n", "<leader>q", close_current_buffer, { desc = "关闭当前文件(Buffer)" })
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
