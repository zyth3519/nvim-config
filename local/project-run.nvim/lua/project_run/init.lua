local runner = require("project_run.runner")
local projects = require("project_run.projects")
local keymaps = require("project_run.keymaps")

local M = {}

local state = {
	initialized = false,
	initializing = false,
	active_keymaps = {},
	opts = nil,
}

local function initialize(opts)
	keymaps.clear_active_keymaps(state)

	local loaded_projects = projects.load(opts.project_glob)
	local project, root = projects.resolve(loaded_projects)
	if not project then
		vim.notify("Project run: no matching project preset", vim.log.levels.INFO)
		return
	end

	local ctx = keymaps.build_context(root, runner)
	local ok, entries = pcall(project.keymaps, ctx)
	if not ok then
		vim.notify(("Project preset %s keymaps failed: %s"):format(project.name, entries), vim.log.levels.ERROR)
		return
	end

	if type(entries) ~= "table" or #entries == 0 then
		return
	end

	local generated = keymaps.expand(ctx, entries)
	if #generated == 0 then
		return
	end

	keymaps.register(state, generated)
	keymaps.register_which_key(generated)
end

function M.setup(opts)
	opts = opts or {}
	if state.initialized or state.initializing then
		return
	end

	state.opts = vim.deepcopy(opts)
	runner.setup(opts.runner or {})

	vim.api.nvim_create_user_command("ProjectRunRedetect", function()
		require("project_run").redetect()
	end, {
		desc = "重新检测项目运行键位",
	})

	state.initializing = true

	vim.schedule(function()
		initialize(opts)
		state.initialized = true
		state.initializing = false
	end)
end

function M.redetect()
	if state.initializing then
		return
	end

	state.initializing = true

	vim.schedule(function()
		initialize(state.opts or {})
		state.initialized = true
		state.initializing = false
	end)
end

function M.run(cmd, opts)
	runner.run(cmd, opts)
end

function M.cmdline_prev_run()
	return runner.cmdline_prev_run()
end

function M.cmdline_next_run()
	return runner.cmdline_next_run()
end

return M
