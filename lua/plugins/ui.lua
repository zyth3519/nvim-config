return {
	-- 1. 主题 (Colorscheme)
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

	-- 2. 状态栏 (Statusline)
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup()
		end,
	},

	-- 3. 顶部标签栏/缓冲区 (Bufferline)
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

	-- 4. 快捷键提示 (Which-key)
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-mini/mini.nvim" },
		opts = {
			preset = "modern",
		},
	},

	-- 5. LSP 加载进度提示 (Fidget)
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

	-- 6. 缩进线 (Indent Blankline)
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

	-- 7. UI 增强 (Noice)
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- 在这里可以添加配置项
		},
		dependencies = {
			-- 如果懒加载，需要确保依赖的可用性
			"MunifTanjim/nui.nvim",
			-- 推荐的通知插件
			"rcarriga/nvim-notify",
		},
	},
}
