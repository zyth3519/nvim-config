return {
	name = "zig",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/build.zig") ~= nil
	end,
	keymaps = function()
		return {
			{
				lhs = "<leader>r1",
				desc = "Zig Build",
				cmd = "zig build",
			},
			{
				lhs = "<leader>r2",
				desc = "Zig Test",
				cmd = "zig build test",
			},
			{
				lhs = "<leader>r3",
				desc = "Zig Fmt",
				cmd = "zig fmt .",
			},
		}
	end,
}
