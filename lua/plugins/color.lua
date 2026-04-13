return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	opts = {
		integrations = {
			indent_blankline = {
				enabled = true,
				scope_color = "lavender",
				colored_indent_levels = false,
			},
		},
	},
	config = function()
		-- 设置主题
		vim.cmd("colorscheme catppuccin")
	end,
}
