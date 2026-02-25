local map = vim.keymap.set
-- 将所有 leader 键配置在这里
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- =========================================================================
-- 1. 核心基础快捷键 (Core)
-- =========================================================================

-- 窗口导航 (Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口", noremap = true, silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "跳转到下方窗口", noremap = true, silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "跳转到上方窗口", noremap = true, silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "跳转到右侧窗口", noremap = true, silent = true })

-- 窗口大小调整 (Ctrl + 箭头)
map("n", "<C-Up>", "5<C-w>-", { desc = "窗口高度减少", noremap = true, silent = true })
map("n", "<C-Down>", "5<C-w>+", { desc = "窗口高度增加", noremap = true, silent = true })
map("n", "<C-Left>", "5<C-w><", { desc = "窗口宽度减少", noremap = true, silent = true })
map("n", "<C-Right>", "5<C-w>>", { desc = "窗口宽度增加", noremap = true, silent = true })

-- 缓冲区切换 (Shift + hl)
map("n", "<S-h>", ":bp<cr>", { desc = "上一个缓冲区", noremap = true, silent = true })
map("n", "<S-l>", ":bn<cr>", { desc = "下一个缓冲区", noremap = true, silent = true })

-- =========================================================================
-- 2. 插件快捷键注册 (统合至此以实现统一管理)
-- =========================================================================

-- 配置 Which-Key 的快捷键组描述 (仅用于弹出面板的菜单分类提示)
local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
    wk.add({
        { "<leader>b", group = "缓冲区 (Buffer)" },
        { "<leader>c", group = "代码 (Code)" },
        { "<leader>d", group = "调试 (Debug)" },
        { "<leader>e", group = "文件树 (Explorer)" },
        { "<leader>s", group = "搜索 (Search)" },
        { "<leader>w", group = "窗口 (Window)" },
        { "g", group = "导航/跳转 (Go)" },
    })
end

-- 【文件管理器 (Explorer)】
map("n", "<leader>ee", ":Tree<cr>", { desc = "打开树形浏览器", noremap = true, silent = true })
map("n", "<leader>eo", ":Oil --float<cr>", { desc = "打开 Oil 文件管理器", noremap = true, silent = true })
map("n", "<leader>eO", ":Oil --float .<cr>", { desc = "打开 Oil (Root)", noremap = true, silent = true })
map("n", "<leader>t", ":ToggleTerm<cr>", { desc = "打开终端", noremap = true, silent = true })

-- 【窗口管理 (Window)】
map("n", "<leader>wh", ":split<cr>", { desc = "水平分割当前窗口", noremap = true, silent = true })
map("n", "<leader>wv", ":vsplit<cr>", { desc = "垂直分割当前窗口", noremap = true, silent = true })
map("n", "<leader>wx", "<C-w>x", { desc = "窗口互换", noremap = true, silent = true })
map("n", "<leader>wq", "<C-w>q", { desc = "关闭当前窗口", noremap = true, silent = true })
map("n", "<leader>wo", ":only<cr>", { desc = "关闭其他所有窗口", noremap = true, silent = true })
map("n", "<leader>wns", ":new<cr>", { desc = "横向分割并新建文件", noremap = true, silent = true })
map("n", "<leader>wnv", ":vnew<cr>", { desc = "垂直分割并新建文件", noremap = true, silent = true })

-- 【缓冲区管理 (Buffer)】
map("n", "<leader>bl", ":ls<cr>", { desc = "显示 Buffer 列表", noremap = true, silent = true })
map("n", "<leader>ba", ":ball<cr>", { desc = "为每个 Buffer 打开窗口", noremap = true, silent = true })
map("n", "<leader>bd", ":bd<cr>", { desc = "删除 Buffer 并关闭窗口", noremap = true, silent = true })
map("n", "<leader>bD", ":bw<cr>", { desc = "彻底删除当前 Buffer", noremap = true, silent = true })
map("n", "<leader>bo", ":%bd | e# | bd#<cr>", { desc = "只保留当前编辑的文件", noremap = true, silent = true })
map("n", "<leader>bf", ":bf<cr>", { desc = "跳转到第一个 Buffer", noremap = true, silent = true })
map("n", "<leader>bF", ":bl<cr>", { desc = "跳转到最后一个 Buffer", noremap = true, silent = true })

-- 【Telescope 搜索 (Search)】
map("n", "<leader>sf", "<cmd>Telescope find_files<cr>", { desc = "查找文件 (find_files)", noremap = true, silent = true })
map("n", "<leader>sg", "<cmd>Telescope live_grep<cr>", { desc = "全局搜索内容 (live_grep)", noremap = true, silent = true })
map("n", "<leader>sb", "<cmd>Telescope buffers<cr>", { desc = "搜索缓冲区 (buffers)", noremap = true, silent = true })
map("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "搜索帮助文档 (help_tags)", noremap = true, silent = true })
map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "当前文档 LSP 符号", noremap = true, silent = true })
map("n", "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "工作区 LSP 符号", noremap = true, silent = true })
map("n", "<leader>sd", "<cmd>Telescope diagnostics<cr>", { desc = "查找诊断信息", noremap = true, silent = true })

-- 【LSP 代码操作 (Code)】
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "重命名符号 (Rename)", noremap = true, silent = true })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作 (Code Action)", noremap = true, silent = true })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "显示悬浮诊断 (Diagnostic)", noremap = true, silent = true })
map("n", "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "格式化缓冲区 (Format)", noremap = true, silent = true })

-- 【LSP 导航与查看 (Go)】
map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", { desc = "跳转到定义", noremap = true, silent = true })
map("n", "gD", vim.lsp.buf.declaration, { desc = "跳转到声明", noremap = true, silent = true })
map("n", "gri", "<cmd>Telescope lsp_implementations<cr>", { desc = "跳转到实现", noremap = true, silent = true })
map("n", "grr", "<cmd>Telescope lsp_references<cr>", { desc = "查看所有引用", noremap = true, silent = true })
map("n", "grt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "查看类型定义", noremap = true, silent = true })
map("n", "gO", vim.lsp.buf.document_symbol, { desc = "查看文档符号", noremap = true, silent = true })
map("n", "K", vim.lsp.buf.hover, { desc = "悬浮显示文档/注释", noremap = true, silent = true })
map("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作", noremap = true, silent = true })
map("n", "grn", vim.lsp.buf.rename, { desc = "重命名", noremap = true, silent = true })

-- 【DAP 调试 (Debug)】
map("n", "<F5>", function() require('dap').continue() end, { desc = "启动/继续调试", noremap = true, silent = true })
map("n", "<F6>", function() require('dap').disconnect({ terminateDebuggee = true }) end, { desc = "断开调试", noremap = true, silent = true })
map("n", "<F10>", function() require('dap').step_over() end, { desc = "逐过程 (Step Over)", noremap = true, silent = true })
map("n", "<F11>", function() require('dap').step_into() end, { desc = "单步调试 (Step Into)", noremap = true, silent = true })
map("n", "<F12>", function() require('dap').step_out() end, { desc = "单步跳出 (Step Out)", noremap = true, silent = true })
map("n", "<leader>dp", function() require('dap').toggle_breakpoint() end, { desc = "切换断点", noremap = true, silent = true })
map("n", "<leader>dt", function() require('dapui').toggle() end, { desc = "显示/隐藏调试 UI", noremap = true, silent = true })
