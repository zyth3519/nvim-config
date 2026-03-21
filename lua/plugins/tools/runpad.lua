return {
	{
		dir = vim.fn.stdpath("config") .. "/local/runpad.nvim",
		name = "runpad.nvim",
		lazy = false,
		config = function()
			require("runpad").setup({
				launchbox = {
					height = 12,
					ft = "runner",
					title = "Run",
					command_name = "Run",
					cwd = nil,
					env = nil,
				},
				project_glob = "lua/config/projects/*.lua",
			})

			vim.cmd([[cnoreabbrev <expr> sh ((getcmdtype() == ':' && getcmdline() == 'sh') ? 'Run' : 'sh')]])
		end,
	},
}
