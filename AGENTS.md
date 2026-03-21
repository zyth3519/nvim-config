# Repository Guidelines

## Project Structure & Module Organization
This repository is a personal Neovim config written in Lua. `init.lua` is the entry point. Core editor behavior lives in `lua/config/`: `options.lua`, `lazy.lua`, `autocmds/`, `commands/`, and `keymaps/`. Plugin specs are organized under `lua/plugins/{core,editor,lang,tools,ui}`. Filetype-specific overrides belong in `after/ftplugin/`.

Project-aware run behavior is split intentionally:
- `lua/config/projects/*.lua`: project detectors and ordered run entries
- `local/runpad.nvim/lua/runpad/init.lua`: setup and `:ProjectRunRedetect`
- `local/runpad.nvim/lua/runpad/projects.lua`: rule loading and project resolution
- `local/runpad.nvim/lua/runpad/keymaps.lua`: `<leader>rN` / `<leader>rrN` generation
- `local/runpad.nvim/lua/runpad/launchbox.lua`: `:Run` implementation and command entry

Keep new logic inside the right layer instead of pushing more responsibility into one file.

## Commit & Pull Request Guidelines
Recent history uses short Chinese commit subjects such as `模块化项目运行键位配置` and `优化项目运行文档表述`. Keep commits concise, imperative, and scoped to one change. If a commit needs to be undone, prefer `git revert` over manually re-editing files so history stays clear.

## Documentation & Configuration Tips
When behavior changes, update `README.md` and the nearest module README together, especially for `local/runpad.nvim/README.md`. Avoid machine-specific paths and secrets. Prefer Neovim APIs such as `vim.fn.stdpath()`, `vim.fs`, and `vim.uv` over ad hoc shell assumptions.
