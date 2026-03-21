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
				rule_glob = "lua/config/project_rules/*.lua",
			})
		end,
	},
}
