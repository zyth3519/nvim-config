local loader = require("config.keymaps.project.loader")
local runtime = require("config.keymaps.project.runtime")

local M = {}

local state = {
	initialized = false,
	initializing = false,
	active_keymaps = {},
}

local function initialize()
	runtime.clear_active_keymaps(state)

	local projects = loader.load_projects()
	local project, root = loader.resolve_project(projects)
	if not project then
		vim.notify("Project run: no matching project preset", vim.log.levels.INFO)
		return
	end

	local ctx = runtime.build_context(root)
	local ok, entries = pcall(project.keymaps, ctx)
	if not ok then
		vim.notify(("Project preset %s keymaps failed: %s"):format(project.name, entries), vim.log.levels.ERROR)
		return
	end

	if type(entries) ~= "table" or #entries == 0 then
		return
	end

	local keymaps = runtime.expand_keymaps(ctx, entries)
	if #keymaps == 0 then
		return
	end

	runtime.register_keymaps(state, keymaps)
	runtime.register_which_key(keymaps)
end

function M.redetect()
	if state.initializing then
		return
	end

	state.initializing = true

	vim.schedule(function()
		initialize()
		state.initialized = true
		state.initializing = false
	end)
end

function M.setup()
	if state.initialized or state.initializing then
		return
	end

	vim.api.nvim_create_user_command("ProjectRunRedetect", function()
		require("config.keymaps.project").redetect()
	end, {
		desc = "重新检测项目运行键位",
	})

	state.initializing = true

	vim.schedule(function()
		initialize()
		state.initialized = true
		state.initializing = false
	end)
end

return M
