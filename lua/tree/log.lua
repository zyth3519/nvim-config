local M = {}

-- 固定路径
local LOG_FILE = vim.fn.expand("~/.cache/nvim/tree.log")

-- 确保日志目录存在
local function ensure_log_dir()
	local dir = vim.fn.fnamemodify(LOG_FILE, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

-- 获取时间戳
local function get_timestamp()
	return os.date("%Y-%m-%d %H:%M:%S")
end

-- 核心日志函数
local function write_log(level, msg, ...)
	-- 格式化消息
	local formatted_msg = msg
	if select("#", ...) > 0 then
		formatted_msg = string.format(msg, ...)
	end

	local log_entry = string.format("[%s] [%s] %s", get_timestamp(), level, formatted_msg)

	-- 确保目录存在
	ensure_log_dir()

	-- 写入文件
	local file = io.open(LOG_FILE, "a")
	if file then
		file:write(log_entry .. "\n")
		file:close()
	end
end

-- 公共API
function M.debug(msg, ...)
	write_log("DEBUG", msg, ...)
end

function M.info(msg, ...)
	write_log("INFO", msg, ...)
end

function M.warn(msg, ...)
	write_log("WARN", msg, ...)
end

function M.error(msg, ...)
	write_log("ERROR", msg, ...)
end

-- 记录函数调用
function M.enter(func_name, ...)
	local args = { ... }
	local args_str = ""
	if #args > 0 then
		args_str = " args: " .. vim.inspect(args)
	end
	write_log("DEBUG", "→ %s()%s", func_name, args_str)
end

function M.exit(func_name, result)
	if result ~= nil then
		write_log("DEBUG", "← %s() return: %s", func_name, vim.inspect(result))
	else
		write_log("DEBUG", "← %s()", func_name)
	end
end

-- 记录变量值
function M.var(name, value)
	write_log("DEBUG", "VAR %s = %s", name, vim.inspect(value))
end

-- 记录表格数据
function M.table(label, tbl)
	label = label or "Table"
	write_log("DEBUG", "%s: %s", label, vim.inspect(tbl))
end

-- 清空日志文件
function M.clear()
	ensure_log_dir()
	local file = io.open(LOG_FILE, "w")
	if file then
		file:close()
	end
end

-- 获取日志文件路径
function M.get_path()
	return LOG_FILE
end

-- 快速查看日志
function M.view()
	vim.cmd("vsplit " .. LOG_FILE)
end

-- 包装函数，自动记录调用
function M.wrap(func_name, func)
	return function(...)
		M.enter(func_name, ...)
		local result = func(...)
		M.exit(func_name, result)
		return result
	end
end

return M
