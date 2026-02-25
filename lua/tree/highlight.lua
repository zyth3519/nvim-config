-- lua/tree/highlight.lua
local M = {}

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
