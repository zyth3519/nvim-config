local M = {}

local levels = {
	debug = 1,
	info = 2,
	warn = 3,
	error = 4,
}

local config = {
	enabled = true,
	level = "info",
	path = vim.fn.stdpath("state") .. "/runpad.log",
}

local function should_log(level)
	return config.enabled and levels[level] >= levels[config.level]
end

local function append(line)
	local ok, err = pcall(vim.fn.writefile, { line }, config.path, "a")
	if not ok then
		vim.schedule(function()
			vim.notify(("Runpad log write failed: %s"):format(err), vim.log.levels.WARN)
		end)
	end
end

local function log(level, message, data)
	if not should_log(level) then
		return
	end

	local line = os.date("%Y-%m-%d %H:%M:%S")
		.. " ["
		.. level:upper()
		.. "] "
		.. message

	if data ~= nil then
		line = line .. " " .. vim.inspect(data)
	end

	append(line)
end

function M.setup(opts)
	config = vim.tbl_extend("force", config, opts or {})
end

function M.debug(message, data)
	log("debug", message, data)
end

function M.info(message, data)
	log("info", message, data)
end

function M.warn(message, data)
	log("warn", message, data)
end

function M.error(message, data)
	log("error", message, data)
end

function M.path()
	return config.path
end

return M
