# runpad.nvim

当前配置里使用的本地插件，负责提供 `:Run` 和按项目生成的运行键位。

## 功能

- 提供 `:Run`
- 提供 `Run` 命令历史搜索
- 从可配置的 glob 加载项目规则
- 自动生成 `<leader>rN` 和 `<leader>rrN`
- 提供 `:ProjectRunRedetect`

其中执行器部分单独抽成了同级插件 `launchbox.nvim`，它负责：

- 注册命令
- 打开底部分屏终端
- 维护命令历史搜索
- 执行传入的命令

`launchbox.nvim` 可以独立复用，不必和项目规则绑定。

## 配置示例

```lua
require("runpad").setup({
  project_glob = "lua/config/projects/*.lua",
})
```

## 项目条目

项目规则返回的条目会按顺序生成键位：

- `<leader>rN`：直接执行条目
- `<leader>rrN`：把命令填入命令行，只给字符串命令生成

常见的字符串条目：

```lua
{
  desc = "Cargo Run",
  cmd = "cargo run",
  opts = {
    cwd = "/tmp/demo",
  },
}
```

也可以把 `cmd` 写成函数。函数会收到合并后的 `opts`，并参与 `<leader>rN` 的生成：

```lua
{
  desc = "Custom Action",
  cmd = function(opts)
    vim.notify(vim.inspect(opts))
  end,
}
```

如果条目里同时存在字符串和函数，`<leader>rrN` 会只对字符串命令单独连续编号，不会出现缺号。
