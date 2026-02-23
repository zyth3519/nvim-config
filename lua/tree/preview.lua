-- lua/tree/preview.lua
-- 预览窗口：渲染目录列表 / 文件内容，支持滚动

local M = {}
local cfg = require("tree.config").defaults
local utils = require('tree.utils')

local NS = vim.api.nvim_create_namespace("tree_preview")

---@class PreviewCtx
---@field pbuf     integer
---@field pwin     integer
---@field file_map table<integer, string>
---@field is_dir_map table<integer, boolean>
---@field abs_root string

--- 解析路径（支持相对路径补全）
---@param fpath    string
---@param abs_root string
---@return string|nil
local function resolve(fpath, abs_root)
    if not fpath then return nil end
    local candidates = { fpath }
    if not vim.startswith(fpath, "/") then
        table.insert(candidates, abs_root .. "/" .. fpath)
    end
    for _, p in ipairs(candidates) do
        if vim.fn.filereadable(p) == 1 or vim.fn.isdirectory(p) == 1 then
            return p
        end
    end
    return nil
end

--- 生成目录预览行
---@param resolved string
---@return string[]
local function dir_lines(resolved)
    local lines = { "📁 " .. resolved, "" }
    local ok, items = pcall(vim.fn.readdir, resolved)

    if #items == 0 then
        table.insert(lines, "  (空目录)")
        return lines
    end

    if ok then
        for _, item in ipairs(items) do
            local full = resolved .. "/" .. item
            if vim.fn.isdirectory(full) == 1 then
                table.insert(lines, "  📂 " .. item .. "/")
            else
                table.insert(lines, "  📄 " .. item)
            end
        end
    end
    return lines
end

--- 生成文件预览行
---@param resolved string
---@return string[], string   lines, filetype
local function file_lines(resolved)
    if not utils.is_text_file(resolved) then
        local lines = { "⚠️ 无法预览二进制文件" }
        return lines
    end

    local ok, result = pcall(vim.fn.readfile, resolved, "", cfg.preview_max_lines)
    local lines = ok and result or { "⚠️ 无法读取文件" }
    local ft_ok, ft = pcall(vim.filetype.match, { filename = resolved })
    local ext = vim.fn.fnamemodify(resolved, ":e")
    return lines, (ft_ok and ft) or ext or ""
end

--- 更新预览内容（在主窗口 CursorMoved 时调用）
---@param ctx PreviewCtx
function M.update(ctx)
    local pbuf, pwin = ctx.pbuf, ctx.pwin
    if not vim.api.nvim_buf_is_valid(pbuf) then return end
    if not vim.api.nvim_win_is_valid(pwin) then return end

    local lnum              = vim.fn.line(".")
    local fpath             = ctx.file_map[lnum]
    local resolved          = resolve(fpath, ctx.abs_root)

    vim.bo[pbuf].modifiable = true
    vim.api.nvim_buf_clear_namespace(pbuf, NS, 0, -1)

    local ft = ""
    local lines

    if resolved and vim.fn.isdirectory(resolved) == 1 then
        lines = dir_lines(resolved)
    elseif resolved and vim.fn.filereadable(resolved) == 1 then
        lines, ft = file_lines(resolved)
    else
        lines = { "" }
    end

    vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
    vim.bo[pbuf].filetype   = ft
    vim.bo[pbuf].modifiable = false
end

--- 滚动预览窗口
---@param pwin      integer
---@param pbuf      integer
---@param direction "up"|"down"
function M.scroll(pwin, pbuf, direction)
    if not vim.api.nvim_win_is_valid(pwin) then return end

    local total = vim.api.nvim_buf_line_count(pbuf)
    local win_h = vim.api.nvim_win_get_height(pwin)
    local top   = vim.fn.getwininfo(pwin)[1].topline
    local step  = math.ceil(win_h * cfg.preview_scroll_ratio)

    local new_top
    if direction == "down" then
        new_top = math.min(top + step, math.max(1, total - win_h + 1))
    else
        new_top = math.max(1, top - step)
    end

    vim.api.nvim_win_call(pwin, function()
        vim.fn.winrestview({ topline = new_top })
    end)
end

return M
