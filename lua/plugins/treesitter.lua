return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install({
				"lua",
				"rust",
				"zig",
				"javascript",
				"typescript",
				"tsx",
				"json",
				"toml",
				"markdown",
				"markdown_inline",
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					"lua",
					"rust",
					"zig",
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"json",
					"toml",
					"markdown",
				},
				callback = function()
					pcall(vim.treesitter.start)
					vim.opt_local.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		init = function()
			vim.g.no_plugin_maps = true
		end,
		config = function()
			require("nvim-treesitter-textobjects").setup({
				move = {
					set_jumps = true,
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({
				enable = true, -- 开启此功能
				max_lines = 1, -- 最多显示几行
				trim_scope = "outer", -- 保留外部作用域
			})
		end,
	},
}
