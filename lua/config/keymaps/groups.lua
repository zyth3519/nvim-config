local wk_ok, wk = pcall(require, "which-key")
if not wk_ok then
	return
end

wk.add({
	{ "<leader>b", group = "缓冲区 (Buffer)", icon = "󰓩" },
	{ "<leader>c", group = "代码 (Code)", icon = "󰅩" },
	{ "<leader>d", group = "调试 (Debug)", icon = "󰃤" },
	{ "<leader>f", group = "文件 (File)", icon = "󰉋" },
	{ "<leader>g", group = "版本控制 (Git)", icon = "󰊢" },
	{ "<leader>s", group = "搜索 (Search)", icon = "󰍉" },
	{ "<leader>w", group = "窗口 (Window)", icon = "󱂬" },
	{ "g", group = "导航/跳转 (Go)", icon = "󰜎" },
	{ "<leader>e", desc = "打开Oil", icon = "󰉋" },
	{ "<leader>E", desc = "打开Oil（Root）", icon = "󰉋" },
	{ "<leader>r", group = "运行 (Run)", icon = "󰆍" },
})
