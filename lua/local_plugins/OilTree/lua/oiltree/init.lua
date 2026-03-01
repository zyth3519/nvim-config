local M = {}

---@param opts? OilTreeConfig
function M.setup(opts)
  require("oiltree.config").setup(opts)
end

return M
