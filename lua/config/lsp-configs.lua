-- LSP 服务器配置 (注册模式)

local M = {}

-- 注册表
local servers = {}

--- 注册一个 LSP 服务器配置
--- @param name string 服务器名称 (对应 lspconfig 的 key)
--- @param opts? table 额外配置 (settings, cmd, filetypes 等)
function M.register(name, opts)
	servers[name] = opts or {}
end

--- 获取所有已注册的服务器名称列表 (供 mason-lspconfig ensure_installed 使用)
--- @return string[]
function M.get_server_names()
	return vim.tbl_keys(servers)
end

--- 将所有已注册的配置应用到 LSP
function M.apply()
	-- 注入 Ufo 折叠能力
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}

	for name, opts in pairs(servers) do
		local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, opts)
		vim.lsp.config(name, config)
		vim.lsp.enable(name)
	end
end

------------------------------------------------------------
-- 注册 Lua
------------------------------------------------------------
M.register("lua_ls", {
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

------------------------------------------------------------
-- 注册 Rust
------------------------------------------------------------
M.register("rust_analyzer")

------------------------------------------------------------
-- 注册 TypeScript
------------------------------------------------------------
M.register("ts_ls")

------------------------------------------------------------
-- 注册 Zig
------------------------------------------------------------
M.register("zls")

return M
