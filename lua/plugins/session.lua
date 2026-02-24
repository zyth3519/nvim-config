return {
    "rmagatti/auto-session",
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    opts = {
        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        -- log_level = 'debug',
    },
    config = function()
        require("auto-session").setup({
            log_level = "error",
            auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },

            -- session 保存前/后的钩子
            pre_save_cmds = { "tabdo NvimTreeClose" }, -- 关闭文件树再保存

            post_restore_cmds = {
                function()
                    vim.defer_fn(function()
                        -- 1. 重新检测文件类型
                        vim.cmd("bufdo filetype detect")

                        -- 2. 触发 FileType 事件让 LSP 附加
                        vim.cmd("bufdo do FileType")
                    end, 300)
                end,
            },
        })
    end
}
