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
}
