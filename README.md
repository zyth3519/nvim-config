# nvim-config

一套以 Lua 编写的 Neovim 配置，面向日常开发场景，重点放在这几件事上：启动结构清晰、插件按功能拆分、LSP/格式化开箱可用、搜索与 Git 操作顺手、终端任务和会话管理实用。

## 特性

- 使用 `lazy.nvim` 管理插件，启动入口简单，配置拆分明确
- 使用 `mason.nvim` 管理 LSP、格式化器和调试工具
- 内置 `conform.nvim`，保存时自动格式化，支持手动格式化
- 使用 `telescope.nvim` 负责文件、全文、符号、诊断搜索
- 使用 `oil.nvim` 作为文件管理器，适合快速浏览和改名移动
- 内置 `:Run` 命令，在底部分屏执行系统命令
- 使用 `resession.nvim` 自动保存当前目录会话
- 集成 Git、DAP、状态栏、缓冲区栏、消息增强与窗口布局管理

## 目录结构

```text
.
├── init.lua
├── lua
│   ├── config
│   │   ├── options.lua
│   │   ├── autocmds.lua
│   │   ├── keymaps/
│   │   └── commands/
│   └── plugins
│       ├── core/
│       ├── editor/
│       ├── lang/
│       ├── tools/
│       └── ui/
├── after/ftplugin/
├── lazy-lock.json
└── .luacheckrc
```

- `init.lua`：配置入口
- `lua/config`：核心配置，包括选项、快捷键、自动命令和自定义命令
- `lua/plugins`：插件定义，按职责分组
- `lua/plugins/core`：核心运行能力，例如会话管理
- `lua/plugins/editor`：编辑体验相关，例如补全、搜索、Treesitter、文件管理、窗口导航
- `lua/plugins/lang`：语言支持相关，例如 LSP、语言插件、Markdown
- `lua/plugins/tools`：开发工具相关，例如 Git、DAP
- `lua/plugins/ui`：界面与交互层，例如主题、状态栏、消息系统、布局管理
- `after/ftplugin`：文件类型专属配置
- `lazy-lock.json`：插件版本锁定

## 环境依赖

建议先安装以下外部工具：

- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [lazygit](https://github.com/jesseduffield/lazygit)
- `tree`
- `yazi`
- `git`
- `make`
- `Nerd Font`

其中部分插件会依赖外部命令，例如：

- `telescope-fzf-native.nvim` 需要 `make`
- `live_grep` 依赖 `ripgrep`
- 文件搜索体验依赖 `fd`
- 图标显示依赖 Nerd Font

## 安装

如果你希望直接把它作为当前 Neovim 配置使用：

```sh
git clone https://github.com/zyth3519/nvim-config.git ~/.config/nvim
nvim
```

首次启动会自动引导安装 `lazy.nvim`。随后可以在 Neovim 内执行：

```vim
:Lazy sync
:Mason
```

前者同步插件，后者查看和管理 LSP / formatter / debugger 工具。

## 当前已配置的核心能力

### LSP 与格式化

当前仓库已经配置：

- LSP：`lua_ls`、`ts_ls`、`zls`
- 自动安装工具：`stylua`、`prettier`、`codelldb`
- 保存时格式化：Lua、Rust、Zig、JavaScript、TypeScript、JSON、HTML、CSS、Markdown、TOML 等

手动格式化当前缓冲区：

```text
<leader>cf
```

## 常用快捷键

Leader 键为 `<Space>`。

### 文件与搜索

- `<leader>e`：智能打开 Oil
- `<leader>ff`：搜索当前项目文件
- `<leader>sg`：全文搜索
- `<leader>sb`：搜索缓冲区
- `<leader>sd`：搜索诊断信息

### 代码操作

- `gd`：跳转到定义
- `grr`：查看引用
- `gri`：查看实现
- `K`：悬浮文档
- `<leader>ca`：代码操作
- `<leader>cr`：重命名符号

### Git

- `<leader>gg`：打开 Neogit
- `<leader>gd`：打开 Diffview
- `<leader>gb`：查看当前行 blame
- `<leader>gh`：预览 hunk

### 调试

- `<F5>`：启动/继续调试
- `<F9>`：切换断点
- `<F10>` / `<F11>` / `<F12>`：单步调试
- `<leader>dt`：切换调试 UI

### 命令与窗口

- `<M-x>`：快速输入 `:Run`
- `:sh`：已重定向到 `:Run`
- `<C-h/j/k/l>`：窗口跳转
- `<A-h/j/k/l>`：窗口尺寸调整
- `<S-h>` / `<S-l>`：切换缓冲区

## 自定义命令

### `:Run`

在底部分屏执行系统命令，适合临时运行脚本、构建命令或查看输出。

示例：

```vim
:Run cargo test
:Run npm run dev
```

### `:Session`

用于管理会话：

```vim
:Session save my-work
:Session load my-work
:Session delete my-work
```

此外，仓库已启用基于当前工作目录的自动会话保存与恢复。

## 验证与维护

修改配置后，至少建议做一次基本检查：

```sh
nvim --headless "+Lazy! sync" +qa
nvim --headless "+checkhealth" +qa
luacheck .
```

- `Lazy! sync`：同步插件并检查插件定义是否正常
- `checkhealth`：检查运行环境和外部依赖
- `luacheck .`：检查 Lua 代码质量

## 适合继续完善的方向

- 为 README 补充完整键位清单
- 为 `:Run` 和调试工作流增加按语言区分的示例
- 增加截图，展示 Oil、Telescope、Git 和 DAP 的实际界面
