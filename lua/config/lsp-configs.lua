-- LSP 服务器配置 (注册模式)
-- 注意：大部分 LSP 配置已移至 ftplugin/ 目录
-- 此文件仅保留全局 LSP 相关函数和通用配置

local M = {}

-- 全局 LSP 能力配置（供 ftplugin 使用）
function M.get_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- 注入 Ufo 折叠能力
	capabilities.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}
	return capabilities
end

-- 保留注册接口以兼容其他可能的用途
local servers = {}

function M.register(name, opts)
	servers[name] = opts or {}
end

function M.get_server_names()
	return vim.tbl_keys(servers)
end

-- 仅应用仍注册在此的服务器配置
-- 大部分服务器现在通过 ftplugin 直接启用
function M.apply()
	local capabilities = M.get_capabilities()
	for name, opts in pairs(servers) do
		local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, opts)
		vim.lsp.config(name, config)
		vim.lsp.enable(name)
	end
end

return M
