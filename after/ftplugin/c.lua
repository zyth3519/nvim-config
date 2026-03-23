-- C 文件 LSP 配置
vim.lsp.config("clangd", {
	cmd = { "clangd" },
})

vim.lsp.enable("clangd")

-- 仅对当前缓冲区生效，避免污染其他文件类型
vim.opt_local.tabstop = 4 -- 一个 Tab 显示为 4 个空格宽度
vim.opt_local.shiftwidth = 4 -- 自动缩进时使用 4 个空格
vim.opt_local.expandtab = true -- 将 Tab 转换为空格
vim.opt_local.softtabstop = 4 -- 编辑时按退格键删除 4 个空格
