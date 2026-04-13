return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	opts = {
		views = {
			split = {
				size = {
					height = 15,
				},
			},
		},
		routes = {
			{
				view = "split",
				filter = {
					event = "msg_show",
					kind = {
						"shell_out",
						"shell_err",
					},
				},
				opts = {
					skip = false,
				},
			},
		},
	},
}
