local M = {}

--- 判断文件是否为文本文件
---@param filepath string
---@return boolean
function M.is_text_file(filepath)
    if not filepath or filepath == "" then
        return false
    end

    filepath = vim.fn.expand(filepath)

    if vim.fn.filereadable(filepath) == 0 then
        return false
    end

    local output = vim.fn.system({ "file", "-b", "--mime-encoding", filepath })
    output = vim.trim(output)

    return output ~= "binary"
end

-- 安全设置光标位置
---@param win_id integer
---@param buf_id integer
---@param row integer
---@param col integer
function M.safe_set_cursor(win_id, buf_id, row, col)
    local line_count = vim.api.nvim_buf_line_count(buf_id)

    -- 调整行号
    if row <= 1 then row = 1 end
    if row > line_count then row = line_count end

    -- 获取行长度
    local line = vim.api.nvim_buf_get_lines(buf_id, row - 1, row, false)[1] or ""

    -- 调整列号
    if col < 0 then col = 0 end
    if col > #line then col = #line end

    vim.api.nvim_win_set_cursor(win_id, { row, col })
end

return M
