-- 将所有 leader 键配置在这里
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- =========================================================================
-- 1. 核心基础快捷键 (Core)
-- =========================================================================
-- 窗口导航 (Ctrl + hjkl)
vim.keymap.set("n", "<A-h>", require("smart-splits").resize_left)
vim.keymap.set("n", "<A-j>", require("smart-splits").resize_down)
vim.keymap.set("n", "<A-k>", require("smart-splits").resize_up)
vim.keymap.set("n", "<A-l>", require("smart-splits").resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right)

-- vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口" })
-- vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "跳转到下方窗口" })
-- vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "跳转到上方窗口" })
-- vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "跳转到右侧窗口" })
-- -- 窗口大小调整 (Alt + hjkl)
-- vim.keymap.set("n", "<A-j>", "5<C-w>-", { desc = "窗口高度减少" })
-- vim.keymap.set("n", "<A-k>", "5<C-w>+", { desc = "窗口高度增加" })
-- vim.keymap.set("n", "<A-h>", "5<C-w><", { desc = "窗口宽度减少" })
-- vim.keymap.set("n", "<A-l>", "5<C-w>>", { desc = "窗口宽度增加" })

-- 缓冲区切换 (Shift + hl)
vim.keymap.set("n", "<S-h>", "<cmd>bp<cr>", { desc = "上一个缓冲区" })
vim.keymap.set("n", "<S-l>", "<cmd>bn<cr>", { desc = "下一个缓冲区" })

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
		{ "<leader>w", group = "窗口 (Window)", icon = "󱂬" },
		{ "<leader>r", group = "任务 (Overseer)", icon = "󰆍" },
		{ "g", group = "导航/跳转 (Go)", icon = "󰜎" },
		{ "<leader>e", desc = "打开Oil", icon = "󰉋" },
		{ "<leader>E", desc = "打开Oil（Root）", icon = "󰉋" },
	})
end

require("config.keymaps.buffer")
require("config.keymaps.window")
require("config.keymaps.search")
require("config.keymaps.file")
require("config.keymaps.git")
require("config.keymaps.cursor")
require("config.keymaps.coding")
require("config.keymaps.debug")
