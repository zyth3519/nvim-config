-- DAP 调试项与编译项配置 (注册模式)

local M = {}

-- 注册表
local configs = {}

--- 注册一个语言的调试配置
--- @param lang string 语言名称 (对应 dap.configurations 的 key)
--- @param config table { build?: function, configurations: table[] }
function M.register(lang, config)
	configs[lang] = config
end

--- 将所有已注册的配置应用到 DAP
function M.apply()
	local dap = require("dap")
	for lang, config in pairs(configs) do
		dap.configurations[lang] = config.configurations
	end
end

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

------------------------------------------------------------
-- 注册 Rust
------------------------------------------------------------
M.register("rust", {
	configurations = {
		{
			name = "Launch file (Auto Build)",
			type = "codelldb",
			request = "launch",
			program = function()
				local cargo_toml = vim.fn.getcwd() .. "/Cargo.toml"
				local project_name =
					vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")

				-- 如果用户直接回车，自动推导项目名
				if project_name == vim.fn.getcwd() .. "/target/debug/" then
					if vim.fn.filereadable(cargo_toml) == 1 then
						for line in io.lines(cargo_toml) do
							local name = line:match('^name = "([^"]+)"')
							if name then
								project_name = vim.fn.getcwd() .. "/target/debug/" .. name
								break
							end
						end
					end
				end
				return project_name
			end,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = {},
			console = "integratedTerminal",
			env = {
				RUST_BACKTRACE = "1",
			},
			setupCommands = {
				{
					text = "-enable-pretty-printing",
					ignoreFailures = false,
				},
			},
			preLaunchTask = make_builder("cargo build", "Cargo"),
		},
	},
})

------------------------------------------------------------
-- 注册 Zig
------------------------------------------------------------
M.register("zig", {
	configurations = {
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
	},
})

return M
