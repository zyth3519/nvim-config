return {
	name = "node",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/package.json") ~= nil
	end,
	keymaps = function(ctx)
		return {
			{
				lhs = "<leader>r1",
				desc = "NPM Dev",
				rhs = function()
					ctx.run("npm run dev")
				end,
			},
			{
				lhs = "<leader>r2",
				desc = "NPM Build",
				rhs = function()
					ctx.run("npm run build")
				end,
			},
			{
				lhs = "<leader>r3",
				desc = "NPM Test",
				rhs = function()
					ctx.run("npm test")
				end,
			},
		}
	end,
}
