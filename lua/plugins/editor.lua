return {
	-- 优秀的折叠插件 (Ufo)
	{
		"kevinhwang91/nvim-ufo",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			vim.o.foldcolumn = "1"
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}
			local language_servers = vim.lsp.get_clients() -- or list servers manually like {'gopls', 'clangd'}
			for _, ls in ipairs(language_servers) do
				require("lspconfig")[ls].setup({
					capabilities = capabilities,
				})
			end

			require("ufo").setup()
		end,
	},

	-- 多光标支持 (Vim-Visual-Multi)
	{
		"mg979/vim-visual-multi",
		branch = "master",
		event = { "BufReadPost", "BufNewFile" },
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-n>", -- Ctrl-N 选中当前单词并进入多光标模式
				["Find Subword Under"] = "<C-n>", -- 在选中部分词时也使用 Ctrl-N
			}
			-- 修复多光标模式下的退出问题 (ESC)
			vim.g.VM_quit_after_leaving_insert_mode = 1
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
		"folke/edgy.nvim",
		event = "VeryLazy",
		opts = {
			exit_when_last = true,
			left = {
				{
					ft = "NvimTree",
					title = "Nvim Tree",
					size = { width = 30 },
				},
			},

			right = {
				{
					ft = "dapui_scopes",
					size = { width = 30 },
				},
				{
					ft = "dapui_breakpoints",
					size = { width = 30 },
				},
				{
					ft = "dapui_stacks",
					size = { width = 30 },
				},
				{
					ft = "dapui_watches",
					size = { width = 30 },
				},
			},
			bottom = {
				ft = "qf",
				size = { height = 10 },
			},
			{
				{
					ft = "dap-repl",
					size = { height = 10 },
				},
				{
					ft = "dapui_console",
					size = { height = 10 },
				},
				{
					ft = "OverseerList",
					size = { height = 15 },
				},
				{
					ft = "OverseerOutput",
					size = { height = 15 },
				},
			},
		},
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
