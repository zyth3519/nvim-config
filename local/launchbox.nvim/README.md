# launchbox.nvim

用于当前配置的本地执行器插件，负责提供命令入口、底部分屏终端和命令历史搜索。

## 功能

- 提供可自定义命令名的执行入口
- 在底部分屏打开终端并执行命令
- 支持 `cwd` / `env`
- 提供命令行历史搜索

## 配置示例

```lua
require("launchbox").setup({
  height = 12,
  ft = "runner",
  command_name = "Run",
})

vim.cmd([[cnoreabbrev <expr> sh ((getcmdtype() == ':' && getcmdline() == 'sh') ? 'Run' : 'sh')]])
```
