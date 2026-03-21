local M = {}

function M.build_context(launchbox)
	-- 规则文件只需要关心这里暴露出去的上下文：
	--   - root/file/bufnr：当前项目与缓冲区信息
	--   - run(cmd, opts)：立即执行
	--   - open(cmd, opts)：填入命令行但不执行
	local function open_run_cmdline(cmd, opts)
		opts = opts or {}
		local cwd = opts.cwd
		local parts = { launchbox.get_command_name() }
		local current_cwd = vim.fs.normalize(vim.fn.getcwd())
		local normalized_cwd = cwd and vim.fs.normalize(cwd) or nil

		-- 只有目标目录和当前 cwd 不同时，才补 `cwd=...`，
		-- 避免命令行里出现多余参数。
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
		root = vim.fn.getcwd(),
		file = vim.api.nvim_buf_get_name(0),
		bufnr = 0,
		run = function(cmd, opts)
			opts = opts or {}
			opts.cwd = opts.cwd
			launchbox.run(cmd, opts)
		end,
		open = function(cmd, opts)
			open_run_cmdline(cmd, opts)
		end,
	}
end

local function build_lhs(index)
	-- 第 N 个项目命令对应 `<leader>rN`
	return "<leader>r" .. index
end

local function build_prompt_lhs(index)
	-- 第 N 个“填入命令行”键位对应 `<leader>rrN`
	return "<leader>rr" .. index
end

local function resolve_entry_opts(entry)
	-- `opts` 是当前条目的执行选项；保留 `run_opts` 兼容旧配置。
	if type(entry.opts) == "table" then
		return entry.opts
	end
	if type(entry.run_opts) == "table" then
		return entry.run_opts
	end
	return {}
end

function M.build(ctx, entries)
	-- 把规则文件返回的有序条目扩展成真正可注册的键位：
	--   - rN：直接执行
	--   - rrN：填入命令行
	-- `rrN` 只给字符串命令生成，并且会单独连续编号。
	local expanded = {}
	local prompt_index = 0

	for index, entry in ipairs(entries) do
		if type(entry) == "table" then
			local command = entry.cmd
			local run_opts = resolve_entry_opts(entry)
			local rhs = entry.rhs

			-- 大多数规则只提供 `cmd`，这里补默认执行逻辑。
			if rhs == nil and (type(command) == "string" or type(command) == "function") then
				rhs = function()
					ctx.run(command, run_opts)
				end
			end

			if type(rhs) == "function" then
				table.insert(
					expanded,
					vim.tbl_extend("force", entry, {
						lhs = build_lhs(index),
						rhs = rhs,
					})
				)

				-- 只有存在稳定命令字符串时，才生成 `rrN` 这组预填命令行键位。
				if type(command) == "string" then
					prompt_index = prompt_index + 1
					table.insert(expanded, {
						lhs = build_prompt_lhs(prompt_index),
						mode = entry.mode or "n",
						desc = entry.desc or command,
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

function M.clear_active_bindings(state)
	-- 只删除这套插件自己注册过的键位，避免影响别的映射。
	for _, map in ipairs(state.active_keymaps) do
		pcall(vim.keymap.del, map.mode, map.lhs)
	end
	state.active_keymaps = {}
end

function M.register(state, bindings)
	-- 注册键位，同时记录下来，供下次手动重检时清理。
	for _, map in ipairs(bindings) do
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

function M.register_which_key(bindings)
	-- which-key 是可选增强；没有它时，运行逻辑仍然可用。
	local wk_ok, wk = pcall(require, "which-key")
	if not wk_ok then
		return
	end

	local specs = {
		{ "<leader>r", group = "运行 (Run)", icon = "󰆍" },
	}

	for _, map in ipairs(bindings) do
		if map.mode == nil or map.mode == "n" then
			table.insert(specs, { map.lhs, desc = map.desc })
		end
	end

	wk.add(specs)
end

return M
