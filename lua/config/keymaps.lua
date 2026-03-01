local map = vim.keymap.set
-- 将所有 leader 键配置在这里
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local key_obj = {
	dapui_show = false,
}

-- =========================================================================
-- 1. 核心基础快捷键 (Core)
-- =========================================================================

-- 窗口导航 (Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "跳转到下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "跳转到上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "跳转到右侧窗口" })

-- 窗口大小调整 (Ctrl + Alt + hjkl)
map("n", "<A-j>", "5<C-w>-", { desc = "窗口高度减少" })
map("n", "<A-k>", "5<C-w>+", { desc = "窗口高度增加" })
map("n", "<A-h>", "5<C-w><", { desc = "窗口宽度减少" })
map("n", "<A-l>", "5<C-w>>", { desc = "窗口宽度增加" })

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
		{ "<leader>b", group = "缓冲区 (Buffer)", icon = "󰓩" },
		{ "<leader>c", group = "代码 (Code)", icon = "󰅩" },
		{ "<leader>d", group = "调试 (Debug)", icon = "󰃤" },
		{ "<leader>f", group = "文件 (File)", icon = "󰉋" },
		{ "<leader>g", group = "版本控制 (Git)", icon = "󰊢" },
		{ "<leader>s", group = "搜索 (Search)", icon = "󰍉" },
		{ "<leader>qs", desc = "会话管理 (Session)", icon = "󰆓" },
		{ "<leader>w", group = "窗口 (Window)", icon = "󱂬" },
		{ "g", group = "导航/跳转 (Go)", icon = "󰜎" },
		{ "<leader>e", desc = "打开Tree", icon = "󰙅" },
	})
end

-- 【文件管理 (File)】
local function toggle_nvim_tree()
	local api = require("nvim-tree.api")
	if api.tree.is_visible() then
		api.tree.close()
		return
	end

	if vim.bo.filetype == "oil" then
		local ok, oil = pcall(require, "oil")
		if ok then
			local dir = oil.get_current_dir()
			local entry = oil.get_cursor_entry()
			if dir and entry then
				local path = dir .. (entry.parsed_name or entry.name)
				api.tree.open()
				-- 定位到当前 Oil 光标所在行对应的文件
				api.tree.find_file({ buf = path, open = true, focus = true, update_root = true })
				return
			end
		end
	end

	-- 非 Oil 缓冲区或未命中，按当前文件定位并打开
	api.tree.toggle({ find_file = true, focus = true, update_root = true })
end

map("n", "<leader>e", toggle_nvim_tree, { desc = "打开Tree" })

-- 在使用 cmd 调用时如果带有 insert 等其他模式，前置 <Esc> 或者 <C-\><C-n> 可以退回到 normal
map({ "n", "i", "v", "c" }, "<C-e>", function()
	if vim.fn.mode() ~= "n" then
		vim.cmd("stopinsert")
	end
	toggle_nvim_tree()
end, { desc = "快速打开目录树" })

map("n", "<leader>ft", toggle_nvim_tree, { desc = "打开Tree" })

map("n", "<leader>ff", "<cmd>Oil --float<cr>", { desc = "打开 Oil 文件管理器" })
map("n", "<leader>fF", "<cmd>Oil --float .<cr>", { desc = "打开 Oil (Root)" })

