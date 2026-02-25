globals = {
    "vim",
}

-- 屏蔽所有对 vim 的未定义或只读修改的警告
read_globals = { "vim" }

-- 关闭因为设置 vim.bo 等只读字段导致的误报
ignore = {
    "111", -- setting non-standard global variable
    "122", -- setting read-only global variable
}

include_files = {
    "lua/**/*.lua",
}
