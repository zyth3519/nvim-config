local M = {}

local state = {
	win = nil,
	buf = nil,
	job_id = nil,
}

local history_state = {
	index = nil,
	last_cmdline = nil,
}

local config = {
	height = 12,
	ft = "runner",
	title = "Run",
	command_name = "Run",
	cwd = nil,
	env = nil,
}

local function is_valid_win(win)
	return win and type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
	return buf and type(buf) == "number" and vim.api.nvim_buf_is_valid(buf)
end

local function is_job_running(job_id)
	if not job_id or job_id <= 0 then
		return false
	end
	return vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function stop_job()
	if is_job_running(state.job_id) then
		pcall(vim.fn.jobstop, state.job_id)
	end
	state.job_id = nil
end

local function reset_invalid_state()
	if not is_valid_win(state.win) then
		state.win = nil
	end
	if not is_valid_buf(state.buf) then
		state.buf = nil
	end
end

local function normalize_cwd(cwd)
	if cwd == nil or cwd == "" then
		return nil
	end
	return vim.fn.fnamemodify(cwd, ":p")
end

local function normalize_env(env)
	if env == nil or type(env) ~= "table" then
		return nil
	end
	return env
end

local function reset_history_state()
	history_state.index = nil
	history_state.last_cmdline = nil
end

local function is_launchbox_cmdline(cmdline)
	local command_name = config.command_name
	return cmdline == command_name or cmdline:match("^" .. vim.pesc(command_name) .. "%s")
end

function M.cmdline_prev()
	if vim.fn.getcmdtype() ~= ":" then
		return vim.keycode("<C-p>")
	end

	local cmdline = vim.fn.getcmdline()
	if not is_launchbox_cmdline(cmdline) then
		reset_history_state()
		return vim.keycode("<C-p>")
	end

	local max_hist = vim.fn.histnr(":")
	if max_hist <= 0 then
		return ""
	end

	local start = max_hist
	if history_state.last_cmdline == cmdline and history_state.index ~= nil then
		start = history_state.index - 1
	else
		reset_history_state()
	end

	for i = start, 1, -1 do
		local entry = vim.fn.histget(":", i)
		if type(entry) == "string" and is_launchbox_cmdline(entry) then
			history_state.index = i
			history_state.last_cmdline = entry
			return vim.keycode("<C-u>") .. entry
		end
	end

	return ""
end

function M.cmdline_next()
	if vim.fn.getcmdtype() ~= ":" then
		return vim.keycode("<C-n>")
	end

	local cmdline = vim.fn.getcmdline()
	if not is_launchbox_cmdline(cmdline) then
		reset_history_state()
		return vim.keycode("<C-n>")
	end

	local max_hist = vim.fn.histnr(":")
	if max_hist <= 0 then
		return ""
	end

	if history_state.index == nil then
		return ""
	end

	for i = history_state.index + 1, max_hist do
		local entry = vim.fn.histget(":", i)
		if type(entry) == "string" and is_launchbox_cmdline(entry) then
			history_state.index = i
			history_state.last_cmdline = entry
			return vim.keycode("<C-u>") .. entry
		end
	end

	reset_history_state()
	return vim.keycode("<C-u>") .. cmdline
end

local function ensure_win(height)
	reset_invalid_state()

	if is_valid_win(state.win) then
		return state.win
	end

	local cur_win = vim.api.nvim_get_current_win()
	vim.cmd("botright " .. height .. "split")
	local new_win = vim.api.nvim_get_current_win()
	vim.cmd("resize " .. height)
	state.win = new_win

	if is_valid_win(cur_win) then
		vim.api.nvim_set_current_win(cur_win)
	end

	return new_win
end

local function set_window_options(win)
	if not is_valid_win(win) then
		return
	end

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].winfixheight = true
end

local function set_buffer_options(buf, ft)
	if not is_valid_buf(buf) then
		return
	end

	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = ft
end

local function create_buffer(win, height, ft)
	if is_valid_buf(state.buf) then
		pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
		state.buf = nil
	end

	if not is_valid_win(win) then
		win = ensure_win(height)
		if not is_valid_win(win) then
			return nil, nil
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	state.buf = buf

	local ok = pcall(vim.api.nvim_win_set_buf, win, buf)
	if not ok then
		win = ensure_win(height)
		if not is_valid_win(win) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
			state.buf = nil
			return nil, nil
		end

		local ok2 = pcall(vim.api.nvim_win_set_buf, win, buf)
		if not ok2 then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
			state.buf = nil
			return nil, nil
		end
	end

	state.win = win
	set_buffer_options(buf, ft)
	set_window_options(win)

	return buf, win
