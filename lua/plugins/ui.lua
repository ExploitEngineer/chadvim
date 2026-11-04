return {
  -- Colour codes (#hex, rgb(), hsl(), CSS variables, tailwind classes) get a
  -- swatch in front of them.
  {
    "brenoprata10/nvim-highlight-colors",
    event = "User FilePost",
    opts = {
      render = "virtual",
      virtual_symbol = "󱓻",
      virtual_symbol_position = "inline", -- before the code, VS Code style
      enable_named_colors = false, -- else every `red`/`blue` identifier in C source gets painted
      enable_tailwind = true,
      -- NvChad's own float/dashboard buffers draw with extmarks already
      exclude_filetypes = { "lazy", "mason", "nvcheatsheet", "nvdash", "trouble", "help" },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    -- octo renders its issue/PR buffers as markdown, so it gets the same treatment
    ft = { "markdown", "octo" },
    opts = {
      file_types = { "markdown", "octo" },
      completions = { lsp = { enabled = true } },
    },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown render" },
    },
  },
}
