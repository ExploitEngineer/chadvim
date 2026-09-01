-- Linters that conform's formatters and the enabled LSPs don't already cover.
-- Not listed on purpose: js/ts (biome LSP), python (ruff LSP), c/cpp
-- (clangd --clang-tidy), rust (rust-analyzer + clippy).
local lint = require "lint"

lint.linters_by_ft = {
  sh = { "shellcheck" },
  bash = { "shellcheck" },
  -- no zsh: shellcheck has no zsh dialect and errors out on the whole file
  go = { "golangcilint" },
  dockerfile = { "hadolint" },
  markdown = { "markdownlint-cli2" },
}

local function try_lint()
  if not vim.g.autolint then
    return
  end
  -- names_of_linters returns {} for unconfigured filetypes, so this is a no-op
  -- everywhere else
  lint.try_lint()
end

-- BufWritePost only (not InsertLeave): golangci-lint runs the type checker over
-- the whole package, which is far too expensive to fire on every insert exit.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
  callback = try_lint,
})
