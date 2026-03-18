# Repository Guidelines

## Project Structure & Module Organization
This repository is a personal Neovim configuration written in Lua. `init.lua` is the entry point and loads modules from `lua/config`. Put editor behavior in `lua/config/{options,autocmds,keymaps,commands}`. Define plugin specs in `lua/plugins/*.lua`, grouped by concern such as `lsp.lua`, `editor.lua`, and `ui.lua`. Filetype-specific overrides live in `after/ftplugin/*.lua`. Keep new modules small and focused.

## Build, Test, and Development Commands
Use Neovim headless commands to validate changes:

```sh
nvim --headless "+Lazy! sync" +qa
nvim --headless "+checkhealth" +qa
luacheck .
```

`Lazy! sync` installs or updates plugins from `lazy.nvim`. `checkhealth` catches missing external tools such as `rg`, `fd`, `lazygit`, `tree`, `yazi`, and Nerd Font support. `luacheck .` validates Lua code against `.luacheckrc`.

## Coding Style & Naming Conventions
Follow the existing Lua style: tabs for indentation, trailing commas in multiline tables, and short local helpers instead of deep nesting. Module names are lowercase by domain (`lua/plugins/telescope.lua`), while user command modules may use PascalCase (`lua/config/commands/Run.lua`). Prefer descriptive key names and keep plugin declarations self-contained. Format Lua with `stylua` through the configured `conform.nvim` integration.

## Testing Guidelines
There is no dedicated automated test suite in this repo. Treat headless startup and linting as the minimum validation for every change. After editing plugin or command logic, open Neovim and verify the affected workflow manually, especially custom commands like `:Run` and `:Session`. If you add logic with failure modes, include a reproducible manual test note in the PR.

## Commit & Pull Request Guidelines
Recent commits use short, imperative Chinese summaries such as `添加Run命令` and `修改Alt+x按键`. Keep commit subjects concise, action-first, and scoped to one change. Pull requests should include: what changed, why it changed, any new external dependency, and screenshots or short recordings for UI-visible behavior such as windows, keymaps, or floating panels.

## Configuration Tips
Do not hardcode machine-specific paths or secrets. Prefer standard Neovim APIs like `vim.fn.stdpath()` and keep external tool assumptions documented in `README.md` when adding new dependencies.
