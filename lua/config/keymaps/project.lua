local M = {}

-- 项目规则文件目录。
-- 这里的每个 Lua 文件都必须返回一个 table，并实现统一接口：
--   - matches(dir): 判断某个目录是否属于该项目类型
--   - keymaps(ctx): 返回当前项目的“运行条目”列表
--
-- 运行条目本身不需要返回 lhs。
-- `project.lua` 会按返回顺序统一生成两套键位：
--   - <leader>r1 / r2 / ...   直接执行
--   - <leader>rr1 / rr2 / ... 填入命令行但不执行
--
-- 这样项目规则文件只负责“识别项目”和“提供命令定义”，
-- 键位编号、命令行预填和 which-key 注册都由这里集中处理。
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

	-- 扫描所有项目规则文件并做最小接口校验。
	-- 规则文件只要放进 `lua/config/projects/`，下次启动或手动重检时就会被加载。
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
	-- 项目识别优先基于当前缓冲区所在目录。
	-- 对无名缓冲区或异常路径则退回当前工作目录。
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
	-- 从子目录逐级向上遍历，用于查找最接近当前文件的项目根目录。
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

		-- 如果项目根目录就是当前 cwd，就不额外拼 `cwd=...`，
		-- 避免命令行里出现重复且无意义的参数。
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
			-- 直接执行时统一复用 `config.commands.run`，这里不暴露其内部实现。
			require("config.commands.run").run(cmd, opts)
		end,
		open = function(cmd, opts)
			-- 预填命令行时不执行命令，只是把最终的 `:Run ...` 送入命令行。
			open_run_cmdline(cmd, opts)
		end,
	}
end

local function build_lhs(index)
	-- 索引到执行键位的统一映射：1 -> <leader>r1
	return "<leader>r" .. index
end

local function build_prompt_lhs(index)
	-- 索引到“编辑后再执行”键位的统一映射：1 -> <leader>rr1
	return "<leader>rr" .. index
end

local function expand_keymaps(ctx, keymaps)
	-- 项目规则返回的是顺序化条目，这里把它扩展成真正注册到 Neovim 的键位：
	--   1. `<leader>rN` 直接执行
	--   2. `<leader>rrN` 把同一条命令填入命令行
	local expanded = {}

	for index, map in ipairs(keymaps) do
		if type(map) == "table" then
			local command = map.cmd
			local run_opts = map.run_opts or {}
			local rhs = map.rhs
			local lhs = build_lhs(index)

			-- 大多数规则文件只提供 `cmd` 字符串。
			-- 如果没有自定义 rhs，就在这里补一个默认执行器。
			if rhs == nil and type(command) == "string" then
				rhs = function()
					ctx.run(command, run_opts)
				end
			end

			if type(rhs) == "function" then
				table.insert(expanded, vim.tbl_extend("force", map, {
					lhs = lhs,
					rhs = rhs,
				}))

				-- 只有存在明确命令字符串时，才派生 `rrN` 这组“填入命令行”的键位。
				if type(command) == "string" then
					table.insert(expanded, {
						lhs = build_prompt_lhs(index),
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
	-- 手动重检前先清掉本模块注册的旧键位，避免全局映射残留。
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
	-- 初始化流程：
	--   1. 清理旧键位
	--   2. 加载规则文件
	--   3. 基于当前 buffer/cwd 找到一个项目规则
	--   4. 生成 `rN` / `rrN` 两套键位
	--   5. 注册 which-key 分组
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
	-- 手动重检命令复用同一套初始化流程，但仍然保证不会并发执行两次。
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
	-- 这个模块默认只在会话启动时初始化一次。
	-- 后续不会自动重跑；如需重新检测，手动执行 `:ProjectRunRedetect`。
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
