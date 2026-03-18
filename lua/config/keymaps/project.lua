local M = {}

-- 项目规则文件目录。
-- 这里的每个 Lua 文件都必须返回一个 table，并实现统一接口：
--   - matches(dir): 判断某个目录是否属于该项目类型
--   - keymaps(ctx): 返回当前项目要注册的键位列表
local PROJECT_GLOB = "lua/config/projects/*.lua"

local projects = {}
local state = {
	-- 整个 Neovim 会话里只初始化一次。
	initialized = false,
	-- 启动阶段异步初始化时，避免重复排队。
	initializing = false,
	-- 记录当前会话里由项目规则注册的全局键位，便于手动重检前清理。
	active_keymaps = {},
}

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

-- 只在启动时基于当前缓冲区或当前工作目录识别一次项目类型。
-- 后续无论切 buffer、切窗口还是修改工作目录，都不会再重新计算。
local function resolve_project()
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

local function build_context(root)
	local function open_run_cmdline(cmd, opts)
		opts = opts or {}
		local cwd = opts.cwd or root
		local parts = { "Run" }
		local current_cwd = vim.fs.normalize(vim.fn.getcwd())
		local normalized_cwd = cwd and vim.fs.normalize(cwd) or nil

		if normalized_cwd and normalized_cwd ~= "" and normalized_cwd ~= current_cwd then
			table.insert(parts, "cwd=" .. vim.fn.fnameescape(cwd))
		end

		if cmd and cmd ~= "" then
			table.insert(parts, cmd)
		end

		local line = table.concat(parts, " ")
		local keys = vim.keycode(":" .. line)
		vim.api.nvim_feedkeys(keys, "n", false)
	end

	return {
		root = root,
		file = vim.api.nvim_buf_get_name(0),
		bufnr = 0,
		run = function(cmd, opts)
			opts = opts or {}
			opts.cwd = opts.cwd or root
			require("config.commands.run").run(cmd, opts)
		end,
		open = function(cmd, opts)
			open_run_cmdline(cmd, opts)
		end,
	}
end

local function derive_prompt_lhs(lhs)
	local suffix = lhs:match("^<leader>r(.+)$")
	if not suffix then
		return nil
	end
	return "<leader>rr" .. suffix
end

local function expand_keymaps(ctx, keymaps)
	local expanded = {}

	for _, map in ipairs(keymaps) do
		if type(map) == "table" and type(map.lhs) == "string" then
			local command = map.cmd
			local run_opts = map.run_opts or {}
			local rhs = map.rhs

			if rhs == nil and type(command) == "string" then
				rhs = function()
					ctx.run(command, run_opts)
				end
			end

			if type(rhs) == "function" then
				table.insert(expanded, vim.tbl_extend("force", map, {
					rhs = rhs,
				}))

				local prompt_lhs = derive_prompt_lhs(map.lhs)
				if prompt_lhs and type(command) == "string" then
					table.insert(expanded, {
						lhs = prompt_lhs,
						mode = map.mode or "n",
						desc = map.desc or command,
						rhs = function()
							ctx.open(command, run_opts)
						end,
					})
				end
			end
		end
	end

	return expanded
end

local function clear_active_keymaps()
	for _, map in ipairs(state.active_keymaps) do
		pcall(vim.keymap.del, map.mode, map.lhs)
	end
	state.active_keymaps = {}
end

-- 命中项目规则后，把运行键位注册成全局映射。
-- 因为整个会话只初始化一次，所以这里不再使用 buffer-local 注册。
local function register_keymaps(keymaps)
	for _, map in ipairs(keymaps) do
		if type(map) == "table" and type(map.lhs) == "string" and type(map.rhs) == "function" then
			local mode = map.mode or "n"
			local opts = {
				desc = map.desc,
				silent = map.silent ~= false,
				nowait = map.nowait,
			}
			vim.keymap.set(mode, map.lhs, map.rhs, opts)
			table.insert(state.active_keymaps, { mode = mode, lhs = map.lhs })
		end
	end
end

-- 只有真正命中项目时，才注册 which-key 的 `<leader>r` 分组。
local function register_which_key(keymaps)
	local wk_ok, wk = pcall(require, "which-key")
	if not wk_ok then
		return
	end

	local specs = {
		{ "<leader>r", group = "运行 (Run)", icon = "󰆍" },
	}

	for _, map in ipairs(keymaps) do
		if map.mode == nil or map.mode == "n" then
			table.insert(specs, {
				map.lhs,
				desc = map.desc,
			})
		end
	end

	wk.add(specs)
end

local function initialize()
	clear_active_keymaps()
	load_projects()

	local project, root = resolve_project()
	if not project then
		vim.notify("Project run: no matching project preset", vim.log.levels.INFO)
		return
	end

	local ok, keymaps = pcall(project.keymaps, build_context(root))
	if not ok then
		vim.notify(("Project preset %s keymaps failed: %s"):format(project.name, keymaps), vim.log.levels.ERROR)
		return
	end

	if type(keymaps) ~= "table" or #keymaps == 0 then
		return
	end

	local ctx = build_context(root)
	keymaps = expand_keymaps(ctx, keymaps)
	if #keymaps == 0 then
		return
	end

	register_keymaps(keymaps)
	register_which_key(keymaps)
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

	-- 启动时延后一拍执行，避免把规则扫描和项目识别塞进最早期初始化阶段。
	vim.schedule(function()
		initialize()
		state.initialized = true
		state.initializing = false
	end)
end

return M
