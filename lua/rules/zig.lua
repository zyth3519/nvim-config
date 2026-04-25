return {
	name = "zig",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/build.zig") ~= nil
	end,
	entries = function()
		return {
			{
				desc = "Zig Run",
				cmd = "zig build run",
			},
			{
				desc = "Zig Build",
				cmd = "zig build",
			},
			{
				desc = "Zig Test",
				cmd = "zig build test",
			},
			{
				desc = "Zig Fmt",
				cmd = "zig fmt .",
			},
		}
	end,
}
