-- 定义自动构建函数
local function auto_build_rust()
    -- 保存所有修改的文件
    vim.cmd("silent wa")

    -- 执行构建
    local build_cmd = "cargo build"
    print(string.format("[Auto Build] 执行命令: %s", build_cmd))

    local build_output = vim.fn.system(build_cmd)
    if vim.v.shell_error ~= 0 then
        -- 构建失败时弹出错误提示
        vim.notify("❌ Cargo 构建失败:\n" .. build_output, vim.log.levels.ERROR)
        error("构建失败，终止调试")
    else
        vim.notify("✅ Cargo 构建成功!", vim.log.levels.INFO)
    end
end

-- 配置 Rust 调试项
local function rust_config()
    local dap = require('dap')
    dap.configurations.rust = {
        {
            name = "Launch file (Auto Build)",
            type = "codelldb",
            request = "launch",
            -- 自动推导可执行文件路径
            program = function()
                local cargo_toml = vim.fn.getcwd() .. "/Cargo.toml"
                local project_name = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/',
                    'file')

                -- 如果用户直接回车，自动推导项目名
                if project_name == vim.fn.getcwd() .. '/target/debug/' then
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
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            args = {},
            console = "integratedTerminal",
            env = {
                RUST_BACKTRACE = "1"
            },
            setupCommands = {
                {
                    text = '-enable-pretty-printing',
                    ignoreFailures = false
                },
            },
            -- 前置钩子：调试启动前执行构建
            preLaunchTask = auto_build_rust,
        }
    }
end


return {
    {
        "mfussenegger/nvim-dap",
        config = function()
            local dap = require('dap')
            -- 配置 codelldb 适配器
            dap.adapters.codelldb = {
                type = 'server',
                port = "${port}",
                executable = {
                    command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
                    args = { "--port", "${port}" },
                }
            }
            
            rust_config()
        end
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio"
        },
        config = function()
            require("dapui").setup()
            local dap, dapui = require("dap"), require("dapui")
            dap.listeners.before.attach.dapui_config = function() dapui.open() end
            dap.listeners.before.launch.dapui_config = function() dapui.open() end
            dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
            dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
        end
    }
}
