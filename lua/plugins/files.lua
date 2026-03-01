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
	-- 文件树 (nvim-tree)
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local function my_on_attach(bufnr)
				local api = require("nvim-tree.api")

				local function opts(desc)
					return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
				end

				-- 默认快捷键
				api.config.mappings.default_on_attach(bufnr)

				-- 移除不需要的文件操作快捷键，使用 oil 进行管理
				local del_keys = { "a", "d", "D", "r", "e", "x", "p" }
				for _, key in ipairs(del_keys) do
					pcall(vim.keymap.del, "n", key, { buffer = bufnr })
				end

				-- 绑定 o 打开 Oil
				vim.keymap.set("n", "o", function()
					local node = api.tree.get_node_under_cursor()
					local path = node.type == "directory" and node.absolute_path
						or vim.fn.fnamemodify(node.absolute_path, ":h")
					-- 切换回主窗口并打开 Oil
					vim.cmd("wincmd p")
					require("oil").open(path)
				end, opts("Open Oil"))
			end

			require("nvim-tree").setup({
				on_attach = my_on_attach,
				view = {
					width = 30,
				},
				update_focused_file = {
					enable = true,
				},
			})
		end,
	},

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
