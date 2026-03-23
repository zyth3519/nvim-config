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

local function open_welcome_buffer()
	vim.cmd("enew")

	local bufnr = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	local width = vim.api.nvim_win_get_width(win)
	local height = vim.api.nvim_win_get_height(win)

	local function center(text)
		local pad = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
		return string.rep(" ", pad) .. text
	end

	local body = {
		center("Neovim"),
		center("-------"),
		"",
		center("Quick Start"),
		"",
		center("<leader>ff  查找文件"),
		center("<leader>e   打开 Oil"),
		center("<M-x>       执行 Run"),
		center(":Session    会话管理"),
		"",
		center("Press q to close"),
	}

	local top_padding = math.max(0, math.floor((height - #body) / 2)) - 10
	local lines = {}

	for _ = 1, top_padding do
		table.insert(lines, "")
	end

	vim.list_extend(lines, body)

	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].buflisted = false
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].modifiable = true

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	vim.bo[bufnr].modifiable = false
	vim.bo[bufnr].filetype = "starter"

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].colorcolumn = ""
	vim.wo[win].spell = false

	vim.keymap.set("n", "q", "<cmd>bd<cr>", {
		buffer = bufnr,
		silent = true,
		desc = "关闭欢迎页",
	})
end

local function close_current_buffer()
	local current = vim.api.nvim_get_current_buf()
	local buffers = list_normal_buffers()

	if #buffers <= 1 then
		open_welcome_buffer()
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
