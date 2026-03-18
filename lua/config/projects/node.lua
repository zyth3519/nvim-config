local PRIORITY_SCRIPTS = {
	"dev",
	"start",
	"build",
	"test",
	"lint",
	"preview",
}

local function read_package_json(root)
	local path = root .. "/package.json"
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
	if not content or content == "" then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, content)
	if not ok or type(decoded) ~= "table" then
		return nil
	end

	return decoded
end

local function collect_script_names(scripts)
	local names = {}
	local seen = {}

	for _, name in ipairs(PRIORITY_SCRIPTS) do
		if type(scripts[name]) == "string" then
			table.insert(names, name)
			seen[name] = true
		end
	end

	local extras = {}
	for name, command in pairs(scripts) do
		if type(name) == "string" and type(command) == "string" and not seen[name] then
			table.insert(extras, name)
		end
	end

	table.sort(extras)
	vim.list_extend(names, extras)

	return names
end

local function detect_package_manager(root, package_json)
	local package_manager = package_json.packageManager
	if type(package_manager) == "string" then
		local name = package_manager:match("^([%w%-_]+)@")
		if name == "pnpm" or name == "yarn" or name == "bun" or name == "npm" then
			return name
		end
	end

	if vim.uv.fs_stat(root .. "/pnpm-lock.yaml") ~= nil then
		return "pnpm"
	end
	if vim.uv.fs_stat(root .. "/yarn.lock") ~= nil then
		return "yarn"
	end
	if vim.uv.fs_stat(root .. "/bun.lockb") ~= nil or vim.uv.fs_stat(root .. "/bun.lock") ~= nil then
		return "bun"
	end
	return "npm"
end

local function build_run_command(package_manager, script_name)
	if package_manager == "yarn" then
		return ("yarn %s"):format(script_name)
	end
	if package_manager == "bun" then
		return ("bun run %s"):format(script_name)
	end
	return ("%s run %s"):format(package_manager, script_name)
end

local function make_keymap(index, script_name, package_manager)
	local command = build_run_command(package_manager, script_name)
	return {
		lhs = "<leader>r" .. index,
		desc = ("%s %s"):format(package_manager:upper(), script_name),
		cmd = command,
	}
end

return {
	name = "node",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/package.json") ~= nil
	end,
	keymaps = function(ctx)
		local package_json = read_package_json(ctx.root)
		if type(package_json) ~= "table" or type(package_json.scripts) ~= "table" then
			return {}
		end

		local package_manager = detect_package_manager(ctx.root, package_json)
		local script_names = collect_script_names(package_json.scripts)
		local keymaps = {}

		for index, script_name in ipairs(script_names) do
			if index > 9 then
				break
			end

			table.insert(keymaps, make_keymap(index, script_name, package_manager))
		end

		return keymaps
	end,
}
