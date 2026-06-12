# Concepts

The building blocks every modern Neovim config is made of, what each one does, and where it lives in this config. If you've used VSCode: most of these are things VSCode does invisibly, split into explicit, swappable parts.

## lazy.nvim — the plugin manager

Plugins are just git repos cloned into `~/.local/share/nvim/lazy/`. [lazy.nvim](https://github.com/folke/lazy.nvim) clones them, loads them, and — its defining feature — **lazy-loads** them: a plugin isn't loaded into memory until something triggers it (a key, a command, a filetype, an event). That's why this config starts in ~40ms despite 50 plugins.

A plugin **spec** describes one plugin:

```lua
{
  "folke/trouble.nvim",        -- github repo
  cmd = "Trouble",             -- load when this command runs (trigger)
  keys = { ... },              -- ...or when these keys are pressed (trigger)
  event = "BufReadPre",        -- ...or on this event (trigger)
  opts = {},                   -- passed to the plugin's setup() function
  dependencies = { ... },      -- loaded together with it
}
```

`lazy-lock.json` records the exact commit of every plugin — commit it, and a fresh clone reproduces this exact setup. Commands: `:Lazy` (UI), `:Lazy sync` (install/update to match specs), `:Lazy update`.

> NvChad itself is installed through lazy.nvim as a plugin — see `init.lua`. It's a plugin that happens to bring a UI and defaults with it.

## LSP — Language Server Protocol

The thing that gives you _go to definition_, _rename_, _hover docs_, _code actions_, _diagnostics as you type_. A **language server** is a separate program (clangd, rust-analyzer, gopls…) that runs next to the editor, parses your whole project, and answers questions over a standard protocol. The editor doesn't understand C++ — clangd does; the editor just asks.

Neovim has the LSP **client** built in. Since 0.11 the native API is all you need:

```lua
vim.lsp.config("clangd", { ... settings ... })   -- configure
vim.lsp.enable("clangd")                          -- auto-start for matching filetypes
```

The [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) plugin supplies the default configs (which binary to run, which root markers to look for) that `vim.lsp.enable` picks up by name. Our server list and keymaps: `lua/configs/lspconfig.lua`. Check what's attached to the current file: `:LspInfo` / `:checkhealth vim.lsp`.

One filetype can run several servers in parallel — Python here runs **basedpyright** (types, hover, navigation) and **ruff** (lint, import sorting) at once.

## Mason — the tool installer

LSP servers, formatters, and debug adapters are external binaries. [mason.nvim](https://github.com/mason-org/mason.nvim) is a package manager _inside Neovim_ that downloads them into `~/.local/share/nvim/mason/` — no root, no fighting the system package manager. `:Mason` opens the UI; `:MasonInstallAll` (NvChad command) installs everything listed in `chadrc.lua`.

Mason **only installs binaries**. It doesn't configure anything — that's lspconfig/conform/dap's job. Mental model: Mason = `pacman`, lspconfig = the config file.

## Treesitter — real parsing for highlighting

Old-school vim highlighting was regex guesswork. [Tree-sitter](https://tree-sitter.github.io/) builds an actual syntax tree of the buffer, incrementally, as you type. That tree drives: accurate highlighting, indentation, code folding, and structural selections/motions (flash.nvim's `S` jump uses it; so does the `R` treesitter search).

Per-language **parsers** are compiled C libraries managed by nvim-treesitter — our parser list lives in `lua/plugins/init.lua` (`ensure_installed`). `:TSInstall <lang>` adds one manually; `:InspectTree` shows you the live syntax tree of the current buffer.

LSP and treesitter overlap but differ: treesitter knows the buffer's _structure_ (fast, local, no project knowledge); LSP knows the _project's meaning_ (types, references across files). You want both.

## Completion — nvim-cmp

The popup while typing. [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) is the completion _engine_; it pulls candidates from **sources**: the LSP server, snippets (LuaSnip), file paths, buffer words — and here also crates.nvim (Cargo.toml versions) and dadbod (SQL tables/columns in DB buffers). NvChad wires cmp up by default; we only add sources. `<C-Space>` to trigger manually, `<CR>` to accept.

## Formatters — conform.nvim

Code formatting has two routes: ask the LSP server, or run a dedicated formatter binary (clang-format, biome, stylua — usually faster and more opinionated). [conform.nvim](https://github.com/stevearc/conform.nvim) picks the right formatter per filetype and falls back to LSP when none is configured. Our table: `lua/configs/conform.lua`.

Format on demand: `<leader>cf`. Format on save: enabled, toggle with `<leader>uf` (global) / `<leader>uF` (buffer). Debug what would run: `:ConformInfo`.

## DAP — Debug Adapter Protocol

LSP's sibling, for debugging: breakpoints, stepping, variable inspection, REPL — inside the editor. Same idea: a **debug adapter** (codelldb for C/C++/Rust, debugpy for Python, delve for Go, js-debug for Node) speaks a standard protocol; [nvim-dap](https://github.com/mfussenegger/nvim-dap) is the client, [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) draws the panels (opens/closes automatically here).

Flow: compile with debug info (`gcc -g`, `cargo build`), set a breakpoint (`<leader>db`), start (`<leader>dc`), pick the executable, step with `<leader>di/dO/do`. Rust goes through rustaceanvim instead: `:RustLsp debuggables`. Adapters and per-language launch configs: `lua/configs/dap.lua`. Project-local `.vscode/launch.json` files are picked up automatically.

## NvChad & base46 — the distribution layer

NvChad is a curated base: plugin choices, sane defaults, and a cohesive UI (statusline, tabufline, dashboard, theme picker). Its theme engine, **base46**, is why themes feel instant: it _pre-compiles_ every highlight group into bytecode cache files at `~/.local/share/nvim/base46/`, and startup just `dofile`s them — no theme plugin runs at all.

Consequence to remember: highlights are **cached**. The `<leader>th` picker recompiles automatically, but manual edits to `chadrc.lua` (theme, `hl_override`, integrations) need `:Lazy build base46` to take effect.

## Telescope — the fuzzy finder

The search-everything UI: files (`<leader>ff`), text (`<leader>/`), buffers (`<leader>,`), help, keymaps, LSP symbols (`<leader>ss`), git status. Inside a picker: `<C-j>/<C-k>` move, `<CR>` open, `<C-x>/<C-v>` open in split. Telescope is also a framework — several plugins (todo-comments, NvChad's theme picker) ship their results as telescope pickers.

## which-key — discoverability

Press `<leader>` and wait: a popup lists every binding under that prefix, organized by the group labels defined in `lua/plugins/init.lua`. Forgot a mapping? `<leader>sk` fuzzy-searches all of them. This is the answer to "how do I remember all these keys" — you don't, you browse.

---

### The pipeline, end to end

Open `main.c` → lazy.nvim loads lspconfig/treesitter on the file event → treesitter parses (highlighting) → `vim.lsp.enable` starts **clangd** (Mason-installed binary) → diagnostics appear, `gd`/`K`/`<leader>ca` work, cmp completes from clangd → `:w` runs **clang-format** via conform → `<leader>db` + `<leader>dc` launches **codelldb** via nvim-dap. Five subsystems, one file.
