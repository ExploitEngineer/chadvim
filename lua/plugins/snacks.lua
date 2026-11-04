-- snacks.nvim, for the parts NvChad's UI doesn't already cover. Only the
-- modules enabled here run: no dashboard, statuscolumn, indent or scroll,
-- because nvdash, NvChad's statuscolumn and indent-blankline own those.
--
-- Search keys live in lua/mappings.lua next to the rest of the <leader> map.
return {
  "folke/snacks.nvim",
  lazy = false, -- vim.ui.select must be the picker before anything calls it
  priority = 1000,
  opts = {
    picker = {
      enabled = true,
      -- vim.ui.select through the picker: compiler-explorer's ~900 compilers,
      -- code actions, :Octo and :RustLsp lists all get fuzzy search
      ui_select = true,
    },
  },
}
