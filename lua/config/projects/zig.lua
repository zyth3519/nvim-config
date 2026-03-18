return {
	name = "zig",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/build.zig") ~= nil
	end,
	keymaps = function(ctx)
		return {
			{
				lhs = "<leader>r1",
				desc = "Zig Build",
				rhs = function()
					ctx.run("zig build")
				end,
			},
			{
				lhs = "<leader>r2",
				desc = "Zig Test",
				rhs = function()
					ctx.run("zig build test")
				end,
			},
			{
				lhs = "<leader>r3",
				desc = "Zig Fmt",
				rhs = function()
					ctx.run("zig fmt .")
				end,
			},
		}
	end,
}
