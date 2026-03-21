local MAX_ENTRIES = 9

local function launch_path(root)
	return root .. "/.vscode/launch.json"
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

local function resolve_config(config, root)
	local resolved = type(config) == "function" and config() or vim.deepcopy(config)
	resolved = replace_workspace_vars(resolved, root)
	resolved.cwd = resolved.cwd or root
	return resolved
end

local function make_entry(config, root)
	return {
		desc = config.name,
		cmd = function()
			local dap = require("dap")
			dap.run(resolve_config(config, root))
		end,
	}
end

return {
	name = "vscode",
	priority = 100,
	matches = function(dir)
		return vim.uv.fs_stat(launch_path(dir)) ~= nil
	end,
	entries = function(ctx)
		local ok, vscode = pcall(require, "dap.ext.vscode")
		if not ok then
			vim.notify("Runpad: failed to load dap.ext.vscode", vim.log.levels.ERROR)
			return {}
		end

		local configs = vscode.getconfigs(launch_path(ctx.root))
		local entries = {}

		for _, config in ipairs(configs) do
			if type(config) == "table" and type(config.name) == "string" and type(config.type) == "string" then
				table.insert(entries, make_entry(config, ctx.root))
				if #entries >= MAX_ENTRIES then
					break
				end
			end
		end

		return entries
	end,
}
