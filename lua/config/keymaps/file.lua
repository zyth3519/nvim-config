vim.keymap.set("n", "<leader>e", "<cmd>Oil<cr>", { desc = "打开 Oil" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "搜索当前项目文件" })
vim.keymap.set("n", "<leader>fe", "<cmd>Oil --float<cr>", { desc = "打开 Oil" })
vim.keymap.set("n", "<leader>fr", "<cmd>Oil --float .<cr>", { desc = "打开 Oil (Root)" })
