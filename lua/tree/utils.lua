local M = {}
local log = require("tree.log")

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

-- 获取Table元素个数
---@param t table
---@return integer
function M.safe_length(t)
	if type(t) ~= "table" then
		return 0
	end
	return vim.tbl_count(t)
end

function M.get_cur_col_pos(cur_path)
	local line = vim.fn.getline(".")
	local name = vim.fn.fnamemodify(cur_path, ":t")
	local result = line:find(name)

	if result then
		return result - 1
	end

	return 0
end

return M
