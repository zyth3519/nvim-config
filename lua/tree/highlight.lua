-- lua/tree/highlight.lua
-- 在指定 buffer 上注册 tree 专用语法高亮规则

local M = {}

local RULES = {
    { "syntax", "match TreeLines /^[│├└─ \\+/]/" },
    { "hi", "default link TreeLines Comment" },
    { "syntax", "match TreeDir /[^│├└─ ]\\S*\\/$/" },
    { "hi", "default link TreeDir Directory" },
    { "syntax", "match TreeExt /\\.\\w\\+$/" },
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
