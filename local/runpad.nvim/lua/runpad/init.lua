local launchbox = require("launchbox")
local rules = require("runpad.rules")
local bindings = require("runpad.bindings")

local M = {}

-- 插件级状态。
-- 这套运行/项目键位默认只在一个 Neovim 会话里初始化一次，
-- 手动执行 `:RunpadRedetect` 时会复用这里保存的状态和配置。
local state = {
	initialized = false,
	initializing = false,
	active_keymaps = {},
	opts = nil,
}

local function initialize(opts)
	-- 每次重建时都先清掉旧键位，再重新按当前项目生成。
	bindings.clear_active_bindings(state)

	local loaded_rules = rules.load(opts.rule_glob)
	local rule, root = rules.resolve(loaded_rules)
	if not rule then
		vim.notify("Runpad: no matching project rule", vim.log.levels.INFO)
		return
	end

	local ctx = bindings.build_context(root, launchbox)
	local ok, entries = pcall(rule.entries, ctx)
	if not ok then
		vim.notify(("Project rule %s entries failed: %s"):format(rule.name, entries), vim.log.levels.ERROR)
		return
	end

	if type(entries) ~= "table" or #entries == 0 then
		return
	end

	local generated = bindings.build(ctx, entries)
	if #generated == 0 then
		return
	end

	bindings.register(state, generated)
	bindings.register_which_key(generated)
end

function M.setup(opts)
	-- 公开入口。
	-- 配置层只需要传项目规则的 glob，
	-- 不需要关心内部是如何解析项目或生成键位的。
	opts = opts or {}
	if state.initialized or state.initializing then
		return
	end

	state.opts = vim.deepcopy(opts)
	vim.api.nvim_create_user_command("RunpadRedetect", function()
		require("runpad").redetect()
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
	-- 手动重检当前项目，并重新注册这套插件生成的键位。
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

-- function M.run(cmd, opts)
-- 	-- 暴露统一的执行入口，方便外部代码直接调用。
-- 	launchbox.run(cmd, opts)
-- end
--
-- function M.cmdline_prev()
-- 	-- 公开命令行历史搜索能力，供命令行模式映射复用。
-- 	return launchbox.cmdline_prev()
-- end
--
-- function M.cmdline_next()
-- 	return launchbox.cmdline_next()
-- end

return M
