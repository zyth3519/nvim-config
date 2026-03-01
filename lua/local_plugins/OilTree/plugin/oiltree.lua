if vim.g.loaded_oiltree == 1 then
  return
end
vim.g.loaded_oiltree = 1

-- 如果需要在启动时自动执行 setup，可以取消注释下面这行：
-- require("oiltree").setup()
