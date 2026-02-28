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
	},

	-- 2. 强大的文件管理器 (Oil)
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
}
