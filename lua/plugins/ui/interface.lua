return {
	-- 彩虹括号
	{
		"HiPhish/rainbow-delimiters.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- 必须依赖 treesitter
		},
	},

	-- 主题 (Colorscheme)
	{
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
	},

	-- 状态栏 (Statusline)
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup()
		end,
	},

	-- 顶部标签栏/缓冲区 (Bufferline)
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("bufferline").setup({
				options = {
					mode = "buffers",
					numbers = "ordinal",
					indicator = { style = "underline" },
					buffer_close_icon = "󰅖",
					modified_icon = "●",
					separator_style = "thin",
					always_show_bufferline = true,
					-- 解决与自定义文件树以及 Oil 的重叠问题
					offsets = {
						{
							filetype = "mytree",
							text = "File Explorer",
							text_align = "left",
						},
						{
							filetype = "oil",
							text = "Oil File Manager",
							text_align = "left",
						},
					},
					diagnostics = "nvim_lsp",
					diagnostics_indicator = function(count, level)
						local icon = level:match("error") and " " or level:match("warn") and " " or "ℹ "
						return " " .. icon .. count
					end,
				},
			})
		end,
	},

	-- 快捷键提示 (Which-key)
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
		},
	},

	-- LSP 加载进度提示 (Fidget)
	{
		"j-hui/fidget.nvim",
		tag = "legacy",
		opts = {
			text = {
				spinner = "dots",
				done = "✓",
				commenced = "启动中...",
				completed = "加载完成",
			},
			window = {
				relative = "editor",
				blend = 0,
				border = "none",
			},
			sources = {
				["*"] = { ignore = false },
			},
		},
		event = "LspAttach",
	},

	-- 缩进线 (Indent Blankline)
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- 必须依赖 treesitter
		},
		config = function()
			require("ibl").setup({
				indent = {
					char = "▏", -- 另一种比较细的字符
				},
				scope = {
					show_start = true,
					show_end = true,
					include = {
						node_type = {
							["*"] = {
								"arguments",
								"block",
								"bracket",
								"declaration",
								"field",
								"for_statement",
								"func_literal",
								"function",
								"function_call",
								"function_declaration",
								"if_statement",
								"import_statement",
								"list",
								"method",
								"object",
								"return_statement",
								"switch_statement",
								"table",
								"try_statement",
							},
							lua = {
								"table_constructor",
								"function_definition",
							},
						},
					},
				},
			})
		end,
	},
	-- UI 增强 (Noice)
	{
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
	},
	-- 窗口管理
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		opts = {
			keys = {
				["<A-h>"] = function(win)
					win:resize("width", -2)
				end,
				["<A-l>"] = function(win)
					win:resize("width", 2)
				end,
				["<A-j>"] = function(win)
					win:resize("height", 2)
				end,
				["<A-k>"] = function(win)
					win:resize("height", -2)
				end,
			},
			exit_when_last = true,
			options = {
				left = { size = 25 },
				bottom = { size = 0.40 },
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
					size = { height = 0.40 },
				},
				{
					ft = "zyth_terminal",
					title = "Terminal",
					size = { height = 0.40 },
				},

				{
					ft = "man",
					title = "Man",
					size = { height = 0.40 },
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
				{
					title = "OverseerList",
					ft = "OverseerList",
				},
				{
					title = "OverseerOutput",
					ft = "OverseerOutput",
				},
			},
		},
	},
}
