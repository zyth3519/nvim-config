# project-run.nvim

用于当前配置的本地插件，负责提供 `:Run` 命令和按项目生成的运行键位。

## 功能

- 提供 `:Run`
- 提供 `Run` 命令历史搜索
- 从可配置的 glob 加载项目规则
- 自动生成 `<leader>rN` 和 `<leader>rrN`
- 提供 `:ProjectRunRedetect`

## 配置示例

```lua
require("project_run").setup({
  runner = {
    height = 12,
    ft = "runner",
  },
  project_glob = "lua/config/projects/*.lua",
})
```
