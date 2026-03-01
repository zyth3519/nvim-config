return {
	{
		"mfussenegger/nvim-dap",
		cmd = { "DapContinue", "DapToggleBreakpoint" },
		config = function()
			local dap = require("dap")

			-- 配置 codelldb 适配器
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- 应用所有已注册的调试配置
			require("config.dap-configs").apply()
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			require("dapui").setup()
			local dap, dapui = require("dap"), require("dapui")

			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end
		end,
	},
}
