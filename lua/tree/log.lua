-- lua/tree/log.lua
local M = {}

local log_file = vim.fn.stdpath("cache") .. "/tree.log"
-- 实际路径: ~/.cache/nvim/tree.log

local levels = {
    DEBUG = "DEBUG",
    INFO  = "INFO",
    WARN  = "WARN",
    ERROR = "ERROR",
}

local function write(level, msg)
    local time = os.date("%H:%M:%S")
    local line = string.format("[%s][%s] %s\n", time, level, msg)
    local f = io.open(log_file, "a")
    if f then
        f:write(line)
        f:close()
    end
end

function M.debug(msg) write(levels.DEBUG, msg) end
function M.info(msg)  write(levels.INFO,  msg) end
function M.warn(msg)  write(levels.WARN,  msg) end
function M.error(msg) write(levels.ERROR, msg) end

-- 支持传 table，自动序列化
function M.dump(label, obj)
    write(levels.DEBUG, label .. ": " .. vim.inspect(obj))
end

-- 清空日志
function M.clear()
    local f = io.open(log_file, "w")
    if f then f:close() end
end

return M
