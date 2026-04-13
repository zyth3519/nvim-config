return {
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
}
