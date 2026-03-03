-- TypeScript/JavaScript 文件 LSP 配置

local capabilities = require("config.lsp-configs").get_capabilities()

vim.lsp.config("ts_ls", {
	cmd = { "typescript-language-server", "--stdio" },
	capabilities = capabilities,
	filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
})

vim.lsp.enable("ts_ls")
