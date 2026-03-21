local M = {}

-- 规则文件加载失败时不直接打断启动，而是异步给出提示。
local function notify_invalid(path, message)
	vim.schedule(function()
		vim.notify(("Project preset %s: %s"):format(path, message), vim.log.levels.WARN)
	end)
end

-- 把 `/.../lua/foo/bar.lua` 转成 `foo.bar` 这种 require 可用的模块名。
local function path_to_module(path)
	local module = path:match("/lua/(.+)%.lua$")
	if not module then
		return nil
	end
	return module:gsub("/", ".")
end

function M.load(glob)
	-- 加载项目规则并做最小约定校验：
	--   1. 规则文件必须返回 table
	--   2. 必须提供 `matches(dir)`
	--   3. 必须提供 `keymaps(ctx)`
	local projects = {}
	local paths = vim.api.nvim_get_runtime_file(glob, true)
	table.sort(paths)

	for _, path in ipairs(paths) do
		local module = path_to_module(path)
		if module then
			local ok, project = pcall(require, module)
			if not ok then
				notify_invalid(path, project)
			elseif type(project) ~= "table" then
				notify_invalid(path, "must return a table")
			elseif type(project.matches) ~= "function" then
				notify_invalid(path, "missing `matches(dir)` function")
			elseif type(project.keymaps) ~= "function" then
				notify_invalid(path, "missing `keymaps(ctx)` function")
			else
				project.name = project.name or module:match("([^.]+)$")
				table.insert(projects, project)
			end
		end
	end

	return projects
end

local function get_start_dir()
	-- 优先从当前缓冲区所在目录开始判断项目类型。
	-- 对无名缓冲区则退回当前工作目录。
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return vim.fs.normalize(vim.fn.getcwd())
	end

	local dir = vim.fs.dirname(vim.fs.normalize(name))
	if not dir or vim.fn.isdirectory(dir) == 0 then
		return vim.fs.normalize(vim.fn.getcwd())
	end

	return dir
end

local function iter_parents(start_dir)
	-- 从当前目录逐级向上遍历，确保“离当前文件最近的项目根目录”优先命中。
	local dir = vim.fs.normalize(start_dir)
	return function()
		if not dir then
			return nil
		end

		local current = dir
		local parent = vim.fs.dirname(dir)
		if parent == dir then
			dir = nil
		else
			dir = parent
		end
		return current
	end
end

function M.resolve(projects)
	-- 遍历所有父目录，找到第一个成功命中的项目规则。
	local start_dir = get_start_dir()
	if not start_dir then
		return nil
	end

	for dir in iter_parents(start_dir) do
		for _, project in ipairs(projects) do
			local ok, matched = pcall(project.matches, dir)
			if ok and matched then
				return project, dir
			end
		end
	end

	return nil
end

return M
