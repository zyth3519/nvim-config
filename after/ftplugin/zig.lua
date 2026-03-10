-- Zig 文件 LSP 和 DAP 配置

-- LSP 配置
vim.lsp.config("zls", {
	cmd = { "zls" },
})

vim.lsp.enable("zls")

-- DAP 配置
local dap = require("dap")

-- 通用构建函数
local function make_builder(cmd, label)
	return function()
		vim.cmd("silent wa")
		print(string.format("[Auto Build] 执行命令: %s", cmd))
		local output = vim.fn.system(cmd)
		if vim.v.shell_error ~= 0 then
			vim.notify("❌ " .. label .. " 构建失败:\n" .. output, vim.log.levels.ERROR)
			error("构建失败，终止调试")
		else
			vim.notify("✅ " .. label .. " 构建成功!", vim.log.levels.INFO)
		end
	end
end

dap.configurations.zig = {
	{
		name = "Launch file (Auto Build)",
		type = "codelldb",
		request = "launch",
		program = function()
			local cwd = vim.fn.getcwd()
			local project_name = vim.fn.fnamemodify(cwd, ":t")
			local default_path = cwd .. "/zig-out/bin/" .. project_name
			return vim.fn.input("Path to executable: ", default_path, "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
		console = "integratedTerminal",
		preLaunchTask = make_builder("zig build", "Zig"),
	},
}
