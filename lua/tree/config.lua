-- lua/tree/config.lua
-- 全局配置常量，统一管理所有魔法数字和可调参数

local M = {}

M.defaults = {
    -- 浮窗尺寸比例
    win_width_ratio      = 0.8,
    win_height_ratio     = 0.8,
    -- 主/预览窗口宽度比例
    main_width_ratio     = 0.4,
    -- fd 排除规则
    fd_exclude           = { ".git" },
    -- 预览最大行数
    preview_max_lines    = 200,
    -- 预览滚动步进比例
    preview_scroll_ratio = 0.8,
}

return M
