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

-- UFO (代码折叠) 自定义文本处理逻辑
local ufo_handler = function(virtText, lnum, endLnum, width, truncate)
	local newVirtText = {}
	local suffix = (" 󰁂 %d "):format(endLnum - lnum)
	local sufWidth = vim.fn.strdisplaywidth(suffix)
	local targetWidth = width - sufWidth
	local curWidth = 0
	for _, chunk in ipairs(virtText) do
		local chunkText = chunk[1]
		local chunkWidth = vim.fn.strdisplaywidth(chunkText)
		if targetWidth > curWidth + chunkWidth then
			table.insert(newVirtText, chunk)
		else
			chunkText = truncate(chunkText, targetWidth - curWidth)
			local hlGroup = chunk[2]
			table.insert(newVirtText, { chunkText, hlGroup })
			chunkWidth = vim.fn.strdisplaywidth(chunkText)
			if curWidth + chunkWidth < targetWidth then
				suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
			end
			break
		end
		curWidth = curWidth + chunkWidth
	end
	table.insert(newVirtText, { suffix, "MoreMsg" })
	return newVirtText
end

return {
	-- 文件搜索 (Telescope)
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			-- 使用 Telescope picker 替代 vim.ui.select
			vim.ui.select = function(items, opts, on_choice)
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				local format = (opts and opts.format_item) or tostring

				pickers
					.new({}, {
						prompt_title = (opts and opts.prompt) or "Select",
						finder = finders.new_table({
							results = items,
							entry_maker = function(item)
								local text = format(item)
								return { value = item, display = text, ordinal = text }
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(bufnr)
							actions.select_default:replace(function()
								local selection = action_state.get_selected_entry()
								actions.close(bufnr)
								if selection then
									-- 找到原始 index
									for i, item in ipairs(items) do
										if item == selection.value then
											on_choice(selection.value, i)
											return
										end
									end
								end
								on_choice(nil, nil)
							end)
							return true
						end,
					})
					:find()
			end
		end,
	},

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

	-- Git 状态栏提示 (Gitsigns)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				watch_gitdir = { follow_files = true },
				auto_attach = true,
				sign_priority = 6,
				update_debounce = 100,
			})
		end,
	},

	-- 优秀的折叠插件 (Ufo)
	{
		"kevinhwang91/nvim-ufo",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			require("ufo").setup({ fold_virt_text_handler = ufo_handler })
		end,
	},

	-- 多光标支持 (Vim-Visual-Multi)
	{
		"mg979/vim-visual-multi",
		branch = "master",
		event = { "BufReadPost", "BufNewFile" },
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-n>", -- Ctrl-N 选中当前单词并进入多光标模式
				["Find Subword Under"] = "<C-n>", -- 在选中部分词时也使用 Ctrl-N
			}
			-- 修复多光标模式下的退出问题 (ESC)
			vim.g.VM_quit_after_leaving_insert_mode = 1
		end,
	},

	-- 强大且安全的会话管理 (Resession)
	{
		"stevearc/resession.nvim",
		config = function()
			local resession = require("resession")
			resession.setup({
				-- 自动在退出时保存会话
				autosave = {
					enabled = true,
					interval = 60,
					notify = false,
				},
			})

			-- 在离开 Neovim 时自动保存当前目录的会话
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function()
					resession.save(vim.fn.getcwd(), { dir = "dirsession", notify = false })
				end,
			})

			-- 在进入 Neovim 时自动恢复当前目录的会话（不带参数时）
			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					-- 如果带参数启动（比如 nvim file.txt），不要加载会话
					if vim.fn.argc(-1) == 0 then
						resession.load(vim.fn.getcwd(), { dir = "dirsession", silence_errors = true })
						-- 会话恢复后，重新触发文件类型检测和 BufReadPost 事件
						-- 以激活懒加载的插件（gitsigns、ufo、indent-blankline 等）
						vim.defer_fn(function()
							for _, buf in ipairs(vim.api.nvim_list_bufs()) do
								if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
									vim.api.nvim_buf_call(buf, function()
										vim.cmd("filetype detect")
									end)
								end
							end
							vim.api.nvim_exec_autocmds("BufReadPost", { modeline = false })
						end, 50)
					end
				end,
			})
		end,
	},

	-- 强大的纯文本 Git 客户端 (Magit for Neovim)
	{
		"NeogitOrg/neogit",
		cmd = { "Neogit" },
		dependencies = {
			"nvim-lua/plenary.nvim", -- 必须
			"nvim-telescope/telescope.nvim", -- 推荐
		},
		config = true,
	},

	-- Git 差异视图 (Diffview)
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	},
}
