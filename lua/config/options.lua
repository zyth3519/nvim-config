-- 启用绝对行号
vim.opt.number = true
-- 启用相对行号
vim.opt.relativenumber = true

-- 核心缩进配置：4 个空格缩进
vim.opt.shiftwidth = 4        -- 缩进/反缩进的空格数
vim.opt.tabstop = 4           -- tab 键插入的空格数
vim.opt.softtabstop = 4       -- backspace 键删除的空格数
vim.opt.expandtab = true      -- tab 键转换为空格

-- 自动缩进配置
vim.opt.autoindent = true     -- 继承上一行缩进
vim.opt.smartindent = true    -- 智能代码缩进

-- netrw配置
vim.g.netrw_banner = 0        -- 关闭顶部横幅
vim.g.netrw_liststyle = 3     -- 树形显示文件
vim.g.netrw_winsize = 25      -- 侧边栏宽度

-- 设置主题
vim.cmd('colorscheme catppuccin')
