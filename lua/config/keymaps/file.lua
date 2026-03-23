-- 智能打开 Oil：如果在 nvim-tree 中，根据当前节点路径打开
local function open_oil_smart()
	local buf_name = vim.api.nvim_buf_get_name(0)
	-- 检查是否在 nvim-tree 窗口
	if buf_name:match("NvimTree_") then
		local ok, api = pcall(require, "nvim-tree.api")
		if ok then
			local node = api.tree.get_node_under_cursor()
			if node then
				local path = node.absolute_path
				-- 如果是文件，获取其父目录
				if node.type == "file" then
					path = vim.fn.fnamemodify(path, ":h")
				end
				require("oil").open(path)
				return
			end
		end
	end
	-- 默认打开当前目录
	require("oil").open()
end

vim.keymap.set("n", "<leader>e", open_oil_smart, { desc = "打开 Oil" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "搜索当前项目文件" })
vim.keymap.set("n", "<leader>fe", "<cmd>Oil --float<cr>", { desc = "打开 Oil" })
vim.keymap.set("n", "<leader>fr", "<cmd>Oil --float .<cr>", { desc = "打开 Oil (Root)" })
