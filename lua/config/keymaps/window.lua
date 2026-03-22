-- 【窗口管理 (Window)】
vim.keymap.set("n", "<C-x>", "<cmd>split<cr>", { desc = "水平分割当前窗口" })
vim.keymap.set("n", "<C-s>", "<cmd>vsplit<cr>", { desc = "垂直分割当前窗口" })
vim.keymap.set("n", "<leader>wh", "<cmd>split<cr>", { desc = "水平分割当前窗口" })
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "垂直分割当前窗口" })
vim.keymap.set("n", "<leader>wx", "<C-w>x", { desc = "窗口互换" })
vim.keymap.set("n", "<leader>wq", "<C-w>q", { desc = "关闭当前窗口" })
vim.keymap.set("n", "<leader>wo", "<cmd>only<cr>", { desc = "关闭其他所有窗口" })
