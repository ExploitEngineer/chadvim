return {
  {
    "catgoose/nvim-colorizer.lua",
    event = "User FilePost",
    opts = {
      filetypes = {
        "*",
        -- NvChad's own float/dashboard buffers draw with extmarks already
        "!lazy",
        "!mason",
        "!nvcheatsheet",
        "!nvdash",
        "!NvimTree",
        "!TelescopePrompt",
        "!trouble",
        "!help",
      },
      user_default_options = {
        names = false, -- else every `red`/`blue` identifier in C source gets painted
        tailwind = "both", -- class names *and* the hex the LSP resolves them to
        css = true,
        css_fn = true,
        mode = "virtualtext",
        virtualtext = "󱓻",
        virtualtext_inline = "before",
      },
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
