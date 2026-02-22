vim.api.nvim_create_user_command('Tree', function(opts)
    -- 如果有参数则传给 fd，否则默认为当前目录
    local path = opts.args ~= "" and opts.args or "."
    local cmd = string.format("fd . %s | tree --fromfile", path)

    local result = vim.fn.system(cmd)

    -- 2. 创建一个垂直分割的窗口
    vim.cmd("vsplit")
    local buf = vim.api.nvim_create_buf(false, true) -- 创建临时缓冲区
    vim.api.nvim_win_set_buf(0, buf)

    -- 3. 将结果写入缓冲区
    local lines = {}
    for line in result:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- 4. 设置一些美化属性
    vim.bo[buf].buftype = "nofile" -- 不保存文件
    vim.bo[buf].bufhidden = "wipe" -- 关闭窗口后自动删除缓冲区
    vim.bo[buf].filetype = "text"  -- 或者根据需要设置高亮
    vim.wo.wrap = false            -- 不自动换行
end, { desc = '使用 fd 和 tree 展示当前目录树' })
