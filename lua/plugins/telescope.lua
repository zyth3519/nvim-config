return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-telescope/telescope-frecency.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			{ "nvim-telescope/telescope-smart-history.nvim", dependencies = "kkharji/sqlite.lua" },
		},
		config = function()
			local data_path = vim.fn.stdpath("data")
			require("telescope").setup({
				defaults = {
					file_ignore_patterns = {
						"node_modules/",
						".git/",
						"%.lock",
						"dist/",
						"build/",
					},
					history = {
						path = data_path .. "/telescope_history.sqlite3",
						limit = 100,
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			-- 加载扩展
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "frecency")
			pcall(require("telescope").load_extension, "ui-select")
			pcall(require("telescope").load_extension, "smart_history")
		end,
	},
}
