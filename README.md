# chadvim

Personal Neovim configuration: **NvChad v2.5 base + LazyVim muscle-memory keybindings**, tuned for cybersecurity, low-level systems programming, and full-stack development.

Built on the [NvChad starter](https://github.com/NvChad/starter) skeleton — NvChad provides the UI (statusline, tabufline, themes, dashboard) and core plumbing; LazyVim's high-frequency keymaps are ported on top wherever the underlying plugin exists. This is a hybrid, not a LazyVim clone: no snacks.nvim, no noice — telescope and nvim-tree stay.

## Install

Prerequisites (Arch): `git ripgrep fd nodejs npm go rust lazygit gcc make unzip curl python` and a Nerd Font. `rustfmt` comes from the `rust` package; `rust-analyzer` is installed via Mason.

```bash
git clone <this-repo> ~/.config/nvim
nvim                  # first run: lazy.nvim bootstraps and installs everything
:MasonInstallAll      # LSP servers, formatters, debug adapters (async, run once)
```

## Docs

- [docs/CODE-TOUR.md](docs/CODE-TOUR.md) — reading order, load order, what lives where, "where do I add X"
- [docs/CONCEPTS.md](docs/CONCEPTS.md) — LSP, DAP, Mason, lazy.nvim, treesitter, conform, base46 … explained

## Structure

```
init.lua                  unchanged starter bootstrap (lazy.nvim + NvChad v2.5 import)
lua/chadrc.lua            theme + :MasonInstallAll package list
lua/options.lua           LazyVim option ports, sessionoptions, mason PATH
lua/autocmds.lua          yank highlight, restore last location, sql cmp source
lua/mappings.lua          THE keybinding layer: nvchad.mappings + conflict fixes + ports
lua/configs/
  lspconfig.lua           on_attach override + vim.lsp.config/enable (nvim 0.11+ API)
  conform.lua             formatters_by_ft + toggleable format-on-save
  dap.lua                 codelldb / debugpy / js-debug adapters, dap-ui wiring
lua/plugins/
  init.lua                core overrides: conform, lspconfig, treesitter, which-key groups
  editor.lua              flash, trouble, todo-comments, grug-far, harpoon2, persistence, mini.surround
  git.lua                 gitsigns keymaps, diffview
  dap.lua                 nvim-dap stack
  lang.lua                rustaceanvim, crates.nvim, schemastore
  tools.lua               kulala (REST), dadbod (DB)
```

## Languages

| Language | LSP | Formatter | DAP |
|---|---|---|---|
| C / C++ | clangd (clang-tidy on) | clang-format | codelldb |
| Assembly | asm-lsp | — | — |
| Rust | rust-analyzer via **rustaceanvim** | rustfmt (system) | codelldb via `:RustLsp debuggables` |
| Python | basedpyright + ruff | ruff (imports + format) | debugpy |
| Go | gopls (gofumpt, staticcheck) | goimports + gofumpt | delve (nvim-dap-go) |
| JS / TS / Next.js | vtsls + **biome** | biome | js-debug-adapter (pwa-node) |
| Web | html, cssls, tailwindcss | prettier (css/html/md/yaml) | — |
| Lua | lua_ls (NvChad default) | stylua | — |
| Misc | jsonls+yamlls (schemastore), bashls, dockerls | shfmt | — |

## Keybindings

`<leader>` = space. Press `<leader>` and wait for the which-key popup. NvChad defaults not listed here still apply (`<Tab>`/`<S-Tab>` buffer cycle, `<leader>th` theme picker, `<C-n>` tree, `<A-i/h/v>` terminals, …).

### Changed from stock NvChad (why: LazyVim muscle memory)

| Key | Now | Was |
|---|---|---|
| `<leader>e` | Explorer **toggle** | NvimTreeFocus |
| `<leader>/` | Live grep | Toggle comment (use `gcc` / `gc`) |
| `<leader>h` | Harpoon menu | Horizontal terminal (`<A-h>` remains) |
| `<leader>ds` | DAP session | Diagnostic loclist |
| `<leader>D` | DBUI toggle | LSP type definition (use `gy`) |

### General

| Key | Action |
|---|---|
| `<S-h>` / `<S-l>` | Prev / next buffer |
| `<leader>bd` / `<leader>bo` | Delete buffer / delete others |
| `<A-j>` / `<A-k>` | Move line/selection down/up (n,i,v) |
| `<leader>-` / `<leader>\|` / `<leader>wd` | Split below / right / close window |
| `<C-/>` | Bottom terminal (same toggle as `<A-h>`; `<A-i>` = floating) |
| `<leader>gg` | Lazygit (floating) |
| `s` / `S` | Flash jump / Flash treesitter |
| `gsa` / `gsd` / `gsr` | Surround add / delete / replace |
| `<leader>uw ud ul uL uf uF` | Toggle wrap / diagnostics / numbers / relnumber / autoformat global / buffer |
| `<leader>qs ql qS qd` | Session restore / last / select / stop |
| `<leader>H`, `<leader>1-5` | Harpoon add, jump to slot |

### Find / search

| Key | Action |
|---|---|
| `<leader><space>` `<leader>ff` | Find files |
| `<leader>,` `<leader>fb` | Buffers |
| `<leader>/` `<leader>sg` `<leader>fw` | Live grep |
| `<leader>sw` | Grep word under cursor |
| `<leader>sb` | Buffer fuzzy find |
| `<leader>sk` / `<leader>sh` / `<leader>:` | Keymaps / help / command history |
| `<leader>sR` | Resume last picker |
| `<leader>st` / `<leader>sT` | Todo comments (all / TODO+FIX only) |
| `<leader>sr` | Search & replace (grug-far) |

### LSP / code (buffer-local, on attach)

| Key | Action |
|---|---|
| `gd` `gr` `gI` `gy` `gD` | Definition / references / implementation / type def / declaration |
| `K` / `gK` / `<C-k>` (i) | Hover / signature help |
| `<leader>ca` | Code action |
| `<leader>cr` (also `<leader>ra`) | Rename |
| `<leader>cf` (also `<leader>fm`) | Format |
| `<leader>cd` | Line diagnostics |
| `<leader>ss` / `<leader>sS` | Document / workspace symbols |
| `]d [d ]e [e ]w [w` | Next/prev diagnostic / error / warning |
| `<leader>xx xX xl xq xt` | Trouble: diagnostics / buffer / loclist / quickfix / todos |
| `<leader>cs` | Symbols outline (Trouble) |

### Git

| Key | Action |
|---|---|
| `]h` / `[h` | Next / prev hunk |
| `<leader>ghs ghr ghS ghR` | Stage / reset hunk, stage / reset buffer |
| `<leader>ghp` / `<leader>ghd` | Preview hunk inline / diff this |
| `<leader>gb` / `<leader>ghb` | Blame line (short / full) |
| `<leader>gd` / `<leader>gf` / `<leader>gF` | Diffview / file history / repo history |
| `<leader>gt` / `<leader>cm` | Git status / commits (telescope, NvChad) |

### Debug (DAP)

| Key | Action |
|---|---|
| `<leader>db` / `<leader>dB` | Toggle / conditional breakpoint |
| `<leader>dc` / `<leader>da` | Continue / run with args |
| `<leader>di do dO` | Step into / out / over |
| `<leader>dC` / `<leader>dg` | Run to cursor / go to line |
| `<leader>dj dk` | Down / up stack frame |
| `<leader>dl dr ds dt dP` | Run last / REPL / session / terminate / pause |
| `<leader>du` / `<leader>de` / `<leader>dw` | Dap UI / eval / widgets |

### REST & DB

| Key | Action |
|---|---|
| `<leader>Rs Ra Rr` | Send request / send all / replay (`.http` files) |
| `<leader>Ri Rc Rt` | Inspect / copy as cURL / toggle headers-body |
| `<leader>Rn Rp Rq Rb` | Next / prev request, close UI, scratchpad |
| `<leader>D` | Toggle DBUI |

## Maintenance notes

- **Update**: `:Lazy update`. After NvChad updates, re-check that the LSP `<leader>D` shadow fix still holds (`:map <leader>D` in an LSP buffer should show only DBUI) — it relies on `nvchad.configs.lspconfig` resolving `on_attach` at LspAttach time.
- **Broken highlights after update/theme edit**: rebuild the base46 cache — `:Lazy build base46` or `rm -rf ~/.local/share/nvim/base46`.
- **Mappings load order**: `lua/mappings.lua` runs after lazy setup, so NvChad's own maps would clobber plugin `keys=` specs on the same LHS. Keys that collide (harpoon, dap, dbui) are defined in `mappings.lua` as `require()` closures — keep new colliding keys there, not in plugin specs.
- **Biome in monorepos**: nested packages need `"extends"` from the root `biome.json` or the server won't attach.
- **codelldb**: adapter shim at `~/.local/share/nvim/mason/bin/codelldb`; fallback path is `mason/packages/codelldb/extension/adapter/codelldb`.