-- 【窗口管理 (Window)】
map("n", "<leader>wh", "<cmd>split<cr>", { desc = "水平分割当前窗口" })
map("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "垂直分割当前窗口" })
map("n", "<leader>wx", "<C-w>x", { desc = "窗口互换" })
map("n", "<leader>wq", "<C-w>q", { desc = "关闭当前窗口" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "关闭其他所有窗口" })

-- 【缓冲区管理 (Buffer)】
map("n", "<leader>q", "<cmd>bd<cr>", { desc = "关闭当前文件(Buffer)" })
map("n", "<leader>Q", "<cmd>bw<cr>", { desc = "彻底销毁当前 Buffer" })
map("n", "<leader>bl", "<cmd>ls<cr>", { desc = "显示 Buffer 列表" })
map("n", "<leader>ba", "<cmd>ball<cr>", { desc = "为每个 Buffer 打开窗口" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "只保留当前编辑的文件" })
map("n", "<leader>bf", "<cmd>bf<cr>", { desc = "跳转到第一个 Buffer" })
map("n", "<leader>bF", "<cmd>bl<cr>", { desc = "跳转到最后一个 Buffer" })

-- Bufferline 数字切换 (1-9)
for i = 1, 9 do
	map("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", { desc = "跳转到 Buffer " .. i })
end

-- 【Telescope 搜索 (Search)】
map("n", "<leader>sf", "<cmd>Telescope find_files<cr>", { desc = "查找文件 (find_files)" })
map("n", "<leader>sg", "<cmd>Telescope live_grep<cr>", { desc = "全局搜索内容 (live_grep)" })
map("n", "<leader>sb", "<cmd>Telescope buffers<cr>", { desc = "搜索缓冲区 (buffers)" })
map("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "搜索帮助文档 (help_tags)" })
map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "当前文档 LSP 符号" })
map("n", "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "工作区 LSP 符号" })
map("n", "<leader>sd", "<cmd>Telescope diagnostics<cr>", { desc = "查找诊断信息" })

-- 【会话管理 (Session) - resession】
map("n", "<leader>qss", function()
	require("resession").save()
end, { desc = "保存会话 (Save)" })
map("n", "<leader>qsl", function()
	require("resession").load()
end, { desc = "加载会话 (Load)" })
map("n", "<leader>qsd", function()
	require("resession").delete()
end, { desc = "删除会话 (Delete)" })

-- 【Git 操作 (Neogit & Gitsigns)】
map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "打开 Neogit" })
map("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Git 提交 (Commit)" })
map("n", "<leader>gp", "<cmd>Neogit pull<cr>", { desc = "Git 拉取 (Pull)" })
map("n", "<leader>gP", "<cmd>Neogit push<cr>", { desc = "Git 推送 (Push)" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "打开差异视图 (Diffview)" })
map("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "关闭差异视图 (Diffview)" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "单行责备 (Blame)" })
map("n", "<leader>gB", "<cmd>Gitsigns toggle_current_line_blame<cr>", { desc = "开启单行责备" })
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "回滚代码块 (Reset)" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "回滚整个文件" })
map("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<cr>", { desc = "预览代码块差异" })

-- 【LSP 代码操作 (Code)】
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "重命名符号 (Rename)" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作 (Code Action)" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "显示悬浮诊断 (Diagnostic)" })
map("n", "<leader>cf", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "格式化缓冲区 (Format)" })

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
map("n", "<F5>", function()
	require("dap").continue()
end, { desc = "启动/继续调试" })
map("n", "<F6>", function()
	require("dap").disconnect({ terminateDebuggee = true })
end, { desc = "断开调试" })
map("n", "<F10>", function()
	require("dap").step_over()
end, { desc = "逐过程 (Step Over)" })
map("n", "<F11>", function()
	require("dap").step_into()
end, { desc = "单步调试 (Step Into)" })
map("n", "<F12>", function()
	require("dap").step_out()
end, { desc = "单步跳出 (Step Out)" })
map("n", "<leader>dc", function()
	require("dap").continue()
end, { desc = "启动/继续调试" })
map("n", "<leader>ds", function()
	require("dap").disconnect({ terminateDebuggee = true })
end, { desc = "断开调试" })
map("n", "<leader>dv", function()
	require("dap").step_over()
end, { desc = "逐过程 (Step Over)" })
map("n", "<leader>di", function()
	require("dap").step_into()
end, { desc = "单步调试 (Step Into)" })
map("n", "<leader>do", function()
	require("dap").step_out()
end, { desc = "单步跳出 (Step Out)" })

map("n", "<leader>dp", function()
	require("dap").toggle_breakpoint()
end, { desc = "切换断点" })

map("n", "<F9>", function()
	require("dap").toggle_breakpoint()
end, { desc = "切换断点" })

local dapui_show = false
map("n", "<leader>dt", function()
	local dapui = require("dapui")
	local api = require("nvim-tree.api")

	if not dapui_show then
		dapui.open()
		api.tree.close()
		dapui_show = true
	else
		dapui.close()
		if not api.tree.is_visible() then
			api.tree.open()
			vim.cmd("wincmd p")
		end
		dapui_show = false
	end
end, { desc = "显示/隐藏调试 UI" })
