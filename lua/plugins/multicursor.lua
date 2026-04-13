return {
	"jake-stewart/multicursor.nvim",
	branch = "1.0",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local mc = require("multicursor-nvim")
		mc.setup()

		mc.addKeymapLayer(function(layerSet)
			layerSet({ "n", "x" }, "<left>", mc.prevCursor, { desc = "上一个光标" })
			layerSet({ "n", "x" }, "<right>", mc.nextCursor, { desc = "下一个光标" })
			layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "删除当前光标" })

			layerSet("n", "<esc>", function()
				if not mc.cursorsEnabled() then
					mc.enableCursors()
				else
					mc.clearCursors()
				end
			end, { desc = "启用/清除光标" })
		end)

		local hl = vim.api.nvim_set_hl
		hl(0, "MultiCursorCursor", { reverse = true })
		hl(0, "MultiCursorVisual", { link = "Visual" })
		hl(0, "MultiCursorSign", { link = "SignColumn" })
		hl(0, "MultiCursorMatchPreview", { link = "Search" })
		hl(0, "MultiCursorDisabledCursor", { reverse = true })
		hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
		hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
	end,
}
