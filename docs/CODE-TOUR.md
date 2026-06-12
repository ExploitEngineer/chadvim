# Code Tour

How to read this config. Files are listed in the order Neovim actually loads them — read them in this order and the whole thing will make sense.

## The 30-second version

NvChad is **not a fork of Neovim** and this repo is **not a fork of NvChad**. NvChad is installed as a _plugin_ (see `init.lua`), and this repo only contains the deltas: our options, our keymaps, our plugin list. Everything NvChad-flavored you see on screen (statusline, tabufline, dashboard, themes) lives in the plugin at `~/.local/share/nvim/lazy/NvChad/` and `~/.local/share/nvim/lazy/ui/` — we just configure it.

## Load order (what happens when nvim starts)

```
init.lua
 ├─ 1. sets <space> as leader, base46 cache path
 ├─ 2. bootstraps lazy.nvim (clones it on first run)
 ├─ 3. require("lazy").setup({ NvChad/NvChad, import "plugins" }, configs/lazy.lua)
 │      └─ every file in lua/plugins/*.lua is merged into one plugin list
 ├─ 4. dofile(base46 cache) — pre-compiled theme highlights, this is why startup is fast
 ├─ 5. require "options"    (lua/options.lua)
 ├─ 6. require "autocmds"   (lua/autocmds.lua)
 └─ 7. vim.schedule → require "mappings"  (lua/mappings.lua — runs LAST, on purpose)
```

Step 7 matters: because `mappings.lua` runs _after_ all plugins are set up, anything we map there wins over both NvChad's defaults and plugin `keys=` specs. That's the mechanism behind every "conflict fix" in this config.

## Reading order

### 1. `init.lua`

Unchanged from the NvChad starter. Bootstrap + load order, nothing else. Don't edit it.

### 2. `lua/chadrc.lua`

NvChad's own config schema (mirrors [nvconfig.lua](https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua)). Owns:

- the theme (`M.base46.theme`)
- highlight overrides (`hl_override` — e.g. the Lazy UI readability fix)
- extra base46 integrations (theme colors for flash/trouble/dap/…)
- `M.mason.pkgs` — the list `:MasonInstallAll` installs. **Add new LSP servers/formatters/debuggers here first.**

### 3. `lua/options.lua`

Vim options. Loads NvChad's defaults, then our LazyVim ports (relativenumber, scrolloff, sessionoptions for persistence.nvim), plus two load-bearing lines: `vim.g.autoformat` (the format-on-save switch) and the mason `PATH` prepend (lets LSP binaries resolve before mason.nvim itself loads).

### 4. `lua/autocmds.lua`

Event hooks: highlight-on-yank, restore last cursor position, attach the SQL completion source in database buffers.

### 5. `lua/mappings.lua` — the heart of the config

All keybindings. Structured top-to-bottom:

1. `require "nvchad.mappings"` — NvChad defaults come in
2. deletions/overwrites of the five NvChad keys that fight LazyVim muscle memory
3. grouped sections: buffers, pickers, diagnostics, editing, windows, toggles, terminal, git, harpoon, dap, db

**Rule:** if a key's plugin is lazy-loaded AND NvChad maps the same key (harpoon's `<leader>h`, dap's `<leader>ds`, dbui's `<leader>D`), the mapping must live here as a `require()` closure — a `keys=` spec in the plugin file would get clobbered by step 1. Non-colliding keys live next to their plugin in `lua/plugins/*.lua`.

### 6. `lua/configs/` — implementation details

- `lazy.lua` — lazy.nvim's own settings (everything defaults to lazy-loaded; change-detection notification off)
- `lspconfig.lua` — replaces NvChad's `on_attach` (our LazyVim-style LSP keymaps), per-server settings, and the `vim.lsp.enable` list. **Add per-server tweaks here.**
- `conform.lua` — which formatter runs per filetype + the format-on-save logic
- `dap.lua` — debug adapter definitions (codelldb, debugpy, js-debug) and dap-ui auto open/close

### 7. `lua/plugins/` — the plugin list

Every file returns a list of lazy.nvim specs; all of them get imported automatically. Organized by theme:

| File         | Owns                                                                                                             |
| ------------ | ---------------------------------------------------------------------------------------------------------------- |
| `init.lua`   | overrides of NvChad's bundled plugins: conform, lspconfig wiring, treesitter parser list, which-key group labels |
| `editor.lua` | movement/editing: flash, trouble, todo-comments, grug-far, harpoon, persistence, mini.surround                   |
| `git.lua`    | gitsigns keymaps (via `on_attach`), diffview                                                                     |
| `dap.lua`    | the nvim-dap stack (ui, virtual-text, python/go helpers)                                                         |
| `lang.lua`   | language-specific: rustaceanvim, crates.nvim, schemastore                                                        |
| `tools.lua`  | kulala (REST client), dadbod (databases)                                                                         |

## "Where do I add…?"

| I want to…         | Touch                                                                                                                                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| add a plugin       | new spec in the matching `lua/plugins/*.lua` file (or a new file — auto-imported)                                                                                                                                   |
| add a keymap       | `lua/mappings.lua` if it collides with an NvChad default or belongs to a lazy plugin NvChad also maps; otherwise `keys=` in the plugin spec                                                                         |
| add a language     | server in `configs/lspconfig.lua` (`vim.lsp.config` + `vim.lsp.enable`), formatter in `configs/conform.lua`, parser in `plugins/init.lua` treesitter list, packages in `chadrc.lua` mason list → `:MasonInstallAll` |
| change the theme   | `<leader>th` (picker, recompiles automatically) or edit `chadrc.lua` then `:Lazy build base46`                                                                                                                      |
| change LSP keymaps | the `on_attach` function in `configs/lspconfig.lua`                                                                                                                                                                 |
| add a debugger     | adapter + configurations in `configs/dap.lua`, adapter package in `chadrc.lua`                                                                                                                                      |

New to LSP/DAP/Mason/treesitter as concepts? Read [CONCEPTS.md](CONCEPTS.md) first.
