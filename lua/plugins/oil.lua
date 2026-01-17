return {
    {
        'stevearc/oil.nvim',
        ---@module 'oil'
        ---@type oil.SetupOpts
        opts = {
            columns = {
                "icon",
                 "permissions",
                 "size",
                 "mtime",
            },
        },
        dependencies = { { "nvim-mini/mini.icons", opts = {} } },
        lazy = false,
    }
}
