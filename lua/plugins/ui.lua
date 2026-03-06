return {
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
		config = function()
			local hooks = require("ibl.hooks")
			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				vim.api.nvim_set_hl(0, "IblScope", { fg = "#585b70" })
			end)

			require("ibl").setup({
				indent = { char = "┊" },
				scope = {
					show_start = false,
					show_end = false,
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
		opts = {
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
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		keys = {
			-- close window
			["q"] = function(win)
				win:close()
			end,
			-- hide window
			["<c-q>"] = function(win)
				win:hide()
			end,
			-- close sidebar
			["Q"] = function(win)
				win.view.edgebar:close()
			end,
			-- next open window
			["]w"] = function(win)
				win:next({ visible = true, focus = true })
			end,
			-- previous open window
			["[w"] = function(win)
				win:prev({ visible = true, focus = true })
			end,
			-- next loaded window
			["]W"] = function(win)
				win:next({ pinned = false, focus = true })
			end,
			-- prev loaded window
			["[W"] = function(win)
				win:prev({ pinned = false, focus = true })
			end,
			-- increase width
			["<c-w>>"] = function(win)
				win:resize("width", 2)
			end,
			-- decrease width
			["<c-w><lt>"] = function(win)
				win:resize("width", -2)
			end,
			-- increase height
			["<c-w>+"] = function(win)
				win:resize("height", 2)
			end,
			-- decrease height
			["<c-w>-"] = function(win)
				win:resize("height", -2)
			end,
			-- reset all custom sizing
			["<c-w>="] = function(win)
				win.view.edgebar:equalize()
			end,
		},
		opts = {
			exit_when_last = true,
			options = {
				left = { size = 30 },
				bottom = { size = 10 },
				right = { size = 30 },
				top = { size = 10 },
			},
			left = {
				{
					ft = "NvimTree",
					title = "Nvim Tree",
				},
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
