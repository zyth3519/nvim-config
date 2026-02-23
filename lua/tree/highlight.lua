-- lua/tree/highlight.lua
local M = {}

local RULES = {
    -- 树形连接线
    { "syntax", [[match TreeLines /[│├└─]/]] },
    { "hi", "default link TreeLines Comment" },
    -- 目录（以 / 结尾，或带 [+] 标记）
    { "syntax", [[match TreeDir /\S\+\/\(\s*\[+\]\)\?$/]] },
    { "hi", "default link TreeDir Directory" },
    -- 折叠标记 [+]
    { "syntax", [[match TreeFold /\[+\]/]] },
    { "hi", "default link TreeFold WarningMsg" },
    -- 文件扩展名
    { "syntax", [[match TreeExt /\.\w\+$/]] },
    { "hi", "default link TreeExt Type" },
}

---@param buf integer
function M.apply(buf)
    vim.api.nvim_buf_call(buf, function()
        for _, rule in ipairs(RULES) do
            vim.cmd(rule[1] .. " " .. rule[2])
        end
    end)
end

return M
