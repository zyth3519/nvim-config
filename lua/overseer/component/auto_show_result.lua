return {
	desc = "Include a description of your component",
	params = {},
	editable = true,
	serializable = true,
	constructor = function()
		-- You may optionally define any of the methods below
		return {
			on_init = function() end,
			---@return nil|boolean
			on_pre_start = function() end,
			on_start = function()
				vim.cmd("OverseerOpen!")
			end,
			on_reset = function() end,
		}
	end,
}
