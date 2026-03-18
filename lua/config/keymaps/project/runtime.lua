local M = {}

function M.build_context(root)
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

local function build_lhs(index)
	return "<leader>r" .. index
end

local function build_prompt_lhs(index)
	return "<leader>rr" .. index
end

function M.expand_keymaps(ctx, entries)
	local expanded = {}

	for index, entry in ipairs(entries) do
		if type(entry) == "table" then
			local command = entry.cmd
			local run_opts = entry.run_opts or {}
			local rhs = entry.rhs

			if rhs == nil and type(command) == "string" then
				rhs = function()
					ctx.run(command, run_opts)
				end
			end

			if type(rhs) == "function" then
				table.insert(expanded, vim.tbl_extend("force", entry, {
					lhs = build_lhs(index),
					rhs = rhs,
				}))

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

function M.clear_active_keymaps(state)
	for _, map in ipairs(state.active_keymaps) do
		pcall(vim.keymap.del, map.mode, map.lhs)
	end
	state.active_keymaps = {}
end

function M.register_keymaps(state, keymaps)
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

function M.register_which_key(keymaps)
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

return M
