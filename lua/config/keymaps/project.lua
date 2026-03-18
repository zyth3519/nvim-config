local M = {}

-- 项目规则文件目录。
-- 这里的每个 Lua 文件都必须返回一个 table，并实现统一接口：
--   - matches(dir): 判断某个目录是否属于该项目类型
--   - keymaps(ctx): 返回当前项目要注册的键位列表
local PROJECT_GLOB = "lua/config/projects/*.lua"
local PROJECT_GROUP = vim.api.nvim_create_augroup("ProjectRunKeymaps", { clear = true })

local projects = {}
local state = {
	-- 是否已经完成过规则文件扫描。
	loaded = false,
	-- 是否正在异步加载，避免重复触发扫描。
	loading = false,
	-- 扫描完成后需要继续执行的回调队列。
	pending = {},
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

	-- 从运行时路径中扫描所有项目规则文件。
	-- 这样后续新增规则时，只需要在 `lua/config/projects/` 下新增文件，
	-- 不需要再回头修改这个加载器。
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
				-- 为没有显式声明 name 的规则补一个默认名字，方便调试和提示。
				project.name = project.name or module:match("([^.]+)$")
				table.insert(projects, project)
			end
		end
	end
end

local function is_valid_buf(bufnr)
	return type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr)
end

local function get_buffer_dir(bufnr)
	-- 无名缓冲区退回到当前工作目录，避免路径相关逻辑直接失效。
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
	-- 生成一个向上遍历父目录的迭代器。
	-- 用于从“当前文件所在目录”逐级向上查找项目根目录。
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
	-- 从当前缓冲区目录开始向上查找，直到某个规则命中。
	-- 一旦某个项目规则的 `matches(dir)` 返回 true，
	-- 就认为该目录是项目根目录，并停止继续向上搜索。
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
	-- 这些运行键位是 buffer-local 的。
	-- 每次重新匹配项目类型前，先清掉旧键位，避免目录切换后残留错误映射。
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
	-- 提供给项目规则文件的上下文对象。
	-- 规则文件只需要基于这些公开能力生成键位，不需要直接依赖 run.lua 的内部实现。
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

-- `which-key` 只在命中项目规则后注册当前 buffer 的运行分组。
-- 这样没有匹配项目时，不会在 `<leader>` 面板里提前暴露 `<leader>r`。
local function register_which_key(bufnr, keymaps)
	local wk_ok, wk = pcall(require, "which-key")
	if not wk_ok then
		return
	end

	local specs = {
		{ "<leader>r", group = "运行 (Run)", buffer = bufnr, icon = "󰆍" },
	}

	for _, map in ipairs(keymaps) do
		if map.mode == nil or map.mode == "n" then
			table.insert(specs, {
				map.lhs,
				desc = map.desc,
				buffer = bufnr,
			})
		end
	end

	wk.add(specs)
end

local function apply_buffer_keymaps(bufnr)
	-- 每次应用前都先清掉旧的 buffer-local 运行键位。
	clear_buffer_keymaps(bufnr)

	-- 特殊缓冲区不参与项目规则匹配，例如终端、帮助页、插件面板等。
	if not is_valid_buf(bufnr) or vim.bo[bufnr].buftype ~= "" then
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

	-- 这里把项目规则返回的键位注册成 buffer-local 映射。
	-- 这样同一个 Neovim 会话里，不同项目可以同时拥有不同的 `<leader>r*` 行为，
	-- 互不污染。
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

	if #applied == 0 then
		return
	end

	-- `which-key` 也使用 buffer 级注册，保证只在当前项目有效。
	register_which_key(bufnr, keymaps)

	vim.b[bufnr].project_run_keymaps = applied
	vim.b[bufnr].project_run_name = project.name
	vim.b[bufnr].project_run_root = root
end

-- 首次需要时才扫描 `lua/config/projects/*.lua`，避免在启动阶段同步 require 所有规则文件。
local function ensure_projects_loaded(callback)
	if state.loaded then
		callback()
		return
	end

	if callback then
		table.insert(state.pending, callback)
	end

	if state.loading then
		return
	end

	state.loading = true

	vim.schedule(function()
		-- 延后到调度阶段执行扫描，减少启动阶段同步工作量。
		load_projects()
		state.loaded = true
		state.loading = false

		local pending = state.pending
		state.pending = {}

		for _, fn in ipairs(pending) do
			pcall(fn)
		end
	end)
end

-- 这里用 `vim.schedule` 做一次主线程延后执行，避免在高频 BufEnter/BufWinEnter 中直接跑目录扫描和规则匹配。
local function request_apply(bufnr)
	ensure_projects_loaded(function()
		vim.schedule(function()
			if is_valid_buf(bufnr) then
				apply_buffer_keymaps(bufnr)
			end
		end)
	end)
end

function M.setup()
	-- 进入缓冲区时尝试为当前文件匹配项目规则。
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = PROJECT_GROUP,
		callback = function(args)
			request_apply(args.buf)
		end,
	})

	-- 当工作目录变化时，也重新检查当前缓冲区对应的项目规则。
	vim.api.nvim_create_autocmd("DirChanged", {
		group = PROJECT_GROUP,
		callback = function()
			request_apply(vim.api.nvim_get_current_buf())
		end,
	})

	-- 启动完成后对当前缓冲区做一次首轮匹配。
	request_apply(vim.api.nvim_get_current_buf())
end

return M
