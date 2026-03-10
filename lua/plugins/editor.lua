return {
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

	-- 强大且安全的会话管理 (Resession)
	{
		"stevearc/resession.nvim",
		config = function()
			local resession = require("resession")
			-- 定期保存会话
			resession.setup({
				autosave = {
					enabled = true,
					interval = 60,
					notify = false,
				},
				extensions = {
					dap = {}, -- 保存 dap 断点信息
				},
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					-- Only load the session if nvim was started with no args and without reading from stdin
					if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
						-- Save these to a different directory, so our manual sessions don't get polluted
						resession.load(vim.fn.getcwd(), { dir = "dirsession", silence_errors = true })
					end
				end,
				nested = true,
			})
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function()
					if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
						resession.save(vim.fn.getcwd(), { dir = "dirsession", notify = false })
					end
				end,
			})
			vim.api.nvim_create_autocmd("StdinReadPre", {
				callback = function()
					-- Store this for later
					vim.g.using_stdin = true
				end,
			})
		end,
	},
	{
		"stevearc/overseer.nvim",
		opts = {
			component_aliases = {
				-- 重新定义 "default" 别名
				default = {
					{ "on_exit_set_status" },
					-- 加入你的自定义组件
					{ "auto_show_result" },
				},
			},
		},
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "OverseerList", "OverseerForm", "OverseerConfirm" },
				callback = function(event)
					local opts = { buffer = event.buf, noremap = true, silent = true }
					vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
					vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
					vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
					vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
				end,
			})
		end,
	},

	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
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
