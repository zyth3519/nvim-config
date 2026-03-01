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
	-- 1. 文件搜索 (Telescope)
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

	-- 2. 强大的文件管理器 (Oil)
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
				local del_keys = { "a", "d", "D", "r", "e", "c", "x", "p", "y", "Y" }
				for _, key in ipairs(del_keys) do
					pcall(vim.keymap.del, "n", key, { buffer = bufnr })
				end

				-- 绑定 o 打开 Oil
				vim.keymap.set("n", "o", function()
					local node = api.tree.get_node_under_cursor()
					local path = node.type == "directory" and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
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
			})
		end,
	},

	{
		"stevearc/oil.nvim",
		opts = {
			default_file_explorer = true,
			columns = { "icon", "permissions", "size", "mtime" },
			win_options = { winbar = "%!v:lua.get_oil_winbar()" },
		},
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		lazy = false,
	},

	-- 3. 会话管理 (Auto-Session)
	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			log_level = "error",
			bypass_save_filetypes = {
				"terminal",
				"oil",
				"MyTree",
				"qf",
				"help",
				"checkhealth",
				"lazy",
				"mason",
				"TelescopePrompt",
				"OverseerList",
			},
			pre_save_cmds = {
				function()
					-- 在保存会话前，强制关闭所有终端窗口和其他不需要的界面
					local bufs = vim.api.nvim_list_bufs()
					for _, bufnr in ipairs(bufs) do
						if vim.api.nvim_buf_is_valid(bufnr) then
							local bt = vim.bo[bufnr].buftype
							local ft = vim.bo[bufnr].filetype
							if bt == "terminal" or bt == "nofile" or bt == "prompt" or ft == "qf" then
								-- 关闭所有包含这些 buffer 的窗口
								for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
									vim.api.nvim_win_close(winid, true)
								end
								-- 删除 buffer
								vim.api.nvim_buf_delete(bufnr, { force = true })
							end
						end
					end
				end,
			},
			post_restore_cmds = {
				function()
					vim.defer_fn(function()
						vim.cmd("bufdo filetype detect")
						vim.cmd("bufdo do FileType")
					end, 300)
				end,
			},
		},
	},

	-- 4. Git 集成客户端 (Lazygit)
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			vim.g.lazygit_use_neovim_remote = 0
		end,
	},

	-- 5. Git 状态栏提示 (Gitsigns)
	{
		"lewis6991/gitsigns.nvim",
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

	-- 6. 优秀的折叠插件 (Ufo)
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			require("ufo").setup({ fold_virt_text_handler = ufo_handler })
		end,
	},

	-- 7. 多光标支持 (Vim-Visual-Multi)
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

	-- 8. 任务运行器 (Overseer)
	{
		"stevearc/overseer.nvim",
		cmd = { "OverseerRun", "OverseerToggle", "OverseerTaskAction", "OverseerOpen" },
		config = function()
			local overseer = require("overseer")

			overseer.setup({
				task_list = {
					direction = "bottom",
					min_height = 15,
					max_height = 15,
					default_detail = 1,
					bindings = {
						["q"] = "<Cmd>OverseerClose<CR>",
					},
				},
				component_aliases = {
					default = {
						"on_exit_set_status",
						"on_complete_notify",
						"open_on_finish",
					},
				},
			})

			-- 为 OverseerList 提供窗口跳转快捷键
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "OverseerList",
				callback = function()
					local opts = { buffer = 0, noremap = true, silent = true }
					vim.keymap.set("n", "<C-h>", "<Cmd>wincmd h<CR>", opts)
					vim.keymap.set("n", "<C-j>", "<Cmd>wincmd j<CR>", opts)
					vim.keymap.set("n", "<C-k>", "<Cmd>wincmd k<CR>", opts)
					vim.keymap.set("n", "<C-l>", "<Cmd>wincmd l<CR>", opts)
				end,
			})
		end,
	},
}
