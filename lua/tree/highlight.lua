-- lua/tree/highlight.lua
local M = {}

local NS = vim.api.nvim_create_namespace("tree_icons")

local RULES = {
    -- 树形连接线
    { "syntax", [[match TreeLines /[│├└─]/]] },
    { "hi", "default link TreeLines Comment" },
    -- 目录（以 / 结尾，或带 [+] 标记）
    -- 使用更严谨的正则：匹配整行中最后一个符号之后直到行尾包含 / 的部分，支持空格
    { "syntax", [[match TreeDir /\(│\s\+\|├── \|└── \|^\s*\)\@<=[^\/│├└─]\+\/\(\s*\[+\]\)\?$/]] },
    { "hi", "default link TreeDir Directory" },
    -- 折叠标记 [+]
    { "syntax", [[match TreeFold /\[+\]/]] },
    { "hi", "default link TreeFold WarningMsg" },
}

---@param buf integer
function M.apply(buf)
    vim.api.nvim_buf_call(buf, function()
        for _, rule in ipairs(RULES) do
            vim.cmd(rule[1] .. " " .. rule[2])
        end
    end)
end

--- 应用图标颜色高亮 (Extmarks)
---@param buf integer
---@param icon_hl_map table<integer, {col_start: number, col_end: number, hl_group: string}>
function M.apply_icons(buf, icon_hl_map)
    if not vim.api.nvim_buf_is_valid(buf) then return end

    -- 清理旧的图标高亮
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

    for lnum, hl_info in pairs(icon_hl_map) do
        -- lnum 转换为 0 索引
        pcall(vim.api.nvim_buf_set_extmark, buf, NS, lnum - 1, hl_info.col_start, {
            end_row = lnum - 1,
            end_col = hl_info.col_end,
            hl_group = hl_info.hl_group,
            priority = 100,
        })
    end
end

return M
