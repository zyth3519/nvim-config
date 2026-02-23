-- lua/tree/renderer.lua
-- 将 Trie 渲染为树形文本行，同时产出 file_map / is_dir_map
-- 支持折叠状态（折叠的目录只显示自身，子内容跳过）

local M = {}

-- 树形绘制符号
local SYM = {
    branch = "├── ",
    last   = "└── ",
    pipe   = "│   ",
    blank  = "    ",
}

---@class RenderResult
---@field lines      string[]               渲染出的文本行
---@field file_map   table<integer, string> 行号 → 绝对路径
---@field is_dir_map table<integer, boolean> 行号 → 是否目录

--- 递归渲染一个 TrieNode 的所有子节点
---@param node       TrieNode
---@param prefix     string          当前行的缩进前缀
---@param lines      string[]
---@param file_map   table
---@param is_dir_map table
---@param fold_state table<string, boolean>  path → closed
local function render_node(node, prefix, lines, file_map, is_dir_map, fold_state)
    -- 按 目录优先、名字字母序 排列子节点
    local children = {}
    for name, child in pairs(node.children) do
        table.insert(children, { name = name, child = child })
    end
    table.sort(children, function(a, b)
        local ad = a.child.is_dir and 0 or 1
        local bd = b.child.is_dir and 0 or 1
        if ad ~= bd then return ad < bd end
        return a.name < b.name
    end)

    local count = #children
    for i, entry in ipairs(children) do
        local name         = entry.name
        local child        = entry.child
        local is_last      = (i == count)

        -- 当前行的连接符
        local connector    = is_last and SYM.last or SYM.branch
        -- 子节点递归时的前缀
        local child_prefix = prefix .. (is_last and SYM.blank or SYM.pipe)

        -- 目录名加 /，文件不加
        local display      = child.is_dir and (name .. "/") or name

        -- 折叠标记：目录且被折叠时加 [+]
        local fold_mark    = ""
        if child.is_dir and fold_state[child.full_path] then
            fold_mark = "  [+]"
        end

        -- 写入当前行
        local lnum       = #lines + 1
        lines[lnum]      = prefix .. connector .. display .. fold_mark
        file_map[lnum]   = child.full_path
        is_dir_map[lnum] = child.is_dir

        -- 目录且未折叠：递归渲染子节点
        if child.is_dir and not fold_state[child.full_path] then
            render_node(child, child_prefix, lines, file_map, is_dir_map, fold_state)
        end
    end
end

--- 对外接口：渲染整棵树
---@param trie_root  TrieNode
---@param abs_root   string
---@param fold_state table<string, boolean>   path → closed（可传 {}）
---@return RenderResult
function M.render(trie_root, abs_root, fold_state)
    fold_state       = fold_state or {}

    local lines      = {}
    local file_map   = {}
    local is_dir_map = {}

    -- 第一行：根目录
    lines[1]         = abs_root .. "/"
    file_map[1]      = abs_root
    is_dir_map[1]    = true

    render_node(trie_root, "", lines, file_map, is_dir_map, fold_state)

    return {
        lines      = lines,
        file_map   = file_map,
        is_dir_map = is_dir_map,
    }
end

return M
