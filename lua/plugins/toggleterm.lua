return {
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        opts = {
            -- 核心配置
            size = 10,        -- 水平分割终端的默认高度（垂直分割时为宽度）
            direction = 'horizontal', -- 终端默认打开方式：horizontal（水平）/ vertical（垂直）/ float（悬浮）
            close_on_exit = true, -- 终端进程退出后自动关闭终端窗口
            shade_terminals = true, -- 终端窗口阴影效果（提升美观度）
            float_opts = {
                border = 'rounded', -- 悬浮终端的圆角边框
                winblend = 10, -- 悬浮终端透明度
            },
        },
    }

}
