vim.lsp.config("ts_ls", {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
})
vim.lsp.enable("ts_ls")

-- 设置全局缩进
vim.opt.tabstop = 2 -- 一个 Tab 显示为 2 个空格宽度
vim.opt.shiftwidth = 2 -- 自动缩进时使用 2 个空格
vim.opt.expandtab = true -- 将 Tab 转换为空格
vim.opt.softtabstop = 2 -- 编辑时按退格键删除 2 个空格
