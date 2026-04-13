return {
	{
		dir = vim.fn.stdpath("config") .. "/local/launchbox.nvim",
		name = "launchbox.nvim",
		lazy = false,
		config = function()
			require("launchbox").setup({
				height = 12,
				ft = "runner",
				title = "Run",
				command_name = "Run",
				cwd = nil,
				env = nil,
			})

			vim.cmd([[cnoreabbrev <expr> sh ((getcmdtype() == ':' && getcmdline() == 'sh') ? 'Run' : 'sh')]])
		end,
	},

	{
		dir = vim.fn.stdpath("config") .. "/local/runpad.nvim",
		name = "runpad.nvim",
		dependencies = {
			"launchbox.nvim",
			"folke/which-key.nvim",
		},
		lazy = false,
		config = function()
			require("runpad").setup({
				rule_glob = "lua/rules/*.lua",
			})
		end,
	},
}
