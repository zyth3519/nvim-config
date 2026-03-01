local M = {}

---@class OilTreeConfig
M.defaults = {
  -- Add default configuration here
  debug = false,
}

M.options = {}

---@param opts? OilTreeConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
