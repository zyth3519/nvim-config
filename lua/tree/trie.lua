-- lua/tree/trie.lua
-- 根据 fd 返回的路径列表构建 Trie，用于后续解析 tree 输出时快速查找节点

local M = {}

---@class TrieNode
---@field children  table<string, TrieNode>
---@field full_path string|nil
---@field is_dir    boolean

--- 创建空根节点
---@param abs_root string
---@return TrieNode
local function new_root(abs_root)
    return { children = {}, full_path = abs_root, is_dir = true }
end

--- 递归标记含子节点的节点为目录
---@param node TrieNode
local function mark_dirs(node)
    if next(node.children) then
        node.is_dir = true
    end
    for _, child in pairs(node.children) do
        mark_dirs(child)
    end
end

--- 将 fd 原始路径规范化为相对路径片段列表
---@param raw      string   fd 返回的原始路径
---@param prefix   string   需去除的前缀（target_path + "/"）
---@return string[]|nil     路径各段，失败返回 nil
local function to_parts(raw, prefix)
    local rel = raw:gsub("/$", "")
    if vim.startswith(rel, prefix) then
        rel = rel:sub(#prefix + 1)
    elseif vim.startswith(rel, "./") then
        rel = rel:sub(3)
    end
    rel = rel:gsub("/$", "")
    if rel == "" then return nil end
    return vim.split(rel, "/", { plain = true })
end

--- 将 fd 路径列表插入 Trie
---@param fd_paths  string[]
---@param target    string   扫描目标路径
---@param abs_root  string   绝对根路径
---@return TrieNode
function M.build(fd_paths, target, abs_root)
    local root   = new_root(abs_root)
    local prefix = target .. "/"

    for _, p in ipairs(fd_paths) do
        local parts = to_parts(p, prefix)
        if parts then
            local node = root
            for i, part in ipairs(parts) do
                if not node.children[part] then
                    node.children[part] = { children = {}, full_path = nil, is_dir = false }
                end
                node = node.children[part]
                if i < #parts then node.is_dir = true end
            end
            node.full_path = p:gsub("/$", "")
        end
    end

    mark_dirs(root)
    return root
end

return M
