return {

	-- Zig
	{
		"ziglang/zig.vim",
		ft = { "zig" },
		init = function()
			-- 我们使用 conform 来控制格式化，这里关掉 zig.vim 自带的保存时格式化
			vim.g.zig_fmt_autosave = 0
		end,
	},
	-- c3
	{
		"ManuLinares/nvim-c3",
		build = function()
			require("c3").update()
		end, -- (Optional) Auto-update binaries
		config = true,
	},
	-- rust
	{
		"mrcjkb/rustaceanvim",
		version = "^8", -- Recommended
		lazy = false, -- This plugin is already lazy
		init = function()
			vim.g.rustaceanvim = {
				-- LSP 配置
				server = {
					default_settings = {
						-- rust-analyzer 专属设置
						["rust-analyzer"] = {
							checkOnSave = {
								enable = true,
								command = "clippy", -- 将默认的 check 改为 clippy
							},
						},
					},
				},
			}
		end,
	},
}
