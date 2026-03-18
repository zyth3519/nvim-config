local M = {}

local PROJECT_GLOB = "lua/config/projects/*.lua"
local PROJECT_GROUP = vim.api.nvim_create_augroup("ProjectRunKeymaps", { clear = true })

local projects = {}

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

local function load_projects()
	projects = {}

	local paths = vim.api.nvim_get_runtime_file(PROJECT_GLOB, true)
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
end

local function get_buffer_dir(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return vim.uv.cwd()
	end

	local dir = vim.fs.dirname(vim.fs.normalize(name))
	if not dir or vim.fn.isdirectory(dir) == 0 then
		return vim.uv.cwd()
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

local function resolve_project(bufnr)
	local start_dir = get_buffer_dir(bufnr)
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

local function clear_buffer_keymaps(bufnr)
	local active = vim.b[bufnr].project_run_keymaps
	if type(active) ~= "table" then
		return
	end

	for _, map in ipairs(active) do
		pcall(vim.keymap.del, map.mode, map.lhs, { buffer = bufnr })
	end

	vim.b[bufnr].project_run_keymaps = nil
	vim.b[bufnr].project_run_name = nil
	vim.b[bufnr].project_run_root = nil
end

local function build_context(bufnr, root)
	return {
		bufnr = bufnr,
		root = root,
		file = vim.api.nvim_buf_get_name(bufnr),
		run = function(cmd, opts)
			opts = opts or {}
			opts.cwd = opts.cwd or root
			require("config.commands.run").run(cmd, opts)
		end,
	}
end

local function apply_buffer_keymaps(bufnr)
	clear_buffer_keymaps(bufnr)

	if vim.bo[bufnr].buftype ~= "" then
		return
	end

	local project, root = resolve_project(bufnr)
	if not project then
		return
	end

	local ok, keymaps = pcall(project.keymaps, build_context(bufnr, root))
	if not ok then
		vim.notify(("Project preset %s keymaps failed: %s"):format(project.name, keymaps), vim.log.levels.ERROR)
		return
	end

	if type(keymaps) ~= "table" then
		vim.notify(("Project preset %s must return a keymap list"):format(project.name), vim.log.levels.ERROR)
		return
	end

	local applied = {}

	for _, map in ipairs(keymaps) do
		if type(map) == "table" and type(map.lhs) == "string" and type(map.rhs) == "function" then
			local mode = map.mode or "n"
			local opts = {
				buffer = bufnr,
				desc = map.desc,
				silent = map.silent ~= false,
				nowait = map.nowait,
			}
			vim.keymap.set(mode, map.lhs, map.rhs, opts)
			table.insert(applied, { mode = mode, lhs = map.lhs })
		end
	end

	vim.b[bufnr].project_run_keymaps = applied
	vim.b[bufnr].project_run_name = project.name
	vim.b[bufnr].project_run_root = root
end

function M.setup()
	load_projects()

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = PROJECT_GROUP,
		callback = function(args)
			apply_buffer_keymaps(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("DirChanged", {
		group = PROJECT_GROUP,
		callback = function()
			apply_buffer_keymaps(vim.api.nvim_get_current_buf())
		end,
	})

	apply_buffer_keymaps(vim.api.nvim_get_current_buf())
end

return M
