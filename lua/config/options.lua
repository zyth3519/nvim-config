-- 启用绝对行号
vim.opt.number = true
-- 启用相对行号
vim.opt.relativenumber = true

-- 核心缩进配置：4 个空格缩进
vim.opt.shiftwidth = 4 -- 缩进/反缩进的空格数
vim.opt.tabstop = 4 -- tab 键插入的空格数
vim.opt.softtabstop = 4 -- backspace 键删除的空格数
vim.opt.expandtab = true -- tab 键转换为空格

vim.opt.splitright = true -- 垂直分割时，新窗口默认创建在当前窗口右侧（替代默认左侧）
vim.opt.splitbelow = true -- 水平分割时，新窗口默认创建在当前窗口下方（替代默认上方）

vim.o.foldcolumn = "1" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.opt.laststatus = 3
vim.opt.splitkeep = "screen"

if vim.fn.has("wsl") == 1 then
	vim.g.clipboard = {
		name = "win32yank-wsl",
		copy = {
			["+"] = "win32yank.exe -i --crlf",
			["*"] = "win32yank.exe -i --crlf",
		},
		paste = {
			["+"] = "win32yank.exe -o --lf",
			["*"] = "win32yank.exe -o --lf",
		},
		cache_enabled = 0,
	}
end
