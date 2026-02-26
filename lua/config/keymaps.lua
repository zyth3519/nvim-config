local map = vim.keymap.set
-- 将所有 leader 键配置在这里
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- =========================================================================
-- 1. 核心基础快捷键 (Core)
-- =========================================================================

-- 窗口导航 (Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "跳转到下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "跳转到上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "跳转到右侧窗口" })

-- 窗口大小调整 (Ctrl + 箭头)
map("n", "<C-Up>", "5<C-w>-", { desc = "窗口高度减少" })
map("n", "<C-Down>", "5<C-w>+", { desc = "窗口高度增加" })
map("n", "<C-Left>", "5<C-w><", { desc = "窗口宽度减少" })
map("n", "<C-Right>", "5<C-w>>", { desc = "窗口宽度增加" })

-- 缓冲区切换 (Shift + hl)
map("n", "<S-h>", "<cmd>bp<cr>", { desc = "上一个缓冲区" })
map("n", "<S-l>", "<cmd>bn<cr>", { desc = "下一个缓冲区" })

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
map("n", "<leader>ee", "<cmd>Tree<cr>", { desc = "打开树形浏览器" })
map("n", "<leader>eo", "<cmd>Oil --float<cr>", { desc = "打开 Oil 文件管理器" })
map("n", "<leader>eO", "<cmd>Oil --float .<cr>", { desc = "打开 Oil (Root)" })
map("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "打开终端" })

-- 【窗口管理 (Window)】
map("n", "<leader>wh", "<cmd>split<cr>", { desc = "水平分割当前窗口" })
map("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "垂直分割当前窗口" })
map("n", "<leader>wx", "<C-w>x", { desc = "窗口互换" })
map("n", "<leader>wq", "<C-w>q", { desc = "关闭当前窗口" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "关闭其他所有窗口" })
map("n", "<leader>wns", "<cmd>new<cr>", { desc = "横向分割并新建文件" })
map("n", "<leader>wnv", "<cmd>vnew<cr>", { desc = "垂直分割并新建文件" })

-- 【缓冲区管理 (Buffer)】
map("n", "<leader>bl", "<cmd>ls<cr>", { desc = "显示 Buffer 列表" })
map("n", "<leader>ba", "<cmd>ball<cr>", { desc = "为每个 Buffer 打开窗口" })
map("n", "<leader>bd", "<cmd>bd<cr>", { desc = "删除 Buffer 并关闭窗口" })
map("n", "<leader>bD", "<cmd>bw<cr>", { desc = "彻底删除当前 Buffer" })
map("n", "<leader>bo", "<cmd>%bd | e# | bd#<cr>", { desc = "只保留当前编辑的文件" })
map("n", "<leader>bf", "<cmd>bf<cr>", { desc = "跳转到第一个 Buffer" })
map("n", "<leader>bF", "<cmd>bl<cr>", { desc = "跳转到最后一个 Buffer" })

-- 【Telescope 搜索 (Search)】
map("n", "<leader>sf", "<cmd>Telescope find_files<cr>", { desc = "查找文件 (find_files)" })
map("n", "<leader>sg", "<cmd>Telescope live_grep<cr>", { desc = "全局搜索内容 (live_grep)" })
map("n", "<leader>sb", "<cmd>Telescope buffers<cr>", { desc = "搜索缓冲区 (buffers)" })
map("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "搜索帮助文档 (help_tags)" })
map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "当前文档 LSP 符号" })
map("n", "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "工作区 LSP 符号" })
map("n", "<leader>sd", "<cmd>Telescope diagnostics<cr>", { desc = "查找诊断信息" })

-- 【LSP 代码操作 (Code)】
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "重命名符号 (Rename)" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作 (Code Action)" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "显示悬浮诊断 (Diagnostic)" })
map("n", "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "格式化缓冲区 (Format)" })

-- 【LSP 导航与查看 (Go)】
map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", { desc = "跳转到定义" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "跳转到声明" })
map("n", "gri", "<cmd>Telescope lsp_implementations<cr>", { desc = "跳转到实现" })
map("n", "grr", "<cmd>Telescope lsp_references<cr>", { desc = "查看所有引用" })
map("n", "grt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "查看类型定义" })
map("n", "gO", vim.lsp.buf.document_symbol, { desc = "查看文档符号" })
map("n", "K", vim.lsp.buf.hover, { desc = "悬浮显示文档/注释" })
map("n", "gra", vim.lsp.buf.code_action, { desc = "代码操作" })
map("n", "grn", vim.lsp.buf.rename, { desc = "重命名" })

-- 【DAP 调试 (Debug)】
map("n", "<F5>", function() require('dap').continue() end, { desc = "启动/继续调试" })
map("n", "<F6>", function() require('dap').disconnect({ terminateDebuggee = true }) end, { desc = "断开调试" })
map("n", "<F10>", function() require('dap').step_over() end, { desc = "逐过程 (Step Over)" })
map("n", "<F11>", function() require('dap').step_into() end, { desc = "单步调试 (Step Into)" })
map("n", "<F12>", function() require('dap').step_out() end, { desc = "单步跳出 (Step Out)" })
map("n", "<leader>dp", function() require('dap').toggle_breakpoint() end, { desc = "切换断点" })
map("n", "<leader>dt", function() require('dapui').toggle() end, { desc = "显示/隐藏调试 UI" })
