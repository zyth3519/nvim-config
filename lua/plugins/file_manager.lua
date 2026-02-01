-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
    local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
    local dir = require("oil").get_current_dir(bufnr)
    if dir then
        return vim.fn.fnamemodify(dir, ":~")
    else
        -- If there is no current directory (e.g. over ssh), just show the buffer name
        return vim.api.nvim_buf_get_name(0)
    end
end

return {
    {
        'stevearc/oil.nvim',
        ---@module 'oil'
        opts = {
            default_file_explorer = true,
            columns = {
                "icon",
                "permissions",
                "size",
                "mtime",
            },
            win_options = {
                winbar = "%!v:lua.get_oil_winbar()",
            },
        },
        dependencies = { { "nvim-mini/mini.icons", opts = {} } },
        lazy = false,
    },

    {
        "mikavilpas/yazi.nvim",
        version = "*", -- use the latest stable version
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            -- 👇 in this section, choose your own keymappings!
            {
                "<leader>-",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
            {
                -- Open in the current working directory
                "<leader>_",
                "<cmd>Yazi cwd<cr>",
                desc = "Open the file manager in nvim's working directory",
            },
            {
                "<c-up>",
                "<cmd>Yazi toggle<cr>",
                desc = "Resume the last yazi session",
            },
        },
        opts = {
            -- if you want to open yazi instead of netrw, see below for more info
            open_for_directories = false,
            keymaps = {
                show_help = "<f1>",
            },
        },
        -- 👇 if you use `open_for_directories=true`, this is recommended
        init = function()
            -- mark netrw as loaded so it's not loaded at all.
            --
            -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
            vim.g.loaded_netrwPlugin = 1
        end,
    }
}
