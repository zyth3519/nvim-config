-- lua/tree/renderer.lua
-- 将 Trie 渲染为树形文本行，同时产出 file_map / is_dir_map / ext_map
-- 支持折叠状态（折叠的目录只显示自身，子内容跳过）

local M = {}

-- 树形绘制符号
local SYM = {
	branch = "├── ",
	last = "└── ",
	pipe = "│   ",
	blank = "    ",
}

-- 尝试加载 devicons
local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local has_mini_icons, mini_icons = pcall(require, "mini.icons")

local function get_icon(name, is_dir)
	if is_dir then
		if has_mini_icons then
			local icon, hl_group = mini_icons.get("directory", name)
			return icon or "📁", hl_group or "Directory"
		end
		return "📁", "Directory"
	else
		local ext = name:match("^.+%.(.+)$") or ""
		if has_devicons then
			local icon, hl_group = devicons.get_icon(name, ext, { default = true })
			return icon or "📄", hl_group or "File"
		elseif has_mini_icons then
			local icon, hl_group = mini_icons.get("file", name)
			return icon or "📄", hl_group or "File"
		end

		return "📄", "File"
	end
end

---@class RenderResult
---@field lines      string[]               渲染出的文本行
---@field file_map   table<integer, string> 行号 → 绝对路径
---@field is_dir_map table<integer, boolean> 行号 → 是否目录
---@field icon_hl_map table<integer, {col_start: number, col_end: number, hl_group: string}> 行号 → 图标高亮信息

--- 递归渲染一个 TrieNode 的所有子节点
---@param node       TrieNode
---@param prefix     string          当前行的缩进前缀
---@param lines      string[]
---@param file_map   table
---@param is_dir_map table
---@param fold_state table<string, boolean>  path → closed
---@param icon_hl_map table
local function render_node(node, prefix, lines, file_map, is_dir_map, fold_state, icon_hl_map)
	-- 按 目录优先、名字字母序 排列子节点
	local children = {}
	for name, child in pairs(node.children) do
		table.insert(children, { name = name, child = child })
	end
	table.sort(children, function(a, b)
		local ad = a.child.is_dir and 0 or 1
		local bd = b.child.is_dir and 0 or 1
		if ad ~= bd then
			return ad < bd
		end
		return a.name < b.name
	end)

	local count = #children
	for i, entry in ipairs(children) do
		local name = entry.name
		local child = entry.child
		local is_last = (i == count)

		-- 当前行的连接符
		local connector = is_last and SYM.last or SYM.branch
		-- 子节点递归时的前缀
		local child_prefix = prefix .. (is_last and SYM.blank or SYM.pipe)

		-- 获取图标
		local icon, hl_group = get_icon(name, child.is_dir)

		-- 目录名加 /，文件不加
		local display = child.is_dir and (name .. "/") or name

		-- 折叠标记：目录且被折叠时加 [+]
		local fold_mark = ""
		if child.is_dir and fold_state[child.full_path] then
			fold_mark = "  [+]"
		end

		-- 计算前面字符的字节长度 (为了给 extmarks 使用)
		local pre_bytes = #(prefix .. connector)

		-- 写入当前行
		local lnum = #lines + 1
		lines[lnum] = prefix .. connector .. icon .. "  " .. display .. fold_mark
		file_map[lnum] = child.full_path
		is_dir_map[lnum] = child.is_dir

		-- 记录图标的高亮位置
		if hl_group then
			icon_hl_map[lnum] = {
				col_start = pre_bytes,
				col_end = pre_bytes + #icon,
				hl_group = hl_group,
			}
		end

		-- 目录且未折叠：递归渲染子节点
		if child.is_dir and not fold_state[child.full_path] then
			render_node(child, child_prefix, lines, file_map, is_dir_map, fold_state, icon_hl_map)
		end
	end
end

--- 对外接口：渲染整棵树
---@param trie_root  TrieNode
---@param abs_root   string
---@param fold_state table<string, boolean>   path → closed（可传 {}）
---@return RenderResult
function M.render(trie_root, abs_root, fold_state)
	fold_state = fold_state or {}

	local lines = {}
	local file_map = {}
	local is_dir_map = {}
	local icon_hl_map = {}

	-- 第一行：根目录
	local root_name = vim.fn.fnamemodify(abs_root, ":t")
	local root_icon, root_hl = get_icon(root_name, true)

	lines[1] = root_icon .. "  " .. abs_root .. "/"
	file_map[1] = abs_root
	is_dir_map[1] = true

	if root_hl then
		icon_hl_map[1] = {
			col_start = 0,
			col_end = #root_icon,
			hl_group = root_hl,
		}
	end

	render_node(trie_root, "", lines, file_map, is_dir_map, fold_state, icon_hl_map)

	return {
		lines = lines,
		file_map = file_map,
		is_dir_map = is_dir_map,
		icon_hl_map = icon_hl_map,
	}
end

return M
