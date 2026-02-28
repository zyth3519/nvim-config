-- lua/tree/renderer.lua
-- 将 tree -J 输出的 JSON 结构渲染为树形文本行
-- 支持折叠状态

local M = {}

local log = require("tree.log")

local SYM = {
	branch = "├── ",
	last = "└── ",
	pipe = "│   ",
	blank = "    ",
}

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

-- node: JSON node from tree -J
local function render_node(
	node,
	current_path,
	prefix,
	lines,
	file_map,
	is_dir_map,
	fold_state,
	icon_hl_map,
	parent_map,
	parent
)
	if not node.contents then
		return
	end

	-- 排序：目录在前，文件在后，按字母序
	local children = node.contents
	table.sort(children, function(a, b)
		local ad = a.type == "directory" and 0 or 1
		local bd = b.type == "directory" and 0 or 1
		if ad ~= bd then
			return ad < bd
		end
		return a.name < b.name
	end)

	local count = #children
	for i, child in ipairs(children) do
		local name = child.name
		local is_dir = (child.type == "directory")
		local is_last = (i == count)
		local child_full_path = current_path .. "/" .. name

		local connector = is_last and SYM.last or SYM.branch
		local child_prefix = prefix .. (is_last and SYM.blank or SYM.pipe)

		local icon, hl_group = get_icon(name, is_dir)
		local display = is_dir and (name .. "/") or name

		local fold_mark = ""
		if is_dir and fold_state[child_full_path] then
			fold_mark = "  [+]"
		end

		local pre_bytes = #(prefix .. connector)
		local lnum = #lines + 1

		lines[lnum] = prefix .. connector .. icon .. "  " .. display .. fold_mark
		file_map[lnum] = child_full_path
		is_dir_map[lnum] = is_dir
		parent_map[lnum] = parent

		if hl_group then
			icon_hl_map[lnum] = {
				col_start = pre_bytes,
				col_end = pre_bytes + #icon,
				hl_group = hl_group,
			}
		end

		if is_dir and not fold_state[child_full_path] then
			render_node(
				child,
				child_full_path,
				child_prefix,
				lines,
				file_map,
				is_dir_map,
				fold_state,
				icon_hl_map,
				parent_map,
				lnum
			)
		end
	end
end

function M.render(tree_json, abs_root, fold_state)
	fold_state = fold_state or {}
	local lines = {}
	local file_map = {}
	local is_dir_map = {}
	local icon_hl_map = {}
	local parent_map = {}

	local root_node = tree_json[1]
	if not root_node or root_node.type ~= "directory" then
		return
	end

	local root_name = vim.fn.fnamemodify(abs_root, ":t")
	local root_icon, root_hl = get_icon(root_name, true)

	lines[1] = root_icon .. "  " .. abs_root .. "/"
	file_map[1] = abs_root
	is_dir_map[1] = true
	parent_map[1] = 1

	if root_hl then
		icon_hl_map[1] = {
			col_start = 0,
			col_end = #root_icon,
			hl_group = root_hl,
		}
	end

	render_node(root_node, abs_root, "", lines, file_map, is_dir_map, fold_state, icon_hl_map, parent_map, 1)

	return {
		lines = lines,
		file_map = file_map,
		is_dir_map = is_dir_map,
		icon_hl_map = icon_hl_map,
		parent_map = parent_map,
	}
end

return M
