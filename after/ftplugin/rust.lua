-- Rust 文件特定配置

-- 使用 RustLsp codeAction 替代默认的 vim.lsp.buf.code_action()
vim.keymap.set(
	{ "n", "v" },
	"<leader>ca",
	function()
		vim.cmd("RustLsp codeAction")
	end,
	{ buffer = true, desc = "Rust Code Action" }
)
