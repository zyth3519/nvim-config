-- 用于显示 Oil 文件管理器的标题路径
function _G.get_oil_winbar()
	local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local dir = require("oil").get_current_dir(bufnr)
	if dir then
		return vim.fn.fnamemodify(dir, ":~")
	else
		return vim.api.nvim_buf_get_name(0)
	end
end

return {
	-- 强大的文件管理器 (Oil)
	{
		"stevearc/oil.nvim",
		opts = {
			default_file_explorer = true,
			columns = { "icon", "permissions", "size", "mtime" },
			win_options = { winbar = "%!v:lua.get_oil_winbar()" },
			keymaps = {
				-- 禁用会和窗口导航 (Ctrl + hjkl) 冲突的快捷键
				["<C-h>"] = false,
				["<C-l>"] = false,
				["<C-j>"] = false,
				["<C-k>"] = false,
				-- 重新映射可能被覆盖的重要快捷键
				["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc = "水平分割打开" },
				["<C-r>"] = { "actions.refresh", desc = "刷新目录" },
			},
		},
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		lazy = false,
	},
}
