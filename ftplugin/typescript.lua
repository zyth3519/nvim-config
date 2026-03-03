-- TypeScript/JavaScript 文件 LSP 配置

vim.lsp.config("ts_ls", {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
})

vim.lsp.enable("ts_ls")
