local function lua_ls_config()
    vim.lsp.config('lua_ls', {
        on_init = function(client)
            if client.workspace_folders then
                local path = client.workspace_folders[1].name
                if
                    path ~= vim.fn.stdpath('config')
                    and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                then
                    return
                end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                runtime = {
                    version = 'LuaJIT',
                    path = {
                        'lua/?.lua',
                        'lua/?/init.lua',
                    },
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME
                    }
                }
            })
        end,
        settings = {
            Lua = {}
        }
    })
end


return {
    -- 1. 核心 LSP 配置
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "j-hui/fidget.nvim"
        },
        config = function()
            vim.lsp.enable('lua_ls')
            vim.lsp.enable('rust_analyzer')
            lua_ls_config()
            -- 全局 LSP 诊断配置：支持所有缓冲区诊断
            vim.diagnostic.config({
                virtual_text = {
                    enable = true,
                    severity = { min = vim.diagnostic.severity.HINT }, -- 显示所有级别诊断（Error/Warn/Info/Hint）
                },
                severity_sort = true
            })
        end,
    },
    -- mason
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = { "lua_ls", "rust_analyzer" },
            automatic_installation = true
        },
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "neovim/nvim-lspconfig",
        },
    },
    -- mason
    {
        "williamboman/mason.nvim",
        opts = {
            ui = {
                border = "rounded", -- 圆角窗口，可选 "none" | "single" | "double" | "rounded"
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        },
    },
    -- lsp加载进度条
    {
        'j-hui/fidget.nvim',
        tag = 'legacy',
        opts = {
            text = {
                spinner = 'dots', -- 加载动画样式（可选：dots、circle、arc 等）
                done = '✓', -- 加载完成标识
                commenced = '启动中...', -- 开始加载提示
                completed = '加载完成', -- 完成加载提示
            },
            window = {
                relative = 'editor', -- 窗口定位方式
                blend = 0,   -- 窗口透明度（0 为不透明）
                border = 'none', -- 窗口边框（none 为无边框）
            },
            sources = {
                -- 针对特定 LSP 进行配置（* 为匹配所有 LSP）
                ['*'] = { ignore = false }
            },
        },
        event = 'LspAttach', -- 延迟加载：LSP 附加到缓冲区时才启动
    }

}
