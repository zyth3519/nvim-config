return {
	name = "rust",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/Cargo.toml") ~= nil
	end,
	keymaps = function()
		return {
			{
				lhs = "<leader>r1",
				desc = "Cargo Run",
				cmd = "cargo run",
			},
			{
				lhs = "<leader>r2",
				desc = "Cargo Build",
				cmd = "cargo build",
			},
			{
				lhs = "<leader>r3",
				desc = "Cargo Test",
				cmd = "cargo test",
			},
		}
	end,
}
