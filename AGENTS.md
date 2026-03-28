# Repository Guidelines

## Project Overview

This is a personal Neovim configuration written in Lua. It uses `lazy.nvim` for plugin management and is organized into modular components for maintainability.

## Project Structure & Module Organization

```
.
├── init.lua                    # Configuration entry point
├── lua/
│   ├── config/
│   │   ├── options.lua         # Neovim options/settings
│   │   ├── lazy.lua            # Plugin manager setup
│   │   ├── autocmds/           # Autocommand definitions
│   │   ├── commands/           # Custom commands
│   │   ├── keymaps/            # Keymap definitions
│   │   └── project_rules/      # Project type detection & run rules
│   └── plugins/
│       ├── core/               # Core plugins (session, etc.)
│       ├── editor/             # Editing experience plugins
│       ├── lang/               # Language support plugins
│       ├── tools/              # Development tools (Git, DAP)
│       └── ui/                 # UI/appearance plugins
├── after/ftplugin/             # Filetype-specific overrides
├── local/
│   ├── launchbox.nvim/         # Command runner plugin
│   └── runpad.nvim/            # Project run keybinding generator
└── scripts/luacheck            # Linting script
```

### Key Architectural Patterns

Project-aware run behavior is split intentionally:
- `local/launchbox.nvim/lua/launchbox/init.lua`: Command entry, runner window, and command history
- `lua/config/project_rules/*.lua`: Project detectors and ordered run entries
- `local/runpad.nvim/lua/runpad/init.lua`: Setup and `:RunpadRedetect`
- `local/runpad.nvim/lua/runpad/rules.lua`: Rule loading and project resolution
- `local/runpad.nvim/lua/runpad/bindings.lua`: `<leader>rN` / `<leader>rrN` generation

Keep new logic inside the right layer instead of pushing more responsibility into one file.

## Build, Lint, and Test Commands

### Linting

```bash
# Lint all Lua files in the repository
./scripts/luacheck .

# Lint a specific file
./scripts/luacheck path/to/file.lua

# The luacheck script uses Lua 5.4 and checks:
# - init.lua
# - lua/**/*.lua
# - after/**/*.lua
# - local/**/*.lua
```

### Validation

```bash
# Sync plugins and verify configuration loads correctly
nvim --headless "+Lazy! sync" +qa

# Run health checks
nvim --headless "+checkhealth" +qa

# Combined validation (run all)
nvim --headless "+Lazy! sync" +qa && \
nvim --headless "+checkhealth" +qa && \
./scripts/luacheck .
```

### Note on Testing

This is a Neovim configuration repository. There is no traditional test suite. Validation is done through:
1. Linting with luacheck
2. Loading Neovim headlessly to verify configuration syntax
3. Manual testing of functionality in a running Neovim instance

## Code Style Guidelines

### Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line endings**: Unix-style (LF)
- **Line length**: No strict limit, but keep lines reasonably short
- **Comments**: Use Chinese for explanatory comments, English for technical references

### Naming Conventions

- **Modules**: Use `local M = {}` pattern, return `M` at end of file
- **Functions**: `snake_case` (e.g., `get_current_buf`, `normalize_cwd`)
- **Variables**: `snake_case` (e.g., `job_id`, `history_state`)
- **Constants**: `UPPER_SNAKE_CASE` or `snake_case` with clear intent
- **Private functions**: Prefix with `_` or keep as local functions
- **Plugin specs**: Return a table, use plugin short names

### Module Pattern

```lua
local M = {}

-- Private state (module-level)
local state = {
    win = nil,
    buf = nil,
}

-- Private helper functions
local function is_valid_win(win)
    return win and type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

-- Public API functions
function M.public_function()
    -- implementation
end

-- Setup function (if applicable)
function M.setup(opts)
    config = vim.tbl_extend("force", config, opts or {})
end

return M
```

### Imports and Requires

```lua
-- Group requires at top of file
local api = vim.api
local fn = vim.fn

-- Prefer require at top level when possible
local other_module = require("config.other_module")

-- Dynamic requires are acceptable in callbacks/config functions
config = function()
    local plugin = require("plugin_name")
    plugin.setup({})
end
```

### Keymap Definitions

```lua
-- Use vim.keymap.set with explicit modes
vim.keymap.set("n", "<leader>ff", function() end, { desc = "描述文字" })

-- Multiple modes as table
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作" })

-- Command mappings use <cmd> or function
vim.keymap.set("n", "<S-h>", "<cmd>bp<cr>", { desc = "上一个缓冲区" })
```

### Plugin Specifications (lazy.nvim)

```lua
return {
    -- Simple plugin with defaults
    "author/plugin-name",

    -- Plugin with configuration
    {
        "author/plugin-name",
        dependencies = { "dependency1", "dependency2" },
        event = "VeryLazy",
        config = function()
            require("plugin").setup({
                -- options
            })
        end,
    },

    -- Plugin with opts
    {
        "author/plugin-name",
        opts = {
            key = "value",
        },
    },
}
```

### Error Handling

```lua
-- Use pcall for operations that might fail
local ok, result = pcall(vim.api.nvim_buf_delete, buf, { force = true })
if not ok then
    vim.notify("Failed to delete buffer", vim.log.levels.ERROR)
end

-- Check validity before operations
if not is_valid_win(state.win) then
    state.win = nil
    return
end
```

### Neovim API Preferences

- Use `vim.api.nvim_*` functions for buffer/window operations
- Use `vim.fn.*` for Vimscript function access
- Use `vim.opt` for options (e.g., `vim.opt.number = true`)
- Use `vim.o`/`vim.wo`/`vim.bo` for specific scopes
- Use `vim.notify` for user-facing messages
- Use `vim.schedule` for callbacks from async contexts

### Project Rules Pattern

```lua
return {
    name = "language",
    matches = function(dir)
        return vim.uv.fs_stat(dir .. "/config.file") ~= nil
    end,
    entries = function()
        return {
            {
                desc = "Description",
                cmd = "command to run",
            },
        }
    end,
}
```

## Documentation & Configuration Tips

When behavior changes, update `README.md` and the nearest module README together, especially for:
- `local/runpad.nvim/README.md`
- `local/launchbox.nvim/README.md`

### Avoid

- Machine-specific paths (use `vim.fn.stdpath()`, `vim.fs`, `vim.uv`)
- Secrets or credentials in configuration
- Ad hoc shell assumptions

### Prefer

- Neovim APIs: `vim.fn.stdpath()`, `vim.fs`, `vim.uv`
- Cross-platform compatible code
- Clear, descriptive variable and function names

## Commit & Pull Request Guidelines

Recent history uses short Chinese commit subjects such as `模块化项目运行键位配置` and `优化项目运行文档表述`.

- Keep commits concise and imperative
- Scope each commit to one logical change
- If a commit needs to be undone, prefer `git revert` over manually re-editing files
- Ensure `./scripts/luacheck .` passes before committing

## External Dependencies

Recommended tools:
- ripgrep (for telescope live_grep)
- fd (for file finding)
- lazygit (for Git integration)
- make (for building telescope-fzf-native)
- tree, yazi, git
- Nerd Font (for icons)
- lua5.4 (for luacheck script)
- luacheck (via luarocks)
