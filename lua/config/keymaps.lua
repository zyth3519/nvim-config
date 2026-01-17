-- leader键
vim.g.mapleader = " "

-- Ctrl+h/j/k/l 快速切换窗口
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- Ctrl + 右箭头：增大当前窗口宽度（垂直分窗，向右扩展）
vim.keymap.set("n", "<C-Right>", "5<C-w>>", { noremap = true, silent = true })
-- Ctrl + 左箭头：缩小当前窗口宽度（垂直分窗，向左收缩）
vim.keymap.set("n", "<C-Left>", "5<C-w><", { noremap = true, silent = true })
-- Ctrl + 下箭头：增大当前窗口高度（水平分窗，向下扩展）
vim.keymap.set("n", "<C-Down>", "5<C-w>+", { noremap = true, silent = true })
-- Ctrl + 上箭头：缩小当前窗口高度（水平分窗，向上收缩）
vim.keymap.set("n", "<C-Up>", "5<C-w>-", { noremap = true, silent = true })

-- buffer切换
vim.keymap.set("n", "<S-h>", ":bp<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<S-l>", ":bn<cr>", { noremap = true, silent = true })

local wk = require("which-key")
local telescope = require("telescope.builtin")

wk.add({
    { "g", group = "导航/查询" },
    { "<leader>c", group = "代码操作" },
    { "<leader>cr", vim.lsp.buf.rename, desc = '重命名' },
    { "<leader>ca", vim.lsp.buf.code_action, desc = '代码操作' },
    { "<leader>cf", vim.lsp.buf.format, desc = '格式化' },
    { "<leader>cd", telescope.diagnostics, desc = '查看诊断' },
})


wk.add({
    { "<leader>f", group = "查找/搜索" },
    { "<leader>ff", telescope.find_files, desc = "查找项目文件（忽略.git）" },
    { "<leader>fg", telescope.live_grep, desc = "全局内容模糊搜索" },
    { "<leader>fb", telescope.buffers, desc = "查询已打开缓冲区" },
    { "<leader>fh", telescope.help_tags, desc = "查询 Neovim 帮助文档" },
    { "<leader>fs", telescope.lsp_document_symbols, desc = "查询当前文档 LSP 符号" },
    { "<leader>fS", telescope.lsp_workspace_symbols, desc = "查询工作区 LSP 符号" },
})

wk.add({
    {"<leader>e", ":Oil --float<cr>", desc = "打开文件管理器"},
    {"<leader>E", ":Oil --float .<cr>", desc = "打开文件管理器(Root)"},
    {"<leader>t", ":ToggleTerm<cr>", desc = "打开终端"},
})

vim.keymap.set("n", "grr", telescope.lsp_references , { noremap = true, silent = true, desc = '查看引用' })
vim.keymap.set("n", "grt", telescope.lsp_type_definitions, { noremap = true, silent = true, desc = '查看类型定义' })
vim.keymap.set("n", "gd", telescope.lsp_definitions, { noremap = true, silent = true, desc = "跳转到定义" })
vim.keymap.set("n", "gri", telescope.lsp_implementations, { noremap = true, silent = true, desc = "跳转到实现" })

vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { noremap = true, silent = true, desc = "跳转到声明" })
vim.keymap.set("n", "gO", vim.lsp.buf.document_symbol, { noremap = true, silent = true, desc = '查看符号' })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "悬浮显示文档注释" })
vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { noremap = true, silent = true, desc = '代码操作' })
vim.keymap.set("n", "grn", vim.lsp.buf.rename, { noremap = true, silent = true, desc = '重命名' })
