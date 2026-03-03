-- Lua 文件 LSP 配置

local capabilities = require("config.lsp-configs").get_capabilities()

vim.lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = { "lua/?.lua", "lua/?/init.lua" },
			},
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
		},
	},
})

vim.lsp.enable("lua_ls")