end

local function start_job(cmd, buf, win, ft, cwd, env)
	if not is_valid_win(win) or not is_valid_buf(buf) then
		return nil
	end

	local job_id
	local current_job_ref = nil

	local job_opts = {
		term = true,
		cwd = cwd,
		env = env,
		on_exit = function(_, code, _)
			vim.schedule(function()
				if is_valid_buf(buf) then
					vim.bo[buf].filetype = ft
					vim.b[buf].runner_exited = true
					vim.b[buf].runner_exit_code = code
					vim.b[buf].runner_cmd = cmd
					vim.b[buf].runner_cwd = cwd
					vim.b[buf].runner_env = env
				end

				if state.job_id == current_job_ref then
					state.job_id = nil
				end
			end)
		end,
	}

	vim.api.nvim_win_call(win, function()
		job_id = vim.fn.jobstart(cmd, job_opts)
		current_job_ref = job_id
	end)

	return job_id
end

function M.run(cmd, opts)
	opts = opts or {}
	local height = opts.height or config.height
	local ft = opts.ft or config.ft
	local cwd = normalize_cwd(opts.cwd ~= nil and opts.cwd or config.cwd)
	local env = normalize_env(opts.env ~= nil and opts.env or config.env)

	if cmd == nil or cmd == "" then
		vim.notify(config.command_name .. ": empty command", vim.log.levels.WARN)
		return
	end

	if cwd and vim.fn.isdirectory(cwd) == 0 then
		vim.notify(config.command_name .. ": invalid cwd: " .. cwd, vim.log.levels.ERROR)
		return
	end

	if is_job_running(state.job_id) then
		stop_job()
	end

	local target_win = ensure_win(height)
	if not is_valid_win(target_win) then
		vim.notify(config.command_name .. ": failed to create runner window", vim.log.levels.ERROR)
		return
	end

	local buf, win = create_buffer(target_win, height, ft)
	if not buf or not win then
		vim.notify(config.command_name .. ": failed to prepare runner buffer", vim.log.levels.ERROR)
		return
	end

	local job_id = start_job(cmd, buf, win, ft, cwd, env)
	if not job_id or job_id <= 0 then
		if is_valid_buf(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
		state.buf = nil
		vim.notify(config.command_name .. ": failed to start job", vim.log.levels.ERROR)
		return
	end

	state.job_id = job_id

	if is_valid_buf(buf) then
		vim.b[buf].terminal_job_id = job_id
		vim.b[buf].runner_cmd = cmd
		vim.b[buf].runner_exited = false
		vim.b[buf].runner_cwd = cwd
		vim.b[buf].runner_env = env
	end
end

local function parse_args(cmd)
	local cwd = nil
	local env = nil
	for _, v in ipairs(cmd) do
		if v:sub(1, 4) == "cwd=" then
			cwd = v:sub(5)
		elseif v:sub(1, 4) == "env=" then
			env = v:sub(5)
		end
	end
	return { cwd = cwd, env = env }
end

function M.get_command_name()
	return config.command_name
end

function M.setup(opts)
	config = vim.tbl_extend("force", config, opts or {})

	vim.api.nvim_create_user_command(config.command_name, function(command_opts)
		local args = parse_args(command_opts.fargs)
		M.run(command_opts.args, {
			height = config.height,
			ft = config.ft,
			cwd = args.cwd or config.cwd,
			env = args.env or config.env,
		})
	end, {
		nargs = "+",
		complete = "shellcmd",
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(args)
			local closed = tonumber(args.match)
			if state.win == closed then
				if is_job_running(state.job_id) then
					pcall(vim.fn.jobstop, state.job_id)
				end
				state.win = nil
				state.buf = nil
				state.job_id = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd("CmdlineLeave", {
		pattern = ":",
		callback = reset_history_state,
	})

	vim.keymap.set("c", "<C-p>", function()
		return require("launchbox").cmdline_prev()
	end, { expr = true, desc = config.command_name .. " 命令历史向前搜索" })
	vim.keymap.set("c", "<C-n>", function()
		return require("launchbox").cmdline_next()
	end, { expr = true, desc = config.command_name .. " 命令历史向后搜索" })
end

return M
