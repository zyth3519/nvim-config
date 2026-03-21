local M = {}

-- 规则文件加载失败时不直接打断启动，而是异步给出提示。
local function notify_invalid(path, message)
	vim.schedule(function()
		vim.notify(("Project rule %s: %s"):format(path, message), vim.log.levels.WARN)
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
	--   3. 必须提供 `entries(ctx)`
	local rules = {}
	local paths = vim.api.nvim_get_runtime_file(glob, true)
	table.sort(paths)

	for _, path in ipairs(paths) do
		local module = path_to_module(path)
		if module then
			local ok, rule = pcall(require, module)
			if not ok then
				notify_invalid(path, rule)
			elseif type(rule) ~= "table" then
				notify_invalid(path, "must return a table")
			elseif type(rule.matches) ~= "function" then
				notify_invalid(path, "missing `matches(dir)` function")
			elseif type(rule.entries) ~= "function" then
				notify_invalid(path, "missing `entries(ctx)` function")
			else
				rule.name = rule.name or module:match("([^.]+)$")
				table.insert(rules, rule)
			end
		end
	end

	return rules
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

function M.resolve(rules)
	-- 遍历所有父目录，找到第一个成功命中的项目规则。
	local start_dir = get_start_dir()
	if not start_dir then
		return nil
	end

	for dir in iter_parents(start_dir) do
		for _, rule in ipairs(rules) do
			local ok, matched = pcall(rule.matches, dir)
			if ok and matched then
				return rule, dir
			end
		end
	end

	return nil
end

return M
