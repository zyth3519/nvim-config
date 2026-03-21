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
