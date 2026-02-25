return {
    -- 1. 主题 (Colorscheme)
    { 
        "catppuccin/nvim", 
        name = "catppuccin", 
        priority = 1000 
    },

    -- 2. 状态栏 (Statusline)
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup()
        end
    },

    -- 3. 顶部标签栏/缓冲区 (Bufferline)
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    numbers = "ordinal",
                    indicator = { style = "underline" },
                    buffer_close_icon = "󰅖",
                    modified_icon = "●",
                    separator_style = "thin",
                    always_show_bufferline = true,
                    -- 解决与自定义文件树以及 Oil 的重叠问题
                    offsets = {
                        {
                            filetype = "mytree",
                            text = "File Explorer",
                            text_align = "left",
                        },
                        {
                            filetype = "oil",
                            text = "Oil File Manager",
                            text_align = "left",
                        }
                    },
                    diagnostics = "nvim_lsp",
                    diagnostics_indicator = function(count, level)
                        local icon = level:match("error") and " " or level:match("warn") and " " or "ℹ "
                        return " " .. icon .. count
                    end,
                },
            })
        end,
    },

    -- 4. 快捷键提示 (Which-key)
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-mini/mini.nvim" },
        opts = {
            preset = "modern",
        },
    },

    -- 5. LSP 加载进度提示 (Fidget)
    {
        'j-hui/fidget.nvim',
        tag = 'legacy',
        opts = {
            text = {
                spinner = 'dots',
                done = '✓',
                commenced = '启动中...',
                completed = '加载完成',
            },
            window = {
                relative = 'editor',
                blend = 0,
                border = 'none',
            },
            sources = {
                ['*'] = { ignore = false }
            },
        },
        event = 'LspAttach',
    }
}
