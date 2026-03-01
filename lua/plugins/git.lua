return {
	-- Git 状态栏提示 (Gitsigns)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				watch_gitdir = { follow_files = true },
				auto_attach = true,
				sign_priority = 6,
				update_debounce = 100,
			})
		end,
	},

	-- 强大的纯文本 Git 客户端 (Magit for Neovim)
	{
		"NeogitOrg/neogit",
		cmd = { "Neogit" },
		dependencies = {
			"nvim-lua/plenary.nvim", -- 必须
			"nvim-telescope/telescope.nvim", -- 推荐
		},
		config = true,
	},

	-- Git 差异视图 (Diffview)
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	},
}
