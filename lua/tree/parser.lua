-- lua/tree/parser.lua
-- 解析 `tree --fromfile` 的输出，建立 行号 → {full_path, is_dir} 的映射

local M = {}

---@class LineInfo
---@field path   string|nil
---@field is_dir boolean

-- UTF-8 连接符字节前缀（├ └）
local CONNECTOR_BYTES = { ["├"] = true, ["└"] = true }

--- 找到行内第一个连接符（├/└）的字节起始位置，同时返回其前字节数
---@param line string
---@return integer|nil  connector_byte_pos
local function find_connector(line)
    local i, len = 1, #line
    while i <= len do
        local b = string.byte(line, i)
        if b == 0xE2 and i + 2 <= len then
            local c3 = line:sub(i, i + 2)
            if CONNECTOR_BYTES[c3] then
                return i
            end
            i = i + 3
        else
            i = i + 1
        end
    end
    return nil
end

--- 从连接符位置计算缩进深度和文件名
---@param line       string
---@param conn_pos   integer
---@return integer depth, string|nil name
local function parse_depth_name(line, conn_pos)
    local before     = line:sub(1, conn_pos - 1)
    local depth      = vim.fn.strdisplaywidth(before) / 4 + 1
    -- 连接符(3字节) + "── "(4字节) = 7字节；加上实际 tree 输出共 10 字节偏移
    local name_start = conn_pos + 10
    local name       = name_start <= #line and line:sub(name_start) or nil
    return depth, name
end

---@param name string  可能带 tree -F 标记（/ * @ 等）
---@return string
local function clean_name(name)
    return (name:gsub("[/*=>|@]$", ""))
end

--- 核心解析：输入 tree 输出行列表 + Trie 根 + abs_root
---  返回 行号→路径、行号→是否目录 两张表
---@param tree_lines string[]
---@param trie_root  TrieNode
---@param abs_root   string
---@return table<integer,string>, table<integer,boolean>
function M.parse(tree_lines, trie_root, abs_root)
    local file_map   = {} -- line_idx → full_path
    local is_dir_map = {} -- line_idx → boolean
    local stack      = { [0] = trie_root }

    for idx, line in ipairs(tree_lines) do
        -- 第一行是根目录行
        if idx == 1 then
            file_map[idx]   = abs_root
            is_dir_map[idx] = true
            goto continue
        end

        local conn = find_connector(line)
        if not conn then
            file_map[idx]   = nil
            is_dir_map[idx] = false
            goto continue
        end

        local depth, raw_name = parse_depth_name(line, conn)
        if not raw_name or raw_name == "" then
            file_map[idx]   = nil
            is_dir_map[idx] = false
            goto continue
        end

        local cname  = clean_name(raw_name)
        local parent = stack[depth - 1]

        if parent and parent.children[cname] then
            local node = parent.children[cname]
            stack[depth] = node
            -- 清除更深层的旧栈帧
            for d = depth + 1, #stack do stack[d] = nil end
            file_map[idx]   = node.full_path
            is_dir_map[idx] = node.is_dir
        else
            file_map[idx]   = nil
            is_dir_map[idx] = false
        end

        ::continue::
    end

    return file_map, is_dir_map
end

return M
