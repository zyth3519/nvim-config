-- lua/tree/ui.lua
-- 负责创建、管理浮窗（主窗口 + 预览窗口）

local M = {}
local cfg = require("tree.config").defaults

--- 计算浮窗的几何参数
---@return table { width, height, row, col, main_width, preview_width }
local function calc_geometry()
	local width = math.ceil(vim.o.columns * cfg.win_width_ratio)
	local height = math.ceil(vim.o.lines * cfg.win_height_ratio)
	local row = math.ceil((vim.o.lines - height) / 2 - 1)
	local col = math.ceil((vim.o.columns - width) / 2)
	local main_width
	if cfg.preview then
		main_width = math.ceil(width * cfg.main_width_ratio)
	else
		main_width = width
	end
	local preview_width = width - main_width - 1 -- -1 留边框间隙
	return {
		width = width,
		height = height,
		row = row,
		col = col,
		main_width = main_width,
		preview_width = preview_width,
	}
end

--- 创建预览 buffer（只读 nofile）
---@return integer buf_handle
local function create_preview_buf()
	local pbuf = vim.api.nvim_create_buf(false, true)
	vim.bo[pbuf].buftype = "nofile"
	vim.bo[pbuf].modifiable = false
	return pbuf
end

--- 创建主 buffer（nofile / mytree filetype）
---@return integer buf_handle
local function create_main_buf()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].filetype = "MyTree"
	vim.bo[buf].modifiable = false
	return buf
end

---@class WinPair
---@field buf     integer  主 buffer
---@field win     integer  主窗口
---@field pbuf    integer  预览 buffer
---@field pwin    integer  预览窗口
---@field geo     table    几何参数

--- 一次性创建双窗口布局，返回句柄集合
---@param target_path string 显示在标题里的路径标签
---@return WinPair
function M.create_layout(target_path)
	local geo = calc_geometry()
	local pbuf = create_preview_buf()
	local buf = create_main_buf()
	local pwin = 0

	if cfg.preview then
		-- 先创建预览窗口（false = 不聚焦）
		pwin = vim.api.nvim_open_win(pbuf, false, {
			relative = "editor",
			width = geo.preview_width,
			height = geo.height,
			row = geo.row,
			col = geo.col + geo.main_width + 1,
			style = "minimal",
			border = "rounded",
			title = " Preview ",
			title_pos = "center",
		})
	end

	-- 再创建主窗口（true = 聚焦）
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = geo.main_width,
		height = geo.height,
		row = geo.row,
		col = geo.col,
		style = "minimal",
		border = "rounded",
		title = " Directory Tree [" .. target_path .. "] ",
		title_pos = "center",
	})

	-- 设置窗口换行
	vim.api.nvim_set_option_value("wrap", false, { win = win })
	vim.api.nvim_set_option_value("linebreak", false, { win = win })

	return { buf = buf, win = win, pbuf = pbuf, pwin = pwin, geo = geo }
end

--- 注册窗口关闭联动（主窗口离开时一并关闭预览）
---@param layout WinPair
function M.setup_close_autocmd(layout)
	local buf, win, pbuf, pwin = layout.buf, layout.win, layout.pbuf, layout.pwin

	vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(function()
				local t = { { win, buf } }

				if cfg.preview then
					t = {
						{ pwin, pbuf },
						{ win, buf },
					}
				end

				for _, pair in ipairs(t) do
					local w, b = pair[1], pair[2]
					if vim.api.nvim_win_is_valid(w) then
						vim.api.nvim_win_close(w, true)
					end
					if vim.api.nvim_buf_is_valid(b) then
						vim.api.nvim_buf_delete(b, { force = true })
					end
				end
			end)
		end,
	})
end

--- 在 buf 写入单行提示（modifiable 保护）
---@param buf integer
---@param msg string
function M.set_loading(buf, msg)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { msg })
	vim.bo[buf].modifiable = false
end

return M
