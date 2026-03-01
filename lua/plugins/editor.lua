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
			-- 定期保存会话
			resession.setup({
				autosave = {
					enabled = true,
					interval = 60,
					notify = false,
				},
				extensions = {
					dap = {}, -- 保存 dap 断点信息
				},
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					-- Only load the session if nvim was started with no args and without reading from stdin
					if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
						-- Save these to a different directory, so our manual sessions don't get polluted
						resession.load(vim.fn.getcwd(), { dir = "dirsession", silence_errors = true })
					end
				end,
				nested = true,
			})
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function()
					resession.save(vim.fn.getcwd(), { dir = "dirsession", notify = false })
				end,
			})
			vim.api.nvim_create_autocmd("StdinReadPre", {
				callback = function()
					-- Store this for later
					vim.g.using_stdin = true
				end,
			})
		end,
	},
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		opts = {
			left = {
				{
					ft = "NvimTree",
					title = "Nvim Tree",
					size = { width = 30 },
				},
			},
		},
	},
}
