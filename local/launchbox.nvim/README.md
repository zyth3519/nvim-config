# launchbox.nvim

用于当前配置的本地执行器插件，负责提供命令入口、底部分屏终端和命令历史搜索。

## 功能

- 提供可自定义命令名的执行入口
- 在底部分屏打开终端并执行命令
- 支持 `cwd` / `env`
- 支持函数型执行入口
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

## `run(cmd, opts)`

`cmd` 支持两种形式：

- 字符串：在底部分屏终端中执行
- 函数：直接调用函数，并把最终生效的 `opts` 传进去

```lua
require("launchbox").run("cargo test", {
  cwd = vim.fn.getcwd(),
})

require("launchbox").run(function(opts)
  vim.notify(vim.inspect(opts))
end, {
  cwd = vim.fn.getcwd(),
})
```
