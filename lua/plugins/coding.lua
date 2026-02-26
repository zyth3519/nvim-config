return {
    -- 1. 代码补全与提示 (Blink.cmp)
    {
        'saghen/blink.cmp',
        dependencies = { 'rafamadriz/friendly-snippets' },
        event = { "BufReadPost", "BufNewFile" },
        version = '1.*',
        opts = {
            keymap = {
                preset = 'none',
                ['<cr>'] = { 'select_and_accept', 'fallback' },
                ['<Up>'] = { 'select_prev', 'fallback' },
                ['<Down>'] = { 'select_next', 'fallback' },
                ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
                ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
                ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
                ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
            },
            appearance = { nerd_font_variant = 'mono' },
            completion = { documentation = { auto_show = true } },
            sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
            signature = { enabled = true },
        },
        opts_extend = { "sources.default" }
    },

    -- 2. 括号自动补全 (Autopairs)
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
    },

    -- 3. 环绕字符编辑支持 (Surround)
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
    },

    -- 4. 代码格式化引擎 (Conform)
    -- (注：格式化快捷键已被统一管理至 lua/config/keymaps.lua 中)
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                rust = { "rustfmt" },
                zig = { "zigfmt" }, -- 添加 Zig 格式化
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                json = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },
                markdown = { "prettier" },
            },
            -- 将 format_on_save 改为一个动态函数来避免在退出时触发格式化进而导致 auto-session 报错
            format_on_save = function(bufnr)
                -- 忽略在退出等特殊过程中的触发
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                
                -- 当使用 :wq 或 :x 退出时，往往会触发 session 保存，此时异步格式化会导致错乱
                -- 通过判断这几种边缘情况，直接返回跳过格式化
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                if bufname:match("Session.vim") or vim.bo[bufnr].filetype == "mytree" then
                    return
                end
                
                return { timeout_ms = 500, lsp_fallback = true }
            end,
        },
    }
}
