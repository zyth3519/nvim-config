return {
	name = "c3",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/project.json") ~= nil
	end,
	entries = function()
		return {
			{
				desc = "C3 Run",
				cmd = "c3c run",
			},
			{
				desc = "C3 Build",
				cmd = "c3c build",
			},
		}
	end,
}
