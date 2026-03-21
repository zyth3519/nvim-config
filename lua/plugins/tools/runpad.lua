return {
	{
		dir = vim.fn.stdpath("config") .. "/local/runpad.nvim",
		name = "runpad.nvim",
		dependencies = {
			"launchbox.nvim",
		},
		lazy = false,
		config = function()
			require("runpad").setup({
				project_glob = "lua/config/project_rules/*.lua",
			})
		end,
	},
}
