# nvim-config

一套以 Lua 编写的 Neovim 配置，面向日常开发场景，重点放在这几件事上：启动结构清晰、插件按功能拆分、LSP/格式化开箱可用、搜索与 Git 操作顺手、终端任务和会话管理实用。

## 特性

- 使用 `lazy.nvim` 管理插件，启动入口简单，配置拆分明确
- 使用 `mason.nvim` 管理 LSP、格式化器和调试工具
- 内置 `conform.nvim`，保存时自动格式化，支持手动格式化
- 使用 `telescope.nvim` 负责文件、全文、符号、诊断搜索
- 使用 `oil.nvim` 作为文件管理器，适合快速浏览和改名移动
- 内置 `:Run` 命令，并支持按项目类型动态注入运行键位
- 使用 `resession.nvim` 自动保存当前目录会话
- 集成 Git、DAP、状态栏、缓冲区栏、消息增强与窗口布局管理

## 目录结构

```text
.
├── init.lua
├── lua
│   ├── config
│   │   ├── options.lua
│   │   ├── lazy.lua
│   │   ├── autocmds/
│   │   ├── projects/
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
- `lua/config/project_rules`：项目运行规则目录，用来放不同项目的识别方式和常用命令
- `local/launchbox.nvim/`：本地执行器插件，负责命令入口和底部分屏终端
- `local/runpad.nvim/`：本地项目运行插件，负责读取项目规则并生成运行键位
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

前者用于同步插件，后者用于查看和管理 LSP、格式化器和调试工具。

## 当前已配置的核心能力

### LSP 与格式化

当前仓库已经配置：

- LSP：`lua_ls`、`ts_ls`、`zls`
- 自动安装工具：`stylua`、`prettier`、`codelldb`、`js-debug-adapter`
- 保存时格式化：Lua、Rust、Zig、JavaScript、TypeScript、JSON、HTML、CSS、Markdown、TOML 等

手动格式化当前缓冲区：

```text
<leader>cf
```

## 完整键位清单

Leader 键为 `<Space>`。

### 核心与窗口

- `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>`：跳转到左 / 下 / 上 / 右窗口
- `<C-\>`：跳转到上一个窗口
- `<A-h>` / `<A-j>` / `<A-k>` / `<A-l>`：调整窗口大小
- `<leader><leader>h` / `j` / `k` / `l`：与相邻窗口交换缓冲区
- `<leader>wh`：水平分割当前窗口
- `<leader>wv`：垂直分割当前窗口
- `<leader>wx`：窗口互换
- `<leader>wq`：关闭当前窗口
- `<leader>wo`：关闭其他所有窗口

### 缓冲区

- `<S-h>` / `<S-l>`：切换上一个 / 下一个缓冲区
- `<leader>q`：关闭当前缓冲区
- `<leader>bo`：只保留当前缓冲区
- `<leader>bl` / `<leader>br`：关闭左侧 / 右侧所有缓冲区
- `<leader>b<` / `<leader>b>`：向左 / 向右移动缓冲区
- `<leader>bf` / `<leader>bF`：跳到第一个 / 最后一个缓冲区
- `<leader>1` 到 `<leader>9`：跳转到对应编号缓冲区

### 文件与搜索

- `<leader>e`：智能打开 Oil
- `<leader>fe`：以浮窗打开 Oil
- `<leader>fr`：以浮窗打开项目根目录
- `<leader>ff`：搜索当前项目文件
- `<leader>ss`：打开 Telescope 总入口
- `<leader>sf`：查找文件
- `<leader>sF`：按 frecency 排序查找文件
- `<leader>sg`：全文搜索
- `<leader>sb`：搜索缓冲区
- `<leader>sh`：搜索帮助文档
- `<leader>sy` / `<leader>sY`：搜索当前文档 / 工作区符号
- `<leader>sd`：搜索诊断信息

### 代码与 LSP

- `<leader>ca`：代码操作
- `<leader>cr`：重命名符号
- `<leader>cd`：显示悬浮诊断
- `<leader>cf`：格式化当前缓冲区
- `gd`：跳转到定义
- `gD`：跳转到声明
- `gri`：跳转到实现
- `grr`：查看引用
- `grt`：查看类型定义
- `gO`：查看文档符号
- `gra`：代码操作
- `grn`：重命名
- `K`：悬浮文档

### Git

- `<leader>gg`：打开 Neogit
- `<leader>gc`：提交
- `<leader>gp` / `<leader>gP`：拉取 / 推送
- `<leader>gd` / `<leader>gD`：打开 / 关闭 Diffview
- `<leader>gb` / `<leader>gB`：单行 blame / 切换当前行 blame
- `<leader>gr` / `<leader>gR`：回滚 hunk / 回滚整个缓冲区
- `<leader>gh`：预览 hunk

### 调试

- `<F5>` / `<leader>dc`：启动或继续调试
- `<F6>` / `<leader>ds`：断开调试
- `<F9>` / `<leader>dp`：切换断点
- `<F10>` / `<leader>dv`：逐过程
- `<F11>` / `<leader>di`：单步进入
- `<F12>` / `<leader>do`：单步跳出
- `<leader>dt`：显示或隐藏调试 UI

### 多光标

- `<A-Up>` / `<A-Down>`：在上方 / 下方添加光标
- `<A-S-Up>` / `<A-S-Down>`：跳过上方 / 下方行
- `<A-n>` / `<A-N>`：向下 / 向上添加匹配光标
- `<A-s>` / `<A-S>`：向下 / 向上跳过匹配
- `<C-LeftMouse>`：鼠标添加光标
- `<C-LeftDrag>`：鼠标拖动
- `<C-LeftRelease>`：鼠标释放

### Treesitter 文本对象

- `]f` / `[f`：跳到下一个 / 上一个函数开始
- `]F` / `[F`：跳到下一个 / 上一个函数结束
- `]c` / `[c`：跳到下一个 / 上一个类开始
- `]C` / `[C`：跳到下一个 / 上一个类结束
- `]]` / `[[`：跳到下一个 / 上一个作用域开始
- `][` / `[]`：跳到下一个 / 上一个作用域结束
- `]z` / `[z`：跳到下一个 / 上一个折叠开始
- `]Z` / `[Z`：跳到下一个 / 上一个折叠结束
- `af` / `if`：选择函数外层 / 内层
- `ac` / `ic`：选择类外层 / 内层
- `as`：选择当前作用域

### Flash

- `s`：快速跳转
- `S`：基于 Treesitter 快速跳转
- `<C-s>`：切换命令行搜索 Flash

### 命令与终端

- `<M-x>`：快速输入 `:Run`
- `<leader>r1` / `<leader>r2` / ...：按当前项目类型直接执行预设命令
- `<leader>rr1` / `<leader>rr2` / ...：把对应项目命令填入命令行
- `:sh`：已重定向到 `:Run`
- 终端模式 `<Esc>` / `jk`：退出终端插入模式
- 终端模式 `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>`：在窗口间跳转
- 终端模式 `<C-w>`：进入窗口命令前缀

### Rust 专属

- `<leader>ca`：在 Rust 文件中调用 `RustLsp codeAction`，覆盖默认 LSP code action

## 自定义命令

### `:Run`

在底部分屏执行系统命令，适合临时运行脚本、构建命令或查看输出。

示例：

```vim
:Run cargo test
:Run npm run dev
```

补充说明：

- `:Run` 会在底部分屏打开一个 `runner` 窗口显示输出
- `:sh` 已重定向到 `:Run`
- 如果需要指定目录，可直接把命令写成 `:Run cwd=路径 实际命令`

### 项目运行键位

启动时会扫描 `lua/config/project_rules/*.lua`。每个规则文件都需要返回一个 table，并提供：

- `matches(dir)`：判断某个目录是否属于该项目类型
- `entries(ctx)`：返回当前项目可用的运行条目

`ctx` 会提供 `root`、`file`、`bufnr`、`run(cmd, opts)` 和 `open(cmd, opts)`。规则文件里通过 `entries(ctx)` 返回一组条目，例如：

```lua
{
  { desc = "Cargo Run", cmd = "cargo run" },
  { desc = "Cargo Build", cmd = "cargo build", opts = { cwd = "/tmp/demo" } },
  {
    desc = "Custom Action",
    cmd = function(opts)
      vim.notify(vim.inspect(opts))
    end,
  },
}
```

这些命令会由 `local/runpad.nvim/` 统一转换成两套键位，实际执行则交给 `local/launchbox.nvim/`：

- `<leader>rN`：直接执行
- `<leader>rrN`：把命令填入命令行但不执行

如果项目根目录和当前工作目录不同，预填命令会自动带上 `cwd=...`；如果本来就在当前目录下，就不会额外添加。

目前已经内置：

- Rust 项目：检测 `Cargo.toml`
- Node 项目：检测 `package.json`
- VS Code 任务项目：检测 `.vscode/tasks.json`
- Zig 项目：检测 `build.zig`

当前实现只会在 Neovim 启动时识别一次项目类型。后续不会自动重跑；如果你修改了配置，或者希望重新识别当前项目，可以手动执行：

```vim
:RunpadRedetect
```

示例：

- Rust：`<leader>r1` -> `cargo run`，`<leader>rr1` -> 预填 `:Run cargo run`
- Node：`<leader>r1` -> 直接执行首个脚本，`<leader>rr1` -> 预填同一条命令
- Zig：`<leader>r1` -> `zig build`，`<leader>rr2` -> 预填 `:Run zig build test`

详细实现说明见：

- [README.md](/home/zyth/.config/nvim/local/runpad.nvim/README.md)
- [README.md](/home/zyth/.config/nvim/local/launchbox.nvim/README.md)

### `:Session`

用于管理会话：

```vim
:Session save my-work
:Session load my-work
:Session delete my-work
```

此外，仓库已启用基于当前工作目录的自动会话保存与恢复。

## 调试工作流示例

当前调试快捷键统一为：

- 启动 / 继续：`<F5>` 或 `<leader>dc`
- 断开：`<F6>` 或 `<leader>ds`
- 断点：`<F9>` 或 `<leader>dp`
- 单步：`<F10>` / `<F11>` / `<F12>`
- 调试 UI：`<leader>dt`

按语言示例：

### Zig

Zig 已配置 `codelldb` 调试，进入 `.zig` 文件后可直接使用：

1. 在目标位置按 `<F9>` 下断点
2. 按 `<F5>` 启动调试
3. 首次启动会先执行 `zig build`
4. 默认可执行文件路径为 `zig-out/bin/<当前目录名>`

如果你的产物路径不同，启动时按提示修改即可。

### Rust

当前仓库已配置 Rust 开发环境与 `RustLsp codeAction` 快捷键，但没有在仓库内定义独立的 Rust DAP 启动项。更稳妥的工作流是：

1. 优先使用 `<leader>r1`、`<leader>r2`、`<leader>r3` 执行 `cargo run`、`cargo build`、`cargo test`
2. 用 `<leader>ca` 调用 `RustLsp codeAction`
3. 如需 Rust 专属 DAP 启动配置，再补充到 `after/ftplugin/rust.lua`

### Lua

当前为 Lua 配置了 `lua_ls`，但没有单独提供 Lua DAP 启动项。推荐工作流：

1. 先通过 `K`、`gd`、`grr` 等 LSP 能力完成定位
2. 用 `:Run lua %` 或 `:Run luacheck .` 做快速验证

### TypeScript / JavaScript

当前为前端文件配置了 `ts_ls`、格式化以及基于 `js-debug-adapter` 的 Node 调试。推荐工作流：

1. 在 Node 项目内优先使用 `<leader>r1`、`<leader>r2`、`<leader>r3`
2. 也可以直接用 `:Run npm run dev`、`:Run npm test` 或 `:Run pnpm dev`
3. 用 `gd`、`gri`、`grr`、`<leader>ca` 配合 LSP 进行排查
4. 在 `.ts`、`.tsx`、`.js`、`.jsx` 文件中按 `<F5>` 启动 `Launch current file`
5. 如果需要附加到现有 Node 进程，可选择 `Attach to process`

当前内置的 JS / TS DAP 启动项：

- `Launch current file`
- `Attach to process`

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
