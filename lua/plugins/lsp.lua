return {
	-- Zig 官方文件类型与高亮支持
	{
		"ziglang/zig.vim",
		ft = { "zig" },
		init = function()
			-- 我们使用 conform 来控制格式化，这里关掉 zig.vim 自带的保存时格式化
			vim.g.zig_fmt_autosave = 0
		end,
	},

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

			-- 应用所有已注册的 LSP 配置
			require("config.lsp-configs").apply()
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
		opts = function()
			return {
				ensure_installed = require("config.lsp-configs").get_server_names(),
				automatic_installation = true,
			}
		end,
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
			},
			auto_update = false,
			run_on_start = true,
			start_delay = 3000,
		},
	},
}
