-- lua/tree/init.lua
-- 入口：注册 :Tree 命令，串联各模块
local ui       = require("tree.ui")
local hl       = require("tree.highlight")
local trie_mod = require("tree.trie")
local parser   = require("tree.parser")
local preview  = require("tree.preview")
local keymaps  = require("tree.keymaps")
local cfg      = require("tree.config").defaults

--- 检查外部依赖
---@return boolean
local function check_deps()
    for _, bin in ipairs({ "fd", "tree" }) do
        if vim.fn.executable(bin) == 0 then
            vim.notify("⚠️ 必须安装 '" .. bin .. "'", vim.log.levels.ERROR)
            return false
        end
    end
    return true
end

--- 构建 fd 命令行
---@param target string
---@return string[]
local function build_fd_cmd(target)
    local cmd = { "fd", "--type", "f", "--type", "d", "--hidden" }
    for _, ex in ipairs(cfg.fd_exclude) do
        vim.list_extend(cmd, { "--exclude", ex })
    end
    vim.list_extend(cmd, { ".", target })
    return cmd
end

--- 主流程
---@param target_path string
---@param abs_root    string
local function run(target_path, abs_root)
    -- ── 1. 创建 UI ──────────────────────────────────────────────
    local layout = ui.create_layout(target_path)
    local buf, win, pbuf, pwin =
        layout.buf, layout.win, layout.pbuf, layout.pwin

    ui.set_loading(buf, "⏳ 正在扫描 [" .. target_path .. "] ...")
    ui.setup_close_autocmd(layout)
    hl.apply(buf)

    -- ── 2. fd 扫描 ──────────────────────────────────────────────
    local fd_paths = {}
    local fd_job

    fd_job = vim.fn.jobstart(build_fd_cmd(target_path), {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then return end
            for _, line in ipairs(data) do
                -- line = line:gsub("\r$", ""):gsub("/$", "")
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

                -- ── 3. 构建 Trie ────────────────────────────────
                local trie = trie_mod.build(fd_paths, target_path, abs_root)

                -- ── 4. tree 渲染 ────────────────────────────────
                local tree_lines = {}
                local tree_job = vim.fn.jobstart(
                    { "tree", "-F", "--fromfile", "--noreport" },
                    {
                        stdout_buffered = true,
                        on_stdout = function(_, data)
                            if not data then return end
                            for _, line in ipairs(data) do
                                if line ~= "" then
                                    table.insert(tree_lines, line)
                                end
                            end
                        end,
                        on_exit = function(_, tree_code)
                            vim.schedule(function()
                                if not vim.api.nvim_buf_is_valid(buf) then return end

                                if tree_code ~= 0 then
                                    ui.set_loading(buf, "❌ tree 命令失败")
                                    return
                                end

                                -- ── 5. 解析映射 ─────────────────
                                local file_map, is_dir_map =
                                    parser.parse(tree_lines, trie, abs_root)

                                -- ── 6. 写入 buffer ──────────────
                                vim.bo[buf].modifiable = true
                                vim.api.nvim_buf_set_lines(buf, 0, -1, false, tree_lines)
                                vim.bo[buf].modifiable = false

                                -- ── 7. 绑定快捷键 & 预览 ────────
                                local ctx = {
                                    buf        = buf,
                                    pbuf       = pbuf,
                                    pwin       = pwin,
                                    file_map   = file_map,
                                    is_dir_map = is_dir_map,
                                    abs_root   = abs_root,
                                }
                                keymaps.setup(ctx, preview)

                                -- 立刻渲染一次预览
                                vim.schedule(function()
                                    preview.update(ctx)
                                end)
                            end)
                        end,
                    }
                )

                -- 通过 stdin 把路径列表传给 tree
                local stdin_data = table.concat(fd_paths, "\n") .. "\n"
                vim.fn.chansend(tree_job, stdin_data)
                vim.fn.chanclose(tree_job, "stdin")
            end)
        end,
    })

    -- buf 被强制关闭时，终止后台 fd 任务
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer   = buf,
        once     = true,
        callback = function()
            if fd_job and fd_job > 0 then
                pcall(vim.fn.jobstop, fd_job)
            end
        end,
    })
end

-- ── 注册命令 ───────────────────────────────────────────────────
vim.api.nvim_create_user_command("Tree", function(opts)
    if not check_deps() then return end

    local path        = opts.args
    local target_path = path == "" and "." or path
    local abs_root    = vim.fn.fnamemodify(target_path, ":p"):gsub("/$", "")

    run(target_path, abs_root)
end, { nargs = "?", complete = "dir", desc = "浮动目录树" })
