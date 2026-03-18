local PRIORITY_LABELS = {
	"dev",
	"start",
	"build",
	"test",
	"lint",
	"preview",
}

local function read_file(path)
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

local function strip_json_comments(content)
	local out = {}
	local i = 1
	local in_string = false
	local quote = nil

	while i <= #content do
		local ch = content:sub(i, i)
		local next_two = content:sub(i, i + 1)

		if in_string then
			table.insert(out, ch)
			if ch == "\\" and i < #content then
				i = i + 1
				table.insert(out, content:sub(i, i))
			elseif ch == quote then
				in_string = false
				quote = nil
			end
		elseif ch == '"' or ch == "'" then
			in_string = true
			quote = ch
			table.insert(out, ch)
		elseif next_two == "//" then
			i = i + 2
			while i <= #content and content:sub(i, i) ~= "\n" do
				i = i + 1
			end
			goto continue
		elseif next_two == "/*" then
			i = i + 2
			while i <= #content - 1 and content:sub(i, i + 1) ~= "*/" do
				i = i + 1
			end
			i = i + 1
		else
			table.insert(out, ch)
		end

		::continue::
		i = i + 1
	end

	return table.concat(out)
end

local function read_tasks_json(root)
	local content = read_file(root .. "/.vscode/tasks.json")
	if not content or content == "" then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, strip_json_comments(content))
	if not ok or type(decoded) ~= "table" then
		return nil
	end

	return decoded
end

local function expand_vars(value, root)
	if type(value) ~= "string" then
		return value
	end

	return value
		:gsub("${workspaceFolder}", root)
		:gsub("${workspaceFolderBasename}", vim.fs.basename(root))
end

local function shellescape_args(args, root)
	if type(args) ~= "table" then
		return ""
	end

	local parts = {}
	for _, arg in ipairs(args) do
		if type(arg) == "string" then
			table.insert(parts, vim.fn.shellescape(expand_vars(arg, root)))
		end
	end
	return table.concat(parts, " ")
end

local function resolve_task_command(task, root)
	if type(task.command) ~= "string" or task.command == "" then
		return nil
	end

	local command = expand_vars(task.command, root)
	local args = shellescape_args(task.args, root)
	if args ~= "" then
		command = command .. " " .. args
	end

	local cwd = root
	if type(task.options) == "table" and type(task.options.cwd) == "string" then
		cwd = expand_vars(task.options.cwd, root)
	end

	return {
		command = command,
		cwd = cwd,
	}
end

local function collect_tasks(tasks)
	local prioritized = {}
	local remaining = {}
	local seen = {}

	for _, label in ipairs(PRIORITY_LABELS) do
		for _, task in ipairs(tasks) do
			if type(task) == "table" and type(task.label) == "string" and task.label == label and not seen[label] then
				table.insert(prioritized, task)
				seen[label] = true
			end
		end
	end

	for _, task in ipairs(tasks) do
		if type(task) == "table" and type(task.label) == "string" and not seen[task.label] then
			table.insert(remaining, task)
		end
	end

	table.sort(remaining, function(a, b)
		return a.label < b.label
	end)

	vim.list_extend(prioritized, remaining)
	return prioritized
end

local function make_keymap(index, task, resolved, ctx)
	return {
		lhs = "<leader>r" .. index,
		desc = ("Task %s"):format(task.label),
		rhs = function()
			ctx.run(resolved.command, { cwd = resolved.cwd })
		end,
	}
end

return {
	name = "vscode",
	priority = 100,
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/.vscode/tasks.json") ~= nil
	end,
	keymaps = function(ctx)
		local tasks_json = read_tasks_json(ctx.root)
		if type(tasks_json) ~= "table" or type(tasks_json.tasks) ~= "table" then
			return {}
		end

		local tasks = collect_tasks(tasks_json.tasks)
		local keymaps = {}

		for index, task in ipairs(tasks) do
			if index > 9 then
				break
			end

			local resolved = resolve_task_command(task, ctx.root)
			if resolved then
				table.insert(keymaps, make_keymap(index, task, resolved, ctx))
			end
		end

		return keymaps
	end,
}
