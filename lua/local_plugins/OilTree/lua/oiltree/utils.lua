local M = {}

local log = require("oiltree.log")

---@param msg string
---@param level? number
function M.notify(msg, level)
  -- 兼容旧接口，根据 level 重定向到不同的 log 方法
  level = level or vim.log.levels.INFO
  
  if level == vim.log.levels.TRACE then
    log.trace(msg)
  elseif level == vim.log.levels.DEBUG then
    log.debug(msg)
  elseif level == vim.log.levels.INFO then
    log.info(msg)
  elseif level == vim.log.levels.WARN then
    log.warn(msg)
  elseif level == vim.log.levels.ERROR then
    log.error(msg)
  else
    log.info(msg)
  end
end

return M
