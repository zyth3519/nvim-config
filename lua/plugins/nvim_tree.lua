return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- 可选，提供文件图标支持（更美观）
    },
    config = function()
        require("nvim-tree").setup({
            view = {
                width = 30,    -- 侧边栏宽度
                relativenumber = true, -- 启用相对行号
            },
            renderer = {
                indent_markers = {
                    enable = true, -- 启用缩进线标记
                },
                icons = {
                    show = {
                        file = true,
                        folder = true,
                        folder_arrow = true,
                        git = true,
                    },
                },
            },
            actions = {
                open_file = {
                    window_picker = {
                        enable = false, -- 关闭文件窗口选择器，直接在当前分屏打开
                    },
                },
            },
            filters = {
                dotfiles = false,            -- 显示隐藏文件（.git、.env 等）
                custom = { "node_modules", ".git" }, -- 过滤隐藏指定目录/文件
            },

        })
    end,
}
