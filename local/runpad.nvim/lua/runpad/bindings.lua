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

		-- 只要条目显式提供了 cwd，就保留到命令行里，
		-- 让 `rrN` 和直接执行时的行为保持一致。
		if type(cwd) == "string" and cwd ~= "" then
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
		bufnr = vim.api.nvim_get_current_buf(),
		run = function(cmd, opts)
			opts = opts or {}
			launchbox.run(cmd, opts)
		end,
		open = function(cmd, opts)
			open_run_cmdline(cmd, opts)
		end,
	}
end

local function build_lhs(index)
	-- 1-9: <leader>r1 到 <leader>r9
	-- 10-18: <leader>ra1 到 <leader>ra9
	-- 19-27: <leader>rb1 到 <leader>rb9
	-- ...以此类推
	if index >= 1 and index <= 9 then
		return "<leader>r" .. index
	else
		local letter_index = math.floor((index - 10) / 9)
		local letter = string.char(97 + letter_index) -- 0->a, 1->b, ...
		local num = ((index - 10) % 9) + 1
		return "<leader>r" .. letter .. num
	end
end

local function build_prompt_lhs(index)
	-- 1-9: <leader>rr1 到 <leader>rr9
	-- 10-18: <leader>r<leader>a1 到 <leader>r<leader>a9
	-- ...以此类推
	if index >= 1 and index <= 9 then
		return "<leader>r<leader>" .. index
	else
		local letter_index = math.floor((index - 10) / 9)
		local letter = string.char(97 + letter_index)
		local num = ((index - 10) % 9) + 1
		return "<leader>r<leader>" .. letter .. num
	end
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

				-- 只有存在稳定命令字符串时，才生成 `r<leader>N` 这组预填命令行键位。
				if type(command) == "string" then
					table.insert(expanded, {
						lhs = build_prompt_lhs(index),
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
