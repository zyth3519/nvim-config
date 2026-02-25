local function get_lua_ls_settings()
    return {
        runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME }
        }
    }
end

return {
    -- 1. 核心 LSP 配置
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            -- 全局 LSP 诊断配置
            vim.diagnostic.config({
                virtual_text = {
                    enable = true,
                    severity = { min = vim.diagnostic.severity.HINT },
                },
                severity_sort = true
            })

            -- 注入 Ufo 折叠能力
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true
            }

            -- 依据 Neovim 0.11+ 标准使用 vim.lsp.config 配置并启用
            vim.lsp.config('lua_ls', {
                capabilities = capabilities,
                settings = {
                    Lua = get_lua_ls_settings()
                }
            })
            vim.lsp.enable('lua_ls')

            -- 对其他服务器按需配参数并启动
            vim.lsp.config('rust_analyzer', { capabilities = capabilities })
            vim.lsp.enable('rust_analyzer')
            
            vim.lsp.config('ts_ls', { capabilities = capabilities })
            vim.lsp.enable('ts_ls')
        end,
    },

    -- 2. 依赖管理总管 (Mason)
    {
        "williamboman/mason.nvim",
        opts = {
            ui = {
                border = "rounded",
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        },
    },

    -- 3. LSP 服务器自动安装
    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            ensure_installed = { "lua_ls", "rust_analyzer", "ts_ls" },
            automatic_installation = true
        },
    },

    -- 4. 格式化器及其他工具自动安装
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        event = "VeryLazy",
        opts = {
            ensure_installed = {
                -- 代码格式化器
                "stylua",     -- Lua 格式化
                "prettier",   -- 前端 & Markdown 格式化
                -- "rustfmt", -- (注: Rust 社区推荐直接使用 rustup 安装 rustfmt, 故注释掉)
                
                -- DAP 调试适配器
                "codelldb",   -- C/C++/Rust 调试器
            },
            auto_update = false,
            run_on_start = true,
            start_delay = 3000, -- 延迟 3 秒执行，不影响编辑器启动速度
        },
    }
}
