local MAX_ENTRIES = 9

local function tasks_path(root)
	return root .. "/.vscode/tasks.json"
end

local function read_text(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end

	local stat = vim.uv.fs_fstat(fd)
	if not stat then
		vim.uv.fs_close(fd)
		return nil
	end

	local content = vim.uv.fs_read(fd, stat.size, 0)
	vim.uv.fs_close(fd)
	return content
end

local function replace_workspace_vars(value, root)
	if type(value) == "table" then
		local result = {}
		for key, item in pairs(value) do
			result[replace_workspace_vars(key, root)] = replace_workspace_vars(item, root)
		end
		return setmetatable(result, getmetatable(value))
	end

	if type(value) ~= "string" then
		return value
	end

	local basename = vim.fs.basename(root)
	return value
		:gsub("${workspaceFolder}", root)
		:gsub("${workspaceFolderBasename}", basename)
end

local function read_tasks(root)
	local content = read_text(tasks_path(root))
	if not content or content == "" then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, content, { skip_comments = true })
	if not ok or type(decoded) ~= "table" then
		return nil
	end

	return decoded
end

local function shell_escape(value)
	return vim.fn.shellescape(tostring(value))
end

local function build_command(task, root)
	local command = replace_workspace_vars(task.command, root)
	if type(command) ~= "string" or command == "" then
		return nil
	end

	local parts = { command }
	if type(task.args) == "table" then
		for _, arg in ipairs(task.args) do
			local resolved = replace_workspace_vars(arg, root)
			if resolved ~= nil then
				table.insert(parts, shell_escape(resolved))
			end
		end
	end

	return table.concat(parts, " ")
end

local function build_opts(task, root)
	local opts = {}
	local options = type(task.options) == "table" and task.options or nil
	if not options then
		return opts
	end

	local cwd = replace_workspace_vars(options.cwd, root)
	if type(cwd) == "string" and cwd ~= "" then
		opts.cwd = cwd
	end

	if type(options.env) == "table" then
		opts.env = replace_workspace_vars(options.env, root)
	end

	return opts
end

local function make_entry(task, root)
	local command = build_command(task, root)
	if not command then
		return nil
	end

	return {
		desc = task.label,
		cmd = command,
		opts = build_opts(task, root),
	}
end

return {
	name = "vscode",
	priority = 100,
	matches = function(dir)
		return vim.uv.fs_stat(tasks_path(dir)) ~= nil
	end,
	entries = function(ctx)
		local decoded = read_tasks(ctx.root)
		if type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then
			return {}
		end

		local entries = {}
		for _, task in ipairs(decoded.tasks) do
			if type(task) == "table" and type(task.label) == "string" then
				local entry = make_entry(task, ctx.root)
				if entry then
					table.insert(entries, entry)
				end
				if #entries >= MAX_ENTRIES then
					break
				end
			end
		end

		return entries
	end,
}
