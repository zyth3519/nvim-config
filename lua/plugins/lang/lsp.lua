return {
	-- 核心 LSP 配置
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			-- 全局 LSP 诊断配置
			vim.diagnostic.config({
				virtual_text = {
					enable = true,
					severity = { min = vim.diagnostic.severity.HINT },
				},
				severity_sort = true,
			})

			-- 添加类型推断
			vim.lsp.inlay_hint.enable(true)
		end,
	},

	-- 依赖管理总管 (Mason)
	{
		"williamboman/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- LSP 服务器自动安装
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			ensure_installed = {
				"clangd",
				"lua_ls",
				"ts_ls",
				"zls",
			},
			automatic_installation = false,
		},
	},

	-- 格式化器及其他工具自动安装
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = "VeryLazy",
		opts = {
			ensure_installed = {
				-- 代码格式化器
				"stylua", -- Lua 格式化
				"prettier", -- 前端 & Markdown 格式化
				-- DAP 调试适配器
				"codelldb", -- C/C++/Rust/Zig 调试器
				"js-debug-adapter", -- JavaScript / TypeScript 调试器
			},
			auto_update = false,
			run_on_start = true,
			start_delay = 3000,
		},
	},
}
