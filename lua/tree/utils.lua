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

return M
