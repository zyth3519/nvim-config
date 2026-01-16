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
}
