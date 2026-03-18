vim.keymap.set("n", "<A-h>", require("smart-splits").resize_left, { desc = "缩小左侧窗口" })
vim.keymap.set("n", "<A-j>", require("smart-splits").resize_down, { desc = "增大下方窗口" })
vim.keymap.set("n", "<A-k>", require("smart-splits").resize_up, { desc = "减小上方窗口" })
vim.keymap.set("n", "<A-l>", require("smart-splits").resize_right, { desc = "增大右侧窗口" })

vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "跳转到左侧窗口" })
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "跳转到下方窗口" })
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "跳转到上方窗口" })
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "跳转到右侧窗口" })
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous, { desc = "跳转到上一个窗口" })

vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left, { desc = "与左侧窗口交换缓冲区" })
vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down, { desc = "与下方窗口交换缓冲区" })
vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up, { desc = "与上方窗口交换缓冲区" })
vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right, { desc = "与右侧窗口交换缓冲区" })

vim.keymap.set("n", "<S-h>", "<cmd>bp<cr>", { desc = "上一个缓冲区" })
vim.keymap.set("n", "<S-l>", "<cmd>bn<cr>", { desc = "下一个缓冲区" })
vim.keymap.set({ "n" }, "<M-x>", ":Run ", { desc = "执行系统命令" })
