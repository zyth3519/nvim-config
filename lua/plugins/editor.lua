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
			resession.setup({
				-- 自动在退出时保存会话
				autosave = {
					enabled = true,
					interval = 60,
					notify = false,
				},
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
}
