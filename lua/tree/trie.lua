-- lua/tree/trie.lua
local M = {}

---@class TrieNode
---@field children  table<string, TrieNode>
---@field full_path string|nil
---@field is_dir    boolean

local function new_root(abs_root)
    return { children = {}, full_path = abs_root, is_dir = true }
end

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

function M.build(fd_paths, target, abs_root)
    local root   = new_root(abs_root)
    local prefix = target .. "/"

    for _, p in ipairs(fd_paths) do
        local is_dir = p:sub(-1) == "/"
        local parts  = to_parts(p, prefix)
        if parts then
            local node = root
            for i, part in ipairs(parts) do
                if not node.children[part] then
                    node.children[part] = {
                        children  = {},
                        full_path = nil,
                        is_dir    = false,
                    }
                end
                node = node.children[part]
                -- 中间节点一定是目录
                if i < #parts then
                    node.is_dir = true
                end
            end
            -- full_path 统一不带末尾 /
            node.full_path = abs_root .. "/" .. table.concat(parts, "/")
            node.is_dir    = is_dir or node.is_dir
        end
    end

    return root
end

return M
