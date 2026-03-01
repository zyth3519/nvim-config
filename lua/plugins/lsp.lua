local function get_lua_ls_settings()
	return {
		runtime = {
			version = "LuaJIT",
			path = { "lua/?.lua", "lua/?/init.lua" },
		},
		workspace = {
			checkThirdParty = false,
			library = { vim.env.VIMRUNTIME },
		},
	}
end

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
		event = { "BufReadPre", "BufNewFile" },
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

			-- 注入 Ufo 折叠能力
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- 依据 Neovim 0.11+ 标准使用 vim.lsp.config 配置并启用
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = get_lua_ls_settings(),
				},
			})
			vim.lsp.enable("lua_ls")

			-- Rust
			vim.lsp.config("rust_analyzer", { capabilities = capabilities })
			vim.lsp.enable("rust_analyzer")

			-- TypeScript
			vim.lsp.config("ts_ls", { capabilities = capabilities })
			vim.lsp.enable("ts_ls")

			-- Zig (zls)
			vim.lsp.config("zls", { capabilities = capabilities })
			vim.lsp.enable("zls")
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
			ensure_installed = { "lua_ls", "rust_analyzer", "ts_ls", "zls" },
			automatic_installation = true,
		},
	},

	-- 4. 格式化器及其他工具自动安装
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
