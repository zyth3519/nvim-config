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
					-- 语法高亮（Neovim 内置）
					pcall(vim.treesitter.start)
					-- 代码折叠（Neovim 内置）
					vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.wo[0][0].foldmethod = "expr"
					-- 智能缩进（nvim-treesitter 提供，实验性）
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
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
