-- 启用绝对行号
vim.opt.number = true
-- 启用相对行号
vim.opt.relativenumber = true

-- 核心缩进配置：4 个空格缩进
vim.opt.shiftwidth = 4 -- 缩进/反缩进的空格数
vim.opt.tabstop = 4 -- tab 键插入的空格数
vim.opt.softtabstop = 4 -- backspace 键删除的空格数
vim.opt.expandtab = true -- tab 键转换为空格

-- 自动缩进配置
vim.opt.autoindent = true -- 继承上一行缩进
vim.opt.smartindent = true -- 智能代码缩进

-- netrw配置
vim.g.netrw_banner = 0 -- 关闭顶部横幅
vim.g.netrw_liststyle = 3 -- 树形显示文件
vim.g.netrw_winsize = 25 -- 侧边栏宽度

-- 设置主题
vim.cmd("colorscheme catppuccin")

vim.opt.splitright = true -- 垂直分割时，新窗口默认创建在当前窗口右侧（替代默认左侧）
vim.opt.splitbelow = true -- 水平分割时，新窗口默认创建在当前窗口下方（替代默认上方）

-- 折叠设置
vim.o.foldcolumn = "1" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
-- Default splitting will cause your main splits to jump when opening an edgebar.
-- To prevent this, set `splitkeep` to either `screen` or `topline`.
vim.opt.splitkeep = "screen"

vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = require("vim.ui.clipboard.osc52").paste("+"),
		["*"] = require("vim.ui.clipboard.osc52").paste("*"),
	},
}
