local M = {}

local function notify_invalid(path, message)
	vim.schedule(function()
		vim.notify(("Project preset %s: %s"):format(path, message), vim.log.levels.WARN)
	end)
end

local function path_to_module(path)
	local module = path:match("/lua/(.+)%.lua$")
	if not module then
		return nil
	end
	return module:gsub("/", ".")
end

function M.load(glob)
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
