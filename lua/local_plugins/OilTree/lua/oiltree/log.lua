local config = require("oiltree.config")

---@class OilTreeLog
local M = {}

M.levels = {
  TRACE = vim.log.levels.TRACE or 0,
  DEBUG = vim.log.levels.DEBUG or 1,
  INFO  = vim.log.levels.INFO or 2,
  WARN  = vim.log.levels.WARN or 3,
  ERROR = vim.log.levels.ERROR or 4,
}

local level_names = {
  [M.levels.TRACE] = "TRACE",
  [M.levels.DEBUG] = "DEBUG",
  [M.levels.INFO]  = "INFO",
  [M.levels.WARN]  = "WARN",
  [M.levels.ERROR] = "ERROR",
}

-- Safe formatting function
local function format_msg(msg, ...)
  local args = { ... }
  if #args == 0 then
    if type(msg) ~= "string" then
      return vim.inspect(msg)
    end
    return msg
  end
  
  -- Use vim.inspect for non-string arguments to avoid string.format errors
  for i, v in ipairs(args) do
    if type(v) == "table" or type(v) == "function" or type(v) == "userdata" then
      args[i] = vim.inspect(v)
    end
  end
  return string.format(tostring(msg), unpack(args))
end

local function get_log_file()
  local ok, path = pcall(vim.fn.stdpath, "state")
  if not ok or not path then
    path = vim.fn.stdpath("cache")
  end
  return string.format("%s/oiltree.log", path)
end

local log_file = get_log_file()

local function write_to_file(level, msg)
  local f = io.open(log_file, "a")
  if f then
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local level_name = level_names[level] or "UNKNOWN"
    f:write(string.format("[%s] [%s] %s\n", time, level_name, msg))
    f:close()
  end
end

local function log(level, msg, ...)
  local is_debug = config.options and config.options.debug

  if level < M.levels.INFO and not is_debug then
    return
  end

  local formatted_msg = format_msg(msg, ...)

  write_to_file(level, formatted_msg)

  if level >= M.levels.INFO or is_debug then
    vim.notify(formatted_msg, level, { title = "OilTree" })
  end
end

function M.trace(msg, ...) log(M.levels.TRACE, msg, ...) end
function M.debug(msg, ...) log(M.levels.DEBUG, msg, ...) end
function M.info(msg, ...)  log(M.levels.INFO, msg, ...) end
function M.warn(msg, ...)  log(M.levels.WARN, msg, ...) end
function M.error(msg, ...) log(M.levels.ERROR, msg, ...) end

--- Get the path to the log file
---@return string
function M.get_path()
  return log_file
end

return M
