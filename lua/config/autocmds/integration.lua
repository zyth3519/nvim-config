vim.api.nvim_create_autocmd("CmdlineLeave", {
	pattern = ":",
	callback = function()
		local cmdline = vim.fn.getcmdline()
		if cmdline:match("^!") or cmdline:match("^%%!") then
			pcall(vim.cmd, "Noice dismiss")
		end
	end,
	desc = "Dismiss Noice messages before executing shell commands",
})
