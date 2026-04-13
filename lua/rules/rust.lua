return {
	name = "rust",
	matches = function(dir)
		return vim.uv.fs_stat(dir .. "/Cargo.toml") ~= nil
	end,
	entries = function()
		return {
			{
				desc = "Cargo Run",
				cmd = "cargo run",
			},
			{
				desc = "Cargo Build",
				cmd = "cargo build",
			},
			{
				desc = "Cargo Clippy",
				cmd = "cargo clippy",
			},
			{
				desc = "Cargo Check",
				cmd = "cargo check",
			},
			{
				desc = "Cargo Test",
				cmd = "cargo test",
			},
		}
	end,
}
