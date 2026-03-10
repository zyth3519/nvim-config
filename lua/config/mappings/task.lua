-- 【任务运行 (Overseer)】
vim.keymap.set("n", "<leader>rr", "<cmd>OverseerRun<cr>", { desc = "运行任务" })
vim.keymap.set("n", "<leader>rt", "<cmd>OverseerToggle<cr>", { desc = "切换面板任务列表" })
vim.keymap.set("n", "<leader>ra", "<cmd>OverseerTaskAction<cr>", { desc = "任务操作" })
vim.keymap.set("n", "<leader>ro", "<cmd>OverseerOpen<cr>", { desc = "打开任务列表" })
vim.keymap.set("n", "<leader>rc", "<cmd>OverseerClose<cr>", { desc = "关闭任务列表" })
