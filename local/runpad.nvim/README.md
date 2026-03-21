# runpad.nvim

当前配置里使用的本地插件，负责根据项目类型生成运行键位，并配合 `:Run` 使用。

## 功能

- 配合 `launchbox.nvim` 使用 `:Run`
- 支持 `Run` 命令历史搜索
- 从可配置的 glob 加载项目规则
- 自动生成 `<leader>rN` 和 `<leader>rrN`
- 提供 `:RunpadRedetect`

命令执行部分由同级插件 `launchbox.nvim` 负责，它主要处理：

- 注册命令
- 打开底部分屏终端
- 维护命令历史搜索
- 执行传入的命令

所以 `runpad.nvim` 只关心“当前是什么项目、要暴露哪些命令”，执行细节交给 `launchbox.nvim`。

## 配置示例

```lua
require("runpad").setup({
  project_glob = "lua/config/projects/*.lua",
})
```

## 项目条目

项目规则返回的条目会按顺序生成键位：

- `<leader>rN`：直接执行
- `<leader>rrN`：把命令填入命令行，只对字符串命令生效

最常见的是字符串命令：

```lua
{
  desc = "Cargo Run",
  cmd = "cargo run",
  opts = {
    cwd = "/tmp/demo",
  },
}
```

如果某个条目需要更灵活的处理，也可以把 `cmd` 写成函数。函数会收到最终生效的 `opts`，并同样参与 `<leader>rN` 的生成：

```lua
{
  desc = "Custom Action",
  cmd = function(opts)
    vim.notify(vim.inspect(opts))
  end,
}
```

如果条目里同时有字符串和函数，`<leader>rrN` 会只对字符串命令连续编号，不会出现跳号。
