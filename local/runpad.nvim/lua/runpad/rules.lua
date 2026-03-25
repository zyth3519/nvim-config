local M = {}

-- 规则文件加载失败时不直接打断启动，而是异步给出提示。
local function notify_invalid(path, message)
	vim.schedule(function()
		vim.notify(("Project rule %s: %s"):format(path, message), vim.log.levels.WARN)
	end)
end

local function notify_rule(name, message)
	vim.schedule(function()
		vim.notify(("Project rule %s: %s"):format(name, message), vim.log.levels.WARN)
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
				rule.priority = tonumber(rule.priority) or 0
				table.insert(rules, rule)
			end
		end
	end

	table.sort(rules, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end
		return a.name < b.name
	end)

	return rules
end

function M.resolve(rules)
	local matchs = {}
	for _, rule in ipairs(rules) do
		local ok, matched = pcall(rule.matches, vim.fn.getcwd())
		if not ok then
			notify_rule(rule.name or "unknown", matched)
		elseif matched then
			matchs[#matchs + 1] = rule
		end
	end

	return matchs
end

return M
