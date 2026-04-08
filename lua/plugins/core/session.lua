return {
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
				buf_filter = function(bufnr)
					local name = vim.api.nvim_buf_get_name(bufnr)
					if name == "" then
						return false
					end
					local cwd = vim.fn.getcwd() .. "/"
					if name:sub(1, #cwd) ~= cwd then
						return false
					end
					return not name:find(cwd .. ".vim/", 1, true)
				end,
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
					if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
						pcall(resession.save, vim.fn.getcwd(), { dir = "dirsession", notify = false })
					end
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
}
