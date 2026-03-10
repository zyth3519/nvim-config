return {
	{
		"stevearc/overseer.nvim",
		opts = {
			component_aliases = {
				-- 重新定义 "default" 别名
				default = {
					{ "on_exit_set_status" },
					-- 加入你的自定义组件
					{ "auto_show_result" },
				},
			},
		},
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "OverseerList", "OverseerForm", "OverseerConfirm" },
				callback = function(event)
					local opts = { buffer = event.buf, noremap = true, silent = true }
					vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
					vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
					vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
					vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
				end,
			})
		end,
	},
}
