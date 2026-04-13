return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				numbers = "ordinal",
				indicator = { style = "underline" },
				buffer_close_icon = "󰅖",
				modified_icon = "●",
				separator_style = "thin",
				always_show_bufferline = true,
				-- 解决与自定义文件树以及 Oil 的重叠问题
				offsets = {
					{
						filetype = "mytree",
						text = "File Explorer",
						text_align = "left",
					},
					{
						filetype = "oil",
						text = "Oil File Manager",
						text_align = "left",
					},
				},
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(count, level)
					local icon = level:match("error") and " " or level:match("warn") and " " or "ℹ "
					return " " .. icon .. count
				end,
			},
		})
	end,
}
