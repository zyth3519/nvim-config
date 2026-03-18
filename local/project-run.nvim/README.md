# project-run.nvim

Local plugin for this config's `:Run` command and project-aware run keymaps.

## Features

- Provides `:Run`
- Redirects `:sh` to `:Run`
- Adds command-line history filtering for `Run`
- Loads project presets from a configurable glob
- Generates `<leader>rN` and `<leader>rrN`
- Exposes `:ProjectRunRedetect`

## Setup

```lua
require("project_run").setup({
  runner = {
    height = 12,
    ft = "runner",
  },
  project_glob = "lua/config/projects/*.lua",
})
```
