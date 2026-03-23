return {
	-- 代码补全与提示 (Blink.cmp)
	{
		"saghen/blink.cmp",
		dependencies = { "rafamadriz/friendly-snippets" },
		event = { "BufReadPost", "BufNewFile" },
		version = "1.*",
		opts = {
			keymap = {
				preset = "none",
				["<cr>"] = { "select_and_accept", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback_to_mappings" },
				["<C-n>"] = { "select_next", "fallback_to_mappings" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
			},
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = true } },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			signature = { enabled = true },
			fuzzy = {
				implementation = "prefer_rust_with_warning",
				sorts = {
					"exact",
					-- 降低下划线开头的条目优先级 (如 _private_var)
					function(a, b)
						local _, a_under = a.label:find("^_+")
						local _, b_under = b.label:find("^_+")
						a_under = a_under or 0
						b_under = b_under or 0
						if a_under > b_under then
							return false
						elseif a_under < b_under then
							return true
						end
					end,
					"score",
					"sort_text",
				},
			},
		},
		opts_extend = { "sources.default" },
	},

	-- 括号自动补全 (Autopairs)
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},

	-- 环绕字符编辑支持 (Surround)
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
	},

	-- 代码格式化引擎 (Conform)
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters = {
				clang_format = {
					append_args = {
						"--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, ColumnLimit: 100}",
					},
				},
			},
			formatters_by_ft = {
				c = { "clang_format" },
				cpp = { "clang_format" },
				h = { "clang_format" },
				hpp = { "clang_format" },
				lua = { "stylua" },
				rust = { "rustfmt" },
				zig = { "zigfmt" }, -- 添加 Zig 格式化
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				markdown = { "prettier" },
				toml = { "taplo" },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		},
	},

	-- 优秀的折叠插件 (Ufo)
	{
		"kevinhwang91/nvim-ufo",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			-- treesitter
			require("ufo").setup({
				provider_selector = function()
					return { "treesitter", "indent" }
				end,
			})
		end,
	},

	-- 多光标支持 (Multicursor.nvim)
	{
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local mc = require("multicursor-nvim")
			mc.setup()

			mc.addKeymapLayer(function(layerSet)
				layerSet({ "n", "x" }, "<left>", mc.prevCursor, { desc = "上一个光标" })
				layerSet({ "n", "x" }, "<right>", mc.nextCursor, { desc = "下一个光标" })
				layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "删除当前光标" })

				layerSet("n", "<esc>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					else
						mc.clearCursors()
					end
				end, { desc = "启用/清除光标" })
			end)

			local hl = vim.api.nvim_set_hl
			hl(0, "MultiCursorCursor", { reverse = true })
			hl(0, "MultiCursorVisual", { link = "Visual" })
			hl(0, "MultiCursorSign", { link = "SignColumn" })
			hl(0, "MultiCursorMatchPreview", { link = "Search" })
			hl(0, "MultiCursorDisabledCursor", { reverse = true })
			hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
			hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
		end,
	},

	-- 快速跳转 (Flash)
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
}
