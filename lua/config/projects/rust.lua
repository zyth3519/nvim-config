return {
	name = "rust",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/Cargo.toml") ~= nil
	end,
	keymaps = function(ctx)
		return {
			{
				lhs = "<leader>r1",
				desc = "Cargo Run",
				rhs = function()
					ctx.run("cargo run")
				end,
			},
			{
				lhs = "<leader>r2",
				desc = "Cargo Build",
				rhs = function()
					ctx.run("cargo build")
				end,
			},
			{
				lhs = "<leader>r3",
				desc = "Cargo Test",
				rhs = function()
					ctx.run("cargo test")
				end,
			},
		}
	end,
}
