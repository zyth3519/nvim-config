return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	opts = {
		keys = {
			["<A-h>"] = function(win)
				win:resize("width", 2)
			end,
			["<A-l>"] = function(win)
				win:resize("width", -2)
			end,
			["<A-j>"] = function(win)
				win:resize("height", -2)
			end,
			["<A-k>"] = function(win)
				win:resize("height", 2)
			end,
		},
		exit_when_last = true,
		options = {
			left = { size = 25 },
			bottom = { size = 0.20 },
			right = { size = 30 },
			top = { size = 10 },
		},

		right = {
			{
				title = "Dap Scopes",
				ft = "dapui_scopes",
			},
			{
				title = "Dap Breakpoints",
				ft = "dapui_breakpoints",
			},
			{
				title = "Dap Stacks",
				ft = "dapui_stacks",
			},
			{
				title = "Dap Watches",
				ft = "dapui_watches",
			},
		},
		bottom = {
			{
				ft = "runner",
				title = "Run",
				size = { height = 0.25 },
			},
			{
				ft = "zyth_terminal",
				title = "Terminal",
				size = { height = 0.25 },
			},

			{
				ft = "qf",
				title = "QuickFix",
			},
			{
				title = "Dap Repl",
				ft = "dap-repl",
			},
			{
				title = "Dap Console",
				ft = "dapui_console",
			},
		},
	},
}
