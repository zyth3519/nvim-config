-- lua/tree/init.lua
local ui       = require("tree.ui")
local hl       = require("tree.highlight")
local trie_mod = require("tree.trie")
local renderer = require("tree.renderer") -- ← 替换 parser
local preview  = require("tree.preview")
local keymaps  = require("tree.keymaps")
local fold     = require("tree.fold")
local cfg      = require("tree.config").defaults
local utils    = require('tree.utils')

local function check_deps()
    -- 只需要 fd，不再需要 tree
    if vim.fn.executable("fd") == 0 then
        vim.notify("⚠️ 必须安装 'fd'", vim.log.levels.ERROR)
        return false
    end
    return true
end

local function build_fd_cmd(target)
    local cmd = { "fd", "--type", "f", "--type", "d", "--hidden" }
    for _, ex in ipairs(cfg.fd_exclude) do
        vim.list_extend(cmd, { "--exclude", ex })
    end
    vim.list_extend(cmd, { ".", target })
    return cmd
end

local function run(target_path, abs_root, args)
    local layout = ui.create_layout(target_path)
    local buf, win, pbuf, pwin =
        layout.buf, layout.win, layout.pbuf, layout.pwin

    ui.set_loading(buf, "⏳ 正在扫描 [" .. target_path .. "] ...")
    ui.setup_close_autocmd(layout)
    hl.apply(buf)

    local fd_paths = {}
    local fd_job

    fd_job = vim.fn.jobstart(build_fd_cmd(target_path), {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then return end
            for _, line in ipairs(data) do
                if line ~= "" then table.insert(fd_paths, line) end
            end
        end,
        on_exit = function(_, fd_code)
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end
                if fd_code ~= 0 or #fd_paths == 0 then
                    ui.set_loading(buf, "⚠️ 未找到任何文件。")
                    return
                end

                -- ── 1. 构建 Trie ────────────────────────────────
                local trie = trie_mod.build(fd_paths, target_path, abs_root)

                -- ── 2. 首次渲染 ─────────────────────────────────
                local result = renderer.render(trie, abs_root, {})

                -- ctx 用闭包共享，折叠刷新后更新 file_map/is_dir_map
                local ctx = {
                    buf        = buf,
                    win        = win,
                    pbuf       = pbuf,
                    pwin       = pwin,
                    file_map   = result.file_map,
                    is_dir_map = result.is_dir_map,
                    abs_root   = abs_root,
                }

                -- ── 3. 写入 buffer ──────────────────────────────
                vim.bo[buf].modifiable = true
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, result.lines)
                vim.bo[buf].modifiable = false

                -- ── 4. 初始化折叠模块 ───────────────────────────
                fold.init(buf, win, trie, abs_root, function(new_file_map, new_is_dir_map)
                    -- 折叠刷新后同步 ctx，让 preview / keymaps 拿到最新数据
                    ctx.file_map = new_file_map
                    ctx.is_dir_map = new_is_dir_map
                end)

                -- ── 5. 绑定快捷键 ───────────────────────────────
                keymaps.setup(ctx, preview, fold)

                -- ── 6. 初始预览 ─────────────────────────────────
                vim.schedule(function()
                    preview.update(ctx)
                end)

                -- 设置光标位置
                local row = 1
                local col = 0
                for index, value in ipairs(result.file_map) do
                    if value == args then
                        row = index
                        local name = vim.fn.fnamemodify(value, ":t")
                        col = string.len(result.lines[index]) - string.len(name)
                        break;
                    end
                end

                utils.safe_set_cursor(ctx.win, ctx.buf, row, col)
            end)
        end,
    })

    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer   = buf,
        once     = true,
        callback = function()
            fold.cleanup(buf)
            if fd_job and fd_job > 0 then
                pcall(vim.fn.jobstop, fd_job)
            end
        end,
    })
end

local function is_path_inside_cwd(input_path)
    if input_path == "." then return true end
    local cwd      = vim.fn.getcwd():gsub("/$", "")
    local abs_path = vim.fn.fnamemodify(input_path, ":p"):gsub("/$", "")

    return vim.startswith(abs_path .. "/", cwd .. "/")
end

vim.api.nvim_create_user_command("Tree", function(opts)
    if not check_deps() then return end

    local file_path = vim.fn.expand("%:p")
    if string.len(opts.args) > 0 then
        file_path = vim.fn.fnamemodify(opts.args, ":p")
    end
    file_path = file_path:gsub("^oil://", ""):gsub("/+$", "")

    local abs_root = vim.fn.getcwd()
    if not is_path_inside_cwd(file_path) then
        vim.notify(string.format("路径不能是项目目录的上级或同级: %s", file_path))
        return
    end

    run(abs_root, abs_root, file_path)
end, { nargs = "?", complete = "dir", desc = "浮动目录树" })
