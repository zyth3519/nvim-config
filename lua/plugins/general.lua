return {
    -- 主题
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    -- 显示缓存区状态
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" }, -- 可选，提供文件图标（增强美观度）
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers", -- 仅展示缓冲区（默认，不展示 tab 页）
                    numbers = "ordinal", -- 显示缓冲区编号（与 :ls 编号对应，方便切换）
                    indicator = {
                        style = "underline", -- 当前缓冲区的高亮指示器（下划线样式）
                    },
                    buffer_close_icon = "󰅖", -- 关闭缓冲区的图标
                    modified_icon = "●", -- 缓冲区文件修改后的标记（红色圆点）
                    separator_style = "thin", -- 标签栏分隔线样式（可选 "thick"、"slant"）
                    offsets = {
                        {
                            filetype = "NvimTree", -- 与 nvim-tree 兼容，避免标签栏与文件管理器重叠
                            text = "File Explorer",
                            text_align = "left",
                        },
                    },
                    always_show_bufferline = true, -- 始终显示标签栏（即使只有一个缓冲区）
                    diagnostics = "nvim_lsp",
                    -- 自定义诊断指示器（非当前缓冲区也会显示, 诊断信息）
                    diagnostics_indicator = function(count, level)
                        -- count：总诊断数；level：诊断级别（error/warn/info/hint）
                        -- context.buffer_id：当前缓冲区 ID，区分是否为活动缓冲区
                        local icon = level:match("error") and " " or level:match("warn") and " " or "ℹ "
                        -- 返回展示格式，可根据需求调整（如只显示错误数、或所有级别总和）
                        return " " .. icon .. count
                    end,
                },
            })
        end,
    },
    -- 按键提示
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-mini/mini.nvim"
        },
        opts = {
            ---@type false | "classic" | "modern" | "helix"
            -- preset = "helix",
            preset = "modern",
        },
    },
    -- 终端
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        opts = {
            -- 核心配置
            size = 10,                -- 水平分割终端的默认高度（垂直分割时为宽度）
            direction = 'horizontal', -- 终端默认打开方式：horizontal（水平）/ vertical（垂直）/ float（悬浮）
            close_on_exit = true,     -- 终端进程退出后自动关闭终端窗口
            shade_terminals = true,   -- 终端窗口阴影效果（提升美观度）
            float_opts = {
                border = 'rounded',   -- 悬浮终端的圆角边框
                winblend = 10,        -- 悬浮终端透明度
            },
        },
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup()
        end
    }
}
