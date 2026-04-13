return {
	-- 括号自动补全 (Autopairs)
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},

	-- 环绕字符编辑支持 (Surround)
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
	},
}
