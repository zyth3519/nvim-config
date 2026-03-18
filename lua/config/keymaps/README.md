# Keymaps Notes

## `project.lua`

`project.lua` 负责把 `lua/config/projects/` 里的项目规则转换成最终可用的运行键位。

### 规则接口

每个项目规则文件都需要返回一个 table，并提供：

- `matches(dir)`：判断目录是否属于该项目类型
- `keymaps(ctx)`：返回按顺序排列的运行条目列表

运行条目不需要返回 `lhs`。常见写法：

```lua
return {
  matches = function(dir)
    return vim.uv.fs_stat(dir .. "/Cargo.toml") ~= nil
  end,
  keymaps = function()
    return {
      { desc = "Cargo Run", cmd = "cargo run" },
      { desc = "Cargo Build", cmd = "cargo build" },
    }
  end,
}
```

### 键位生成

`project.lua` 会根据条目索引自动生成两套键位：

- `<leader>r1`、`<leader>r2` ...：直接执行
- `<leader>rr1`、`<leader>rr2` ...：把同一条命令填入命令行

如果项目根目录和当前工作目录不同，命令行会自动补 `cwd=...`；相同则不会补。

### 生命周期

- 默认只在 Neovim 会话启动时初始化一次
- 不会因切 buffer、切窗口或切目录自动重跑
- 需要时手动执行 `:ProjectRunRedetect`
